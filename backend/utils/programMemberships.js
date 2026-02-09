const { Op } = require("sequelize");
const { Program, ProgramMembership, Member } = require("../models");
const { createNotification, getActiveProgramMemberIds } = require("./notifications");

const findOldestActiveMembership = async ({
    programId,
    excludeMemberId,
    role,
    transaction
}) => {
    const where = {
        program_id: programId,
        status: "active"
    };
    if (excludeMemberId) {
        where.member_id = { [Op.ne]: excludeMemberId };
    }
    if (role) {
        where.role = role;
    }

    return ProgramMembership.findOne({
        where,
        include: [
            {
                model: Member,
                attributes: ["id", "member_name", "global_role"]
            }
        ],
        order: [
            ["joined_at", "ASC"],
            ["member_id", "ASC"]
        ],
        transaction
    });
};

const handleMemberExit = async ({
    programId,
    exitingMemberId,
    transaction,
    updateCreatedBy = false
}) => {
    const program = await Program.findByPk(programId, { transaction });
    if (!program || program.is_deleted) {
        return { programDeleted: false };
    }

    const remainingMembersCount = await ProgramMembership.count({
        where: {
            program_id: programId,
            status: "active",
            member_id: { [Op.ne]: exitingMemberId }
        },
        transaction
    });

    if (remainingMembersCount === 0) {
        await program.update(
            { is_deleted: true, updated_at: new Date() },
            { transaction }
        );
        const activeMemberIds = await getActiveProgramMemberIds(programId, transaction);
        const recipients = Array.from(new Set([...activeMemberIds, exitingMemberId].filter(Boolean)));
        if (recipients.length > 0) {
            await createNotification({
                type: "program.deleted",
                programId,
                actorMemberId: exitingMemberId || null,
                title: "Program deleted",
                body: `${program.name} was deleted because no members remain.`,
                recipientIds: recipients,
                transaction
            });
        }
        return { programDeleted: true };
    }

    const remainingAdminsCount = await ProgramMembership.count({
        where: {
            program_id: programId,
            status: "active",
            role: "admin",
            member_id: { [Op.ne]: exitingMemberId }
        },
        transaction
    });

    let promotedMembership = null;
    if (remainingAdminsCount === 0) {
        promotedMembership = await findOldestActiveMembership({
            programId,
            excludeMemberId: exitingMemberId,
            transaction
        });

        if (promotedMembership && promotedMembership.role !== "admin") {
            await promotedMembership.update({ role: "admin" }, { transaction });
        }
    }

    if (promotedMembership) {
        await createNotification({
            type: "program.role_changed",
            programId,
            actorMemberId: exitingMemberId || null,
            title: "Role updated",
            body: `Your role in ${program.name} is now admin.`,
            recipientIds: [promotedMembership.member_id],
            transaction
        });

        const activeMemberIds = await getActiveProgramMemberIds(programId, transaction);
        if (activeMemberIds.length > 0) {
            await createNotification({
                type: "program.admin_transferred",
                programId,
                actorMemberId: promotedMembership.member_id,
                title: "New admin assigned",
                body: `${promotedMembership.Member?.member_name || "A member"} is now an admin of ${program.name}.`,
                recipientIds: activeMemberIds,
                transaction
            });
        }
    }

    if (updateCreatedBy && program.created_by === exitingMemberId) {
        let replacementMembership = null;
        if (remainingAdminsCount > 0) {
            replacementMembership = await findOldestActiveMembership({
                programId,
                excludeMemberId: exitingMemberId,
                role: "admin",
                transaction
            });
        } else if (promotedMembership) {
            replacementMembership = promotedMembership;
        } else {
            replacementMembership = await findOldestActiveMembership({
                programId,
                excludeMemberId: exitingMemberId,
                transaction
            });
        }

        if (replacementMembership) {
            await program.update(
                { created_by: replacementMembership.member_id, updated_at: new Date() },
                { transaction }
            );
        }
    }

    return {
        programDeleted: false,
        newAdminMemberId: promotedMembership?.member_id || null,
        newAdminMemberName: promotedMembership?.Member?.member_name || null
    };
};

module.exports = {
    handleMemberExit
};
