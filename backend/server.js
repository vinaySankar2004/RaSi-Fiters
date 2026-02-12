const express = require("express");
const cors = require("cors");
const { connectDB } = require("./config/database");
require("./models/index");
const authRoutes = require("./routes/auth");
const memberRoutes = require("./routes/members");
const programMembershipRoutes = require("./routes/programMemberships");
const memberMetricsRoutes = require("./routes/memberMetrics");
const memberHistoryRoutes = require("./routes/memberHistory");
const memberStreaksRoutes = require("./routes/memberStreaks");
const memberRecentRoutes = require("./routes/memberRecent");
const workoutRoutes = require("./routes/workouts");
const programWorkoutRoutes = require("./routes/programWorkouts");
const workoutLogRoutes = require("./routes/workoutLogs");
const analyticsRoutes = require("./routes/analytics");
const analyticsV2Routes = require("./routes/analyticsV2");
const dailyHealthLogRoutes = require("./routes/dailyHealthLogs");
const programRoutes = require("./routes/programs");
const notificationRoutes = require("./routes/notifications");
require("dotenv").config();

const app = express();

app.use(cors({
    origin: ["http://localhost:3000", "https://rasifiters.netlify.app"],
    credentials: true
}));

app.get("/", (req, res) => {
    res.send("Rasi Fiters API is running!");
});

app.use(express.json());

// Minimal app config for client version checks
app.get("/api/app-config", (req, res) => {
    res.json({
        min_ios_version: process.env.MIN_IOS_VERSION || null
    });
});

// Register Routes
app.use("/api/auth", authRoutes);
app.use("/api/members", memberRoutes);
app.use("/api/program-memberships", programMembershipRoutes);
app.use("/api/member-metrics", memberMetricsRoutes);
app.use("/api/member-history", memberHistoryRoutes);
app.use("/api/member-streaks", memberStreaksRoutes);
app.use("/api/member-recent", memberRecentRoutes);
app.use("/api/workouts", workoutRoutes);
app.use("/api/program-workouts", programWorkoutRoutes);
app.use("/api/workout-logs", workoutLogRoutes);
app.use("/api/daily-health-logs", dailyHealthLogRoutes);
app.use("/api/analytics", analyticsRoutes);
app.use("/api/analytics-v2", analyticsV2Routes);
app.use("/api/programs", programRoutes);
app.use("/api/notifications", notificationRoutes);

// for testing purposes
app.get("/api/test", (req, res) => {
    res.json({
        message: "API is working!",
        version: "2.0.0", // Updated version to reflect the database restructuring
        dbSchema: "Consolidated"
    });
});

const PORT = process.env.PORT || 5001;

const startServer = async () => {
    try {
        await connectDB();
        console.log("Database connected successfully");

        app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
    } catch (error) {
        console.error("Failed to start server:", error);
        process.exit(1);
    }
};

startServer();
