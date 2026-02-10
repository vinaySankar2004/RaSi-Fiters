const express = require("express");
const { DailyHealthLog, ProgramMembership } = require("../models");
const { authenticateToken } = require("../middleware/auth");
const { Op } = require("sequelize");

const router = express.Router();

const parseOptionalNumber = (value) => {
    if (value === undefined || value === null || value === "") {
        return null;
    }
    const num = Number(value);
    return Number.isFinite(num) ? num : NaN;
};

router.post("/", authenticateToken, async (req, res) => {
    try {
        const { program_id, log_date, sleep_hours, food_quality, member_id: bodyMemberId } = req.body;

        if (!program_id || !log_date) {
            return res.status(400).json({ error: "program_id and log_date are required." });
        }

        const sleepValue = parseOptionalNumber(sleep_hours);
        const foodValue = parseOptionalNumber(food_quality);

        if (Number.isNaN(sleepValue)) {
            return res.status(400).json({ error: "sleep_hours must be a number." });
        }

        if (Number.isNaN(foodValue)) {
            return res.status(400).json({ error: "food_quality must be a number." });
        }

        if (sleepValue === null && foodValue === null) {
            return res.status(400).json({ error: "At least one of sleep_hours or food_quality is required." });
        }

        if (sleepValue !== null && (sleepValue < 0 || sleepValue > 24)) {
            return res.status(400).json({ error: "sleep_hours must be between 0 and 24." });
        }

        if (foodValue !== null) {
            if (!Number.isInteger(foodValue) || foodValue < 1 || foodValue > 5) {
                return res.status(400).json({ error: "food_quality must be an integer between 1 and 5." });
            }
        }

        const requester = req.user;
        let canLogForAny = requester?.global_role === "global_admin";

        if (!canLogForAny) {
            const requesterMembership = await ProgramMembership.findOne({
                where: { program_id, member_id: requester?.id, status: "active" }
            });

            if (!requesterMembership) {
                return res.status(403).json({ error: "You are not enrolled in this program." });
            }

            if (["admin", "logger"].includes(requesterMembership.role)) {
                canLogForAny = true;
            }
        }

        let targetMemberId = requester?.id;
        if (bodyMemberId) {
            if (!canLogForAny && bodyMemberId !== requester?.id) {
                return res.status(403).json({ error: "You can only log your own daily health." });
            }
            if (canLogForAny) {
                targetMemberId = bodyMemberId;
            }
        }

        const targetMembership = await ProgramMembership.findOne({
            where: { program_id, member_id: targetMemberId, status: "active" }
        });

        if (!targetMembership) {
            return res.status(404).json({ error: "Member is not enrolled in this program." });
        }

        const existing = await DailyHealthLog.findOne({
            where: { program_id, member_id: targetMemberId, log_date }
        });

        if (existing) {
            return res.status(409).json({ error: "Daily health log already exists for this date." });
        }

        const created = await DailyHealthLog.create({
            program_id,
            member_id: targetMemberId,
            log_date,
            sleep_hours: sleepValue,
            food_quality: foodValue
        });

        res.status(201).json(created);
    } catch (err) {
        console.error("Error adding daily health log:", err);
        res.status(500).json({ error: "Failed to add daily health log." });
    }
});

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

        const requester = req.user;
        let canLogForAny = requester?.global_role === "global_admin";

        if (!canLogForAny) {
            const requesterMembership = await ProgramMembership.findOne({
                where: { program_id: programId, member_id: requester?.id, status: "active" }
            });

            if (!requesterMembership) {
                return res.status(403).json({ error: "You are not enrolled in this program." });
            }

            if (["admin", "logger"].includes(requesterMembership.role)) {
                canLogForAny = true;
            }
        }

        if (!canLogForAny && memberId !== requester?.id) {
            return res.status(403).json({ error: "You can only view your own daily health logs." });
        }

        const targetMembership = await ProgramMembership.findOne({
            where: { program_id: programId, member_id: memberId, status: "active" }
        });

        if (!targetMembership) {
            return res.status(404).json({ error: "Member is not enrolled in this program." });
        }

        const whereClause = {
            program_id: programId,
            member_id: memberId
        };

        if (startDate || endDate) {
            whereClause.log_date = {};
            if (startDate) {
                whereClause.log_date[Op.gte] = startDate;
            }
            if (endDate) {
                whereClause.log_date[Op.lte] = endDate;
            }
        }

        let orderColumn;
        switch (sortBy) {
            case "sleep_hours":
                orderColumn = "sleep_hours";
                break;
            case "food_quality":
                orderColumn = "food_quality";
                break;
            case "date":
            default:
                orderColumn = "log_date";
                break;
        }

        const orderDirection = sortDir.toLowerCase() === "asc" ? "ASC" : "DESC";

        const queryOptions = {
            where: whereClause,
            order: [[orderColumn, orderDirection]],
            attributes: ["program_id", "member_id", "log_date", "sleep_hours", "food_quality"]
        };

        const limitNum = Number(limit);
        if (limitNum > 0) {
            queryOptions.limit = limitNum;
        }

        const logs = await DailyHealthLog.findAll(queryOptions);

        const items = logs.map((log, idx) => ({
            id: `${log.member_id}-${log.log_date}-${idx}`,
            logDate: log.log_date,
            sleepHours: log.sleep_hours !== null && log.sleep_hours !== undefined ? Number(log.sleep_hours) : null,
            foodQuality: log.food_quality !== null && log.food_quality !== undefined ? Number(log.food_quality) : null
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
        console.error("Error fetching daily health logs:", err);
        res.status(500).json({ error: "Failed to fetch daily health logs." });
    }
});

router.put("/", authenticateToken, async (req, res) => {
    try {
        const { program_id, log_date, sleep_hours, food_quality, member_id: bodyMemberId } = req.body;

        if (!program_id || !log_date) {
            return res.status(400).json({ error: "program_id and log_date are required." });
        }

        const sleepValue = parseOptionalNumber(sleep_hours);
        const foodValue = parseOptionalNumber(food_quality);
        const hasSleepField = Object.prototype.hasOwnProperty.call(req.body, "sleep_hours");
        const hasFoodField = Object.prototype.hasOwnProperty.call(req.body, "food_quality");

        if (!hasSleepField && !hasFoodField) {
            return res.status(400).json({ error: "At least one of sleep_hours or food_quality is required." });
        }

        if (hasSleepField && Number.isNaN(sleepValue)) {
            return res.status(400).json({ error: "sleep_hours must be a number." });
        }

        if (hasFoodField && Number.isNaN(foodValue)) {
            return res.status(400).json({ error: "food_quality must be a number." });
        }

        if (sleepValue === null && foodValue === null) {
            return res.status(400).json({ error: "At least one of sleep_hours or food_quality is required." });
        }

        if (sleepValue !== null && (sleepValue < 0 || sleepValue > 24)) {
            return res.status(400).json({ error: "sleep_hours must be between 0 and 24." });
        }

        if (foodValue !== null) {
            if (!Number.isInteger(foodValue) || foodValue < 1 || foodValue > 5) {
                return res.status(400).json({ error: "food_quality must be an integer between 1 and 5." });
            }
        }

        const requester = req.user;
        let canLogForAny = requester?.global_role === "global_admin";

        if (!canLogForAny) {
            const requesterMembership = await ProgramMembership.findOne({
                where: { program_id, member_id: requester?.id, status: "active" }
            });

            if (!requesterMembership) {
                return res.status(403).json({ error: "You are not enrolled in this program." });
            }

            if (["admin", "logger"].includes(requesterMembership.role)) {
                canLogForAny = true;
            }
        }

        let targetMemberId = requester?.id;
        if (bodyMemberId) {
            if (!canLogForAny && bodyMemberId !== requester?.id) {
                return res.status(403).json({ error: "You can only update your own daily health." });
            }
            if (canLogForAny) {
                targetMemberId = bodyMemberId;
            }
        }

        const targetMembership = await ProgramMembership.findOne({
            where: { program_id, member_id: targetMemberId, status: "active" }
        });

        if (!targetMembership) {
            return res.status(404).json({ error: "Member is not enrolled in this program." });
        }

        const log = await DailyHealthLog.findOne({
            where: { program_id, member_id: targetMemberId, log_date }
        });

        if (!log) {
            return res.status(404).json({ error: "Daily health log not found." });
        }

        const updateData = {};
        if (hasSleepField) updateData.sleep_hours = sleepValue;
        if (hasFoodField) updateData.food_quality = foodValue;

        await log.update(updateData);

        res.json(log);
    } catch (err) {
        console.error("Error updating daily health log:", err);
        res.status(500).json({ error: "Failed to update daily health log." });
    }
});

router.delete("/", authenticateToken, async (req, res) => {
    try {
        const { program_id, log_date, member_id: bodyMemberId } = req.body;

        if (!program_id || !log_date) {
            return res.status(400).json({ error: "program_id and log_date are required." });
        }

        const requester = req.user;
        let canLogForAny = requester?.global_role === "global_admin";

        if (!canLogForAny) {
            const requesterMembership = await ProgramMembership.findOne({
                where: { program_id, member_id: requester?.id, status: "active" }
            });

            if (!requesterMembership) {
                return res.status(403).json({ error: "You are not enrolled in this program." });
            }

            if (["admin", "logger"].includes(requesterMembership.role)) {
                canLogForAny = true;
            }
        }

        let targetMemberId = requester?.id;
        if (bodyMemberId) {
            if (!canLogForAny && bodyMemberId !== requester?.id) {
                return res.status(403).json({ error: "You can only delete your own daily health." });
            }
            if (canLogForAny) {
                targetMemberId = bodyMemberId;
            }
        }

        const targetMembership = await ProgramMembership.findOne({
            where: { program_id, member_id: targetMemberId, status: "active" }
        });

        if (!targetMembership) {
            return res.status(404).json({ error: "Member is not enrolled in this program." });
        }

        const log = await DailyHealthLog.findOne({
            where: { program_id, member_id: targetMemberId, log_date }
        });

        if (!log) {
            return res.status(404).json({ error: "Daily health log not found." });
        }

        await log.destroy();

        res.json({ message: "Daily health log deleted successfully." });
    } catch (err) {
        console.error("Error deleting daily health log:", err);
        res.status(500).json({ error: "Failed to delete daily health log." });
    }
});

module.exports = router;
