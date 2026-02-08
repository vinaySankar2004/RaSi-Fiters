const express = require("express");
const { WorkoutLog, Member, ProgramWorkout, ProgramMembership, Workout } = require("../models/index");
const { Op } = require("sequelize");
const { authenticateToken, isAdmin, canModifyLog } = require("../middleware/auth");
const router = express.Router();

// Get workout logs
router.get("/", authenticateToken, async (req, res) => {
    try {
        let { date, programId } = req.query;
        if (!date) {
            return res.status(400).json({ error: "Date is required." });
        }

        console.log("Fetching logs for date:", date);

        // Build query conditions
        const whereCondition = {
            log_date: date
        };
        if (programId) {
            whereCondition.program_id = programId;
        }

        // Get logs with member information using the association
        const logs = await WorkoutLog.findAll({
            where: whereCondition,
            include: [{
                model: Member,
                attributes: ['member_name'] // Only include member_name
            }, {
                model: ProgramWorkout,
                attributes: ["workout_name"]
            }]
        });

        console.log("Found logs:", logs.length);

        // Format the response for the frontend
        const formattedLogs = logs.map(log => ({
            member_id: log.member_id,
            member_name: log.Member ? log.Member.member_name : null, // Get member_name from the included Member model
            workout_name: log.ProgramWorkout ? log.ProgramWorkout.workout_name : null,
            date: log.log_date,
            duration: log.duration,
            canEdit: req.user.role === 'admin' || log.member_id === req.user.id
        }));

        res.json(formattedLogs);
    } catch (err) {
        console.error("Error fetching workout logs:", err);
        res.status(500).json({ error: "Failed to fetch workout logs." });
    }
});

// Add a new workout log
router.post("/", authenticateToken, async (req, res) => {
    try {
        const { member_name, member_id: bodyMemberId, workout_name, date, duration, program_id } = req.body;

        console.log("Received log data:", { member_name, workout_name, date, duration });

        if (!workout_name || !date || !duration) {
            console.log("Missing required fields:", { workout_name, date, duration });
            return res.status(400).json({
                error: "All fields are required."
            });
        }
        if (!program_id) {
            return res.status(400).json({ error: "program_id is required." });
        }

        // Validate duration is a number
        if (isNaN(duration)) {
            return res.status(400).json({ error: "Duration must be a number." });
        }

        // Determine target member_id
        let member_id = req.user.id; // default to the authenticated user

        const requester = req.user;
        let canLogForAny = requester?.global_role === "global_admin";

        if (!canLogForAny) {
            const requesterMembership = await ProgramMembership.findOne({
                where: { program_id, member_id: requester?.id }
            });

            if (!requesterMembership) {
                return res.status(403).json({ error: "You are not enrolled in this program." });
            }

            if (["admin", "logger"].includes(requesterMembership.role)) {
                canLogForAny = true;
            }
        }

        if (bodyMemberId) {
            if (!canLogForAny && bodyMemberId !== requester?.id) {
                return res.status(403).json({ error: "You can only log your own workouts." });
            }
            if (canLogForAny) {
                member_id = bodyMemberId;
            }
        } else if (member_name) {
            if (!canLogForAny && member_name !== requester?.member_name) {
                return res.status(403).json({ error: "You can only log your own workouts." });
            }
            const member = await Member.findOne({ where: { member_name } });
            if (!member) {
                return res.status(404).json({ error: "Member not found." });
            }
            if (!canLogForAny && member.id !== requester?.id) {
                return res.status(403).json({ error: "You can only log your own workouts." });
            }
            member_id = member.id;
        }

        const targetMembership = await ProgramMembership.findOne({
            where: { program_id, member_id, status: "active" }
        });
        if (!targetMembership) {
            return res.status(404).json({ error: "Member is not an active participant in this program." });
        }

        const workoutName = workout_name.trim();
        let programWorkout = null;

        // If the workout exists in the global library, prefer linking to it
        const libraryWorkout = await Workout.findOne({
            where: { workout_name: workoutName }
        });

        if (libraryWorkout) {
            programWorkout = await ProgramWorkout.findOne({
                where: { program_id, library_workout_id: libraryWorkout.id }
            });

            if (!programWorkout) {
                // If a custom workout with the same name exists (likely created by a prior bug),
                // upgrade it to point at the global library workout to prevent duplicates.
                const existingCustom = await ProgramWorkout.findOne({
                    where: { program_id, workout_name: workoutName, library_workout_id: null }
                });

                if (existingCustom) {
                    programWorkout = await existingCustom.update({
                        library_workout_id: libraryWorkout.id
                    });
                } else {
                    programWorkout = await ProgramWorkout.create({
                        program_id,
                        workout_name: libraryWorkout.workout_name,
                        library_workout_id: libraryWorkout.id
                    });
                }
            }
        } else {
            programWorkout = await ProgramWorkout.findOne({
                where: { program_id, workout_name: workoutName }
            });
            if (!programWorkout) {
                programWorkout = await ProgramWorkout.create({
                    program_id,
                    workout_name: workoutName,
                    library_workout_id: null
                });
            }
        }

        // Create the workout log
        const newLog = await WorkoutLog.create({
            program_id,
            member_id,
            program_workout_id: programWorkout.id,
            log_date: date,
            duration: parseInt(duration, 10)
        });

        // Get the member info to include in response
        const member = await Member.findByPk(member_id);

        res.status(201).json({
            ...newLog.toJSON(),
            member_name: member ? member.member_name : null,
            workout_name: workoutName,
            date
        });
    } catch (err) {
        console.error("Error adding workout log:", err);
        res.status(500).json({ error: "Failed to add workout log.", details: err.message });
    }
});

// Update a workout log - check if user can modify this log
router.put("/", authenticateToken, async (req, res) => {
    try {
        const { member_name, workout_name, date, duration, program_id } = req.body;

        if (!workout_name || !date || !duration) {
            return res.status(400).json({ error: "Workout name, date, and duration are required." });
        }
        if (!program_id) {
            return res.status(400).json({ error: "program_id is required." });
        }

        // Get member_id from member_name if provided
        let member_id = req.user.id;

        if (member_name && member_name !== req.user.member_name) {
            // Only admins can update other members' logs
            if (req.user.role !== 'admin') {
                return res.status(403).json({ error: "You can only update your own logs." });
            }

            const member = await Member.findOne({
                where: { member_name }
            });

            if (!member) {
                return res.status(404).json({ error: "Member not found." });
            }

            member_id = member.id;
        }

        // Find the log
        const programWorkout = await ProgramWorkout.findOne({
            where: { program_id, workout_name: workout_name.trim() }
        });
        if (!programWorkout) {
            return res.status(404).json({ error: "Workout type not found for program." });
        }

        const log = await WorkoutLog.findOne({
            where: {
                program_id,
                member_id,
                program_workout_id: programWorkout.id,
                log_date: date
            }
        });

        if (!log) {
            return res.status(404).json({ error: "Workout log not found." });
        }

        // Update duration
        log.duration = parseInt(duration, 10);
        await log.save();

        res.json({
            ...log.toJSON(),
            workout_name: workout_name.trim(),
            date
        });
    } catch (err) {
        console.error("Error updating workout log:", err);
        res.status(500).json({ error: "Failed to update workout log." });
    }
});

// Delete a workout log - check if user can modify this log
router.delete("/", authenticateToken, async (req, res) => {
    try {
        const { member_id, member_name, workout_name, date, program_id } = req.body;

        console.log("Delete request received:", { member_id, member_name, workout_name, date });

        if (!workout_name || !date) {
            return res.status(400).json({ error: "Workout name and date are required." });
        }
        if (!program_id) {
            return res.status(400).json({ error: "program_id is required." });
        }

        // Build the where condition
        const programWorkout = await ProgramWorkout.findOne({
            where: { program_id, workout_name: workout_name.trim() }
        });
        if (!programWorkout) {
            return res.status(404).json({ error: "Workout type not found for program." });
        }

        const whereCondition = {
            program_id,
            program_workout_id: programWorkout.id,
            log_date: date
        };

        // If member_id is provided directly, use it
        if (member_id) {
            whereCondition.member_id = member_id;
        }
        // Otherwise try to find the member by name
        else if (member_name) {
            // Only admins can delete other members' logs by name
            if (req.user.role !== 'admin' && req.user.member_name !== member_name) {
                return res.status(403).json({ error: "You can only delete your own logs." });
            }

            const member = await Member.findOne({
                where: { member_name }
            });

            if (!member) {
                return res.status(404).json({ error: "Member not found." });
            }

            whereCondition.member_id = member.id;
        }
        // If neither is provided, use the current user's ID
        else {
            whereCondition.member_id = req.user.id;
        }

        console.log("Final where condition:", whereCondition);

        // Find the log
        const log = await WorkoutLog.findOne({
            where: whereCondition
        });

        if (!log) {
            return res.status(404).json({ error: "Workout log not found." });
        }

        // Check if user has permission to delete this log
        if (req.user.role !== 'admin' && log.member_id !== req.user.id) {
            return res.status(403).json({ error: "You can only delete your own logs." });
        }

        // Delete the log
        await log.destroy();

        res.json({ message: "Workout log deleted successfully." });
    } catch (err) {
        console.error("Error deleting workout log:", err);
        res.status(500).json({ error: "Failed to delete workout log." });
    }
});

// Get all workout logs for a specific member
router.get("/member/:memberName", authenticateToken, async (req, res) => {
    try {
        const { memberName } = req.params;

        // Get member ID from member name
        const member = await Member.findOne({
            where: { member_name: memberName }
        });

        if (!member) {
            return res.status(404).json({ error: "Member not found." });
        }

        // Check if user has permission to view these logs
        if (req.user.role !== 'admin' && req.user.id !== member.id) {
            return res.status(403).json({ error: "You can only view your own logs." });
        }

        // Get all logs for this member
        const logs = await WorkoutLog.findAll({
            where: {
                member_id: member.id
            },
            include: [{
                model: ProgramWorkout,
                attributes: ["workout_name"]
            }],
            order: [["log_date", "DESC"]] // Sort by date in descending order
        });

        // Format logs to include member_name for consistency with frontend
        const formattedLogs = logs.map(log => ({
            ...log.toJSON(),
            member_name: memberName,
            workout_name: log.ProgramWorkout ? log.ProgramWorkout.workout_name : null,
            date: log.log_date
        }));

        res.json(formattedLogs);
    } catch (err) {
        console.error("Error fetching member workout logs:", err);
        res.status(500).json({ error: "Failed to fetch workout logs." });
    }
});

module.exports = router;
