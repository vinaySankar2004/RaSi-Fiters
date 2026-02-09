const streamsByMember = new Map();

const registerNotificationStream = (memberId, res) => {
    if (!streamsByMember.has(memberId)) {
        streamsByMember.set(memberId, new Set());
    }
    streamsByMember.get(memberId).add(res);
};

const removeNotificationStream = (memberId, res) => {
    const streams = streamsByMember.get(memberId);
    if (!streams) return;
    streams.delete(res);
    if (streams.size === 0) {
        streamsByMember.delete(memberId);
    }
};

const sendNotificationToMember = (memberId, payload) => {
    const streams = streamsByMember.get(memberId);
    if (!streams) return;
    const data = `event: notification\ndata: ${JSON.stringify(payload)}\n\n`;
    for (const res of streams) {
        try {
            res.write(data);
        } catch (error) {
            removeNotificationStream(memberId, res);
        }
    }
};

module.exports = {
    registerNotificationStream,
    removeNotificationStream,
    sendNotificationToMember
};
