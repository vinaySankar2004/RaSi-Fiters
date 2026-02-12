import SwiftUI

struct AppRootView: View {
    @StateObject private var programContext = ProgramContext()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Group {
                if programContext.authToken != nil {
                    // Authenticated: show program picker flow
                    NavigationStack {
                        ProgramPickerView()
                    }
                } else {
                    // Unauthenticated: show splash/login flow
                    NavigationStack {
                        SplashView()
                    }
                }
            }

            if let notification = programContext.notificationQueue.first {
                NotificationModalView(
                    title: notification.title,
                    message: notification.body
                ) {
                    Task { @MainActor in
                        await programContext.acknowledgeNotification(notification)
                    }
                }
            }

            if programContext.isUpdateRequired {
                ForcedUpdateModalView(minimumVersion: programContext.minimumSupportedVersion)
            }
        }
        .environmentObject(programContext)
        .task {
            await programContext.checkMinimumSupportedVersion()
            await programContext.refreshSessionIfNeeded()
            if programContext.authToken != nil {
                await MainActor.run {
                    programContext.startNotificationStreamIfNeeded()
                }
            }
        }
        .onChange(of: programContext.authToken) { _ in
            Task { @MainActor in
                if programContext.authToken != nil {
                    programContext.startNotificationStreamIfNeeded()
                } else {
                    programContext.stopNotificationStream()
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            Task { @MainActor in
                if programContext.authToken != nil {
                    programContext.startNotificationStreamIfNeeded()
                }
            }
        }
        .onOpenURL { url in
            if let route = WidgetRoute(url: url) {
                programContext.widgetRoute = route
            }
        }
        .fullScreenCover(
            item: Binding(
                get: { programContext.authToken != nil ? programContext.widgetRoute : nil },
                set: { programContext.widgetRoute = $0 }
            )
        ) { route in
            switch route {
            case .quickAddWorkout:
                QuickAddWorkoutWidgetEntryView()
                    .environmentObject(programContext)
            case .quickAddHealth:
                QuickAddHealthWidgetEntryView()
                    .environmentObject(programContext)
            }
        }
    }
}

#Preview {
    AppRootView()
}
