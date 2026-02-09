import SwiftUI

struct NotificationModalView: View {
    let title: String
    let body: String
    let onAcknowledge: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color(.label))
                    .multilineTextAlignment(.center)

                Text(body)
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)

                Button(action: onAcknowledge) {
                    Text("OK")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appOrange)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }
}

#Preview {
    NotificationModalView(
        title: "Program updated",
        body: "RaSi Winter Reset details were updated.",
        onAcknowledge: {}
    )
}
