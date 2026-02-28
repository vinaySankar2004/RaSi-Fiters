const { Op } = require("sequelize");
const { Member, Program, ProgramMembership, ProgramInvite, ProgramInviteBlock } = require("../models");
const { sequelize } = require("../config/database");
const { AppError } = require("../utils/response");
const { handleMemberExit } = require("../utils/programMemberships");
const { createNotification, getActiveProgramMemberIds } = require("../utils/notifications");

const generateUniqueUsername = async (baseName, transaction) => {
    const slug = (baseName || "")
        .toLowerCase()
        .trim()
        .replace(/\s+/g, "")
        .replace(/[^a-z0-9]/g, "")
        || "user";

    let candidate = slug;
    let counter = 1;
    while (counter < 1000) {
        const exists = await Member.findOne({ where: { username: candidate }, transaction });
        if (!exists) return candidate;
        candidate = `${slug}${counter}`;
        counter += 1;
    }
    throw new Error("Unable to generate unique username");
};

async function createMemberAndEnroll({ member_name, password, program_id, gender, date_of_birth, date_joined, role, status, is_active }, requester) {
    if (!member_name || !password || !program_id) {
        throw new AppError(400, "member_name, password, and program_id are required.");
    }

    const transaction = await sequelize.transaction();
    try {
        if (requester?.global_role !== "global_admin") {
            const pm = await ProgramMembership.findOne({
                where: { program_id, member_id: requester?.id, role: "admin", status: "active" },
                transaction
            });
            if (!pm) {
                await transaction.rollback();
                throw new AppError(403, "Admin privileges required.");
            }
        }

        const program = await Program.findOne({
            where: { id: program_id, is_deleted: false },
            transaction
        });
        if (!program) {
            await transaction.rollback();
            throw new AppError(404, "Program not found.");
        }

        const username = await generateUniqueUsername(member_name, transaction);

        const newMember = await Member.create({
            member_name,
            username,
            password,
            gender,
            date_of_birth,
            date_joined: date_joined || new Date().toISOString().slice(0, 10),
            role: 'member'
        }, { transaction });

        const resolvedStatus = status || (is_active === false ? "removed" : "active");

        await ProgramMembership.create({
            program_id,
            member_id: newMember.id,
            role: role || 'member',
            joined_at: date_joined || new Date().toISOString().slice(0, 10),
            status: resolvedStatus
        }, { transaction });

        await transaction.commit();

        return {
            id: newMember.id,
            member_name: newMember.member_name,
            username: newMember.username,
            gender: newMember.gender,
            date_of_birth: newMember.date_of_birth,
            date_joined: newMember.date_joined,
            role: newMember.role,
            program_id
        };
    } catch (err) {
        if (err instanceof AppError) throw err;
        await transaction.rollback();
        const message = err.message === "Unable to generate unique username"
            ? "Failed to generate unique username."
            : "Failed to add member.";
        throw new AppError(500, message);
    }
}

async function getProgramMembers(programId) {
    if (!programId) throw new AppError(400, "programId is required");

    const memberships = await ProgramMembership.findAll({
        where: { program_id: programId, status: "active" },
        include: [{
            model: Member,
            attributes: ["id", "first_name", "last_name", "username", "gender", "created_at", "global_role"]
        }],
        order: [[Member, "first_name", "ASC"]]
    });

    return memberships
        .filter((m) => m.Member)
        .map((m) => ({
            id: m.Member.id,
            member_name: m.Member.member_name,
            username: m.Member.username,
            gender: m.Member.gender,
            date_joined: m.Member.date_joined,
            global_role: m.Member.global_role
        }));
}

async function getAvailableMembers(programId) {
    if (!programId) throw new AppError(400, "programId is required");

    const existingMemberships = await ProgramMembership.findAll({
        where: { program_id: programId, status: { [Op.ne]: "removed" } },
        attributes: ["member_id"]
    });
    const enrolledMemberIds = existingMemberships.map((m) => m.member_id);

    const whereClause = { global_role: "standard" };
    if (enrolledMemberIds.length > 0) {
        whereClause.id = { [Op.notIn]: enrolledMemberIds };
    }

    return Member.findAll({
        where: whereClause,
        attributes: ["id", "member_name", "username", "gender", "date_joined"],
        order: [["member_name", "ASC"]]
    });
}

async function getMembershipDetails(programId) {
    if (!programId) throw new AppError(400, "programId is required");

    const memberships = await ProgramMembership.findAll({
        where: { program_id: programId, status: "active" },
        include: [{
            model: Member,
            attributes: ["id", "first_name", "last_name", "username", "gender", "created_at", "global_role"]
        }],
        order: [[Member, "first_name", "ASC"]]
    });

    return memberships
        .filter((m) => m.Member)
        .map((m) => ({
            member_id: m.Member.id,
            member_name: m.Member.member_name,
            username: m.Member.username,
            gender: m.Member.gender,
            date_joined: m.Member.date_joined,
            global_role: m.Member.global_role,
            program_role: m.role,
            status: m.status,
            is_active: m.status === "active",
            joined_at: m.joined_at
        }));
}

async function enrollMember({ member_id, program_id, role, joined_at, status, is_active }, requester) {
    if (!member_id || !program_id) {
        throw new AppError(400, "member_id and program_id are required.");
    }

    const transaction = await sequelize.transaction();
    try {
        if (requester?.global_role !== "global_admin") {
            const pm = await ProgramMembership.findOne({
                where: { program_id, member_id: requester?.id, role: "admin", status: "active" },
                transaction
            });
            if (!pm) {
                await transaction.rollback();
                throw new AppError(403, "Admin privileges required.");
            }
        }

        const program = await Program.findOne({
            where: { id: program_id, is_deleted: false },
            transaction
        });
        if (!program) {
            await transaction.rollback();
            throw new AppError(404, "Program not found.");
        }

        const member = await Member.findByPk(member_id, { transaction });
        if (!member) {
            await transaction.rollback();
            throw new AppError(404, "Member not found.");
        }

        const existingMembership = await ProgramMembership.findOne({
            where: { program_id, member_id },
            transaction
        });
        if (existingMembership) {
            await transaction.rollback();
            throw new AppError(400, "Member is already enrolled in this program.");
        }

        const resolvedStatus = status || (is_active === false ? "removed" : "active");
        await ProgramMembership.create({
            program_id,
            member_id,
            role: role || "member",
            joined_at: joined_at || new Date().toISOString().slice(0, 10),
            status: resolvedStatus
        }, { transaction });

        await transaction.commit();

        return {
            member_id: member.id,
            member_name: member.member_name,
            username: member.username,
            gender: member.gender,
            date_of_birth: member.date_of_birth,
            date_joined: member.date_joined,
            program_id,
            message: "Member enrolled successfully."
        };
    } catch (err) {
        if (err instanceof AppError) throw err;
        await transaction.rollback();
        throw new AppError(500, "Failed to enroll member.");
    }
}

async function updateMembership({ program_id, member_id, role, status, is_active, joined_at }, requester) {
    if (!program_id || !member_id) {
        throw new AppError(400, "program_id and member_id are required.");
    }

    const transaction = await sequelize.transaction();
    try {
        const isSelf = requester?.id === member_id;
        const isGlobalAdmin = requester?.global_role === "global_admin";
        let isProgramAdmin = false;
        if (!isGlobalAdmin) {
            const pm = await ProgramMembership.findOne({
                where: { program_id, member_id: requester?.id, role: "admin", status: "active" },
                transaction
            });
            isProgramAdmin = !!pm;
        }
        if (!isGlobalAdmin && !isProgramAdmin && !isSelf) {
            await transaction.rollback();
            throw new AppError(403, "Admin privileges required for this program.");
        }

        const membership = await ProgramMembership.findOne({
            where: { program_id, member_id },
            transaction
        });
        if (!membership) {
            await transaction.rollback();
            throw new AppError(404, "Membership not found.");
        }

        const isAdminUser = isGlobalAdmin || isProgramAdmin;

        if (!isAdminUser && isSelf) {
            if (role !== undefined || joined_at !== undefined) {
                await transaction.rollback();
                throw new AppError(403, "Only status updates are allowed.");
            }
            if (!["invited", "requested"].includes(membership.status)) {
                await transaction.rollback();
                throw new AppError(403, "Cannot update membership status.");
            }
        }

        const updateData = {};
        if (role !== undefined) updateData.role = role;

        let resolvedStatus = status;
        if (resolvedStatus === undefined && is_active !== undefined) {
            resolvedStatus = is_active ? "active" : "removed";
        }
        if (!isAdminUser && isSelf) {
            if (!["active", "removed"].includes(resolvedStatus || "")) {
                await transaction.rollback();
                throw new AppError(400, "Invalid status update.");
            }
        }
        if (resolvedStatus !== undefined) {
            updateData.status = resolvedStatus;
            if (resolvedStatus === "removed") {
                updateData.left_at = new Date();
            } else if (resolvedStatus === "active") {
                updateData.left_at = null;
            }
        }
        if (joined_at !== undefined) updateData.joined_at = joined_at;

        const nextRole = role !== undefined ? role : membership.role;
        const nextStatus = resolvedStatus !== undefined ? resolvedStatus : membership.status;
        const isTargetActiveAdmin = membership.role === "admin" && membership.status === "active";
        const willRemainActiveAdmin = nextRole === "admin" && nextStatus === "active";
        if (isTargetActiveAdmin && !willRemainActiveAdmin) {
            const remainingAdmins = await ProgramMembership.count({
                where: {
                    program_id,
                    role: "admin",
                    status: "active",
                    member_id: { [Op.ne]: member_id }
                },
                transaction
            });
            if (remainingAdmins < 1) {
                await transaction.rollback();
                throw new AppError(400, "Cannot remove the last admin from the program.");
            }
        }

        const previousRole = membership.role;
        await membership.update(updateData, { transaction });

        if (previousRole !== nextRole && nextStatus === "active") {
            const program = await Program.findByPk(program_id, { transaction });
            await createNotification({
                type: "program.role_changed",
                programId: program_id,
                actorMemberId: requester?.id || null,
                title: "Role updated",
                body: `Your role in ${program?.name || "the program"} is now ${nextRole}.`,
                recipientIds: [member_id],
                transaction
            });
        }

        const member = await Member.findByPk(member_id, { transaction });
        await transaction.commit();

        return {
            program_id: membership.program_id,
            member_id: membership.member_id,
            member_name: member?.member_name,
            role: membership.role,
            status: membership.status,
            is_active: membership.status === "active",
            joined_at: membership.joined_at,
            message: "Membership updated successfully."
        };
    } catch (err) {
        if (err instanceof AppError) throw err;
        await transaction.rollback();
        throw new AppError(500, "Failed to update membership.");
    }
}

async function removeMember({ program_id, member_id }, requester) {
    if (!program_id || !member_id) {
        throw new AppError(400, "program_id and member_id are required.");
    }

    const transaction = await sequelize.transaction();
    try {
        if (requester?.global_role !== "global_admin") {
            const pm = await ProgramMembership.findOne({
                where: { program_id, member_id: requester?.id, role: "admin", status: "active" },
                transaction
            });
            if (!pm) {
                await transaction.rollback();
                throw new AppError(403, "Admin privileges required for this program.");
            }
        }

        const membership = await ProgramMembership.findOne({
            where: { program_id, member_id },
            transaction
        });
        if (!membership) {
            await transaction.rollback();
            throw new AppError(404, "Membership not found.");
        }
        if (membership.status === "removed") {
            await transaction.rollback();
            throw new AppError(400, "Member is already removed from this program.");
        }

        await membership.update({ status: "removed", left_at: new Date() }, { transaction });

        const program = await Program.findByPk(program_id, { transaction });
        await createNotification({
            type: "program.member_removed",
            programId: program_id,
            actorMemberId: requester?.id || null,
            title: "Removed from program",
            body: `You were removed from ${program?.name || "the program"}.`,
            recipientIds: [member_id],
            transaction
        });

        await ProgramInviteBlock.destroy({ where: { program_id, member_id }, transaction });
        await ProgramInvite.update(
            { status: "revoked" },
            { where: { program_id, invited_by: member_id, status: "pending" }, transaction }
        );

        const exitResult = await handleMemberExit({
            programId: program_id,
            exitingMemberId: member_id,
            transaction
        });

        await transaction.commit();

        return {
            message: exitResult.programDeleted
                ? "Member removed. The program has been deleted because no active members remain."
                : "Member removed from program successfully.",
            program_deleted: exitResult.programDeleted,
            new_admin_member_id: exitResult.newAdminMemberId,
            new_admin_member_name: exitResult.newAdminMemberName
        };
    } catch (err) {
        if (err instanceof AppError) throw err;
        await transaction.rollback();
        throw new AppError(500, "Failed to remove member from program.");
    }
}

async function leaveProgram(program_id, requester) {
    if (!program_id) throw new AppError(400, "program_id is required.");

    const memberId = requester.id;
    const transaction = await sequelize.transaction();

    try {
        const membership = await ProgramMembership.findOne({
            where: { program_id, member_id: memberId },
            transaction
        });
        if (!membership) {
            await transaction.rollback();
            throw new AppError(404, "Membership not found.");
        }

        if (requester?.global_role === "global_admin") {
            await transaction.rollback();
            throw new AppError(403, "Global admins cannot leave programs.");
        }

        if (membership.status === "removed") {
            await transaction.rollback();
            throw new AppError(400, "You have already left this program.");
        }

        await membership.update({ status: "removed", left_at: new Date() }, { transaction });

        await ProgramInviteBlock.destroy({ where: { program_id, member_id: memberId }, transaction });
        await ProgramInvite.update(
            { status: "revoked" },
            { where: { program_id, invited_by: memberId, status: "pending" }, transaction }
        );

        const exitResult = await handleMemberExit({
            programId: program_id,
            exitingMemberId: memberId,
            transaction
        });

        const remainingMemberIds = await getActiveProgramMemberIds(program_id, transaction);
        if (remainingMemberIds.length > 0) {
            const program = await Program.findByPk(program_id, { transaction });
            const leavingMember = await Member.findByPk(memberId, { transaction });
            await createNotification({
                type: "program.member_left",
                programId: program_id,
                actorMemberId: memberId,
                title: "Member left",
                body: `${leavingMember?.member_name || "A member"} left ${program?.name || "the program"}.`,
                recipientIds: remainingMemberIds,
                transaction
            });
        }

        await transaction.commit();

        const program = await Program.findByPk(program_id);
        let message = `You have left ${program?.name || "the program"}. Your data has been preserved and will be restored if you rejoin.`;
        if (exitResult.programDeleted) {
            message = `You have left ${program?.name || "the program"}. Your data has been preserved. The program was deleted because no active members remain.`;
        } else if (exitResult.newAdminMemberName) {
            message = `You have left ${program?.name || "the program"}. Your data has been preserved and will be restored if you rejoin. ${exitResult.newAdminMemberName} has been promoted to admin.`;
        }

        return {
            message,
            program_id,
            member_id: memberId,
            program_deleted: exitResult.programDeleted,
            new_admin_member_id: exitResult.newAdminMemberId,
            new_admin_member_name: exitResult.newAdminMemberName
        };
    } catch (err) {
        if (err instanceof AppError) throw err;
        await transaction.rollback();
        throw new AppError(500, "Failed to leave program.");
    }
}

module.exports = {
    createMemberAndEnroll,
    getProgramMembers,
    getAvailableMembers,
    getMembershipDetails,
    enrollMember,
    updateMembership,
    removeMember,
    leaveProgram
};
