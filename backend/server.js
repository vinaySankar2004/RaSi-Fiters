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

// Sunset block: the legacy iOS app is being retired. Block NEW INPUTS from it (it writes
// to this old DB) so the migrated Supabase data stays authoritative. Reads + session auth
// (login/refresh/logout) stay alive so users can still browse. 426 (Upgrade Required)
// surfaces the message verbatim in the iOS alert; 401/403 must be avoided here (the app
// treats those as auth failure and signs the user out).
// ON by default — set MAINTENANCE_MODE=false in the environment to re-enable writes.
app.use((req, res, next) => {
    if (process.env.MAINTENANCE_MODE === "false") return next();
    const isMutation = ["POST", "PUT", "DELETE", "PATCH"].includes(req.method);
    const isSessionAuth = /^\/api\/auth\/(login(\/(app|global))?|refresh|logout)$/.test(req.path);
    if (isMutation && !isSessionAuth) {
        return res.status(426).json({
            error: "RaSi Fiters has moved to the web. Please use rasifiters.com to add new entries — the new mobile app is coming very soon."
        });
    }
    next();
});

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
