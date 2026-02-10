const express = require("express");
const { Op } = require("sequelize");
const { authenticateToken } = require("../middleware/auth");
const { WorkoutLog, Program, ProgramMembership } = require("../models");

const router = express.Router();

const ensureActiveProgramAccess = async (req, programId) => {
    if (req.user?.global_role === "global_admin") return true;
    if (!req.user?.id) return false;
    const membership = await ProgramMembership.findOne({
        where: { program_id: programId, member_id: req.user.id, status: "active" }
    });
    return Boolean(membership);
};

// Reuse the same helpers as program timeline for consistent windows/labels
const {
    resolveTimelineWindow,
    buildBuckets,
    bucketKey
} = require("./analytics");

router.get("/", authenticateToken, async (req, res) => {
    try {
        const { programId, memberId, period = "week" } = req.query;
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

        const { windowStart, windowEnd, bucketGranularity, label, labelMode } = await resolveTimelineWindow(period.toLowerCase(), programId);

        const logs = await WorkoutLog.findAll({
            where: {
                program_id: programId,
                member_id: memberId,
                log_date: { [Op.between]: [windowStart, windowEnd] }
            },
            attributes: ["log_date"]
        });

        const buckets = buildBuckets(windowStart, windowEnd, bucketGranularity, labelMode);

        for (const log of logs) {
            const key = bucketKey(new Date(log.log_date + "T00:00:00Z"), bucketGranularity);
            if (!buckets.has(key)) continue;
            const bucket = buckets.get(key);
            bucket.workouts += 1;
        }

        const points = Array.from(buckets.values()).map((bucket) => ({
            date: bucket.date,
            label: bucket.label,
            workouts: bucket.workouts
        }));

        const totalWorkouts = points.reduce((sum, p) => sum + p.workouts, 0);
        const totalDays = Math.max(1, Math.floor((new Date(windowEnd + "T00:00:00Z") - new Date(windowStart + "T00:00:00Z")) / 86400000) + 1);
        const dailyAverage = Number((totalWorkouts / totalDays).toFixed(1));

        res.json({
            period: period.toLowerCase(),
            label,
            daily_average: dailyAverage,
            buckets: points,
            start: windowStart,
            end: windowEnd
        });
    } catch (err) {
        console.error("Error fetching member history:", err);
        res.status(500).json({ error: "Failed to fetch member workout history." });
    }
});

module.exports = router;










