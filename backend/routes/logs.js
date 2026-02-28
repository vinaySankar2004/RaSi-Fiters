const express = require("express");
const { authenticateToken } = require("../middleware/auth");
const logService = require("../services/logService");
const { AppError } = require("../utils/response");

const workoutLogRouter = express.Router();
const dailyHealthLogRouter = express.Router();

// ── Workout Logs ──

workoutLogRouter.get("/", authenticateToken, async (req, res) => {
    try {
        const result = await logService.getWorkoutLogs(req.query, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error fetching workout logs:", err);
        res.status(500).json({ error: "Failed to fetch workout logs." });
    }
});

workoutLogRouter.post("/", authenticateToken, async (req, res) => {
    try {
        const result = await logService.addWorkoutLog(req.body, req.user);
        res.status(201).json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error adding workout log:", err);
        res.status(500).json({ error: "Failed to add workout log.", details: err.message });
    }
});

workoutLogRouter.put("/", authenticateToken, async (req, res) => {
    try {
        const result = await logService.updateWorkoutLog(req.body, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error updating workout log:", err);
        res.status(500).json({ error: "Failed to update workout log." });
    }
});

workoutLogRouter.delete("/", authenticateToken, async (req, res) => {
    try {
        const result = await logService.deleteWorkoutLog(req.body, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error deleting workout log:", err);
        res.status(500).json({ error: "Failed to delete workout log." });
    }
});

workoutLogRouter.get("/member/:memberName", authenticateToken, async (req, res) => {
    try {
        const result = await logService.getMemberWorkoutLogs(req.params.memberName, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error fetching member workout logs:", err);
        res.status(500).json({ error: "Failed to fetch workout logs." });
    }
});

// ── Daily Health Logs ──

dailyHealthLogRouter.post("/", authenticateToken, async (req, res) => {
    try {
        const result = await logService.addDailyHealthLog(req.body, req.user);
        res.status(201).json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error adding daily health log:", err);
        res.status(500).json({ error: "Failed to add daily health log." });
    }
});

dailyHealthLogRouter.get("/", authenticateToken, async (req, res) => {
    try {
        const result = await logService.getDailyHealthLogs(req.query, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error fetching daily health logs:", err);
        res.status(500).json({ error: "Failed to fetch daily health logs." });
    }
});

dailyHealthLogRouter.put("/", authenticateToken, async (req, res) => {
    try {
        const result = await logService.updateDailyHealthLog(req.body, req.user, req.body);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error updating daily health log:", err);
        res.status(500).json({ error: "Failed to update daily health log." });
    }
});

dailyHealthLogRouter.delete("/", authenticateToken, async (req, res) => {
    try {
        const result = await logService.deleteDailyHealthLog(req.body, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error deleting daily health log:", err);
        res.status(500).json({ error: "Failed to delete daily health log." });
    }
});

module.exports = { workoutLogRouter, dailyHealthLogRouter };
