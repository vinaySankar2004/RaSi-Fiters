const express = require("express");
const { authenticateToken } = require("../middleware/auth");
const programService = require("../services/programService");
const { AppError } = require("../utils/response");

const router = express.Router();

router.get("/", authenticateToken, async (req, res) => {
    try {
        const programs = await programService.getPrograms(req.user);
        res.json(programs);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error fetching programs:", err);
        res.status(500).json({ error: "Failed to fetch programs" });
    }
});

router.post("/", authenticateToken, async (req, res) => {
    try {
        const result = await programService.createProgram(req.body, req.user);
        res.status(201).json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error creating program:", err);
        res.status(500).json({ error: "Failed to create program." });
    }
});

router.put("/:id", authenticateToken, async (req, res) => {
    try {
        const result = await programService.updateProgram(req.params.id, req.body, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error updating program:", err);
        res.status(500).json({ error: "Failed to update program." });
    }
});

router.delete("/:id", authenticateToken, async (req, res) => {
    try {
        const result = await programService.deleteProgram(req.params.id, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error deleting program:", err);
        res.status(500).json({ error: "Failed to delete program." });
    }
});

module.exports = router;
