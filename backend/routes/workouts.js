const express = require("express");
const { authenticateToken, isAdmin } = require("../middleware/auth");
const workoutService = require("../services/workoutService");
const { AppError } = require("../utils/response");

const router = express.Router();

router.get("/", authenticateToken, async (req, res) => {
    try {
        const workouts = await workoutService.getAllWorkouts();
        res.json(workouts);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error fetching workouts:", err);
        res.status(500).json({ error: "Failed to fetch workouts." });
    }
});

router.post("/", authenticateToken, isAdmin, async (req, res) => {
    try {
        const workout = await workoutService.createWorkout(req.body.workout_name);
        res.status(201).json(workout);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error adding workout:", err);
        res.status(500).json({ error: "Failed to add workout." });
    }
});

router.post("/mobile", authenticateToken, isAdmin, async (req, res) => {
    try {
        const workout = await workoutService.createWorkout(req.body.workout_name);
        res.status(201).json(workout);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error adding workout (mobile):", err);
        res.status(500).json({ error: "Failed to add workout." });
    }
});

router.put("/:workout_name", authenticateToken, isAdmin, async (req, res) => {
    try {
        const result = await workoutService.updateWorkout(req.params.workout_name, req.body.workout_name);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error updating workout:", err);
        res.status(500).json({ error: "Failed to update workout." });
    }
});

router.delete("/:workout_name", authenticateToken, isAdmin, async (req, res) => {
    try {
        const result = await workoutService.deleteWorkout(req.params.workout_name);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error deleting workout:", err);
        res.status(500).json({ error: "Failed to delete workout." });
    }
});

module.exports = router;
