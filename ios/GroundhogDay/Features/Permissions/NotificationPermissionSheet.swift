import SwiftUI

struct NotificationPermissionSheet: View {
    let scheduler: NotificationScheduler
    @Binding var isPresented: Bool
    var onCompleted: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            lampBackground
            VStack(spacing: 0) {
                header
                    .padding(.bottom, 20)
                benefitsCard
                    .padding(.bottom, 24)
                actions
            }
            .padding(.horizontal, 24)
            .padding(.top, 168)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(440)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground {
            lampBackground
        }
    }

    private var lampBackground: some View {
        BlurredHeroBackground(imageName: "NotificationLamp", imageHeight: 300)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(String(localized: "permission.notifications.title"))
                .font(.title3.weight(.bold))
                .foregroundStyle(FlipClockTheme.primaryText)
                .multilineTextAlignment(.center)
            Text(String(localized: "permission.notifications.body"))
                .font(.subheadline)
                .foregroundStyle(FlipClockTheme.label)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            benefitRow(icon: "sunrise.fill", textKey: "permission.benefit.morning")
            benefitRow(icon: "flag.checkered", textKey: "permission.benefit.arrival")
            benefitRow(icon: "gearshape.fill", textKey: "permission.benefit.settings")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(FlipClockTheme.tileBorder.opacity(0.5), lineWidth: 0.5)
        )
    }

    private func benefitRow(icon: String, textKey: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(FlipClockTheme.accent)
                .frame(width: 24, alignment: .center)
            Text(String(localized: String.LocalizationValue(textKey)))
                .font(.subheadline)
                .foregroundStyle(FlipClockTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    AppLog.lifecycle.info("User requested notification permission")
                    let granted = await scheduler.requestAuthorization()
                    AppLog.lifecycle.info("Notification permission result: \(granted, privacy: .public)")
                    if granted {
                        await scheduler.rescheduleAll()
                    }
                    isPresented = false
                    onCompleted()
                }
            } label: {
                Text(String(localized: "permission.enable"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(FlipClockTheme.onAccent)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(FlipClockTheme.accent)
                    )
            }
            Button {
                AppLog.lifecycle.info("User deferred notification permission")
                isPresented = false
                onCompleted()
            } label: {
                Text(String(localized: "permission.notNow"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FlipClockTheme.label)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
    }
}
