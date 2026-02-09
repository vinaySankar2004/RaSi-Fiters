const { Op } = require("sequelize");
const {
    Notification,
    NotificationRecipient,
    ProgramMembership
} = require("../models");
const { sendNotificationToMember } = require("./notificationStreams");

const buildNotificationPayload = (notification) => ({
    id: notification.id,
    type: notification.type,
    program_id: notification.program_id,
    actor_member_id: notification.actor_member_id,
    title: notification.title,
    body: notification.body,
    created_at: notification.created_at
});

const getActiveProgramMemberIds = async (programId, transaction) => {
    const memberships = await ProgramMembership.findAll({
        where: { program_id: programId, status: "active" },
        attributes: ["member_id"],
        transaction
    });
    return memberships.map((membership) => membership.member_id);
};

const createNotification = async ({
    type,
    programId = null,
    actorMemberId = null,
    title,
    body,
    recipientIds,
    transaction
}) => {
    const uniqueRecipients = Array.from(new Set((recipientIds || []).filter(Boolean)));
    if (uniqueRecipients.length === 0) {
        return null;
    }

    const notification = await Notification.create({
        type,
        program_id: programId,
        actor_member_id: actorMemberId,
        title,
        body
    }, { transaction });

    const recipientRows = uniqueRecipients.map((memberId) => ({
        notification_id: notification.id,
        member_id: memberId,
        acknowledged_at: null
    }));

    await NotificationRecipient.bulkCreate(recipientRows, { transaction });

    const payload = buildNotificationPayload(notification);

    const dispatch = () => {
        uniqueRecipients.forEach((memberId) => sendNotificationToMember(memberId, payload));
    };

    if (transaction && typeof transaction.afterCommit === "function") {
        transaction.afterCommit(dispatch);
    } else {
        dispatch();
    }

    return notification;
};

module.exports = {
    buildNotificationPayload,
    getActiveProgramMemberIds,
    createNotification
};
