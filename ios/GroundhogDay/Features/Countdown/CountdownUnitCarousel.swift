import SwiftUI

struct CountdownUnitCarousel: View {
    let units: [CountdownUnit]
    @Binding var selectedUnitIndex: Int
    let tileAreaHeight: CGFloat
    let screenHeight: CGFloat
    let value: (CountdownUnit) -> Int
    let isSettled: (Int) -> Bool
    let isSpinning: (Int) -> Bool
    let isMuted: (Int) -> Bool
    let reduceMotion: Bool

    @State private var scrollPosition: Int?
    @State private var isRecenteringScroll = false

    private let repetitionCount = 5

    private var totalItemCount: Int {
        units.count * repetitionCount
    }

    private var middleBlockStart: Int {
        units.count * (repetitionCount / 2)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(0 ..< totalItemCount, id: \.self) { index in
                        let unitIndex = index % units.count
                        carouselPage(
                            unit: units[unitIndex],
                            unitIndex: unitIndex,
                            width: proxy.size.width
                        )
                        .frame(width: proxy.size.width)
                        .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition(id: $scrollPosition)
            .onAppear {
                guard scrollPosition == nil else { return }
                scrollPosition = middleBlockStart + selectedUnitIndex
            }
            .onChange(of: scrollPosition) { _, newPosition in
                handleScrollPositionChange(newPosition)
            }
            .onChange(of: selectedUnitIndex) { _, newIndex in
                syncScrollToUnit(newIndex, animated: true)
            }
        }
        .frame(height: tileAreaHeight)
    }

    private func carouselPage(unit: CountdownUnit, unitIndex: Int, width: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            CountdownUnitRowView(
                unit: unit,
                value: value(unit),
                isSettled: isSettled(unitIndex),
                isSpinning: isSpinning(unitIndex),
                isMuted: isMuted(unitIndex),
                reduceMotion: reduceMotion,
                style: .carousel,
                containerWidth: width,
                screenHeight: screenHeight
            )
            Spacer(minLength: 0)
        }
        .frame(width: width, height: tileAreaHeight)
    }

    private func handleScrollPositionChange(_ newPosition: Int?) {
        guard let newPosition, !isRecenteringScroll else { return }

        let unitIndex = normalizedUnitIndex(newPosition)
        if selectedUnitIndex != unitIndex {
            selectedUnitIndex = unitIndex
        }
        recenterIfNeeded(newPosition)
    }

    private func syncScrollToUnit(_ unitIndex: Int, animated: Bool) {
        let target = middleBlockStart + unitIndex
        guard scrollPosition != target else { return }

        if animated {
            scrollPosition = target
            return
        }

        isRecenteringScroll = true
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            scrollPosition = target
        }
        finishRecenteringScroll()
    }

    private func recenterIfNeeded(_ position: Int) {
        let blockSize = units.count
        let lastBlockStart = blockSize * (repetitionCount - 1)
        guard position < blockSize || position >= lastBlockStart else { return }

        let recentered = position < blockSize ? position + middleBlockStart : position - middleBlockStart
        isRecenteringScroll = true
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            scrollPosition = recentered
        }
        finishRecenteringScroll()
    }

    private func finishRecenteringScroll() {
        Task { @MainActor in
            isRecenteringScroll = false
        }
    }

    private func normalizedUnitIndex(_ position: Int) -> Int {
        let blockSize = units.count
        let remainder = position % blockSize
        return remainder >= 0 ? remainder : remainder + blockSize
    }
}
