import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Bindable var storage: EventDateStorage
    let feedback: FeedbackService
    let scheduler: NotificationScheduler

    @State private var label = ""
    @State private var eventArrivedMessage = ""
    @State private var showDateSheet = false
    @State private var draftDate = Date.now
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(String(localized: "settings.eventSection")) {
                TextField(
                    String(localized: "onboarding.eventLabel"),
                    text: $label,
                    prompt: Text(String(localized: "onboarding.eventLabelPlaceholder"))
                )
                .onChange(of: label) { _, newValue in
                    storage.saveLabel(newValue)
                }
                Button {
                    if let eventDate = storage.eventTargetDate {
                        draftDate = eventDate
                    }
                    showDateSheet = true
                } label: {
                    HStack {
                        Text(String(localized: "settings.eventDate"))
                        Spacer()
                        if let eventDate = storage.eventTargetDate {
                            Text(eventDate, format: .dateTime.day().month().year().hour().minute())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section(String(localized: "settings.displaySection")) {
                Picker(String(localized: "settings.defaultUnit"), selection: defaultUnitBinding) {
                    ForEach(CountdownUnit.allCases, id: \.rawValue) { unit in
                        Text(String(localized: String.LocalizationValue(unit.localizationKey)))
                            .tag(unit)
                    }
                }
            }
            Section {
                Toggle(String(localized: "settings.notifications"), isOn: notificationsBinding)
                    .disabled(authorizationStatus == .denied)
                TextField(
                    String(localized: "settings.eventArrivedMessage"),
                    text: $eventArrivedMessage,
                    prompt: Text(String(localized: "push.eventArrived.bodyGeneric")),
                    axis: .vertical
                )
                .lineLimit(2 ... 4)
                .onChange(of: eventArrivedMessage) { _, newValue in
                    storage.saveEventArrivedMessage(newValue)
                }
                if authorizationStatus == .denied {
                    Button(String(localized: "settings.openSystemSettings")) {
                        openSystemSettings()
                    }
                }
            } footer: {
                Text(String(localized: "settings.notifications.footer"))
            }
        }
        .scrollContentBackground(.hidden)
        .background(FlipClockTheme.background.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            label = storage.eventLabel ?? ""
            eventArrivedMessage = storage.eventArrivedMessage ?? ""
            Task { await refreshAuthorizationStatus() }
        }
        .onDisappear {
            Task { await scheduler.rescheduleAll() }
        }
        .sheet(isPresented: $showDateSheet) {
            EventDateEditSheet(
                selectedDate: $draftDate,
                allowsPastDates: false
            ) {
                storage.save(eventDate: draftDate, label: label)
                storage.requestFullRevealAnimation()
                feedback.play(.saved)
                Task { await scheduler.rescheduleAll() }
            }
        }
    }

    private var defaultUnitBinding: Binding<CountdownUnit> {
        Binding(
            get: { storage.defaultCountdownUnit },
            set: { newValue in
                storage.setDefaultCountdownUnit(newValue)
                feedback.play(.toggle)
            }
        )
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { storage.notificationsEnabled },
            set: { newValue in
                storage.setNotificationsEnabled(newValue)
                feedback.play(.toggle)
                Task { await scheduler.rescheduleAll() }
            }
        )
    }

    private func refreshAuthorizationStatus() async {
        authorizationStatus = await scheduler.authorizationStatus()
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
