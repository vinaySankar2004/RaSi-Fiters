const { Op } = require("sequelize");
const { Workout, ProgramWorkout, Program, ProgramMembership, WorkoutLog } = require("../models");
const { AppError } = require("../utils/response");

// ── Global Workout Library ──

async function getAllWorkouts() {
    return Workout.findAll({ order: [["workout_name", "ASC"]] });
}

async function createWorkout(workout_name) {
    if (!workout_name) throw new AppError(400, "Workout name is required.");
    return Workout.create({ workout_name });
}

async function updateWorkout(currentName, newName) {
    const workout = await Workout.findOne({ where: { workout_name: currentName } });
    if (!workout) throw new AppError(404, "Workout not found.");
    await workout.update({ workout_name: newName });
    return { message: "Workout updated successfully." };
}

async function deleteWorkout(workoutName) {
    const workout = await Workout.findOne({ where: { workout_name: workoutName } });
    if (!workout) throw new AppError(404, "Workout not found.");
    await workout.destroy();
    return { message: "Workout deleted successfully." };
}

// ── Program Workouts ──

async function getProgramWorkouts(programId) {
    if (!programId) throw new AppError(400, "programId is required");

    const program = await Program.findOne({ where: { id: programId, is_deleted: false } });
    if (!program) throw new AppError(404, "Program not found");

    const globalWorkouts = await Workout.findAll({ order: [["workout_name", "ASC"]] });
    const programWorkouts = await ProgramWorkout.findAll({ where: { program_id: programId } });

    const programWorkoutMap = new Map();
    programWorkouts.forEach(pw => {
        if (pw.library_workout_id) programWorkoutMap.set(pw.library_workout_id, pw);
    });

    const result = [];

    for (const gw of globalWorkouts) {
        const pw = programWorkoutMap.get(gw.id);
        result.push({
            id: pw?.id || gw.id,
            workout_name: gw.workout_name,
            source: "global",
            is_hidden: pw?.is_hidden || false,
            library_workout_id: gw.id
        });
    }

    const customWorkouts = programWorkouts.filter(pw => !pw.library_workout_id);
    for (const cw of customWorkouts) {
        result.push({
            id: cw.id,
            workout_name: cw.workout_name,
            source: "custom",
            is_hidden: !!cw.is_hidden,
            library_workout_id: null
        });
    }

    result.sort((a, b) => a.workout_name.localeCompare(b.workout_name));
    return result;
}

async function toggleGlobalWorkoutVisibility({ program_id, library_workout_id }, requester) {
    if (!program_id || !library_workout_id) {
        throw new AppError(400, "program_id and library_workout_id are required.");
    }

    if (requester?.global_role !== "global_admin") {
        const pm = await ProgramMembership.findOne({
            where: { program_id, member_id: requester?.id, role: "admin", status: "active" }
        });
        if (!pm) throw new AppError(403, "Admin privileges required.");
    }

    const libraryWorkout = await Workout.findByPk(library_workout_id);
    if (!libraryWorkout) throw new AppError(404, "Workout not found in library.");

    let programWorkout = await ProgramWorkout.findOne({ where: { program_id, library_workout_id } });

    if (programWorkout) {
        await programWorkout.update({ is_hidden: !programWorkout.is_hidden });
    } else {
        programWorkout = await ProgramWorkout.create({
            program_id, library_workout_id,
            workout_name: libraryWorkout.workout_name,
            is_hidden: true
        });
    }

    return {
        id: programWorkout.id,
        workout_name: programWorkout.workout_name,
        source: "global",
        is_hidden: programWorkout.is_hidden,
        library_workout_id: programWorkout.library_workout_id,
        message: programWorkout.is_hidden ? "Workout hidden from program." : "Workout visible in program."
    };
}

async function toggleCustomWorkoutVisibility(workoutId, requester) {
    const programWorkout = await ProgramWorkout.findByPk(workoutId);
    if (!programWorkout) throw new AppError(404, "Workout not found.");
    if (programWorkout.library_workout_id) {
        throw new AppError(400, "Use the global toggle-visibility endpoint for global workouts.");
    }

    if (requester?.global_role !== "global_admin") {
        const pm = await ProgramMembership.findOne({
            where: { program_id: programWorkout.program_id, member_id: requester?.id, role: "admin", status: "active" }
        });
        if (!pm) throw new AppError(403, "Admin privileges required.");
    }

    await programWorkout.update({ is_hidden: !programWorkout.is_hidden });

    return {
        id: programWorkout.id,
        workout_name: programWorkout.workout_name,
        source: "custom",
        is_hidden: programWorkout.is_hidden,
        library_workout_id: null,
        message: programWorkout.is_hidden ? "Custom workout hidden from program." : "Custom workout visible in program."
    };
}

async function addCustomWorkout({ program_id, workout_name }, requester) {
    if (!program_id || !workout_name) {
        throw new AppError(400, "program_id and workout_name are required.");
    }

    if (requester?.global_role !== "global_admin") {
        const pm = await ProgramMembership.findOne({
            where: { program_id, member_id: requester?.id, role: "admin", status: "active" }
        });
        if (!pm) throw new AppError(403, "Admin privileges required.");
    }

    const existing = await ProgramWorkout.findOne({ where: { program_id, workout_name } });
    if (existing) throw new AppError(400, "A workout with this name already exists in the program.");

    const globalConflict = await Workout.findOne({ where: { workout_name } });
    if (globalConflict) throw new AppError(400, "A global workout with this name already exists.");

    const customWorkout = await ProgramWorkout.create({
        program_id,
        library_workout_id: null,
        workout_name,
        is_hidden: false
    });

    return {
        id: customWorkout.id,
        workout_name: customWorkout.workout_name,
        source: "custom",
        is_hidden: false,
        library_workout_id: null,
        message: "Custom workout created successfully."
    };
}

async function editCustomWorkout(workoutId, workout_name, requester) {
    if (!workout_name) throw new AppError(400, "workout_name is required.");

    const programWorkout = await ProgramWorkout.findByPk(workoutId);
    if (!programWorkout) throw new AppError(404, "Workout not found.");
    if (programWorkout.library_workout_id) {
        throw new AppError(400, "Cannot edit a global workout. Use toggle-visibility to hide it instead.");
    }

    if (requester?.global_role !== "global_admin") {
        const pm = await ProgramMembership.findOne({
            where: { program_id: programWorkout.program_id, member_id: requester?.id, role: "admin", status: "active" }
        });
        if (!pm) throw new AppError(403, "Admin privileges required.");
    }

    const existing = await ProgramWorkout.findOne({
        where: { program_id: programWorkout.program_id, workout_name, id: { [Op.ne]: workoutId } }
    });
    if (existing) throw new AppError(400, "A workout with this name already exists in the program.");

    const globalConflict = await Workout.findOne({ where: { workout_name } });
    if (globalConflict) throw new AppError(400, "A global workout with this name already exists.");

    await programWorkout.update({ workout_name });

    return {
        id: programWorkout.id,
        workout_name: programWorkout.workout_name,
        source: "custom",
        is_hidden: false,
        library_workout_id: null,
        message: "Custom workout updated successfully."
    };
}

async function deleteCustomWorkout(workoutId, requester) {
    const programWorkout = await ProgramWorkout.findByPk(workoutId);
    if (!programWorkout) throw new AppError(404, "Workout not found.");
    if (programWorkout.library_workout_id) {
        throw new AppError(400, "Cannot delete a global workout. Use toggle-visibility to hide it instead.");
    }

    if (requester?.global_role !== "global_admin") {
        const pm = await ProgramMembership.findOne({
            where: { program_id: programWorkout.program_id, member_id: requester?.id, role: "admin", status: "active" }
        });
        if (!pm) throw new AppError(403, "Admin privileges required.");
    }

    const logCount = await WorkoutLog.count({ where: { program_workout_id: workoutId } });
    if (logCount > 0) {
        throw new AppError(400, `Cannot delete this workout. It has ${logCount} workout log${logCount === 1 ? '' : 's'} associated with it. Consider hiding it instead.`);
    }

    await programWorkout.destroy();
    return { message: "Custom workout deleted successfully." };
}

module.exports = {
    getAllWorkouts,
    createWorkout,
    updateWorkout,
    deleteWorkout,
    getProgramWorkouts,
    toggleGlobalWorkoutVisibility,
    toggleCustomWorkoutVisibility,
    addCustomWorkout,
    editCustomWorkout,
    deleteCustomWorkout
};
