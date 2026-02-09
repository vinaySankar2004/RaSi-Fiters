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
        }
        .environmentObject(programContext)
        .task {
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
    }
}

#Preview {
    AppRootView()
}
