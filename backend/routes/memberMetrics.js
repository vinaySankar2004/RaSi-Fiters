const express = require("express");
const { Op } = require("sequelize");
const { authenticateToken } = require("../middleware/auth");
const { ProgramMembership, Member, WorkoutLog, Program, DailyHealthLog, ProgramWorkout } = require("../models");

const router = express.Router();

const SORTABLE_FIELDS = new Set([
    "workouts",
    "total_duration",
    "avg_duration",
    "active_days",
    "workout_types",
    "current_streak",
    "longest_streak",
    "avg_sleep_hours",
    "avg_food_quality"
]);

// Utility: compute streaks given sorted date strings (ascending)
const computeStreaks = (dateStrings) => {
    if (!dateStrings.length) {
        return { current: 0, longest: 0 };
    }
    const dates = dateStrings.map(d => new Date(`${d}T00:00:00Z`)).sort((a, b) => a - b);
    let longest = 1;
    let currentRun = 1;
    for (let i = 1; i < dates.length; i++) {
        const prev = dates[i - 1];
        const curr = dates[i];
        const diff = (curr - prev) / (1000 * 60 * 60 * 24);
        if (diff === 1) {
            currentRun += 1;
        } else if (diff === 0) {
            // same day, ignore
        } else {
            longest = Math.max(longest, currentRun);
            currentRun = 1;
        }
    }
    longest = Math.max(longest, currentRun);
    // current streak: streak that includes the latest day if contiguous backwards
    let current = 1;
    for (let i = dates.length - 1; i > 0; i--) {
        const diff = (dates[i] - dates[i - 1]) / (1000 * 60 * 60 * 24);
        if (diff === 1 || diff === 0) {
            current += 1;
        } else {
            break;
        }
    }
    return { current, longest };
};

const isInCurrentMonth = (dateString) => {
    const today = new Date();
    const d = new Date(`${dateString}T00:00:00Z`);
    return d.getUTCFullYear() === today.getUTCFullYear() && d.getUTCMonth() === today.getUTCMonth();
};

// Authorization helper: allow global_admin, otherwise require membership in program
const ensureProgramAccess = async (req, programId) => {
    if (req.user?.global_role === "global_admin") return true;
    if (!req.user?.id) return false;
    const membership = await ProgramMembership.findOne({
        where: { program_id: programId, member_id: req.user.id, status: "active" }
    });
    return Boolean(membership);
};

router.get("/", authenticateToken, async (req, res) => {
    try {
        const {
            programId,
            search = "",
            sort = "workouts",
            direction = "desc",
            startDate,
            endDate,
            memberId,
            workoutsMin,
            workoutsMax,
            totalDurationMin,
            totalDurationMax,
            avgDurationMin,
            avgDurationMax,
            avgSleepHoursMin,
            avgSleepHoursMax,
            activeDaysMin,
            activeDaysMax,
            workoutTypesMin,
            workoutTypesMax,
            currentStreakMin,
            longestStreakMin,
            avgFoodQualityMin,
            avgFoodQualityMax
        } = req.query;

        if (!programId) {
            return res.status(400).json({ error: "programId is required" });
        }

        const hasAccess = await ensureProgramAccess(req, programId);
        if (!hasAccess) {
            return res.status(403).json({ error: "Access denied. Program membership required." });
        }

        const sortField = SORTABLE_FIELDS.has(sort) ? sort : "workouts";
        const dir = direction === "asc" ? "asc" : "desc";

        // Program info for date bounds
        const program = await Program.findOne({
            where: { id: programId, is_deleted: false }
        });
        if (!program) {
            return res.status(404).json({ error: "Program not found." });
        }
        const programStart = program.start_date ? new Date(`${program.start_date}T00:00:00Z`) : null;
        const today = new Date();

        // Date range validation and clamping
        let rangeStart = startDate ? new Date(`${startDate}T00:00:00Z`) : programStart || null;
        let rangeEnd = endDate ? new Date(`${endDate}T23:59:59Z`) : today;

        if (rangeStart && programStart && rangeStart < programStart) rangeStart = programStart;
        if (rangeEnd > today) rangeEnd = today;
        if (rangeStart && rangeEnd && rangeEnd < rangeStart) {
            return res.status(400).json({ error: "Invalid date range." });
        }

        // Load members in program (optionally filtered by memberId)
        const memberWhere = memberId
            ? { program_id: programId, member_id: memberId, status: "active" }
            : { program_id: programId, status: "active" };
        const memberships = await ProgramMembership.findAll({
            where: memberWhere,
            include: [{
                model: Member,
                attributes: ["id", "first_name", "last_name", "username"]
            }]
        });

        const memberIds = memberships.map(m => m.member_id);

        // Load logs for program/members
        const logs = await WorkoutLog.findAll({
            where: {
                program_id: programId,
                member_id: { [Op.in]: memberIds },
                ...(rangeStart && rangeEnd ? {
                    log_date: {
                        [Op.between]: [
                            rangeStart.toISOString().slice(0, 10),
                            rangeEnd.toISOString().slice(0, 10)
                        ]
                    }
                } : {})
            },
            attributes: ["member_id", "log_date", "duration", "program_workout_id"],
            include: [{
                model: ProgramWorkout,
                attributes: ["workout_name"]
            }]
        });

        const healthLogs = memberIds.length ? await DailyHealthLog.findAll({
            where: {
                program_id: programId,
                member_id: { [Op.in]: memberIds },
                ...(rangeStart && rangeEnd ? {
                    log_date: {
                        [Op.between]: [
                            rangeStart.toISOString().slice(0, 10),
                            rangeEnd.toISOString().slice(0, 10)
                        ]
                    }
                } : {})
            },
            attributes: ["member_id", "log_date", "sleep_hours", "food_quality"]
        }) : [];

        // Aggregate metrics
        const metricsMap = new Map(); // member_id -> metrics object
        for (const m of memberships) {
            const firstName = m.Member?.first_name || "";
            const lastName = m.Member?.last_name || "";
            const memberName = `${firstName} ${lastName}`.trim() || "Unknown";
            metricsMap.set(m.member_id, {
                member_id: m.member_id,
                member_name: memberName,
                username: m.Member?.username || "",
                workouts: 0,
                total_duration: 0,
                avg_duration: 0,
                active_days: 0,
                workout_types: 0,
                current_streak: 0,
                longest_streak: 0,
                mtd_workouts: 0,
                total_hours: 0,
                favorite_workout: null,
                avg_sleep_hours: null,
                avg_food_quality: null
            });
        }

        const perMemberDates = new Map(); // member_id -> Set of dates
        const perMemberTypes = new Map(); // member_id -> Set of workout types
        const perMemberTypeCounts = new Map(); // member_id -> Map of type -> count
        const perMemberSleepSum = new Map(); // member_id -> sum of sleep hours
        const perMemberSleepCount = new Map(); // member_id -> count of sleep entries
        const perMemberFoodSum = new Map(); // member_id -> sum of food quality
        const perMemberFoodCount = new Map(); // member_id -> count of food entries

        for (const log of logs) {
            const entry = metricsMap.get(log.member_id);
            if (!entry) continue;
            entry.workouts += 1;
            entry.total_duration += Number(log.duration || 0);
            if (isInCurrentMonth(log.log_date)) {
                entry.mtd_workouts += 1;
            }

            if (!perMemberDates.has(log.member_id)) perMemberDates.set(log.member_id, new Set());
            perMemberDates.get(log.member_id).add(log.log_date);

            const workoutName = log.ProgramWorkout?.workout_name || "";
            if (!perMemberTypes.has(log.member_id)) perMemberTypes.set(log.member_id, new Set());
            perMemberTypes.get(log.member_id).add(workoutName);

            if (!perMemberTypeCounts.has(log.member_id)) perMemberTypeCounts.set(log.member_id, new Map());
            const tmap = perMemberTypeCounts.get(log.member_id);
            tmap.set(workoutName, (tmap.get(workoutName) || 0) + 1);
        }

        for (const log of healthLogs) {
            const entry = metricsMap.get(log.member_id);
            if (!entry) continue;

            if (log.sleep_hours !== null && log.sleep_hours !== undefined) {
                const sleepValue = Number(log.sleep_hours);
                if (Number.isFinite(sleepValue)) {
                    perMemberSleepSum.set(log.member_id, (perMemberSleepSum.get(log.member_id) || 0) + sleepValue);
                    perMemberSleepCount.set(log.member_id, (perMemberSleepCount.get(log.member_id) || 0) + 1);
                }
            }

            if (log.food_quality !== null && log.food_quality !== undefined) {
                const foodValue = Number(log.food_quality);
                if (Number.isFinite(foodValue)) {
                    perMemberFoodSum.set(log.member_id, (perMemberFoodSum.get(log.member_id) || 0) + foodValue);
                    perMemberFoodCount.set(log.member_id, (perMemberFoodCount.get(log.member_id) || 0) + 1);
                }
            }
        }

        for (const [memberId, entry] of metricsMap.entries()) {
            if (entry.workouts > 0) {
                entry.avg_duration = Math.round(entry.total_duration / entry.workouts);
                entry.total_hours = Math.round(entry.total_duration / 60);
            }
            const dateSet = perMemberDates.get(memberId);
            entry.active_days = dateSet ? dateSet.size : 0;
            const typeSet = perMemberTypes.get(memberId);
            entry.workout_types = typeSet ? typeSet.size : 0;

            if (dateSet) {
                const { current, longest } = computeStreaks(Array.from(dateSet));
                entry.current_streak = current;
                entry.longest_streak = longest;
            }

            // Favorite workout type
            const tmap = perMemberTypeCounts.get(memberId);
            if (tmap && tmap.size > 0) {
                let fav = "";
                let max = -1;
                for (const [k, v] of tmap.entries()) {
                    if (v > max) {
                        max = v;
                        fav = k;
                    }
                }
                entry.favorite_workout = fav || null;
            }

            const sleepCount = perMemberSleepCount.get(memberId) || 0;
            if (sleepCount > 0) {
                const avgSleep = (perMemberSleepSum.get(memberId) || 0) / sleepCount;
                entry.avg_sleep_hours = Math.round(avgSleep * 10) / 10;
            }

            const foodCount = perMemberFoodCount.get(memberId) || 0;
            if (foodCount > 0) {
                const avgFood = (perMemberFoodSum.get(memberId) || 0) / foodCount;
                entry.avg_food_quality = Math.round(avgFood);
            }
        }

        // Convert to array
        let result = Array.from(metricsMap.values());

        // Search
        const searchTrim = search.trim().toLowerCase();
        if (searchTrim) {
            result = result.filter(r =>
                r.member_name.toLowerCase().includes(searchTrim) ||
                r.username.toLowerCase().includes(searchTrim)
            );
        }

        // Filters
        const num = (v) => (v !== undefined ? Number(v) : undefined);
        const filters = {
            workouts: [num(workoutsMin), num(workoutsMax)],
            total_duration: [num(totalDurationMin), num(totalDurationMax)],
            avg_duration: [num(avgDurationMin), num(avgDurationMax)],
            avg_sleep_hours: [num(avgSleepHoursMin), num(avgSleepHoursMax)],
            active_days: [num(activeDaysMin), num(activeDaysMax)],
            workout_types: [num(workoutTypesMin), num(workoutTypesMax)],
            current_streak: [num(currentStreakMin), undefined],
            longest_streak: [num(longestStreakMin), undefined],
            avg_food_quality: [num(avgFoodQualityMin), num(avgFoodQualityMax)]
        };

        result = result.filter(r => {
            const within = (value, min, max) => {
                if (min !== undefined && !Number.isNaN(min) && value < min) return false;
                if (max !== undefined && !Number.isNaN(max) && value > max) return false;
                return true;
            };
            return (
                within(r.workouts, filters.workouts[0], filters.workouts[1]) &&
                within(r.total_duration, filters.total_duration[0], filters.total_duration[1]) &&
                within(r.avg_duration, filters.avg_duration[0], filters.avg_duration[1]) &&
                within(r.avg_sleep_hours ?? 0, filters.avg_sleep_hours[0], filters.avg_sleep_hours[1]) &&
                within(r.active_days, filters.active_days[0], filters.active_days[1]) &&
                within(r.workout_types, filters.workout_types[0], filters.workout_types[1]) &&
                within(r.current_streak, filters.current_streak[0], filters.current_streak[1]) &&
                within(r.longest_streak, filters.longest_streak[0], filters.longest_streak[1]) &&
                within(r.avg_food_quality ?? 0, filters.avg_food_quality[0], filters.avg_food_quality[1])
            );
        });

        // Sort
        result.sort((a, b) => {
            const av = a[sortField] ?? 0;
            const bv = b[sortField] ?? 0;
            if (av === bv) return 0;
            return dir === "asc" ? av - bv : bv - av;
        });

        res.json({
            program_id: programId,
            total: metricsMap.size,
            filtered: result.length,
            sort: sortField,
            direction: dir,
            date_range: {
                start: rangeStart ? rangeStart.toISOString().slice(0, 10) : null,
                end: rangeEnd ? rangeEnd.toISOString().slice(0, 10) : null
            },
            members: result
        });
    } catch (err) {
        console.error("Error fetching member metrics:", err);
        res.status(500).json({ error: "Failed to fetch member metrics." });
    }
});

module.exports = router;
