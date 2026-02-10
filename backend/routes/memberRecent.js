const express = require("express");
const { authenticateToken } = require("../middleware/auth");
const { WorkoutLog, ProgramWorkout, ProgramMembership } = require("../models");
const { Op } = require("sequelize");

const router = express.Router();

const ensureActiveProgramAccess = async (req, programId) => {
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
            memberId, 
            limit = 1000,
            startDate,
            endDate,
            sortBy = "date",
            sortDir = "desc"
        } = req.query;
        
        if (!programId || !memberId) {
            return res.status(400).json({ error: "programId and memberId are required." });
        }

        const hasAccess = await ensureActiveProgramAccess(req, programId);
        if (!hasAccess) {
            return res.status(403).json({ error: "Access denied. Active program membership required." });
        }

        const targetMembership = await ProgramMembership.findOne({
            where: { program_id: programId, member_id: memberId, status: "active" }
        });
        if (!targetMembership) {
            return res.status(404).json({ error: "Member is not enrolled in this program." });
        }

        // Build where clause with date filtering
        const whereClause = {
            program_id: programId,
            member_id: memberId
        };

        // Add date range filter if provided
        if (startDate || endDate) {
            whereClause.log_date = {};
            if (startDate) {
                whereClause.log_date[Op.gte] = startDate;
            }
            if (endDate) {
                whereClause.log_date[Op.lte] = endDate;
            }
        }

        // Determine sort column
        let orderSpec;
        const orderDirection = sortDir.toLowerCase() === "asc" ? "ASC" : "DESC";
        switch (sortBy) {
            case "duration":
                orderSpec = [["duration", orderDirection]];
                break;
            case "workoutType":
                // Sort by the associated ProgramWorkout's workout_name
                orderSpec = [[ProgramWorkout, "workout_name", orderDirection]];
                break;
            case "date":
            default:
                orderSpec = [["log_date", orderDirection]];
                break;
        }

        // Build query options
        const queryOptions = {
            where: whereClause,
            order: orderSpec,
            attributes: ["log_date", "duration", "member_id", "program_workout_id"],
            include: [{
                model: ProgramWorkout,
                attributes: ["workout_name"]
            }]
        };

        // Only apply limit if it's greater than 0
        const limitNum = Number(limit);
        if (limitNum > 0) {
            queryOptions.limit = limitNum;
        }

        const workouts = await WorkoutLog.findAll(queryOptions);

        const items = workouts.map((w, idx) => ({
            id: `${w.member_id}-${w.program_workout_id}-${w.log_date}-${idx}`,
            workoutType: w.ProgramWorkout?.workout_name || "",
            workoutDate: w.log_date,
            durationMinutes: Number(w.duration || 0)
        }));

        res.json({ 
            items,
            total: items.length,
            filters: {
                startDate: startDate || null,
                endDate: endDate || null,
                sortBy,
                sortDir: orderDirection.toLowerCase()
            }
        });
    } catch (err) {
        console.error("Error fetching recent workouts:", err);
        res.status(500).json({ error: "Failed to fetch recent workouts." });
    }
});

module.exports = router;











