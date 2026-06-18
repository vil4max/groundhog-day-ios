import SwiftUI

struct FlipDigitView: View {
    @Environment(\.countdownTileMetrics) private var metrics

    let digit: Int
    let isSpinning: Bool
    let reduceMotion: Bool

    @State private var settledDigit: Int
    @State private var isFlipping = false
    @State private var flipFromDigit = 0
    @State private var flipToDigit = 0
    @State private var flipProgress: Double = 0
    @State private var flipGeneration = 0
    @State private var flipCompletionTask: Task<Void, Never>?
    @State private var spinTask: Task<Void, Never>?

    init(digit: Int, isSpinning: Bool, reduceMotion: Bool) {
        self.digit = digit
        self.isSpinning = isSpinning
        self.reduceMotion = reduceMotion
        _settledDigit = State(initialValue: digit)
    }

    var body: some View {
        ZStack {
            tileShell
            if isFlipping {
                splitFlapContent
            } else {
                settledDigitContent
            }
        }
        .frame(width: metrics.tileSize.width, height: metrics.tileSize.height)
        .onChange(of: isSpinning) { _, spinning in
            if spinning {
                startSpinning()
            } else {
                stopSpinning(show: digit)
            }
        }
        .onChange(of: digit) { _, newValue in
            guard !isSpinning else { return }
            guard newValue != settledDigit || isFlipping else { return }
            animateChange(from: settledDigit, to: newValue)
        }
        .onAppear {
            syncToDisplayedDigit(spinning: isSpinning)
        }
        .onDisappear {
            spinTask?.cancel()
            spinTask = nil
            flipCompletionTask?.cancel()
            flipCompletionTask = nil
            snapToDigit(digit)
        }
    }

    private func syncToDisplayedDigit(spinning: Bool) {
        flipCompletionTask?.cancel()
        flipCompletionTask = nil
        spinTask?.cancel()
        spinTask = nil
        snapToDigit(digit)
        if spinning {
            startSpinning()
        }
    }

    private func snapToDigit(_ value: Int) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            settledDigit = value
            isFlipping = false
            flipProgress = 0
        }
    }

    private func snapMidFlipIfNeeded() {
        guard isFlipping else { return }
        snapToDigit(flipProgress >= 0.5 ? flipToDigit : flipFromDigit)
    }

    private var tileShell: some View {
        RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
            .fill(FlipClockTheme.displayPanel)
            .overlay {
                RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                    .strokeBorder(FlipClockTheme.tileBorder, lineWidth: 0.5)
            }
    }

    private var settledDigitContent: some View {
        ZStack {
            Text("\(settledDigit)")
                .font(metrics.digitFont)
                .monospacedDigit()
                .foregroundStyle(FlipClockTheme.digit)
            Rectangle()
                .fill(FlipClockTheme.tileSplit.opacity(0.65))
                .frame(height: 1)
        }
    }

    private var splitFlapContent: some View {
        ZStack {
            VStack(spacing: 0) {
                topSection
                bottomSection
            }
            .clipShape(RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous))
            Rectangle()
                .fill(FlipClockTheme.tileSplit)
                .frame(height: 1)
        }
    }

    private var topSection: some View {
        ZStack {
            FlipDigitHalfLayer(digit: flipToDigit, position: .top, metrics: metrics)
            FlipDigitHalfLayer(digit: flipFromDigit, position: .top, metrics: metrics, isFlap: true)
                .rotation3DEffect(
                    .degrees(topFlapAngle),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: 0.5
                )
                .opacity(topFlapAngle > -90 ? 1 : 0)
        }
        .frame(height: metrics.tileSize.height / 2)
        .clipped()
    }

    private var bottomSection: some View {
        ZStack {
            FlipDigitHalfLayer(digit: flipFromDigit, position: .bottom, metrics: metrics)
            FlipDigitHalfLayer(digit: flipToDigit, position: .bottom, metrics: metrics, isFlap: true)
                .rotation3DEffect(
                    .degrees(bottomFlapAngle),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .top,
                    perspective: 0.5
                )
                .opacity(bottomFlapAngle > 90 ? 0 : 1)
        }
        .frame(height: metrics.tileSize.height / 2)
        .clipped()
    }

    private var topFlapAngle: Double {
        -90 * min(1, flipProgress / 0.52)
    }

    private var bottomFlapAngle: Double {
        let riseProgress = min(1, max(0, (flipProgress - 0.36) / 0.64))
        return 180 - 180 * riseProgress
    }

    private func startSpinning() {
        spinTask?.cancel()
        spinTask = Task {
            while !Task.isCancelled {
                let next = Int.random(in: 0 ... 9)
                await MainActor.run {
                    animateChange(from: settledDigit, to: next, duration: 0.16)
                }
                try? await Task.sleep(for: .milliseconds(80))
            }
        }
    }

    private func stopSpinning(show value: Int) {
        spinTask?.cancel()
        spinTask = nil
        animateChange(from: settledDigit, to: value)
    }

    private func animateChange(
        from oldValue: Int,
        to newValue: Int,
        duration: TimeInterval = 0.30
    ) {
        guard oldValue != newValue else { return }

        flipCompletionTask?.cancel()
        snapMidFlipIfNeeded()

        if reduceMotion {
            settledDigit = newValue
            isFlipping = false
            flipProgress = 0
            return
        }

        flipGeneration += 1
        let generation = flipGeneration

        flipFromDigit = oldValue
        flipToDigit = newValue
        isFlipping = true
        flipProgress = 0

        withAnimation(.easeInOut(duration: duration)) {
            flipProgress = 1
        }

        flipCompletionTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled, generation == flipGeneration else { return }
            await MainActor.run {
                settledDigit = newValue
                isFlipping = false
                flipProgress = 0
            }
        }
    }
}

private struct FlipDigitHalfLayer: View {
    enum Position {
        case top
        case bottom
    }

    let digit: Int
    let position: Position
    let metrics: CountdownTileMetrics
    var isFlap: Bool = false

    var body: some View {
        ZStack {
            if isFlap {
                FlipClockTheme.displayPanel
            }
            digitText
        }
        .frame(width: metrics.tileSize.width, height: metrics.tileSize.height / 2)
        .shadow(
            color: isFlap ? Color.black.opacity(0.2) : .clear,
            radius: isFlap ? 2 : 0,
            y: position == .top ? 1 : -1
        )
    }

    private var digitText: some View {
        Text("\(digit)")
            .font(metrics.digitFont)
            .monospacedDigit()
            .foregroundStyle(FlipClockTheme.digit)
            .frame(
                width: metrics.tileSize.width,
                height: metrics.tileSize.height,
                alignment: position == .top ? .top : .bottom
            )
            .frame(height: metrics.tileSize.height / 2)
            .clipped()
    }
}
