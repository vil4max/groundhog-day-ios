import SwiftUI

struct EventDateEditSheet: View {
    @Binding var selectedDate: Date
    let allowsPastDates: Bool
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draftDate: Date
    @State private var showPastDateAlert = false
    @State private var showTooFarDateAlert = false

    init(selectedDate: Binding<Date>, allowsPastDates: Bool, onSave: @escaping () -> Void) {
        _selectedDate = selectedDate
        self.allowsPastDates = allowsPastDates
        self.onSave = onSave
        _draftDate = State(initialValue: selectedDate.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            VStack {
                Group {
                    if allowsPastDates {
                        DatePicker(
                            String(localized: "settings.eventDate"),
                            selection: $draftDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    } else {
                        DatePicker(
                            String(localized: "settings.eventDate"),
                            selection: $draftDate,
                            in: Date.now...EventDateBounds.latestSelectableDate(),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
                .datePickerStyle(.graphical)
                .tint(FlipClockTheme.accent)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(FlipClockTheme.surface)
                        .padding(.horizontal)
                )
                Spacer()
            }
            .background(FlipClockTheme.background.ignoresSafeArea())
            .navigationTitle(String(localized: "settings.eventDate"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save")) {
                        save()
                    }
                }
            }
            .alert(String(localized: "onboarding.dateInPast"), isPresented: $showPastDateAlert) {
                Button(String(localized: "common.ok"), role: .cancel) {}
            }
            .alert(String(localized: "onboarding.dateTooFar"), isPresented: $showTooFarDateAlert) {
                Button(String(localized: "common.ok"), role: .cancel) {}
            }
        }
    }

    private func save() {
        if !allowsPastDates, draftDate <= .now {
            showPastDateAlert = true
            return
        }
        if !allowsPastDates, !EventDateBounds.isSelectable(draftDate) {
            showTooFarDateAlert = true
            return
        }
        selectedDate = draftDate
        onSave()
        dismiss()
    }
}
