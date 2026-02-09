const express = require("express");
const jwt = require("jsonwebtoken");
const { Notification, NotificationRecipient } = require("../models");
const { authenticateToken } = require("../middleware/auth");
const { registerNotificationStream, removeNotificationStream } = require("../utils/notificationStreams");

const router = express.Router();

const authenticateStream = (req, res, next) => {
    const authHeader = req.headers["authorization"];
    const headerToken = authHeader && authHeader.split(" ")[1];
    const queryToken = req.query?.token;
    const token = headerToken || queryToken;

    if (!token) {
        return res.status(401).json({ error: "Access denied. No token provided." });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
        return next();
    } catch (error) {
        return res.status(401).json({ error: "Invalid token." });
    }
};

// GET /notifications/unacknowledged : fetch queued notifications for the user
router.get("/unacknowledged", authenticateToken, async (req, res) => {
    try {
        const memberId = req.user.id;
        const recipients = await NotificationRecipient.findAll({
            where: {
                member_id: memberId,
                acknowledged_at: null
            },
            include: [
                {
                    model: Notification,
                    attributes: ["id", "type", "program_id", "actor_member_id", "title", "body", "created_at"]
                }
            ],
            order: [[Notification, "created_at", "ASC"]]
        });

        const result = recipients
            .filter((recipient) => recipient.Notification)
            .map((recipient) => ({
                id: recipient.Notification.id,
                type: recipient.Notification.type,
                program_id: recipient.Notification.program_id,
                actor_member_id: recipient.Notification.actor_member_id,
                title: recipient.Notification.title,
                body: recipient.Notification.body,
                created_at: recipient.Notification.created_at
            }));

        res.json(result);
    } catch (error) {
        console.error("Error fetching notifications:", error);
        res.status(500).json({ error: "Failed to fetch notifications." });
    }
});

// POST /notifications/:id/acknowledge : acknowledge a notification
router.post("/:id/acknowledge", authenticateToken, async (req, res) => {
    try {
        const memberId = req.user.id;
        const notificationId = req.params.id;

        const recipient = await NotificationRecipient.findOne({
            where: {
                notification_id: notificationId,
                member_id: memberId,
                acknowledged_at: null
            }
        });

        if (!recipient) {
            return res.status(404).json({ error: "Notification not found." });
        }

        await recipient.update({ acknowledged_at: new Date() });

        res.json({ message: "Notification acknowledged." });
    } catch (error) {
        console.error("Error acknowledging notification:", error);
        res.status(500).json({ error: "Failed to acknowledge notification." });
    }
});

// GET /notifications/stream : SSE stream for real-time notifications (in-app only)
router.get("/stream", authenticateStream, (req, res) => {
    const memberId = req.user.id;

    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");
    res.flushHeaders?.();

    res.write(`event: ready\ndata: {}\n\n`);
    registerNotificationStream(memberId, res);

    const pingInterval = setInterval(() => {
        res.write(`event: ping\ndata: {}\n\n`);
    }, 25000);

    req.on("close", () => {
        clearInterval(pingInterval);
        removeNotificationStream(memberId, res);
    });
});

module.exports = router;
