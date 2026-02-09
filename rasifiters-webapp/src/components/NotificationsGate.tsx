"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { usePathname } from "next/navigation";
import { useAuth } from "@/lib/auth/auth-provider";
import { API_BASE_URL } from "@/lib/config";
import {
  acknowledgeNotification,
  fetchUnacknowledgedNotifications,
  type NotificationItem
} from "@/lib/api/notifications";
import { NotificationModal } from "@/components/NotificationModal";

const sortByCreatedAt = (items: NotificationItem[]) =>
  [...items].sort((a, b) => {
    const aTime = a.created_at ? Date.parse(a.created_at) : 0;
    const bTime = b.created_at ? Date.parse(b.created_at) : 0;
    return aTime - bTime;
  });

export function NotificationsGate() {
  const { session, isBootstrapping } = useAuth();
  const token = session?.token ?? "";
  const pathname = usePathname();
  const [queue, setQueue] = useState<NotificationItem[]>([]);
  const idsRef = useRef(new Set<string>());
  const sourceRef = useRef<EventSource | null>(null);

  const currentNotification = queue[0];
  const isAuthRoute = ["/login", "/create-account", "/splash"].some((route) =>
    pathname?.startsWith(route)
  );
  const shouldRun = !!token && !isBootstrapping && !isAuthRoute;

  const addNotifications = (incoming: NotificationItem[]) => {
    if (incoming.length === 0) return;
    setQueue((prev) => {
      const next = [...prev];
      incoming.forEach((item) => {
        if (idsRef.current.has(item.id)) return;
        idsRef.current.add(item.id);
        next.push(item);
      });
      return sortByCreatedAt(next);
    });
  };

  useEffect(() => {
    if (!shouldRun) {
      setQueue([]);
      idsRef.current.clear();
      return;
    }

    fetchUnacknowledgedNotifications(token)
      .then((items) => addNotifications(items))
      .catch(() => {
        // Silent fail; will retry via stream or next navigation
      });
  }, [token, shouldRun]);

  useEffect(() => {
    if (!shouldRun) {
      if (sourceRef.current) {
        sourceRef.current.close();
        sourceRef.current = null;
      }
      return;
    }

    const streamUrl = `${API_BASE_URL}/notifications/stream?token=${encodeURIComponent(token)}`;
    const eventSource = new EventSource(streamUrl);
    sourceRef.current = eventSource;

    const onNotification = (event: MessageEvent<string>) => {
      try {
        const parsed = JSON.parse(event.data) as NotificationItem;
        if (parsed?.id) {
          addNotifications([parsed]);
        }
      } catch {
        // ignore malformed events
      }
    };

    eventSource.addEventListener("notification", onNotification);
    eventSource.onerror = () => {
      // Let the browser auto-retry; keep existing queue
    };

    return () => {
      eventSource.removeEventListener("notification", onNotification);
      eventSource.close();
      sourceRef.current = null;
    };
  }, [token, shouldRun]);

  const handleAcknowledge = async () => {
    if (!currentNotification || !shouldRun) return;
    const notificationId = currentNotification.id;
    setQueue((prev) => prev.filter((item) => item.id !== notificationId));
    idsRef.current.delete(notificationId);
    try {
      await acknowledgeNotification(token, notificationId);
    } catch {
      // If acknowledge fails, refresh queue on next tick
      fetchUnacknowledgedNotifications(token)
        .then((items) => {
          idsRef.current.clear();
          setQueue(sortByCreatedAt(items));
          items.forEach((item) => idsRef.current.add(item.id));
        })
        .catch(() => {});
    }
  };

  const modalContent = useMemo(() => {
    if (!currentNotification) return null;
    return {
      title: currentNotification.title,
      body: currentNotification.body
    };
  }, [currentNotification]);

  return (
    <NotificationModal
      open={!!modalContent}
      title={modalContent?.title ?? ""}
      body={modalContent?.body ?? ""}
      onConfirm={handleAcknowledge}
    />
  );
}
