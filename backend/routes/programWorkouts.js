const express = require("express");
const { authenticateToken } = require("../middleware/auth");
const workoutService = require("../services/workoutService");
const { AppError } = require("../utils/response");

const router = express.Router();

router.get("/", authenticateToken, async (req, res) => {
    try {
        const result = await workoutService.getProgramWorkouts(req.query.programId);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error fetching program workouts:", err);
        res.status(500).json({ error: "Failed to fetch program workouts." });
    }
});

router.put("/toggle-visibility", authenticateToken, async (req, res) => {
    try {
        const result = await workoutService.toggleGlobalWorkoutVisibility(req.body, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error toggling workout visibility:", err);
        res.status(500).json({ error: "Failed to toggle workout visibility." });
    }
});

router.put("/:id/toggle-visibility", authenticateToken, async (req, res) => {
    try {
        const result = await workoutService.toggleCustomWorkoutVisibility(req.params.id, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error toggling custom workout visibility:", err);
        res.status(500).json({ error: "Failed to toggle custom workout visibility." });
    }
});

router.post("/custom", authenticateToken, async (req, res) => {
    try {
        const result = await workoutService.addCustomWorkout(req.body, req.user);
        res.status(201).json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error creating custom workout:", err);
        res.status(500).json({ error: "Failed to create custom workout." });
    }
});

router.put("/:id", authenticateToken, async (req, res) => {
    try {
        const result = await workoutService.editCustomWorkout(req.params.id, req.body.workout_name, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error updating custom workout:", err);
        res.status(500).json({ error: "Failed to update custom workout." });
    }
});

router.delete("/:id", authenticateToken, async (req, res) => {
    try {
        const result = await workoutService.deleteCustomWorkout(req.params.id, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error deleting custom workout:", err);
        res.status(500).json({ error: "Failed to delete custom workout." });
    }
});

module.exports = router;
