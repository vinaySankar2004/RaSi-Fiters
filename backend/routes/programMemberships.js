const express = require("express");
const crypto = require("crypto");
const { Op } = require("sequelize");
const { Member, Program, ProgramMembership, ProgramInvite, ProgramInviteBlock } = require("../models");
const { sequelize } = require("../config/database");
const { authenticateToken } = require("../middleware/auth");

const router = express.Router();

// Helper to generate a unique username based on member_name
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
        if (!exists) {
            return candidate;
        }
        candidate = `${slug}${counter}`;
        counter += 1;
    }
    throw new Error("Unable to generate unique username");
};

// POST /program-memberships : create member + enroll to program (new endpoint, non-breaking)
router.post("/", authenticateToken, async (req, res) => {
    const transaction = await sequelize.transaction();

    try {
        const { member_name, password, program_id, gender, date_of_birth, date_joined, role, status, is_active } = req.body;
        const requester = req.user;

        if (!member_name || !password || !program_id) {
            await transaction.rollback();
            return res.status(400).json({ error: "member_name, password, and program_id are required." });
        }

        // Authorization: allow if global_admin, otherwise require admin role in the program_memberships row for requester.
        if (requester?.global_role !== "global_admin") {
            const pm = await ProgramMembership.findOne({
                where: {
                    program_id,
                    member_id: requester?.id,
                    role: "admin",
                    status: "active"
                },
                transaction
            });
            if (!pm) {
                await transaction.rollback();
                return res.status(403).json({ error: "Admin privileges required." });
            }
        }

        const program = await Program.findOne({
            where: { id: program_id, is_deleted: false },
            transaction
        });
        if (!program) {
            await transaction.rollback();
            return res.status(404).json({ error: "Program not found." });
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

        res.status(201).json({
            id: newMember.id,
            member_name: newMember.member_name,
            username: newMember.username,
            gender: newMember.gender,
            date_of_birth: newMember.date_of_birth,
            date_joined: newMember.date_joined,
            role: newMember.role,
            program_id
        });
    } catch (err) {
        await transaction.rollback();
        console.error("Error adding member to program:", err);
        const message = err.message === "Unable to generate unique username"
            ? "Failed to generate unique username."
            : "Failed to add member.";
        res.status(500).json({ error: message });
    }
});

// GET /program-memberships/members?programId=... : members in a program
router.get("/members", authenticateToken, async (req, res) => {
    try {
        const { programId } = req.query;
        if (!programId) {
            return res.status(400).json({ error: "programId is required" });
        }

        const memberships = await ProgramMembership.findAll({
            where: { program_id: programId },
            include: [
                {
                    model: Member,
                    attributes: ["id", "first_name", "last_name", "username", "gender", "created_at", "global_role"]
                }
            ],
            order: [[Member, "first_name", "ASC"]]
        });

        // Map to include member_name (virtual field computed from first_name + last_name)
        const members = memberships
            .filter((m) => m.Member)
            .map((m) => ({
                id: m.Member.id,
                member_name: m.Member.member_name,
                username: m.Member.username,
                gender: m.Member.gender,
                date_joined: m.Member.date_joined,
                global_role: m.Member.global_role
            }));

        res.json(members);
    } catch (err) {
        console.error("Error fetching program members:", err);
        res.status(500).json({ error: "Failed to fetch program members." });
    }
});

// GET /program-memberships/available?programId=... : members NOT in the specified program
router.get("/available", authenticateToken, async (req, res) => {
    try {
        const { programId } = req.query;
        if (!programId) {
            return res.status(400).json({ error: "programId is required" });
        }

        // Get IDs of members already in the program
        const existingMemberships = await ProgramMembership.findAll({
            where: { program_id: programId },
            attributes: ["member_id"]
        });
        const enrolledMemberIds = existingMemberships.map((m) => m.member_id);

        // Find all members NOT in the program (exclude admins by global_role)
        const whereClause = {
            global_role: "standard"
        };

        if (enrolledMemberIds.length > 0) {
            whereClause.id = { [Op.notIn]: enrolledMemberIds };
        }

        const availableMembers = await Member.findAll({
            where: whereClause,
            attributes: ["id", "member_name", "username", "gender", "date_joined"],
            order: [["member_name", "ASC"]]
        });

        res.json(availableMembers);
    } catch (err) {
        console.error("Error fetching available members:", err);
        res.status(500).json({ error: "Failed to fetch available members." });
    }
});

// GET /program-memberships/details?programId=... : members with membership details (role, is_active, joined_at)
router.get("/details", authenticateToken, async (req, res) => {
    try {
        const { programId } = req.query;
        if (!programId) {
            return res.status(400).json({ error: "programId is required" });
        }

        const memberships = await ProgramMembership.findAll({
            where: { program_id: programId },
            include: [
                {
                    model: Member,
                    attributes: ["id", "first_name", "last_name", "username", "gender", "created_at", "global_role"]
                }
            ],
            order: [[Member, "first_name", "ASC"]]
        });

        // Return combined member + membership data (compute virtual fields)
        const result = memberships
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

        // Debug logging: print program_role for each member
        console.log(`[program-memberships/details] Returning ${result.length} members for programId=${programId}`);
        result.forEach(m => {
            console.log(`  - Member: ${m.member_name} (${m.member_id}), program_role: ${m.program_role}, global_role: ${m.global_role}`);
        });

        res.json(result);
    } catch (err) {
        console.error("Error fetching program membership details:", err);
        res.status(500).json({ error: "Failed to fetch program membership details." });
    }
});

// POST /program-memberships/enroll : enroll an existing member into a program
router.post("/enroll", authenticateToken, async (req, res) => {
    const transaction = await sequelize.transaction();

    try {
        const { member_id, program_id, role, joined_at, status, is_active } = req.body;
        const requester = req.user;

        if (!member_id || !program_id) {
            await transaction.rollback();
            return res.status(400).json({ error: "member_id and program_id are required." });
        }

        // Authorization: allow if global_admin, otherwise require admin role in the program
        if (requester?.global_role !== "global_admin") {
            const pm = await ProgramMembership.findOne({
                where: {
                    program_id,
                    member_id: requester?.id,
                    role: "admin",
                    status: "active"
                },
                transaction
            });
            if (!pm) {
                await transaction.rollback();
                return res.status(403).json({ error: "Admin privileges required." });
            }
        }

        // Check if program exists
        const program = await Program.findOne({
            where: { id: program_id, is_deleted: false },
            transaction
        });
        if (!program) {
            await transaction.rollback();
            return res.status(404).json({ error: "Program not found." });
        }

        // Check if member exists
        const member = await Member.findByPk(member_id, { transaction });
        if (!member) {
            await transaction.rollback();
            return res.status(404).json({ error: "Member not found." });
        }

        // Check if member is already enrolled in the program
        const existingMembership = await ProgramMembership.findOne({
            where: { program_id, member_id },
            transaction
        });
        if (existingMembership) {
            await transaction.rollback();
            return res.status(400).json({ error: "Member is already enrolled in this program." });
        }

        // Create the program membership
        const resolvedStatus = status || (is_active === false ? "removed" : "active");

        await ProgramMembership.create({
            program_id,
            member_id,
            role: role || "member",
            joined_at: joined_at || new Date().toISOString().slice(0, 10),
            status: resolvedStatus
        }, { transaction });

        await transaction.commit();

        res.status(201).json({
            member_id: member.id,
            member_name: member.member_name,
            username: member.username,
            gender: member.gender,
            date_of_birth: member.date_of_birth,
            date_joined: member.date_joined,
            program_id,
            message: "Member enrolled successfully."
        });
    } catch (err) {
        await transaction.rollback();
        console.error("Error enrolling member to program:", err);
        res.status(500).json({ error: "Failed to enroll member." });
    }
});

// PUT /program-memberships : update membership (role, is_active, joined_at)
router.put("/", authenticateToken, async (req, res) => {
    try {
        const { program_id, member_id, role, status, is_active, joined_at } = req.body;
        const requester = req.user;

        if (!program_id || !member_id) {
            return res.status(400).json({ error: "program_id and member_id are required." });
        }

        const isSelf = requester?.id === member_id;
        const isGlobalAdmin = requester?.global_role === "global_admin";
        let isProgramAdmin = false;
        if (!isGlobalAdmin) {
            const pm = await ProgramMembership.findOne({
                where: {
                    program_id,
                    member_id: requester?.id,
                    role: "admin",
                    status: "active"
                }
            });
            isProgramAdmin = !!pm;
        }
        if (!isGlobalAdmin && !isProgramAdmin && !isSelf) {
            return res.status(403).json({ error: "Admin privileges required for this program." });
        }

        // Find the membership
        const membership = await ProgramMembership.findOne({
            where: { program_id, member_id }
        });

        if (!membership) {
            return res.status(404).json({ error: "Membership not found." });
        }

        const isAdmin = isGlobalAdmin || isProgramAdmin;

        if (!isAdmin && isSelf) {
            if (role !== undefined || joined_at !== undefined) {
                return res.status(403).json({ error: "Only status updates are allowed." });
            }
            if (!["invited", "requested"].includes(membership.status)) {
                return res.status(403).json({ error: "Cannot update membership status." });
            }
        }

        // Build update object with only provided fields
        const updateData = {};
        if (role !== undefined) updateData.role = role;
        let resolvedStatus = status;
        if (resolvedStatus === undefined && is_active !== undefined) {
            resolvedStatus = is_active ? "active" : "removed";
        }
        if (!isAdmin && isSelf) {
            if (!["active", "removed"].includes(resolvedStatus || "")) {
                return res.status(400).json({ error: "Invalid status update." });
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

        // Prevent changes that would leave the program without any active admins
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
                }
            });
            if (remainingAdmins < 1) {
                return res.status(400).json({ error: "Cannot remove the last admin from the program." });
            }
        }

        await membership.update(updateData);

        // Fetch member info for response
        const member = await Member.findByPk(member_id);

        res.json({
            program_id: membership.program_id,
            member_id: membership.member_id,
            member_name: member?.member_name,
            role: membership.role,
            status: membership.status,
            is_active: membership.status === "active",
            joined_at: membership.joined_at,
            message: "Membership updated successfully."
        });
    } catch (err) {
        console.error("Error updating membership:", err);
        res.status(500).json({ error: "Failed to update membership." });
    }
});

// DELETE /program-memberships : remove member from program
router.delete("/", authenticateToken, async (req, res) => {
    try {
        const { program_id, member_id } = req.body;
        const requester = req.user;

        if (!program_id || !member_id) {
            return res.status(400).json({ error: "program_id and member_id are required." });
        }

        // Authorization: allow if global_admin, otherwise require admin role in the program
        if (requester?.global_role !== "global_admin") {
            const pm = await ProgramMembership.findOne({
                where: {
                    program_id,
                    member_id: requester?.id,
                    role: "admin",
                    status: "active"
                }
            });
            if (!pm) {
                return res.status(403).json({ error: "Admin privileges required for this program." });
            }
        }

        // Find the membership
        const membership = await ProgramMembership.findOne({
            where: { program_id, member_id }
        });

        if (!membership) {
            return res.status(404).json({ error: "Membership not found." });
        }

        // Prevent removal if it would leave no admins
        if (membership.role === "admin" && membership.status === "active") {
            const adminCount = await ProgramMembership.count({
                where: { program_id, role: "admin", status: "active" }
            });
            if (adminCount <= 1) {
                return res.status(400).json({ error: "Cannot remove the last admin from the program." });
            }
        }

        await membership.destroy();

        res.json({ message: "Member removed from program successfully." });
    } catch (err) {
        console.error("Error removing member from program:", err);
        res.status(500).json({ error: "Failed to remove member from program." });
    }
});

// POST /program-memberships/invite : send program invitation by username
// Privacy-preserving: always returns success message regardless of whether username exists
router.post("/invite", authenticateToken, async (req, res) => {
    try {
        const { program_id, username } = req.body;
        const requester = req.user;

        if (!program_id || !username) {
            return res.status(400).json({ error: "program_id and username are required." });
        }

        // Authorization: allow if global_admin, otherwise require admin role in the program
        const isGlobalAdmin = requester?.global_role === "global_admin";
        if (!isGlobalAdmin) {
            const pm = await ProgramMembership.findOne({
                where: {
                    program_id,
                    member_id: requester?.id,
                    role: "admin",
                    status: "active"
                }
            });
            if (!pm) {
                return res.status(403).json({ error: "Admin privileges required for this program." });
            }
        }

        // Check if program exists (don't reveal this to user - just proceed)
        const program = await Program.findOne({
            where: { id: program_id, is_deleted: false }
        });
        if (!program) {
            // Still return success for privacy
            return res.json({ message: "Invitation sent" });
        }

        // Normalize username for lookup (case-insensitive)
        const normalizedUsername = username.trim().toLowerCase();

        // Check if user with this username exists
        const targetMember = await Member.findOne({
            where: sequelize.where(
                sequelize.fn('LOWER', sequelize.col('username')),
                normalizedUsername
            )
        });

        // If no such user, silently succeed (privacy protection)
        if (!targetMember) {
            console.log(`[invite] Username '${username}' not found - returning success for privacy`);
            return res.json({ message: "Invitation sent" });
        }

        // Check if user already a member of this program
        const existingMembership = await ProgramMembership.findOne({
            where: { program_id, member_id: targetMember.id }
        });
        if (existingMembership) {
            console.log(`[invite] User '${username}' already member of program - returning success for privacy`);
            return res.json({ message: "Invitation sent" });
        }

        // Check if user has blocked invites from this program
        const blocked = await ProgramInviteBlock.findOne({
            where: { program_id, member_id: targetMember.id }
        });
        if (blocked) {
            console.log(`[invite] User '${username}' blocked invites from this program - returning success for privacy`);
            return res.json({ message: "Invitation sent" });
        }

        // Check if there's already a pending invite for this user to this program
        const existingInvite = await ProgramInvite.findOne({
            where: {
                program_id,
                invited_username: targetMember.username,
                status: "pending"
            }
        });
        if (existingInvite) {
            const isExpired = existingInvite.expires_at && new Date(existingInvite.expires_at) < new Date();
            if (!isExpired) {
                console.log(`[invite] Pending invite already exists for '${username}' - returning success`);
                return res.json({ message: "Invitation sent" });
            }
            await existingInvite.update({ status: "expired" });
            console.log(`[invite] Expired stale pending invite for '${username}' - allowing re-invite`);
        }

        // All checks passed - create the invite
        const tokenHash = crypto.randomBytes(32).toString("hex");

        await ProgramInvite.create({
            program_id,
            invited_by: requester.id,
            invited_username: targetMember.username,
            token_hash: tokenHash,
            status: "pending",
            max_uses: 1,
            uses_count: 0,
            // Set expiration to 30 days from now
            expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        });

        console.log(`[invite] Created invite for '${username}' to program '${program.name}'`);
        return res.json({ message: "Invitation sent" });

    } catch (err) {
        console.error("Error sending program invite:", err);
        // Even on error, return a generic success for privacy
        // But log the actual error server-side
        return res.json({ message: "Invitation sent" });
    }
});

// GET /program-memberships/my-invites : get pending invites for the logged-in user
router.get("/my-invites", authenticateToken, async (req, res) => {
    try {
        const requester = req.user;

        const invites = await ProgramInvite.findAll({
            where: {
                invited_username: requester.username,
                status: "pending"
            },
            include: [
                {
                    model: Program,
                    attributes: ["id", "name", "status", "start_date", "end_date"]
                },
                {
                    model: Member,
                    as: "InvitedByMember",
                    attributes: ["id", "first_name", "last_name", "username"]
                }
            ],
            order: [["created_at", "DESC"]]
        });

        const result = invites.map(inv => ({
            invite_id: inv.id,
            program_id: inv.program_id,
            program_name: inv.Program?.name,
            program_status: inv.Program?.status,
            program_start_date: inv.Program?.start_date,
            program_end_date: inv.Program?.end_date,
            invited_by_name: inv.InvitedByMember?.member_name,
            invited_at: inv.created_at,
            expires_at: inv.expires_at
        }));

        res.json(result);
    } catch (err) {
        console.error("Error fetching user invites:", err);
        res.status(500).json({ error: "Failed to fetch invites." });
    }
});

// GET /program-memberships/all-invites : get ALL pending invites (global_admin only)
router.get("/all-invites", authenticateToken, async (req, res) => {
    try {
        const requester = req.user;

        // Only global_admin can access this endpoint
        if (requester?.global_role !== "global_admin") {
            return res.status(403).json({ error: "Global admin privileges required." });
        }

        const invites = await ProgramInvite.findAll({
            where: {
                status: "pending"
            },
            include: [
                {
                    model: Program,
                    attributes: ["id", "name", "status", "start_date", "end_date"]
                },
                {
                    model: Member,
                    as: "InvitedByMember",
                    attributes: ["id", "first_name", "last_name", "username"]
                }
            ],
            order: [
                [Program, "name", "ASC"],
                ["created_at", "DESC"]
            ]
        });

        // We need to look up the invited member details by username
        const result = await Promise.all(invites.map(async (inv) => {
            // Find the member who was invited
            const invitedMember = await Member.findOne({
                where: sequelize.where(
                    sequelize.fn('LOWER', sequelize.col('username')),
                    inv.invited_username?.toLowerCase()
                ),
                attributes: ["id", "first_name", "last_name", "username"]
            });

            return {
                invite_id: inv.id,
                program_id: inv.program_id,
                program_name: inv.Program?.name,
                program_status: inv.Program?.status,
                program_start_date: inv.Program?.start_date,
                program_end_date: inv.Program?.end_date,
                invited_by_name: inv.InvitedByMember?.member_name,
                invited_at: inv.created_at,
                expires_at: inv.expires_at,
                // Additional fields for admin view
                invited_username: inv.invited_username,
                invited_member_name: invitedMember?.member_name,
                invited_member_id: invitedMember?.id
            };
        }));

        res.json(result);
    } catch (err) {
        console.error("Error fetching all invites:", err);
        res.status(500).json({ error: "Failed to fetch invites." });
    }
});

// PUT /program-memberships/invite-response : accept, decline, or revoke an invite
// Standard users can only respond to their own invites
// Global admin can respond to ANY invite on behalf of users
router.put("/invite-response", authenticateToken, async (req, res) => {
    const transaction = await sequelize.transaction();

    try {
        const { invite_id, action, block_future, target_member_id } = req.body;
        const requester = req.user;
        const isGlobalAdmin = requester?.global_role === "global_admin";

        if (!invite_id || !action) {
            await transaction.rollback();
            return res.status(400).json({ error: "invite_id and action are required." });
        }

        // Valid actions: accept, decline, revoke (revoke is admin-only)
        const validActions = isGlobalAdmin ? ["accept", "decline", "revoke"] : ["accept", "decline"];
        if (!validActions.includes(action)) {
            await transaction.rollback();
            const actionsStr = validActions.join("', '");
            return res.status(400).json({ error: `action must be '${actionsStr}'.` });
        }

        // Find the invite - different logic for admin vs standard user
        let invite;
        let targetMember;

        if (isGlobalAdmin) {
            // Admin can act on any invite
            invite = await ProgramInvite.findOne({
                where: {
                    id: invite_id,
                    status: "pending"
                },
                transaction
            });

            if (!invite) {
                await transaction.rollback();
                return res.status(404).json({ error: "Invite not found or already processed." });
            }

            // Find the target member (the invitee)
            targetMember = await Member.findOne({
                where: sequelize.where(
                    sequelize.fn('LOWER', sequelize.col('username')),
                    invite.invited_username?.toLowerCase()
                ),
                transaction
            });

            if (!targetMember && action === "accept") {
                await transaction.rollback();
                return res.status(404).json({ error: "Invited user not found." });
            }
        } else {
            // Standard user can only act on their own invites
            invite = await ProgramInvite.findOne({
                where: {
                    id: invite_id,
                    invited_username: requester.username,
                    status: "pending"
                },
                transaction
            });

            if (!invite) {
                await transaction.rollback();
                return res.status(404).json({ error: "Invite not found or already processed." });
            }

            targetMember = requester;
        }

        // Check if invite has expired
        if (invite.expires_at && new Date(invite.expires_at) < new Date()) {
            await invite.update({ status: "expired" }, { transaction });
            await transaction.commit();
            return res.status(400).json({ error: "This invite has expired." });
        }

        // Fetch program name for response messages
        const program = await Program.findByPk(invite.program_id, { transaction });
        const programName = program?.name || "the program";

        if (action === "accept") {
            // Check if member has an existing membership (active or removed)
            const existingMembership = await ProgramMembership.findOne({
                where: { program_id: invite.program_id, member_id: targetMember.id },
                transaction
            });

            if (existingMembership) {
                if (existingMembership.status === "removed") {
                    // Reactivate the removed membership - restores access to historical data
                    await existingMembership.update({
                        status: "active",
                        left_at: null
                    }, { transaction });

                    // Update invite status
                    await invite.update({
                        status: "accepted",
                        uses_count: invite.uses_count + 1
                    }, { transaction });

                    await transaction.commit();
                    console.log(`[invite-accept] Reactivated membership for member ${targetMember.id} in program ${invite.program_id}`);
                    return res.json({ 
                        message: isGlobalAdmin 
                            ? `Invitation accepted. ${targetMember.member_name} has rejoined ${programName}. Previous data has been restored.`
                            : `Welcome back! You have rejoined ${programName}. Your previous data has been restored.`
                    });
                }

                // Already an active member - just mark invite as accepted
                await invite.update({
                    status: "accepted",
                    uses_count: invite.uses_count + 1
                }, { transaction });
                await transaction.commit();
                return res.json({ 
                    message: isGlobalAdmin 
                        ? `${targetMember.member_name} is already a member of ${programName}.`
                        : `You are already a member of ${programName}.`
                });
            }

            // Create program membership for the target member
            await ProgramMembership.create({
                program_id: invite.program_id,
                member_id: targetMember.id,
                role: "member",
                status: "active",
                joined_at: new Date()
            }, { transaction });

            // Update invite status
            await invite.update({
                status: "accepted",
                uses_count: invite.uses_count + 1
            }, { transaction });

            await transaction.commit();
            return res.json({ 
                message: isGlobalAdmin 
                    ? `Invitation accepted. ${targetMember.member_name} is now a member of ${programName}.`
                    : `Invitation accepted. You are now a member of ${programName}.`
            });

        } else if (action === "decline") {
            await invite.update({ status: "declined" }, { transaction });

            // Optionally block future invites from this program
            if (block_future === true && targetMember) {
                await ProgramInviteBlock.findOrCreate({
                    where: {
                        program_id: invite.program_id,
                        member_id: targetMember.id
                    },
                    defaults: {
                        program_id: invite.program_id,
                        member_id: targetMember.id
                    },
                    transaction
                });
            }

            await transaction.commit();
            return res.json({ 
                message: isGlobalAdmin 
                    ? `Invitation to ${targetMember?.member_name || invite.invited_username} declined.`
                    : "Invitation declined."
            });

        } else if (action === "revoke") {
            // Revoke is admin-only - cancels the invite without marking it as declined
            await invite.update({ status: "revoked" }, { transaction });

            await transaction.commit();
            return res.json({ 
                message: `Invitation to ${targetMember?.member_name || invite.invited_username} has been revoked.`
            });
        }

    } catch (err) {
        await transaction.rollback();
        console.error("Error responding to invite:", err);
        res.status(500).json({ error: "Failed to process invite response." });
    }
});

// PUT /program-memberships/leave : leave a program (soft removal - data preserved)
router.put("/leave", authenticateToken, async (req, res) => {
    const transaction = await sequelize.transaction();

    try {
        const { program_id } = req.body;
        const memberId = req.user.id;

        if (!program_id) {
            await transaction.rollback();
            return res.status(400).json({ error: "program_id is required." });
        }

        // Find the membership
        const membership = await ProgramMembership.findOne({
            where: { program_id, member_id: memberId },
            transaction
        });

        if (!membership) {
            await transaction.rollback();
            return res.status(404).json({ error: "Membership not found." });
        }

        // Global admins cannot leave programs
        if (req.user?.global_role === "global_admin") {
            await transaction.rollback();
            return res.status(403).json({ error: "Global admins cannot leave programs." });
        }

        // Check if already removed
        if (membership.status === "removed") {
            await transaction.rollback();
            return res.status(400).json({ error: "You have already left this program." });
        }

        // Admins must transfer ownership and demote themselves before leaving
        if (membership.role === "admin") {
            await transaction.rollback();
            return res.status(400).json({
                error: "Admins must transfer admin role and demote themselves before leaving the program."
            });
        }

        // Update membership to removed status
        await membership.update({
            status: "removed",
            left_at: new Date()
        }, { transaction });

        console.log(`[leave-program] Member ${memberId} left program ${program_id}`);

        // Clear any program_invite_blocks for this program/member (allows future re-invitation)
        await ProgramInviteBlock.destroy({
            where: { program_id, member_id: memberId },
            transaction
        });
        console.log(`[leave-program] Cleared invite blocks for member ${memberId} in program ${program_id}`);

        // Revoke any pending invites this user sent for this program
        await ProgramInvite.update(
            { status: "revoked" },
            { 
                where: { 
                    program_id, 
                    invited_by: memberId, 
                    status: "pending" 
                },
                transaction 
            }
        );
        console.log(`[leave-program] Revoked pending invites sent by member ${memberId} for program ${program_id}`);

        await transaction.commit();

        // Fetch program name for response
        const program = await Program.findByPk(program_id);

        res.json({ 
            message: `You have left ${program?.name || "the program"}. Your data has been preserved and will be restored if you rejoin.`,
            program_id,
            member_id: memberId
        });

    } catch (err) {
        await transaction.rollback();
        console.error("Error leaving program:", err);
        res.status(500).json({ error: "Failed to leave program." });
    }
});

module.exports = router;
