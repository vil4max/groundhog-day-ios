import SwiftUI

struct EventDatePickerView: View {
    @Bindable var storage: EventDateStorage
    let feedback: FeedbackService
    let scheduler: NotificationScheduler
    var onCompleted: () -> Void

    @State private var label = ""
    @State private var selectedDate = EventDatePickerView.defaultEventDate()
    @State private var showPastDateAlert = false
    @State private var showTooFarDateAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                calendarCard
                optionalLabel
                startButton
                settingsHint
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(FlipClockTheme.background.ignoresSafeArea())
        .alert(String(localized: "onboarding.dateInPast"), isPresented: $showPastDateAlert) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        }
        .alert(String(localized: "onboarding.dateTooFar"), isPresented: $showTooFarDateAlert) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text(String(localized: "onboarding.headline"))
                .font(.largeTitle.bold())
                .foregroundStyle(FlipClockTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(String(localized: "onboarding.subtitle"))
                .font(.body)
                .foregroundStyle(FlipClockTheme.eventDate)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            DatePicker(
                String(localized: "onboarding.pickDate"),
                selection: $selectedDate,
                in: Date.now...EventDateBounds.latestSelectableDate(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .tint(FlipClockTheme.accent)

            Text(String(localized: "onboarding.dateRangeHint"))
                .font(.footnote)
                .foregroundStyle(FlipClockTheme.labelMuted)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(FlipClockTheme.surface)
        )
    }

    private var optionalLabel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "onboarding.eventLabel"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FlipClockTheme.label)
            TextField(
                String(localized: "onboarding.eventLabel"),
                text: $label,
                prompt: Text(String(localized: "onboarding.eventLabelPlaceholder"))
                    .foregroundStyle(FlipClockTheme.labelMuted)
            )
            .textFieldStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(FlipClockTheme.surface)
            )
            .foregroundStyle(FlipClockTheme.primaryText)
        }
    }

    private var startButton: some View {
        Button {
            startCountdown()
        } label: {
            Text(String(localized: "onboarding.start"))
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(FlipClockTheme.onAccent)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isDateSelectable ? FlipClockTheme.accent : FlipClockTheme.labelMuted)
                )
        }
        .disabled(!isDateSelectable)
    }

    private var settingsHint: some View {
        Text(String(localized: "onboarding.settingsHint"))
            .font(.footnote)
            .foregroundStyle(FlipClockTheme.label)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var isDateSelectable: Bool {
        EventDateBounds.isSelectable(selectedDate)
    }

    private func startCountdown() {
        guard EventDateBounds.isSelectable(selectedDate) else {
            if selectedDate <= .now {
                showPastDateAlert = true
            } else {
                showTooFarDateAlert = true
            }
            feedback.play(.warning)
            return
        }
        storage.save(eventDate: selectedDate, label: label)
        feedback.play(.saved)
        onCompleted()
    }

    static func defaultEventDate() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        return calendar.date(bySettingHour: 6, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
}
