const express = require("express");
const { Op } = require("sequelize");
const {
    Member,
    MemberEmail,
    WorkoutLog,
    Program,
    ProgramInvite,
    ProgramMembership,
    Notification
} = require("../models/index");
const { sequelize } = require("../config/database");
const { authenticateToken, isAdmin } = require("../middleware/auth");
const { handleMemberExit } = require("../utils/programMemberships");
const { createNotification, getActiveProgramMemberIds } = require("../utils/notifications");
const router = express.Router();

// GET all members - exclude global_admin users
router.get("/", authenticateToken, async (req, res) => {
    try {
        // Get all members with global_role 'standard' (exclude global_admins)
        const members = await Member.findAll({
            where: { global_role: 'standard' },
            order: [["first_name", "ASC"]],
        });
        res.json(members);
    } catch (err) {
        console.error("Error fetching members:", err);
        res.status(500).json({ error: "Failed to fetch members." });
    }
});

// GET member by ID
router.get("/:id", authenticateToken, async (req, res) => {
    try {
        const member = await Member.findByPk(req.params.id);
        if (!member) {
            return res.status(404).json({ error: "Member not found." });
        }

        // Format the response - exclude password
        const memberData = {
            id: member.id,
            member_name: member.member_name,
            username: member.username,
            gender: member.gender,
            date_joined: member.date_joined,
            global_role: member.global_role,
            created_at: member.created_at,
            updated_at: member.updated_at
        };

        res.json(memberData);
    } catch (err) {
        console.error("Error fetching member:", err);
        res.status(500).json({ error: "Failed to fetch member." });
    }
});

// POST new member
router.post("/", authenticateToken, isAdmin, async (req, res) => {
    const transaction = await sequelize.transaction();

    try {
        const { member_name, gender, password } = req.body;

        if (!member_name || !password) {
            await transaction.rollback();
            return res.status(400).json({ error: "member_name and password are required." });
        }

        // Generate username from member name (lowercase, no spaces)
        const username = member_name.toLowerCase().replace(/\s+/g, '');

        // Check if username already exists
        const existingMember = await Member.findOne({
            where: { username },
            transaction
        });

        if (existingMember) {
            await transaction.rollback();
            return res.status(400).json({ error: "A user with this username already exists." });
        }

        // Create new member
        const newMember = await Member.create({
            member_name,
            username,
            gender
        }, { transaction });

        await transaction.commit();

        // Return the new member
        const memberData = {
            id: newMember.id,
            member_name: newMember.member_name,
            username: newMember.username,
            gender: newMember.gender,
            date_joined: newMember.date_joined,
            global_role: newMember.global_role
        };

        res.status(201).json(memberData);
    } catch (err) {
        await transaction.rollback();
        console.error("Error adding member:", err);
        res.status(500).json({ error: "Failed to add member." });
    }
});

// UPDATE existing member
router.put("/:id", authenticateToken, async (req, res) => {
    const transaction = await sequelize.transaction();

    try {
        const { first_name, last_name, gender } = req.body;
        const member = await Member.findByPk(req.params.id, { transaction });

        if (!member) {
            await transaction.rollback();
            return res.status(404).json({ error: "Member not found." });
        }

        // Check if user has permission to update this member
        const isOwnProfile = req.user.id === member.id;
        const isGlobalAdmin = req.user.global_role === 'global_admin';

        if (!isOwnProfile && !isGlobalAdmin) {
            await transaction.rollback();
            return res.status(403).json({ error: "You can only update your own profile." });
        }

        // Create update object with fields that should be updated
        const updateData = {};
        if (first_name !== undefined) updateData.first_name = first_name.trim();
        if (last_name !== undefined) updateData.last_name = last_name.trim();
        if (gender !== undefined) updateData.gender = gender;

        // Update member
        await member.update(updateData, { transaction });

        await transaction.commit();

        // Return updated member info
        res.json({ 
            message: "Profile updated successfully.",
            member_name: member.member_name,
            first_name: member.first_name,
            last_name: member.last_name
        });
    } catch (err) {
        await transaction.rollback();
        console.error("Error updating member:", err);
        res.status(500).json({ error: "Failed to update member." });
    }
});

// DELETE member (admin only)
router.delete("/:id", authenticateToken, isAdmin, async (req, res) => {
    const transaction = await sequelize.transaction();

    try {
        const member = await Member.findByPk(req.params.id, { transaction });

        if (!member) {
            await transaction.rollback();
            return res.status(404).json({ error: "Member not found." });
        }

        // Check if trying to delete global admin
        if (member.global_role === 'global_admin') {
            await transaction.rollback();
            return res.status(403).json({ error: "Cannot delete global admin account." });
        }

        // Delete any program invites sent by or targeting this member
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
        await ProgramInvite.destroy({
            where: { [Op.or]: inviteFilters },
            transaction
        });

        // Delete notifications where this member is the actor (PII in title/body)
        await Notification.destroy({
            where: { actor_member_id: member.id },
            transaction
        });

        // Ensure programs remain valid after this member exits
        const activeMemberships = await ProgramMembership.findAll({
            where: {
                member_id: member.id,
                status: "active"
            },
            attributes: ["program_id"],
            transaction
        });

        const createdPrograms = await Program.findAll({
            where: { created_by: member.id, is_deleted: false },
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

        // Delete the member
        await member.destroy({ transaction });

        await transaction.commit();
        res.json({ message: "Member deleted successfully." });
    } catch (err) {
        await transaction.rollback();
        console.error("Error deleting member:", err);
        res.status(500).json({ error: "Failed to delete member." });
    }
});

module.exports = router;
