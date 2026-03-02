const { Op } = require("sequelize");
const { WorkoutLog, Member, ProgramWorkout, ProgramMembership, Workout, DailyHealthLog } = require("../models");
const { AppError } = require("../utils/response");

// ── Authorization helper ──

async function resolveLogPermissions(program_id, requester) {
    if (requester?.global_role === "global_admin") return true;

    const membership = await ProgramMembership.findOne({
        where: { program_id, member_id: requester?.id }
    });
    if (!membership) throw new AppError(403, "You are not enrolled in this program.");

    return ["admin", "logger"].includes(membership.role);
}

const parseOptionalNumber = (value) => {
    if (value === undefined || value === null || value === "") return null;
    const num = Number(value);
    return Number.isFinite(num) ? num : NaN;
};

// ── Workout Logs ──

async function getWorkoutLogs({ date, programId }, requester) {
    if (!date) throw new AppError(400, "Date is required.");

    const whereCondition = { log_date: date };
    if (programId) whereCondition.program_id = programId;

    const logs = await WorkoutLog.findAll({
        where: whereCondition,
        include: [
            { model: Member, attributes: ['member_name'] },
            { model: ProgramWorkout, attributes: ["workout_name"] }
        ]
    });

    let canEditOther = false;
    if (programId) {
        canEditOther = await resolveLogPermissions(programId, requester);
    } else {
        canEditOther = requester.role === 'admin';
    }

    return logs.map(log => ({
        member_id: log.member_id,
        member_name: log.Member ? log.Member.member_name : null,
        workout_name: log.ProgramWorkout ? log.ProgramWorkout.workout_name : null,
        date: log.log_date,
        duration: log.duration,
        canEdit: canEditOther || log.member_id === requester.id
    }));
}

async function addWorkoutLog({ member_name, member_id: bodyMemberId, workout_name, date, duration, program_id }, requester) {
    if (!workout_name || !date || !duration) {
        throw new AppError(400, "All fields are required.");
    }
    if (!program_id) throw new AppError(400, "program_id is required.");
    if (isNaN(duration)) throw new AppError(400, "Duration must be a number.");

    let member_id = requester.id;
    const canLogForAny = await resolveLogPermissions(program_id, requester);

    if (bodyMemberId) {
        if (!canLogForAny && bodyMemberId !== requester?.id) {
            throw new AppError(403, "You can only log your own workouts.");
        }
        if (canLogForAny) member_id = bodyMemberId;
    } else if (member_name) {
        if (!canLogForAny && member_name !== requester?.member_name) {
            throw new AppError(403, "You can only log your own workouts.");
        }
        const member = await Member.findOne({ where: { member_name } });
        if (!member) throw new AppError(404, "Member not found.");
        if (!canLogForAny && member.id !== requester?.id) {
            throw new AppError(403, "You can only log your own workouts.");
        }
        member_id = member.id;
    }

    const targetMembership = await ProgramMembership.findOne({
        where: { program_id, member_id, status: "active" }
    });
    if (!targetMembership) throw new AppError(404, "Member is not an active participant in this program.");

    const workoutName = workout_name.trim();
    let programWorkout = null;

    const libraryWorkout = await Workout.findOne({ where: { workout_name: workoutName } });

    if (libraryWorkout) {
        programWorkout = await ProgramWorkout.findOne({
            where: { program_id, library_workout_id: libraryWorkout.id }
        });

        if (!programWorkout) {
            const existingCustom = await ProgramWorkout.findOne({
                where: { program_id, workout_name: workoutName, library_workout_id: null }
            });

            if (existingCustom) {
                programWorkout = await existingCustom.update({ library_workout_id: libraryWorkout.id });
            } else {
                programWorkout = await ProgramWorkout.create({
                    program_id,
                    workout_name: libraryWorkout.workout_name,
                    library_workout_id: libraryWorkout.id
                });
            }
        }
    } else {
        programWorkout = await ProgramWorkout.findOne({ where: { program_id, workout_name: workoutName } });
        if (!programWorkout) {
            programWorkout = await ProgramWorkout.create({
                program_id, workout_name: workoutName, library_workout_id: null
            });
        }
    }

    const newLog = await WorkoutLog.create({
        program_id,
        member_id,
        program_workout_id: programWorkout.id,
        log_date: date,
        duration: parseInt(duration, 10)
    });

    const member = await Member.findByPk(member_id);

    return {
        ...newLog.toJSON(),
        member_name: member ? member.member_name : null,
        workout_name: workoutName,
        date
    };
}

async function updateWorkoutLog({ member_name, workout_name, date, duration, program_id }, requester) {
    if (!workout_name || !date || !duration) {
        throw new AppError(400, "Workout name, date, and duration are required.");
    }
    if (!program_id) throw new AppError(400, "program_id is required.");

    let member_id = requester.id;

    if (member_name && member_name !== requester.member_name) {
        const canEditOther = await resolveLogPermissions(program_id, requester);
        if (!canEditOther) {
            throw new AppError(403, "You can only update your own logs.");
        }
        const member = await Member.findOne({ where: { member_name } });
        if (!member) throw new AppError(404, "Member not found.");
        member_id = member.id;
    }

    const programWorkout = await ProgramWorkout.findOne({
        where: { program_id, workout_name: workout_name.trim() }
    });
    if (!programWorkout) throw new AppError(404, "Workout type not found for program.");

    const log = await WorkoutLog.findOne({
        where: { program_id, member_id, program_workout_id: programWorkout.id, log_date: date }
    });
    if (!log) throw new AppError(404, "Workout log not found.");

    log.duration = parseInt(duration, 10);
    await log.save();

    return { ...log.toJSON(), workout_name: workout_name.trim(), date };
}

async function deleteWorkoutLog({ member_id, member_name, workout_name, date, program_id }, requester) {
    if (!workout_name || !date) throw new AppError(400, "Workout name and date are required.");
    if (!program_id) throw new AppError(400, "program_id is required.");

    const programWorkout = await ProgramWorkout.findOne({
        where: { program_id, workout_name: workout_name.trim() }
    });
    if (!programWorkout) throw new AppError(404, "Workout type not found for program.");

    const whereCondition = { program_id, program_workout_id: programWorkout.id, log_date: date };

    if (member_id) {
        whereCondition.member_id = member_id;
    } else if (member_name) {
        const canDeleteOther = await resolveLogPermissions(program_id, requester);
        if (!canDeleteOther && requester.member_name !== member_name) {
            throw new AppError(403, "You can only delete your own logs.");
        }
        const member = await Member.findOne({ where: { member_name } });
        if (!member) throw new AppError(404, "Member not found.");
        whereCondition.member_id = member.id;
    } else {
        whereCondition.member_id = requester.id;
    }

    const log = await WorkoutLog.findOne({ where: whereCondition });
    if (!log) throw new AppError(404, "Workout log not found.");

    const canDeleteOther = await resolveLogPermissions(program_id, requester);
    if (!canDeleteOther && log.member_id !== requester.id) {
        throw new AppError(403, "You can only delete your own logs.");
    }

    await log.destroy();
    return { message: "Workout log deleted successfully." };
}

async function getMemberWorkoutLogs(memberName, requester) {
    const member = await Member.findOne({ where: { member_name: memberName } });
    if (!member) throw new AppError(404, "Member not found.");

    if (requester.role !== 'admin' && requester.id !== member.id) {
        throw new AppError(403, "You can only view your own logs.");
    }

    const logs = await WorkoutLog.findAll({
        where: { member_id: member.id },
        include: [{ model: ProgramWorkout, attributes: ["workout_name"] }],
        order: [["log_date", "DESC"]]
    });

    return logs.map(log => ({
        ...log.toJSON(),
        member_name: memberName,
        workout_name: log.ProgramWorkout ? log.ProgramWorkout.workout_name : null,
        date: log.log_date
    }));
}

// ── Daily Health Logs ──

async function addDailyHealthLog({ program_id, log_date, sleep_hours, food_quality, member_id: bodyMemberId }, requester) {
    if (!program_id || !log_date) throw new AppError(400, "program_id and log_date are required.");

    const sleepValue = parseOptionalNumber(sleep_hours);
    const foodValue = parseOptionalNumber(food_quality);

    if (Number.isNaN(sleepValue)) throw new AppError(400, "sleep_hours must be a number.");
    if (Number.isNaN(foodValue)) throw new AppError(400, "food_quality must be a number.");
    if (sleepValue === null && foodValue === null) throw new AppError(400, "At least one of sleep_hours or food_quality is required.");
    if (sleepValue !== null && (sleepValue < 0 || sleepValue > 24)) throw new AppError(400, "sleep_hours must be between 0 and 24.");
    if (foodValue !== null && (!Number.isInteger(foodValue) || foodValue < 1 || foodValue > 5)) {
        throw new AppError(400, "food_quality must be an integer between 1 and 5.");
    }

    const canLogForAny = await resolveLogPermissions(program_id, requester);

    let targetMemberId = requester?.id;
    if (bodyMemberId) {
        if (!canLogForAny && bodyMemberId !== requester?.id) throw new AppError(403, "You can only log your own daily health.");
        if (canLogForAny) targetMemberId = bodyMemberId;
    }

    const targetMembership = await ProgramMembership.findOne({
        where: { program_id, member_id: targetMemberId, status: "active" }
    });
    if (!targetMembership) throw new AppError(404, "Member is not enrolled in this program.");

    const existing = await DailyHealthLog.findOne({
        where: { program_id, member_id: targetMemberId, log_date }
    });
    if (existing) throw new AppError(409, "Daily health log already exists for this date.");

    return DailyHealthLog.create({
        program_id, member_id: targetMemberId, log_date,
        sleep_hours: sleepValue, food_quality: foodValue
    });
}

async function getDailyHealthLogs({
    programId, memberId, limit = 1000,
    startDate, endDate, sortBy = "date", sortDir = "desc",
    minSleepHours, maxSleepHours, minFoodQuality, maxFoodQuality
}, requester) {
    if (!programId || !memberId) throw new AppError(400, "programId and memberId are required.");

    const canLogForAny = await resolveLogPermissions(programId, requester);
    if (!canLogForAny && memberId !== requester?.id) {
        throw new AppError(403, "You can only view your own daily health logs.");
    }

    const targetMembership = await ProgramMembership.findOne({
        where: { program_id: programId, member_id: memberId, status: "active" }
    });
    if (!targetMembership) throw new AppError(404, "Member is not enrolled in this program.");

    const whereClause = { program_id: programId, member_id: memberId };
    if (startDate || endDate) {
        whereClause.log_date = {};
        if (startDate) whereClause.log_date[Op.gte] = startDate;
        if (endDate) whereClause.log_date[Op.lte] = endDate;
    }

    const sleepNum = (v) => {
        if (v === undefined || v === null || v === "") return undefined;
        const n = Number(v);
        return Number.isFinite(n) ? n : undefined;
    };
    const minS = sleepNum(minSleepHours);
    const maxS = sleepNum(maxSleepHours);
    if (minS !== undefined || maxS !== undefined) {
        const sleepCond = [{ sleep_hours: { [Op.ne]: null } }];
        if (minS !== undefined) sleepCond.push({ sleep_hours: { [Op.gte]: minS } });
        if (maxS !== undefined) sleepCond.push({ sleep_hours: { [Op.lte]: maxS } });
        whereClause[Op.and] = whereClause[Op.and] || [];
        whereClause[Op.and].push({ [Op.and]: sleepCond });
    }

    const dietInt = (v) => {
        if (v === undefined || v === null || v === "") return undefined;
        const n = parseInt(v, 10);
        return Number.isFinite(n) && n >= 1 && n <= 5 ? n : undefined;
    };
    const minF = dietInt(minFoodQuality);
    const maxF = dietInt(maxFoodQuality);
    if (minF !== undefined || maxF !== undefined) {
        const dietCond = [{ food_quality: { [Op.ne]: null } }];
        if (minF !== undefined) dietCond.push({ food_quality: { [Op.gte]: minF } });
        if (maxF !== undefined) dietCond.push({ food_quality: { [Op.lte]: maxF } });
        whereClause[Op.and] = whereClause[Op.and] || [];
        whereClause[Op.and].push({ [Op.and]: dietCond });
    }

    let orderColumn;
    switch (sortBy) {
        case "sleep_hours": orderColumn = "sleep_hours"; break;
        case "food_quality": orderColumn = "food_quality"; break;
        default: orderColumn = "log_date"; break;
    }
    const orderDirection = sortDir.toLowerCase() === "asc" ? "ASC" : "DESC";

    const queryOptions = {
        where: whereClause,
        order: [[orderColumn, orderDirection]],
        attributes: ["program_id", "member_id", "log_date", "sleep_hours", "food_quality"]
    };
    const limitNum = Number(limit);
    if (limitNum > 0) queryOptions.limit = limitNum;

    const logs = await DailyHealthLog.findAll(queryOptions);

    const items = logs.map((log, idx) => ({
        id: `${log.member_id}-${log.log_date}-${idx}`,
        logDate: log.log_date,
        sleepHours: log.sleep_hours !== null && log.sleep_hours !== undefined ? Number(log.sleep_hours) : null,
        foodQuality: log.food_quality !== null && log.food_quality !== undefined ? Number(log.food_quality) : null
    }));

    return {
        items,
        total: items.length,
        filters: {
            startDate: startDate || null,
            endDate: endDate || null,
            sortBy,
            sortDir: orderDirection.toLowerCase(),
            minSleepHours: minS ?? null,
            maxSleepHours: maxS ?? null,
            minFoodQuality: minF ?? null,
            maxFoodQuality: maxF ?? null
        }
    };
}

async function updateDailyHealthLog({ program_id, log_date, sleep_hours, food_quality, member_id: bodyMemberId }, requester, body) {
    if (!program_id || !log_date) throw new AppError(400, "program_id and log_date are required.");

    const sleepValue = parseOptionalNumber(sleep_hours);
    const foodValue = parseOptionalNumber(food_quality);
    const hasSleepField = Object.prototype.hasOwnProperty.call(body, "sleep_hours");
    const hasFoodField = Object.prototype.hasOwnProperty.call(body, "food_quality");

    if (!hasSleepField && !hasFoodField) throw new AppError(400, "At least one of sleep_hours or food_quality is required.");
    if (hasSleepField && Number.isNaN(sleepValue)) throw new AppError(400, "sleep_hours must be a number.");
    if (hasFoodField && Number.isNaN(foodValue)) throw new AppError(400, "food_quality must be a number.");
    if (sleepValue === null && foodValue === null) throw new AppError(400, "At least one of sleep_hours or food_quality is required.");
    if (sleepValue !== null && (sleepValue < 0 || sleepValue > 24)) throw new AppError(400, "sleep_hours must be between 0 and 24.");
    if (foodValue !== null && (!Number.isInteger(foodValue) || foodValue < 1 || foodValue > 5)) {
        throw new AppError(400, "food_quality must be an integer between 1 and 5.");
    }

    const canLogForAny = await resolveLogPermissions(program_id, requester);

    let targetMemberId = requester?.id;
    if (bodyMemberId) {
        if (!canLogForAny && bodyMemberId !== requester?.id) throw new AppError(403, "You can only update your own daily health.");
        if (canLogForAny) targetMemberId = bodyMemberId;
    }

    const targetMembership = await ProgramMembership.findOne({
        where: { program_id, member_id: targetMemberId, status: "active" }
    });
    if (!targetMembership) throw new AppError(404, "Member is not enrolled in this program.");

    const log = await DailyHealthLog.findOne({
        where: { program_id, member_id: targetMemberId, log_date }
    });
    if (!log) throw new AppError(404, "Daily health log not found.");

    const updateData = {};
    if (hasSleepField) updateData.sleep_hours = sleepValue;
    if (hasFoodField) updateData.food_quality = foodValue;

    await log.update(updateData);
    return log;
}

async function deleteDailyHealthLog({ program_id, log_date, member_id: bodyMemberId }, requester) {
    if (!program_id || !log_date) throw new AppError(400, "program_id and log_date are required.");

    const canLogForAny = await resolveLogPermissions(program_id, requester);

    let targetMemberId = requester?.id;
    if (bodyMemberId) {
        if (!canLogForAny && bodyMemberId !== requester?.id) throw new AppError(403, "You can only delete your own daily health.");
        if (canLogForAny) targetMemberId = bodyMemberId;
    }

    const targetMembership = await ProgramMembership.findOne({
        where: { program_id, member_id: targetMemberId, status: "active" }
    });
    if (!targetMembership) throw new AppError(404, "Member is not enrolled in this program.");

    const log = await DailyHealthLog.findOne({
        where: { program_id, member_id: targetMemberId, log_date }
    });
    if (!log) throw new AppError(404, "Daily health log not found.");

    await log.destroy();
    return { message: "Daily health log deleted successfully." };
}

module.exports = {
    getWorkoutLogs,
    addWorkoutLog,
    updateWorkoutLog,
    deleteWorkoutLog,
    getMemberWorkoutLogs,
    addDailyHealthLog,
    getDailyHealthLogs,
    updateDailyHealthLog,
    deleteDailyHealthLog
};
