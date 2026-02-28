const jwt = require("jsonwebtoken");
const { ProgramMembership } = require("../models");

const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: "Access denied. No token provided." });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        return res.status(401).json({ error: "Invalid token." });
    }
};

const isAdmin = (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({ error: "Authentication required." });
    }

    const isAdminRole = req.user.role === 'admin';
    const isGlobalAdmin = req.user.global_role === 'global_admin';
    if (!isAdminRole && !isGlobalAdmin) {
        return res.status(403).json({ error: "Access denied. Admin privileges required." });
    }

    next();
};

const canModifyLog = async (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({ error: "Authentication required." });
    }

    if (req.user.role === 'admin') {
        return next();
    }

    const logMemberId = req.body.member_id || req.query.member_id || req.params.member_id;

    if (logMemberId) {
        if (req.user.id !== logMemberId) {
            return res.status(403).json({ error: "Access denied. You can only modify your own logs." });
        }
        return next();
    }

    const memberName = req.body.member_name || req.query.member_name || req.params.member_name;

    if (memberName) {
        if (req.user.member_name !== memberName) {
            return res.status(403).json({ error: "Access denied. You can only modify your own logs." });
        }
        return next();
    }

    return res.status(400).json({ error: "Member identification required for this operation." });
};

const requireProgramAdmin = async (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({ error: "Authentication required." });
    }

    if (req.user.global_role === "global_admin") {
        return next();
    }

    const programId = req.body.program_id || req.query.programId || req.params.programId;
    if (!programId) {
        return res.status(400).json({ error: "Program identification required." });
    }

    const pm = await ProgramMembership.findOne({
        where: {
            program_id: programId,
            member_id: req.user.id,
            role: "admin",
            status: "active"
        }
    });

    if (!pm) {
        return res.status(403).json({ error: "Admin privileges required for this program." });
    }

    next();
};

const requireProgramMember = async (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({ error: "Authentication required." });
    }

    if (req.user.global_role === "global_admin") {
        return next();
    }

    const programId = req.body.program_id || req.query.programId || req.params.programId;
    if (!programId) {
        return res.status(400).json({ error: "Program identification required." });
    }

    const pm = await ProgramMembership.findOne({
        where: {
            program_id: programId,
            member_id: req.user.id,
            status: "active"
        }
    });

    if (!pm) {
        return res.status(403).json({ error: "Access denied. Program membership required." });
    }

    req.programMembership = pm;
    next();
};

module.exports = { authenticateToken, isAdmin, canModifyLog, requireProgramAdmin, requireProgramMember };
