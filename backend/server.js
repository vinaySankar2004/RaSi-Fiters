const express = require("express");
const cors = require("cors");
// Load .env then .env.local (local overrides); on Render only env vars are set
require("dotenv").config();
require("dotenv").config({ path: ".env.local", override: true });
const { connectDB } = require("./config/database");
require("./models/index");
const { errorHandler } = require("./middleware/errorHandler");

const authRoutes = require("./routes/auth");
const memberRoutes = require("./routes/members");
const programRoutes = require("./routes/programs");
const membershipRoutes = require("./routes/memberships");
const inviteRoutes = require("./routes/invites");
const workoutRoutes = require("./routes/workouts");
const programWorkoutRoutes = require("./routes/programWorkouts");
const { workoutLogRouter, dailyHealthLogRouter } = require("./routes/logs");
const { v1Router: analyticsV1Routes, v2Router: analyticsV2Routes } = require("./routes/analytics");
const { metricsRouter, historyRouter, streaksRouter, recentRouter } = require("./routes/memberAnalytics");
const notificationRoutes = require("./routes/notifications");

const app = express();

app.use(cors({
    origin: [
        "http://localhost:3000",
        "https://rasi-fiters.vercel.app",
        "https://rasifiters.com",
        "https://www.rasifiters.com"
    ],
    credentials: true
}));

app.get("/", (req, res) => {
    res.send("Rasi Fiters API is running!");
});

app.use(express.json());

app.get("/api/app-config", (req, res) => {
    res.json({
        min_ios_version: process.env.MIN_IOS_VERSION || null
    });
});

app.use("/api/auth", authRoutes);
app.use("/api/members", memberRoutes);
app.use("/api/programs", programRoutes);
app.use("/api/program-memberships", membershipRoutes);
app.use("/api/program-memberships", inviteRoutes);
app.use("/api/workouts", workoutRoutes);
app.use("/api/program-workouts", programWorkoutRoutes);
app.use("/api/workout-logs", workoutLogRouter);
app.use("/api/daily-health-logs", dailyHealthLogRouter);
app.use("/api/analytics", analyticsV1Routes);
app.use("/api/analytics-v2", analyticsV2Routes);
app.use("/api/member-metrics", metricsRouter);
app.use("/api/member-history", historyRouter);
app.use("/api/member-streaks", streaksRouter);
app.use("/api/member-recent", recentRouter);
app.use("/api/notifications", notificationRoutes);

app.get("/api/test", (req, res) => {
    res.json({
        message: "API is working!",
        version: "3.0.0",
        dbSchema: "Consolidated"
    });
});

app.use(errorHandler);

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
