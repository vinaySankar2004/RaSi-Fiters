const express = require("express");
const { Workout, ProgramWorkout, Program, ProgramMembership, WorkoutLog } = require("../models");
const { sequelize } = require("../config/database");
const { authenticateToken } = require("../middleware/auth");

const router = express.Router();

// GET /program-workouts?programId=... : Get all workouts for a program (global + custom, with hidden status)
router.get("/", authenticateToken, async (req, res) => {
    try {
        const { programId } = req.query;
        if (!programId) {
            return res.status(400).json({ error: "programId is required" });
        }

        // Verify program exists
        const program = await Program.findOne({
            where: { id: programId, is_deleted: false }
        });
        if (!program) {
            return res.status(404).json({ error: "Program not found" });
        }

        // Get all global workouts from the library
        const globalWorkouts = await Workout.findAll({
            order: [["workout_name", "ASC"]]
        });

        // Get program-specific workouts (both hidden global and custom)
        const programWorkouts = await ProgramWorkout.findAll({
            where: { program_id: programId }
        });

        // Create a map of program workouts by library_workout_id for quick lookup
        const programWorkoutMap = new Map();
        programWorkouts.forEach(pw => {
            if (pw.library_workout_id) {
                programWorkoutMap.set(pw.library_workout_id, pw);
            }
        });

        // Build the result array
        const result = [];

        // Add global workouts with their hidden status
        for (const globalWorkout of globalWorkouts) {
            const programWorkout = programWorkoutMap.get(globalWorkout.id);
            result.push({
                id: programWorkout?.id || globalWorkout.id,
                workout_name: globalWorkout.workout_name,
                source: "global",
                is_hidden: programWorkout?.is_hidden || false,
                library_workout_id: globalWorkout.id
            });
        }

        // Add custom workouts (where library_workout_id is null)
        const customWorkouts = programWorkouts.filter(pw => !pw.library_workout_id);
        for (const customWorkout of customWorkouts) {
            result.push({
                id: customWorkout.id,
                workout_name: customWorkout.workout_name,
                source: "custom",
                is_hidden: !!customWorkout.is_hidden,
                library_workout_id: null
            });
        }

        // Sort by workout_name
        result.sort((a, b) => a.workout_name.localeCompare(b.workout_name));

        res.json(result);
    } catch (err) {
        console.error("Error fetching program workouts:", err);
        res.status(500).json({ error: "Failed to fetch program workouts." });
    }
});

// PUT /program-workouts/toggle-visibility : Toggle hide/unhide for a global workout
router.put("/toggle-visibility", authenticateToken, async (req, res) => {
    try {
        const { program_id, library_workout_id } = req.body;
        const requester = req.user;

        if (!program_id || !library_workout_id) {
            return res.status(400).json({ error: "program_id and library_workout_id are required." });
        }

        // Authorization: global_admin or program admin
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
                return res.status(403).json({ error: "Admin privileges required." });
            }
        }

        // Verify the library workout exists
        const libraryWorkout = await Workout.findByPk(library_workout_id);
        if (!libraryWorkout) {
            return res.status(404).json({ error: "Workout not found in library." });
        }

        // Check if a program_workout row exists for this global workout
        let programWorkout = await ProgramWorkout.findOne({
            where: { program_id, library_workout_id }
        });

        if (programWorkout) {
            // Toggle the is_hidden status
            await programWorkout.update({ is_hidden: !programWorkout.is_hidden });
        } else {
            // Create a new row with is_hidden = true (hiding the global workout)
            programWorkout = await ProgramWorkout.create({
                program_id,
                library_workout_id,
                workout_name: libraryWorkout.workout_name,
                is_hidden: true
            });
        }

        res.json({
            id: programWorkout.id,
            workout_name: programWorkout.workout_name,
            source: "global",
            is_hidden: programWorkout.is_hidden,
            library_workout_id: programWorkout.library_workout_id,
            message: programWorkout.is_hidden ? "Workout hidden from program." : "Workout visible in program."
        });
    } catch (err) {
        console.error("Error toggling workout visibility:", err);
        res.status(500).json({ error: "Failed to toggle workout visibility." });
    }
});

// PUT /program-workouts/:id/toggle-visibility : Toggle hide/unhide for a custom workout (by ID)
router.put("/:id/toggle-visibility", authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const requester = req.user;

        // Find the program workout
        const programWorkout = await ProgramWorkout.findByPk(id);
        if (!programWorkout) {
            return res.status(404).json({ error: "Workout not found." });
        }

        // This endpoint is for custom workouts only
        if (programWorkout.library_workout_id) {
            return res.status(400).json({ error: "Use the global toggle-visibility endpoint for global workouts." });
        }

        // Authorization: global_admin or program admin
        const isGlobalAdmin = requester?.global_role === "global_admin";
        if (!isGlobalAdmin) {
            const pm = await ProgramMembership.findOne({
                where: {
                    program_id: programWorkout.program_id,
                    member_id: requester?.id,
                    role: "admin",
                    status: "active"
                }
            });
            if (!pm) {
                return res.status(403).json({ error: "Admin privileges required." });
            }
        }

        // Toggle the is_hidden status
        await programWorkout.update({ is_hidden: !programWorkout.is_hidden });

        res.json({
            id: programWorkout.id,
            workout_name: programWorkout.workout_name,
            source: "custom",
            is_hidden: programWorkout.is_hidden,
            library_workout_id: null,
            message: programWorkout.is_hidden ? "Custom workout hidden from program." : "Custom workout visible in program."
        });
    } catch (err) {
        console.error("Error toggling custom workout visibility:", err);
        res.status(500).json({ error: "Failed to toggle custom workout visibility." });
    }
});

// POST /program-workouts/custom : Add a custom workout to a program
router.post("/custom", authenticateToken, async (req, res) => {
    try {
        const { program_id, workout_name } = req.body;
        const requester = req.user;

        if (!program_id || !workout_name) {
            return res.status(400).json({ error: "program_id and workout_name are required." });
        }

        // Authorization: global_admin or program admin
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
                return res.status(403).json({ error: "Admin privileges required." });
            }
        }

        // Check if workout name already exists in this program
        const existing = await ProgramWorkout.findOne({
            where: { program_id, workout_name }
        });
        if (existing) {
            return res.status(400).json({ error: "A workout with this name already exists in the program." });
        }

        // Also check if it conflicts with a global workout name
        const globalConflict = await Workout.findOne({
            where: { workout_name }
        });
        if (globalConflict) {
            return res.status(400).json({ error: "A global workout with this name already exists." });
        }

        // Create the custom workout (no library_workout_id)
        const customWorkout = await ProgramWorkout.create({
            program_id,
            library_workout_id: null,
            workout_name,
            is_hidden: false
        });

        res.status(201).json({
            id: customWorkout.id,
            workout_name: customWorkout.workout_name,
            source: "custom",
            is_hidden: false,
            library_workout_id: null,
            message: "Custom workout created successfully."
        });
    } catch (err) {
        console.error("Error creating custom workout:", err);
        res.status(500).json({ error: "Failed to create custom workout." });
    }
});

// PUT /program-workouts/:id : Edit a custom workout
router.put("/:id", authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { workout_name } = req.body;
        const requester = req.user;

        if (!workout_name) {
            return res.status(400).json({ error: "workout_name is required." });
        }

        // Find the program workout
        const programWorkout = await ProgramWorkout.findByPk(id);
        if (!programWorkout) {
            return res.status(404).json({ error: "Workout not found." });
        }

        // Only custom workouts can be edited (no library_workout_id)
        if (programWorkout.library_workout_id) {
            return res.status(400).json({ error: "Cannot edit a global workout. Use toggle-visibility to hide it instead." });
        }

        // Authorization: global_admin or program admin
        const isGlobalAdmin = requester?.global_role === "global_admin";
        if (!isGlobalAdmin) {
            const pm = await ProgramMembership.findOne({
                where: {
                    program_id: programWorkout.program_id,
                    member_id: requester?.id,
                    role: "admin",
                    status: "active"
                }
            });
            if (!pm) {
                return res.status(403).json({ error: "Admin privileges required." });
            }
        }

        // Check if new name conflicts with existing workout in program
        const existing = await ProgramWorkout.findOne({
            where: { 
                program_id: programWorkout.program_id, 
                workout_name,
                id: { [require("sequelize").Op.ne]: id }
            }
        });
        if (existing) {
            return res.status(400).json({ error: "A workout with this name already exists in the program." });
        }

        // Also check global conflicts
        const globalConflict = await Workout.findOne({
            where: { workout_name }
        });
        if (globalConflict) {
            return res.status(400).json({ error: "A global workout with this name already exists." });
        }

        await programWorkout.update({ workout_name });

        res.json({
            id: programWorkout.id,
            workout_name: programWorkout.workout_name,
            source: "custom",
            is_hidden: false,
            library_workout_id: null,
            message: "Custom workout updated successfully."
        });
    } catch (err) {
        console.error("Error updating custom workout:", err);
        res.status(500).json({ error: "Failed to update custom workout." });
    }
});

// DELETE /program-workouts/:id : Delete a custom workout
router.delete("/:id", authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const requester = req.user;

        // Find the program workout
        const programWorkout = await ProgramWorkout.findByPk(id);
        if (!programWorkout) {
            return res.status(404).json({ error: "Workout not found." });
        }

        // Only custom workouts can be deleted (no library_workout_id)
        if (programWorkout.library_workout_id) {
            return res.status(400).json({ error: "Cannot delete a global workout. Use toggle-visibility to hide it instead." });
        }

        // Authorization: global_admin or program admin
        const isGlobalAdmin = requester?.global_role === "global_admin";
        if (!isGlobalAdmin) {
            const pm = await ProgramMembership.findOne({
                where: {
                    program_id: programWorkout.program_id,
                    member_id: requester?.id,
                    role: "admin",
                    status: "active"
                }
            });
            if (!pm) {
                return res.status(403).json({ error: "Admin privileges required." });
            }
        }

        // Check if there are any workout logs associated with this workout
        const logCount = await WorkoutLog.count({
            where: { program_workout_id: id }
        });

        if (logCount > 0) {
            return res.status(400).json({ 
                error: `Cannot delete this workout. It has ${logCount} workout log${logCount === 1 ? '' : 's'} associated with it. Consider hiding it instead.`,
                log_count: logCount
            });
        }

        await programWorkout.destroy();

        res.json({ message: "Custom workout deleted successfully." });
    } catch (err) {
        console.error("Error deleting custom workout:", err);
        res.status(500).json({ error: "Failed to delete custom workout." });
    }
});

module.exports = router;
