const express = require("express");
const { authenticateToken } = require("../middleware/auth");
const inviteService = require("../services/inviteService");
const { AppError } = require("../utils/response");

const router = express.Router();

router.post("/invite", authenticateToken, async (req, res) => {
    try {
        const result = await inviteService.sendInvite(req.body, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        res.json({ message: "Invitation sent" });
    }
});

router.get("/my-invites", authenticateToken, async (req, res) => {
    try {
        const result = await inviteService.getMyInvites(req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error fetching user invites:", err);
        res.status(500).json({ error: "Failed to fetch invites." });
    }
});

router.get("/all-invites", authenticateToken, async (req, res) => {
    try {
        const result = await inviteService.getAllInvites(req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error fetching all invites:", err);
        res.status(500).json({ error: "Failed to fetch invites." });
    }
});

router.put("/invite-response", authenticateToken, async (req, res) => {
    try {
        const result = await inviteService.respondToInvite(req.body, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error responding to invite:", err);
        res.status(500).json({ error: "Failed to process invite response." });
    }
});

module.exports = router;
