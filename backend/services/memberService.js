const { Op } = require("sequelize");
const {
    Member,
    MemberEmail,
    Program,
    ProgramInvite,
    ProgramMembership,
    Notification
} = require("../models");
const { sequelize } = require("../config/database");
const { AppError } = require("../utils/response");
const { handleMemberExit } = require("../utils/programMemberships");
const { createNotification, getActiveProgramMemberIds } = require("../utils/notifications");

async function getAllMembers() {
    return Member.findAll({
        where: { global_role: 'standard' },
        order: [["first_name", "ASC"]]
    });
}

async function getMemberById(memberId) {
    const member = await Member.findByPk(memberId);
    if (!member) throw new AppError(404, "Member not found.");

    return {
        id: member.id,
        member_name: member.member_name,
        username: member.username,
        gender: member.gender,
        date_joined: member.date_joined,
        global_role: member.global_role,
        created_at: member.created_at,
        updated_at: member.updated_at
    };
}

async function createMember({ member_name, gender, password }) {
    if (!member_name || !password) {
        throw new AppError(400, "member_name and password are required.");
    }

    const username = member_name.toLowerCase().replace(/\s+/g, '');
    const transaction = await sequelize.transaction();

    try {
        const existingMember = await Member.findOne({ where: { username }, transaction });
        if (existingMember) {
            await transaction.rollback();
            throw new AppError(400, "A user with this username already exists.");
        }

        const newMember = await Member.create({ member_name, username, gender }, { transaction });
        await transaction.commit();

        return {
            id: newMember.id,
            member_name: newMember.member_name,
            username: newMember.username,
            gender: newMember.gender,
            date_joined: newMember.date_joined,
            global_role: newMember.global_role
        };
    } catch (err) {
        if (err instanceof AppError) throw err;
        await transaction.rollback();
        throw new AppError(500, "Failed to add member.");
    }
}

async function updateMember(memberId, { first_name, last_name, gender }, requester) {
    const transaction = await sequelize.transaction();
    try {
        const member = await Member.findByPk(memberId, { transaction });
        if (!member) {
            await transaction.rollback();
            throw new AppError(404, "Member not found.");
        }

        const isOwnProfile = requester.id === member.id;
        const isGlobalAdmin = requester.global_role === 'global_admin';
        if (!isOwnProfile && !isGlobalAdmin) {
            await transaction.rollback();
            throw new AppError(403, "You can only update your own profile.");
        }

        const updateData = {};
        if (first_name !== undefined) updateData.first_name = first_name.trim();
        if (last_name !== undefined) updateData.last_name = last_name.trim();
        if (gender !== undefined) updateData.gender = gender;

        await member.update(updateData, { transaction });
        await transaction.commit();

        return {
            message: "Profile updated successfully.",
            member_name: member.member_name,
            first_name: member.first_name,
            last_name: member.last_name
        };
    } catch (err) {
        if (err instanceof AppError) throw err;
        await transaction.rollback();
        throw new AppError(500, "Failed to update member.");
    }
}

async function deleteMember(memberId) {
    const transaction = await sequelize.transaction();
    try {
        const member = await Member.findByPk(memberId, { transaction });
        if (!member) {
            await transaction.rollback();
            throw new AppError(404, "Member not found.");
        }
        if (member.global_role === 'global_admin') {
            await transaction.rollback();
            throw new AppError(403, "Cannot delete global admin account.");
        }

        const memberEmails = await MemberEmail.findAll({
            where: { member_id: member.id },
            attributes: ["email"],
            transaction
        });
        const emailList = memberEmails.map((row) => row.email).filter(Boolean);
        const inviteFilters = [
            { invited_by: member.id },
            { invited_username: member.username }
        ];
        if (emailList.length > 0) {
            inviteFilters.push({ invited_email: { [Op.in]: emailList } });
        }
        await ProgramInvite.destroy({ where: { [Op.or]: inviteFilters }, transaction });
        await Notification.destroy({ where: { actor_member_id: member.id }, transaction });

        const activeMemberships = await ProgramMembership.findAll({
            where: { member_id: member.id, status: "active" },
            attributes: ["program_id"],
            transaction
        });
        const createdPrograms = await Program.findAll({
            where: { created_by: member.id, is_deleted: false },
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
                exitingMemberId: member.id,
                transaction,
                updateCreatedBy: true,
                notificationActorId: null,
                includeExitingMemberInRecipients: false
            });

            if (!exitResult.programDeleted) {
                const remainingMemberIds = await getActiveProgramMemberIds(programId, transaction);
                const recipients = remainingMemberIds.filter((id) => id !== member.id);
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

        return { message: "Member deleted successfully." };
    } catch (err) {
        if (err instanceof AppError) throw err;
        await transaction.rollback();
        throw new AppError(500, "Failed to delete member.");
    }
}

module.exports = {
    getAllMembers,
    getMemberById,
    createMember,
    updateMember,
    deleteMember
};
