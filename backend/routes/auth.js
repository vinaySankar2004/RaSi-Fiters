const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const { sequelize } = require("../config/database");
const { Op } = require("sequelize");
const {
    Member,
    RefreshToken,
    MemberCredential,
    MemberEmail,
    Program,
    ProgramMembership,
    ProgramInvite,
    Notification
} = require("../models/index");
const { authenticateToken } = require("../middleware/auth");
const { handleMemberExit } = require("../utils/programMemberships");
const { createNotification, getActiveProgramMemberIds } = require("../utils/notifications");

const router = express.Router();

const ACCESS_TOKEN_TTL = process.env.ACCESS_TOKEN_TTL || "1h";

const createAccessToken = (payload) => jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: ACCESS_TOKEN_TTL });

const refreshExpiryDate = () => {
    const days = Number.parseInt(process.env.REFRESH_TOKEN_TTL_DAYS, 10);
    if (!Number.isFinite(days) || days <= 0) {
        return null;
    }
    return new Date(Date.now() + days * 24 * 60 * 60 * 1000);
};

const hashRefreshToken = (token) => crypto.createHash("sha256").update(token).digest("hex");

const issueRefreshToken = async (memberId, clientType) => {
    const rawToken = crypto.randomBytes(64).toString("hex");
    const tokenHash = hashRefreshToken(rawToken);
    await RefreshToken.create({
        member_id: memberId,
        token_hash: tokenHash,
        client_type: clientType,
        expires_at: refreshExpiryDate()
    });
    return { rawToken, tokenHash };
};

const formatMemberName = (member) => member?.member_name || "";

const buildGlobalPayload = (member, globalRole) => ({
    id: member.id,
    username: member.username,
    member_name: formatMemberName(member),
    global_role: globalRole,
    date_joined: member.date_joined
});

const normalizeEmail = (email) => (email || "").trim().toLowerCase();

const resolveMemberByIdentifier = async (identifier) => {
    const trimmed = (identifier || "").trim();
    if (!trimmed) return null;

    const memberByUsername = await Member.findOne({ where: { username: trimmed } });
    if (memberByUsername) return memberByUsername;

    const email = normalizeEmail(trimmed);
    const memberEmail = await MemberEmail.findOne({
        where: { email },
        include: [{ model: Member }]
    });
    return memberEmail?.Member || null;
};

const validatePassword = (password) => {
    if (!password || password.length < 8) {
        return "Password must be at least 8 characters long.";
    }
    if (!/[a-z]/.test(password) || !/[A-Z]/.test(password) || !/[0-9]/.test(password)) {
        return "Password must include upper, lower, and a number.";
    }
    return null;
};

// Shared handler for app (mobile-first) and global login; keeps logic in one place.
const handleAppLogin = async (req, res) => {
    const { identifier, username, password } = req.body;
    const loginId = identifier || username;
    console.log(`[global login] attempt for identifier: ${loginId}`);

    try {
        const member = await resolveMemberByIdentifier(loginId);

        if (!member) {
            console.log(`[global login] user not found: ${loginId}`);
            return res.status(401).json({ error: "Invalid credentials" });
        }

        const credential = await MemberCredential.findByPk(member.id);
        if (!credential) {
            console.log(`[global login] missing credentials for: ${member.id}`);
            return res.status(401).json({ error: "Invalid credentials" });
        }

        console.log(`[global login] credential loaded for member: ${member.id}`);
        const isMatch = await bcrypt.compare(password, credential.password_hash);
        if (!isMatch) {
            console.log(`[global login] password mismatch for user: ${loginId}`);
            return res.status(401).json({ error: "Invalid credentials" });
        }

        console.log(`[global login] password verified for member: ${member.id}`);
        // Default to 'standard' if not set, but the column is non-null with default in DB.
        const globalRole = member.global_role || "standard";

        const payload = buildGlobalPayload(member, globalRole);
        const token = createAccessToken(payload);
        console.log(`[global login] access token created for member: ${member.id}`);
        const { rawToken: refreshToken } = await issueRefreshToken(member.id, "global");
        console.log(`[global login] refresh token issued for member: ${member.id}`);

        res.json({
            token,
            refresh_token: refreshToken,
            member_id: member.id,
            username: member.username,
            member_name: formatMemberName(member),
            global_role: globalRole,
            message: "Login successful"
        });
    } catch (error) {
        console.error("[global login] error:", error);
        res.status(500).json({ error: "Server error during login" });
    }
};

// New mobile-first endpoint for app clients (iOS/Android) using global_role.
router.post("/login/app", handleAppLogin);

// Existing endpoint kept for backward compatibility.
router.post("/login/global", handleAppLogin);

// Refresh access token using a refresh token (rotates refresh token)
router.post("/refresh", async (req, res) => {
    const { refresh_token: refreshToken } = req.body;
    if (!refreshToken) {
        return res.status(400).json({ error: "Refresh token required" });
    }

    try {
        const tokenHash = hashRefreshToken(refreshToken);
        const storedToken = await RefreshToken.findOne({ where: { token_hash: tokenHash } });

        if (!storedToken || storedToken.revoked_at) {
            return res.status(401).json({ error: "Invalid refresh token" });
        }

        if (storedToken.expires_at && storedToken.expires_at < new Date()) {
            await storedToken.update({ revoked_at: new Date() });
            return res.status(401).json({ error: "Refresh token expired" });
        }

        const member = await Member.findByPk(storedToken.member_id);
        if (!member) {
            await storedToken.update({ revoked_at: new Date() });
            return res.status(401).json({ error: "Invalid refresh token" });
        }

        const globalRole = member.global_role || "standard";
        const payload = buildGlobalPayload(member, globalRole);

        const token = createAccessToken(payload);
        const { rawToken: newRefreshToken, tokenHash: newTokenHash } = await issueRefreshToken(member.id, "global");

        await storedToken.update({ revoked_at: new Date(), replaced_by_hash: newTokenHash });

        return res.json({
            token,
            refresh_token: newRefreshToken,
            message: "Token refreshed"
        });
    } catch (error) {
        console.error("[refresh] error:", error);
        return res.status(500).json({ error: "Server error during refresh" });
    }
});

// Logout: revoke refresh token
router.post("/logout", async (req, res) => {
    const { refresh_token: refreshToken } = req.body;
    if (!refreshToken) {
        return res.status(400).json({ error: "Refresh token required" });
    }

    try {
        const tokenHash = hashRefreshToken(refreshToken);
        const storedToken = await RefreshToken.findOne({ where: { token_hash: tokenHash } });
        if (storedToken && !storedToken.revoked_at) {
            await storedToken.update({ revoked_at: new Date() });
        }
        return res.json({ message: "Logged out" });
    } catch (error) {
        console.error("[logout] error:", error);
        return res.status(500).json({ error: "Server error during logout" });
    }
});

// Registration endpoint
router.post("/register", async (req, res) => {
    const { username, password, first_name, last_name, email, gender } = req.body;
    const transaction = await sequelize.transaction();

    try {
        if (!username || !password || !first_name || !last_name || !email) {
            await transaction.rollback();
            return res.status(400).json({ error: "username, password, first_name, last_name, and email are required." });
        }

        const passwordError = validatePassword(password);
        if (passwordError) {
            await transaction.rollback();
            return res.status(400).json({ error: passwordError });
        }

        // Check if username already exists
        const existingMember = await Member.findOne({
            where: { username },
            transaction
        });

        if (existingMember) {
            await transaction.rollback();
            return res.status(400).json({ error: "Username already exists" });
        }

        const normalizedEmail = normalizeEmail(email);
        const existingEmail = await MemberEmail.findOne({
            where: { email: normalizedEmail },
            transaction
        });

        if (existingEmail) {
            await transaction.rollback();
            return res.status(400).json({ error: "Email already exists" });
        }

        const newMember = await Member.create({
            username,
            first_name,
            last_name,
            gender: gender || null
        }, { transaction });

        const passwordHash = await bcrypt.hash(password, 10);
        await MemberCredential.create({
            member_id: newMember.id,
            password_hash: passwordHash
        }, { transaction });

        await MemberEmail.create({
            member_id: newMember.id,
            email: normalizedEmail,
            is_primary: true
        }, { transaction });

        await transaction.commit();

        res.status(201).json({
            message: "Account created successfully",
            member_id: newMember.id,
            username: newMember.username,
            member_name: formatMemberName(newMember)
        });
    } catch (error) {
        await transaction.rollback();
        console.error("Registration error:", error);
        res.status(500).json({ error: "Server error during registration" });
    }
});

// PUT /auth/change-password - change password for authenticated user
router.put("/change-password", authenticateToken, async (req, res) => {
    const { new_password } = req.body;
    const memberId = req.user.id;

    try {
        if (!new_password) {
            return res.status(400).json({ error: "new_password is required." });
        }

        const passwordError = validatePassword(new_password);
        if (passwordError) {
            return res.status(400).json({ error: passwordError });
        }

        const credential = await MemberCredential.findByPk(memberId);
        if (!credential) {
            return res.status(404).json({ error: "Credentials not found." });
        }

        const passwordHash = await bcrypt.hash(new_password, 10);
        await credential.update({ password_hash: passwordHash });

        console.log(`[change-password] Password updated for member: ${memberId}`);
        res.json({ message: "Password changed successfully." });
    } catch (error) {
        console.error("[change-password] error:", error);
        res.status(500).json({ error: "Server error during password change." });
    }
});

// DELETE account - permanently deletes the authenticated user's account and all associated data
router.delete("/account", authenticateToken, async (req, res) => {
    const transaction = await sequelize.transaction();
    const memberId = req.user.id;

    try {
        const member = await Member.findByPk(memberId, { transaction });
        if (!member) {
            await transaction.rollback();
            return res.status(404).json({ error: "Account not found." });
        }

        // Prevent global admins from deleting their accounts through this endpoint
        if (member.global_role === "global_admin") {
            await transaction.rollback();
            return res.status(403).json({ error: "Global admin accounts cannot be deleted through this endpoint." });
        }

        console.log(`[delete-account] Starting account deletion for member: ${memberId}`);

        // Step 1: Delete any program invites sent by or targeting this member
        const memberEmails = await MemberEmail.findAll({
            where: { member_id: memberId },
            attributes: ["email"],
            transaction
        });
        const emailList = memberEmails.map((row) => row.email).filter(Boolean);
        const inviteFilters = [
            { invited_by: memberId },
            { invited_username: member.username }
        ];
        if (emailList.length > 0) {
            inviteFilters.push({ invited_email: { [Op.in]: emailList } });
        }
        await ProgramInvite.destroy({
            where: { [Op.or]: inviteFilters },
            transaction
        });
        console.log(`[delete-account] Deleted program_invites sent by or targeting member`);

        // Step 2: Delete notifications where this member is the actor (PII in title/body)
        await Notification.destroy({
            where: { actor_member_id: memberId },
            transaction
        });
        console.log(`[delete-account] Deleted notifications where member is actor`);

        // Step 3: Ensure programs remain valid after this member exits
        const activeMemberships = await ProgramMembership.findAll({
            where: {
                member_id: memberId,
                status: "active"
            },
            attributes: ["program_id"],
            transaction
        });

        const createdPrograms = await Program.findAll({
            where: { created_by: memberId, is_deleted: false },
            attributes: ["id"],
            transaction
        });

        const programIds = new Set([
            ...activeMemberships.map((membership) => membership.program_id),
            ...createdPrograms.map((program) => program.id)
        ]);

        for (const programId of programIds) {
            const exitResult = await handleMemberExit({
                programId,
                exitingMemberId: memberId,
                transaction,
                updateCreatedBy: true,
                notificationActorId: null,
                includeExitingMemberInRecipients: false
            });

            if (exitResult.programDeleted) {
                console.log(`[delete-account] Soft-deleted program '${programId}' (no active members)`);
            } else if (exitResult.newAdminMemberId) {
                console.log(`[delete-account] Promoted member ${exitResult.newAdminMemberId} to admin for program ${programId}`);
            }

            if (!exitResult.programDeleted) {
                const remainingMemberIds = await getActiveProgramMemberIds(programId, transaction);
                const recipients = remainingMemberIds.filter((id) => id !== memberId);
                if (recipients.length > 0) {
                    const program = await Program.findByPk(programId, { transaction });
                    await createNotification({
                        type: "program.member_left",
                        programId,
                        actorMemberId: null,
                        title: "Member left",
                        body: `A member left ${program?.name || "the program"}.`,
                        recipientIds: recipients,
                        transaction
                    });
                }
            }
        }

        // Step 4: Delete the member record
        // CASCADE will handle:
        // - member_credentials
        // - member_emails
        // - auth_identities
        // - refresh_tokens
        // - program_invite_blocks
        // - program_memberships (and cascade to workout_logs, daily_health_logs)
        await member.destroy({ transaction });
        console.log(`[delete-account] Member record deleted for: ${memberId}`);

        await transaction.commit();

        res.json({ message: "Account deleted successfully." });
    } catch (error) {
        await transaction.rollback();
        console.error("[delete-account] error:", error);
        res.status(500).json({ error: "Server error during account deletion." });
    }
});

module.exports = router;
