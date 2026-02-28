const { Program, ProgramMembership } = require("../models");
const { sequelize } = require("../config/database");
const { AppError } = require("../utils/response");
const { createNotification, getActiveProgramMemberIds } = require("../utils/notifications");

async function getPrograms(requester) {
    const isGlobalAdmin = requester?.global_role === "global_admin";
    const requesterId = requester?.id;

    if (isGlobalAdmin) {
        const [results] = await sequelize.query(`
            SELECT 
                p.id, p.name, p.status, p.start_date, p.end_date,
                p.is_deleted, p.created_at, p.updated_at,
                COALESCE(COUNT(DISTINCT CASE WHEN pm.status = 'active' THEN pm.member_id END), 0)::int AS total_members,
                COALESCE(COUNT(DISTINCT CASE WHEN pm.status = 'active' THEN pm.member_id END), 0)::int AS active_members,
                pm_user.role AS my_role,
                pm_user.status AS my_status,
                CASE 
                    WHEN p.start_date IS NOT NULL AND p.end_date IS NOT NULL 
                         AND p.end_date > p.start_date
                    THEN LEAST(100, GREATEST(0,
                        ((CURRENT_DATE - p.start_date)::numeric / 
                         NULLIF((p.end_date - p.start_date)::numeric, 0)) * 100
                    ))::int
                    ELSE 0
                END AS progress_percent
            FROM programs p
            LEFT JOIN program_memberships pm ON p.id = pm.program_id
            LEFT JOIN program_memberships pm_user ON p.id = pm_user.program_id AND pm_user.member_id = :userId
            WHERE p.is_deleted = false
            GROUP BY p.id, pm_user.role, pm_user.status
            ORDER BY p.start_date ASC
        `, { replacements: { userId: requesterId } });
        return results;
    }

    const [results] = await sequelize.query(`
        SELECT 
            p.id, p.name, p.status, p.start_date, p.end_date,
            p.is_deleted, p.created_at, p.updated_at,
            COALESCE(COUNT(DISTINCT pm_all.member_id), 0)::int AS total_members,
            COALESCE(COUNT(DISTINCT pm_all.member_id), 0)::int AS active_members,
            pm_user.role AS my_role,
            pm_user.status AS my_status,
            CASE 
                WHEN p.start_date IS NOT NULL AND p.end_date IS NOT NULL 
                     AND p.end_date > p.start_date
                THEN LEAST(100, GREATEST(0,
                    ((CURRENT_DATE - p.start_date)::numeric / 
                     NULLIF((p.end_date - p.start_date)::numeric, 0)) * 100
                ))::int
                ELSE 0
            END AS progress_percent
        FROM programs p
        INNER JOIN program_memberships pm_user 
            ON p.id = pm_user.program_id 
            AND pm_user.member_id = :userId
            AND pm_user.status IN ('active', 'invited', 'requested')
        LEFT JOIN program_memberships pm_all 
            ON p.id = pm_all.program_id 
            AND pm_all.status = 'active'
        WHERE p.is_deleted = false
        GROUP BY p.id, pm_user.role, pm_user.status
        ORDER BY p.start_date ASC
    `, { replacements: { userId: requesterId } });
    return results;
}

async function createProgram({ name, status, start_date, end_date, description }, requester) {
    if (!name || typeof name !== "string" || name.trim() === "") {
        throw new AppError(400, "Program name is required.");
    }

    const validStatuses = ["planned", "active", "completed"];
    const programStatus = status && validStatuses.includes(status) ? status : "planned";

    const transaction = await sequelize.transaction();
    try {
        const program = await Program.create({
            name: name.trim(),
            status: programStatus,
            start_date: start_date || null,
            end_date: end_date || null,
            description: description || null,
            created_by: requester?.id,
            is_deleted: false
        }, { transaction });

        await ProgramMembership.create({
            program_id: program.id,
            member_id: requester?.id,
            role: "admin",
            status: "active",
            joined_at: new Date().toISOString().slice(0, 10)
        }, { transaction });

        await transaction.commit();

        return {
            id: program.id,
            name: program.name,
            status: program.status,
            start_date: program.start_date,
            end_date: program.end_date,
            description: program.description,
            message: "Program created successfully."
        };
    } catch (err) {
        await transaction.rollback();
        throw new AppError(500, "Failed to create program.");
    }
}

async function updateProgram(programId, { name, status, start_date, end_date }, requester) {
    const program = await Program.findOne({ where: { id: programId, is_deleted: false } });
    if (!program) throw new AppError(404, "Program not found.");

    if (requester?.global_role !== "global_admin") {
        const pm = await ProgramMembership.findOne({
            where: { program_id: programId, member_id: requester?.id, role: "admin", status: "active" }
        });
        if (!pm) throw new AppError(403, "Admin privileges required for this program.");
    }

    const previousSnapshot = {
        name: program.name,
        status: program.status,
        start_date: program.start_date ? String(program.start_date) : null,
        end_date: program.end_date ? String(program.end_date) : null
    };

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (status !== undefined) updateData.status = status;
    if (start_date !== undefined) updateData.start_date = start_date;
    if (end_date !== undefined) updateData.end_date = end_date;
    updateData.updated_at = new Date();

    await program.update(updateData);

    const detailFields = ["name", "status", "start_date", "end_date"];
    const hasDetailChange = detailFields.some((field) => {
        if (updateData[field] === undefined) return false;
        const nextValue = updateData[field] === null ? null : String(updateData[field]);
        return nextValue !== previousSnapshot[field];
    });

    if (hasDetailChange) {
        const recipientIds = await getActiveProgramMemberIds(programId);
        if (recipientIds.length > 0) {
            await createNotification({
                type: "program.updated",
                programId,
                actorMemberId: requester?.id || null,
                title: "Program updated",
                body: `${program.name} details were updated.`,
                recipientIds
            });
        }
    }

    return {
        id: program.id,
        name: program.name,
        status: program.status,
        start_date: program.start_date,
        end_date: program.end_date,
        message: "Program updated successfully."
    };
}

async function deleteProgram(programId, requester) {
    if (requester?.global_role !== "global_admin") {
        const pm = await ProgramMembership.findOne({
            where: { program_id: programId, member_id: requester?.id, role: "admin", status: "active" }
        });
        if (!pm) throw new AppError(403, "Admin privileges required for this program.");
    }

    const program = await Program.findOne({ where: { id: programId, is_deleted: false } });
    if (!program) throw new AppError(404, "Program not found.");

    await program.update({ is_deleted: true, updated_at: new Date() });

    const recipientIds = await getActiveProgramMemberIds(programId);
    if (recipientIds.length > 0) {
        await createNotification({
            type: "program.deleted",
            programId,
            actorMemberId: requester?.id || null,
            title: "Program deleted",
            body: `${program.name} was deleted.`,
            recipientIds
        });
    }

    return { id: program.id, message: "Program deleted successfully." };
}

module.exports = {
    getPrograms,
    createProgram,
    updateProgram,
    deleteProgram
};
