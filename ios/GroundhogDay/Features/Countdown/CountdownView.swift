import SwiftUI

struct CountdownView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var storage: EventDateStorage
    let feedback: FeedbackService
    let scheduler: NotificationScheduler

    @State private var settledRowCount = 0
    @State private var revealTask: Task<Void, Never>?
    @State private var tickTask: Task<Void, Never>?
    @State private var unitValues = Array(repeating: 0, count: CountdownUnit.allCases.count)
    @State private var previousUnitValues = Array(repeating: 0, count: CountdownUnit.allCases.count)
    @State private var titleContextDate = Date.now
    @State private var lastTickEpochSecond: Int?
    @State private var selectedUnitIndex: Int

    private let units = CountdownUnit.allCases
    private let revealCarouselLastIndex = CountdownUnit.days.rawValue

    init(storage: EventDateStorage, feedback: FeedbackService, scheduler: NotificationScheduler) {
        self.storage = storage
        self.feedback = feedback
        self.scheduler = scheduler
        _selectedUnitIndex = State(initialValue: storage.defaultCountdownUnit.rawValue)
    }

    var body: some View {
        GeometryReader { proxy in
            let baselineTileMetrics = FlipClockTheme.tileMetrics(
                forScreenHeight: proxy.size.height,
                containerWidth: proxy.size.width,
                digitCount: 2
            )
            let carouselSlotHeight = baselineTileMetrics.tileSize.height
            let carouselTopPadding = proxy.size.height / 2 - carouselSlotHeight / 2 - 22

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    quoteBand(screenHeight: proxy.size.height)
                    Spacer(minLength: 0)
                    eventDateFooter
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }

                VStack(spacing: 20) {
                    CountdownUnitCarousel(
                        units: units,
                        selectedUnitIndex: $selectedUnitIndex,
                        tileAreaHeight: carouselSlotHeight,
                        screenHeight: proxy.size.height,
                        value: { value(for: $0) },
                        isSettled: isRowSettled,
                        isSpinning: isRowSpinning,
                        isMuted: isRowMuted,
                        reduceMotion: reduceMotion
                    )
                    .frame(height: carouselSlotHeight)

                    carouselFooter
                }
                .frame(width: proxy.size.width)
                .padding(.top, carouselTopPadding)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .environment(\.countdownTileMetrics, baselineTileMetrics)
        }
        .background {
            BlurredHeroBackground(imageName: "LaunchClock")
                .ignoresSafeArea()
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(String(localized: String.LocalizationValue(countdownTitleKey)))
                    .font(FlipClockTheme.quoteTitleFont)
                    .foregroundStyle(FlipClockTheme.primaryText)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .onAppear {
            AppLog.countdown.info("Countdown view appeared")
            refreshAllSlotsOnOpen()
            startRevealAnimation()
        }
        .onDisappear {
            AppLog.countdown.info("Countdown view disappeared")
            revealTask?.cancel()
            tickTask?.cancel()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refreshAllSlotsOnOpen()
        }
        .onChange(of: storage.needsFullRevealAnimation) { _, needsFull in
            if needsFull {
                startRevealAnimation()
            }
        }
        .onChange(of: settledRowCount) { _, _ in
            syncTickLoop()
        }
        .onChange(of: storage.isEventPassed) { _, _ in
            syncTickLoop()
        }
        .onChange(of: storage.defaultCountdownUnit) { _, unit in
            selectedUnitIndex = unit.rawValue
        }
    }

    private var countdownTitleKey: String {
        if storage.isEventPassed {
            return "countdown.title.passed"
        }
        guard let eventDate = storage.eventTargetDate else {
            return "countdown.title"
        }
        if CountdownCalculator.isWithin24Hours(eventDate: eventDate, now: titleContextDate) {
            return "countdown.title.soon"
        }
        return "countdown.title"
    }

    @ViewBuilder
    private func quoteBand(screenHeight: CGFloat) -> some View {
        let quoteText = String(localized: String.LocalizationValue(GroundhogQuotes.sessionLocalizationKey))

        ZStack {
            Text(quotedMovieLine(quoteText))
                .font(FlipClockTheme.quoteBodyFont)
                .foregroundStyle(FlipClockTheme.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity)
        }
        .frame(height: screenHeight * 0.30)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(quoteText)
    }

    private func quotedMovieLine(_ quote: String) -> String {
        "\u{201C}\(quote)\u{201D}"
    }

    private var eventDateFooter: some View {
        Group {
            if storage.isEventPassed {
                settingsLink {
                    eventPassedBanner
                }
            } else if let eventDate = storage.eventTargetDate {
                settingsLink {
                    eventTargetBanner(for: eventDate)
                }
            }
        }
    }

    private func settingsLink<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        NavigationLink {
            SettingsView(storage: storage, feedback: feedback, scheduler: scheduler)
        } label: {
            label()
        }
        .buttonStyle(.plain)
        .accessibilityHint(String(localized: "countdown.openSettings"))
    }

    private var eventPassedBanner: some View {
        Text(String(localized: "event.alreadyHappened"))
            .font(FlipClockTheme.eventBannerLabelFont)
            .foregroundStyle(FlipClockTheme.accent)
            .multilineTextAlignment(.center)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(eventBannerBackground)
    }

    private func eventTargetBanner(for eventDate: Date) -> some View {
        let dateText = eventDate.formatted(.dateTime.day().month(.wide).year())
        let timeText = eventDate.formatted(date: .omitted, time: .shortened)
        let trimmedLabel = storage.eventLabel?.trimmingCharacters(in: .whitespacesAndNewlines)

        return VStack(spacing: 12) {
            Text(String(localized: "countdown.loopBreaksLabel"))
                .font(FlipClockTheme.eventBannerCaptionFont)
                .foregroundStyle(FlipClockTheme.accent)
                .textCase(.uppercase)
                .tracking(1.4)

            HStack(alignment: .center, spacing: 14) {
                bannerRule
                VStack(spacing: 6) {
                    if let trimmedLabel, !trimmedLabel.isEmpty {
                        Text(trimmedLabel)
                            .font(FlipClockTheme.eventBannerLabelFont)
                            .foregroundStyle(FlipClockTheme.label)
                            .multilineTextAlignment(.center)
                    }
                    Text(dateText)
                        .font(FlipClockTheme.eventBannerDateFont)
                        .foregroundStyle(FlipClockTheme.primaryText)
                        .multilineTextAlignment(.center)
                    Text(timeText)
                        .font(FlipClockTheme.eventBannerTimeFont)
                        .foregroundStyle(FlipClockTheme.eventDate)
                }
                .frame(maxWidth: .infinity)
                bannerRule
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(eventBannerBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(eventAccessibilityLabel(dateText: dateText, timeText: timeText))
    }

    private var bannerRule: some View {
        Rectangle()
            .fill(FlipClockTheme.tileBorder)
            .frame(width: 28, height: 1)
    }

    private var eventBannerBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(FlipClockTheme.tileBorder.opacity(0.55), lineWidth: 0.5)
            }
    }

    private func eventAccessibilityLabel(dateText: String, timeText: String) -> String {
        if let label = storage.eventLabel?.trimmingCharacters(in: .whitespacesAndNewlines), !label.isEmpty {
            return String(localized: "countdown.eventNamed \(label) \(dateText) \(timeText)")
        }
        return String(localized: "countdown.eventPlain \(dateText) \(timeText)")
    }

    private var carouselFooter: some View {
        VStack(spacing: 14) {
            selectedUnitLabel
            unitPageIndicator
            Text(String(localized: "countdown.swipeHint"))
                .font(.footnote)
                .foregroundStyle(FlipClockTheme.labelMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var selectedUnitLabel: some View {
        Text(String(localized: String.LocalizationValue(units[selectedUnitIndex].localizationKey)))
            .font(.title2.weight(.medium))
            .foregroundStyle(
                isRowMuted(selectedUnitIndex) ? FlipClockTheme.labelMuted : FlipClockTheme.label
            )
            .opacity(isRowMuted(selectedUnitIndex) ? 0.35 : 1)
            .animation(.easeInOut(duration: 0.2), value: selectedUnitIndex)
    }

    private var unitPageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Array(units.enumerated()), id: \.offset) { index, _ in
                Capsule()
                    .fill(index == selectedUnitIndex ? FlipClockTheme.accent : FlipClockTheme.tileBorder)
                    .frame(width: index == selectedUnitIndex ? 18 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: selectedUnitIndex)
            }
        }
        .accessibilityHidden(true)
    }

    private var tickLoopIsActive: Bool {
        settledRowCount >= units.count && !storage.isEventPassed
    }

    private func value(for unit: CountdownUnit) -> Int {
        unitValues[unit.rawValue]
    }

    private func isRowSettled(_ index: Int) -> Bool {
        index < settledRowCount
    }

    private func isRowSpinning(_ index: Int) -> Bool {
        !isRowSettled(index) && storage.needsFullRevealAnimation && !reduceMotion && !storage.isEventPassed
    }

    private func isRowMuted(_ index: Int) -> Bool {
        guard !storage.isEventPassed else { return false }
        return value(for: units[index]) == 0
    }

    private func refreshAllSlotsOnOpen() {
        titleContextDate = .now
        refreshUnitValues()
        previousUnitValues = unitValues
        lastTickEpochSecond = nil
        syncTickLoop()
    }

    private func refreshUnitValues(at date: Date = .now) {
        guard let eventDate = storage.eventTargetDate else {
            unitValues = Array(repeating: 0, count: units.count)
            return
        }
        if storage.isEventPassed {
            unitValues = Array(repeating: 0, count: units.count)
        } else {
            unitValues = CountdownCalculator.unitValues(from: date, to: eventDate)
        }
    }

    private func syncTickLoop() {
        tickTask?.cancel()
        guard tickLoopIsActive else {
            AppLog.countdown.debug("Tick loop inactive")
            return
        }
        AppLog.countdown.info("Tick loop started")
        tickTask = Task {
            while !Task.isCancelled {
                handleTick(at: .now)
                try? await Task.sleep(for: .seconds(1))
            }
            AppLog.countdown.info("Tick loop stopped")
        }
    }

    private func finishReveal() {
        settledRowCount = units.count
        applyStoredUnitSelection()
        previousUnitValues = unitValues
        syncTickLoop()
    }

    private func startRevealAnimation() {
        revealTask?.cancel()
        refreshUnitValues()
        lastTickEpochSecond = nil

        if storage.isEventPassed {
            settledRowCount = units.count
            applyStoredUnitSelection()
            previousUnitValues = unitValues
            AppLog.countdown.info("Reveal skipped: event already passed")
            return
        }

        guard storage.needsFullRevealAnimation else {
            settledRowCount = units.count
            applyStoredUnitSelection()
            previousUnitValues = unitValues
            syncTickLoop()
            AppLog.countdown.info("Reveal skipped: already shown")
            return
        }

        settledRowCount = 0
        selectedUnitIndex = 0

        if reduceMotion {
            settledRowCount = units.count
            applyStoredUnitSelection()
            storage.markRevealAnimationCompleted()
            previousUnitValues = unitValues
            syncTickLoop()
            AppLog.countdown.info("Reveal skipped: reduce motion")
            return
        }

        AppLog.countdown.info("Reveal animation started")
        revealTask = Task {
            for index in 0 ... revealCarouselLastIndex {
                try? await Task.sleep(for: .milliseconds(280))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    settledRowCount = index + 1
                    selectedUnitIndex = index
                    feedback.play(.rowSettled)
                }
            }
            await MainActor.run {
                storage.markRevealAnimationCompleted()
                feedback.play(.revealCompleted)
                finishReveal()
            }
        }
    }

    private func applyStoredUnitSelection() {
        selectedUnitIndex = storage.defaultCountdownUnit.rawValue
    }

    private func handleTick(at date: Date) {
        let epochSecond = Int(date.timeIntervalSince1970)
        if lastTickEpochSecond == epochSecond {
            return
        }
        lastTickEpochSecond = epochSecond

        guard let eventDate = storage.eventTargetDate, eventDate > date else {
            AppLog.countdown.debug("Tick ignored: event passed or missing")
            tickTask?.cancel()
            return
        }

        titleContextDate = date
        let newValues = CountdownCalculator.unitValues(from: date, to: eventDate)
        if newValues != previousUnitValues {
            AppLog.countdown.debug("Tick at \(epochSecond, privacy: .public)")
        }
        previousUnitValues = newValues
        unitValues = newValues
    }
}
