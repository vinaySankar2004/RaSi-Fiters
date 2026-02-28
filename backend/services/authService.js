const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const { Op } = require("sequelize");
const { sequelize } = require("../config/database");
const {
    Member,
    RefreshToken,
    MemberCredential,
    MemberEmail,
    Program,
    ProgramMembership,
    ProgramInvite,
    Notification
} = require("../models");
const { AppError } = require("../utils/response");
const { handleMemberExit } = require("../utils/programMemberships");
const { createNotification, getActiveProgramMemberIds } = require("../utils/notifications");

const ACCESS_TOKEN_TTL = process.env.ACCESS_TOKEN_TTL || "1h";

const createAccessToken = (payload) =>
    jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: ACCESS_TOKEN_TTL });

const refreshExpiryDate = () => {
    const days = Number.parseInt(process.env.REFRESH_TOKEN_TTL_DAYS, 10);
    if (!Number.isFinite(days) || days <= 0) return null;
    return new Date(Date.now() + days * 24 * 60 * 60 * 1000);
};

const hashRefreshToken = (token) =>
    crypto.createHash("sha256").update(token).digest("hex");

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

const buildLegacyPayload = (member) => ({
    id: member.id,
    userId: member.id,
    username: member.username,
    member_name: formatMemberName(member),
    role: member.global_role === "global_admin" ? "admin" : "member",
    date_joined: member.date_joined
});

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

const verifyCredentials = async (member) => {
    const credential = await MemberCredential.findByPk(member.id);
    if (!credential) return null;
    return credential;
};

async function loginLegacy(identifier, password) {
    const member = await resolveMemberByIdentifier(identifier);
    if (!member) throw new AppError(401, "Invalid credentials");

    const credential = await verifyCredentials(member);
    if (!credential) throw new AppError(401, "Invalid credentials");

    const isMatch = await bcrypt.compare(password, credential.password_hash);
    if (!isMatch) throw new AppError(401, "Invalid credentials");

    const payload = buildLegacyPayload(member);
    const token = createAccessToken(payload);
    const { rawToken: refreshToken } = await issueRefreshToken(member.id, "legacy");

    return {
        token,
        refresh_token: refreshToken,
        username: member.username,
        role: member.global_role === "global_admin" ? "admin" : "member",
        member_name: formatMemberName(member),
        date_joined: member.date_joined,
        message: "Login successful!"
    };
}

async function loginGlobal(identifier, password) {
    const member = await resolveMemberByIdentifier(identifier);
    if (!member) throw new AppError(401, "Invalid credentials");

    const credential = await verifyCredentials(member);
    if (!credential) throw new AppError(401, "Invalid credentials");

    const isMatch = await bcrypt.compare(password, credential.password_hash);
    if (!isMatch) throw new AppError(401, "Invalid credentials");

    const globalRole = member.global_role || "standard";
    const payload = buildGlobalPayload(member, globalRole);
    const token = createAccessToken(payload);
    const { rawToken: refreshToken } = await issueRefreshToken(member.id, "global");

    return {
        token,
        refresh_token: refreshToken,
        member_id: member.id,
        username: member.username,
        member_name: formatMemberName(member),
        global_role: globalRole,
        message: "Login successful"
    };
}

async function refreshAccessToken(refreshTokenRaw) {
    if (!refreshTokenRaw) throw new AppError(400, "Refresh token required");

    const tokenHash = hashRefreshToken(refreshTokenRaw);
    const storedToken = await RefreshToken.findOne({ where: { token_hash: tokenHash } });

    if (!storedToken || storedToken.revoked_at) {
        throw new AppError(401, "Invalid refresh token");
    }

    if (storedToken.expires_at && storedToken.expires_at < new Date()) {
        await storedToken.update({ revoked_at: new Date() });
        throw new AppError(401, "Refresh token expired");
    }

    const member = await Member.findByPk(storedToken.member_id);
    if (!member) {
        await storedToken.update({ revoked_at: new Date() });
        throw new AppError(401, "Invalid refresh token");
    }

    let payload;
    if (storedToken.client_type === "legacy") {
        payload = buildLegacyPayload(member);
    } else {
        payload = buildGlobalPayload(member, member.global_role || "standard");
    }

    const token = createAccessToken(payload);
    const { rawToken: newRefreshToken, tokenHash: newTokenHash } = await issueRefreshToken(
        member.id,
        storedToken.client_type
    );

    await storedToken.update({ revoked_at: new Date(), replaced_by_hash: newTokenHash });

    return {
        token,
        refresh_token: newRefreshToken,
        message: "Token refreshed"
    };
}

async function logout(refreshTokenRaw) {
    if (!refreshTokenRaw) throw new AppError(400, "Refresh token required");

    const tokenHash = hashRefreshToken(refreshTokenRaw);
    const storedToken = await RefreshToken.findOne({ where: { token_hash: tokenHash } });
    if (storedToken && !storedToken.revoked_at) {
        await storedToken.update({ revoked_at: new Date() });
    }

    return { message: "Logged out" };
}

async function register({ username, password, first_name, last_name, email, gender }) {
    if (!username || !password || !first_name || !last_name || !email) {
        throw new AppError(400, "username, password, first_name, last_name, and email are required.");
    }

    const passwordError = validatePassword(password);
    if (passwordError) throw new AppError(400, passwordError);

    const transaction = await sequelize.transaction();
    try {
        const existingMember = await Member.findOne({ where: { username }, transaction });
        if (existingMember) {
            await transaction.rollback();
            throw new AppError(400, "Username already exists");
        }

        const normalizedEmail = normalizeEmail(email);
        const existingEmail = await MemberEmail.findOne({
            where: { email: normalizedEmail },
            transaction
        });
        if (existingEmail) {
            await transaction.rollback();
            throw new AppError(400, "Email already exists");
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

        return {
            message: "Account created successfully",
            member_id: newMember.id,
            username: newMember.username,
            member_name: formatMemberName(newMember)
        };
    } catch (err) {
        if (err instanceof AppError) throw err;
        await transaction.rollback();
        throw err;
    }
}

async function changePassword(memberId, newPassword) {
    if (!newPassword) throw new AppError(400, "new_password is required.");

    const passwordError = validatePassword(newPassword);
    if (passwordError) throw new AppError(400, passwordError);

    const credential = await MemberCredential.findByPk(memberId);
    if (!credential) throw new AppError(404, "Credentials not found.");

    const passwordHash = await bcrypt.hash(newPassword, 10);
    await credential.update({ password_hash: passwordHash });

    return { message: "Password changed successfully." };
}

async function deleteAccount(memberId) {
    const transaction = await sequelize.transaction();

    try {
        const member = await Member.findByPk(memberId, { transaction });
        if (!member) {
            await transaction.rollback();
            throw new AppError(404, "Account not found.");
        }

        if (member.global_role === "global_admin") {
            await transaction.rollback();
            throw new AppError(403, "Global admin accounts cannot be deleted through this endpoint.");
        }

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

        await Notification.destroy({
            where: { actor_member_id: memberId },
            transaction
        });

        const activeMemberships = await ProgramMembership.findAll({
            where: { member_id: memberId, status: "active" },
            attributes: ["program_id"],
            transaction
        });

        const createdPrograms = await Program.findAll({
            where: { created_by: memberId, is_deleted: false },
            attributes: ["id"],
            transaction
        });

        const programIds = new Set([
            ...activeMemberships.map((m) => m.program_id),
            ...createdPrograms.map((p) => p.id)
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

        await member.destroy({ transaction });
        await transaction.commit();

        return { message: "Account deleted successfully." };
    } catch (err) {
        if (err instanceof AppError) throw err;
        await transaction.rollback();
        throw err;
    }
}

module.exports = {
    loginLegacy,
    loginGlobal,
    refreshAccessToken,
    logout,
    register,
    changePassword,
    deleteAccount
};
