const express = require("express");
const { authenticateToken } = require("../middleware/auth");
const membershipService = require("../services/membershipService");
const { AppError } = require("../utils/response");

const router = express.Router();

router.post("/", authenticateToken, async (req, res) => {
    try {
        const result = await membershipService.createMemberAndEnroll(req.body, req.user);
        res.status(201).json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error adding member to program:", err);
        res.status(500).json({ error: "Failed to add member." });
    }
});

router.get("/members", authenticateToken, async (req, res) => {
    try {
        const members = await membershipService.getProgramMembers(req.query.programId);
        res.json(members);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error fetching program members:", err);
        res.status(500).json({ error: "Failed to fetch program members." });
    }
});

router.get("/available", authenticateToken, async (req, res) => {
    try {
        const members = await membershipService.getAvailableMembers(req.query.programId);
        res.json(members);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error fetching available members:", err);
        res.status(500).json({ error: "Failed to fetch available members." });
    }
});

router.get("/details", authenticateToken, async (req, res) => {
    try {
        const details = await membershipService.getMembershipDetails(req.query.programId);
        res.json(details);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error fetching program membership details:", err);
        res.status(500).json({ error: "Failed to fetch program membership details." });
    }
});

router.post("/enroll", authenticateToken, async (req, res) => {
    try {
        const result = await membershipService.enrollMember(req.body, req.user);
        res.status(201).json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error enrolling member to program:", err);
        res.status(500).json({ error: "Failed to enroll member." });
    }
});

router.put("/", authenticateToken, async (req, res) => {
    try {
        const result = await membershipService.updateMembership(req.body, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error updating membership:", err);
        res.status(500).json({ error: "Failed to update membership." });
    }
});

router.delete("/", authenticateToken, async (req, res) => {
    try {
        const result = await membershipService.removeMember(req.body, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error removing member from program:", err);
        res.status(500).json({ error: "Failed to remove member from program." });
    }
});

router.put("/leave", authenticateToken, async (req, res) => {
    try {
        const result = await membershipService.leaveProgram(req.body.program_id, req.user);
        res.json(result);
    } catch (err) {
        if (err instanceof AppError) return res.status(err.statusCode).json({ error: err.message });
        console.error("Error leaving program:", err);
        res.status(500).json({ error: "Failed to leave program." });
    }
});

module.exports = router;
