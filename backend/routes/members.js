const express = require("express");
const { authenticateToken, isAdmin } = require("../middleware/auth");
const memberService = require("../services/memberService");
const { AppError } = require("../utils/response");

const router = express.Router();

router.get("/", authenticateToken, async (req, res) => {
    try {
        const members = await memberService.getAllMembers();
        res.json(members);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error fetching members:", err);
        res.status(500).json({ error: "Failed to fetch members." });
    }
});

router.get("/:id", authenticateToken, async (req, res) => {
    try {
        const member = await memberService.getMemberById(req.params.id);
        res.json(member);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error fetching member:", err);
        res.status(500).json({ error: "Failed to fetch member." });
    }
});

router.post("/", authenticateToken, isAdmin, async (req, res) => {
    try {
        const member = await memberService.createMember(req.body);
        res.status(201).json(member);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error adding member:", err);
        res.status(500).json({ error: "Failed to add member." });
    }
});

router.put("/:id", authenticateToken, async (req, res) => {
    try {
        const result = await memberService.updateMember(req.params.id, req.body, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error updating member:", err);
        res.status(500).json({ error: "Failed to update member." });
    }
});

router.delete("/:id", authenticateToken, isAdmin, async (req, res) => {
    try {
        const result = await memberService.deleteMember(req.params.id);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error deleting member:", err);
        res.status(500).json({ error: "Failed to delete member." });
    }
});

module.exports = router;
