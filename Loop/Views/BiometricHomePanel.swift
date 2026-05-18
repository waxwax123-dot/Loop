//
//  BiometricHomePanel.swift
//  Loop
//

import SwiftUI

struct BiometricHomePanel: View {
    private let irService: AppleHealthIRServiceProtocol
    private let biometricsService: BiometricsServiceProtocol

    @State private var selectedTile: BiometricTileType?
    @State private var latestSnapshot: BiometricSnapshot?
    @State private var currentMultiplier: Double = 1.0

    init(irService: AppleHealthIRServiceProtocol, biometricsService: BiometricsServiceProtocol) {
        self.irService = irService
        self.biometricsService = biometricsService
    }

    var body: some View {
        VStack(spacing: 0) {
            panelHeader
            Divider()
            metricList
        }
        .background(LoopDS.Colors.surface)
        .cornerRadius(LoopDS.Radius.card)
        .padding(.horizontal, LoopDS.Spacing.md)
        .padding(.vertical, LoopDS.Spacing.sm)
        .onReceive(biometricsService.snapshotPublisher.receive(on: DispatchQueue.main)) { latestSnapshot = $0 }
        .onReceive(irService.multiplierPublisher.receive(on: DispatchQueue.main)) { currentMultiplier = $0 }
        .sheet(item: $selectedTile) { tile in
            BiometricIRDetailView(
                tileType: tile,
                entry: irService.latestEntry,
                allEntries: AppleHealthIREntry.load()
            )
        }
    }

    // MARK: - Header

    private var panelHeader: some View {
        HStack {
            Text(NSLocalizedString("Biometrics", comment: "Biometrics panel section title"))
                .font(LoopDS.Typography.headline)
                .foregroundColor(LoopDS.Colors.primary)
            Spacer()
            IRBadge(multiplier: currentMultiplier)
        }
        .padding(.horizontal, LoopDS.Spacing.md)
        .padding(.vertical, LoopDS.Spacing.sm)
    }

    // MARK: - Metric list

    private var metricList: some View {
        ForEach(BiometricTileType.allCases) { tile in
            MetricRow(
                tile: tile,
                snapshot: latestSnapshot,
                entry: irService.latestEntry
            )
            .contentShape(Rectangle())
            .onTapGesture { selectedTile = tile }

            if tile != BiometricTileType.allCases.last {
                Divider()
                    // Indent divider past icon + label leading edge for visual grouping
                    .padding(.leading, LoopDS.Spacing.md + 22 + LoopDS.Spacing.sm)
            }
        }
    }

    // MARK: - MetricRow

    private struct MetricRow: View {
        let tile: BiometricTileType
        let snapshot: BiometricSnapshot?
        let entry: AppleHealthIREntry?

        private var rawValue: Double? {
            guard let snapshot = snapshot else { return nil }
            switch tile {
            case .sleep:    return snapshot.sleepHours
            case .steps:    return snapshot.stepCount
            case .hrv:      return snapshot.hrvSDNN
            case .exercise: return snapshot.exerciseMinutes
            case .rhr:      return snapshot.heartRate
            }
        }

        private var delta: Double? {
            guard let entry = entry else { return nil }
            switch tile {
            case .sleep:    return entry.sleepDelta
            case .steps:    return entry.stepsDelta
            case .hrv:      return entry.hrvDelta
            case .exercise: return entry.exerciseDelta
            case .rhr:      return entry.rhrDelta
            }
        }

        private var formattedValue: String {
            guard let raw = rawValue else { return "--" }
            switch tile {
            case .steps: return String(format: "%.0f %@", raw, tile.unit)
            default:     return String(format: "%.1f %@", raw, tile.unit)
            }
        }

        var body: some View {
            HStack(spacing: LoopDS.Spacing.sm) {
                // Icon — biometricTint accent, fixed width for column alignment
                Image(systemName: tile.icon)
                    .font(.subheadline)
                    .foregroundColor(LoopDS.Colors.biometricTint)
                    .frame(width: 22, alignment: .center)

                Text(tile.displayName)
                    .font(LoopDS.Typography.subheadline)
                    .foregroundColor(LoopDS.Colors.secondary)

                Spacer()

                // Monospaced digit value — stays stable as data updates
                Text(formattedValue)
                    .font(LoopDS.Typography.metric)
                    .foregroundColor(rawValue == nil ? LoopDS.Colors.secondary : LoopDS.Colors.primary)

                if let d = delta {
                    DeltaChip(delta: d)
                }
            }
            .padding(.horizontal, LoopDS.Spacing.md)
            .padding(.vertical, LoopDS.Spacing.sm + LoopDS.Spacing.xs)
            .accessibilityLabel(accessibilityLabel)
        }

        private var accessibilityLabel: String {
            let valueText = rawValue.map { String(format: "%.1f %@", $0, tile.unit) } ?? "no data"
            let deltaText = delta.map { String(format: ", delta %+.0f%%", $0) } ?? ""
            return "\(tile.displayName): \(valueText)\(deltaText)"
        }
    }

    // MARK: - DeltaChip

    private struct DeltaChip: View {
        let delta: Double

        // Positive delta raises IR (bad) = red; negative lowers IR (good) = green
        private var chipColor: Color { delta >= 0 ? LoopDS.Colors.glucoseUrgent : LoopDS.Colors.glucoseSafe }

        var body: some View {
            Text(String(format: "%+.0f%%", delta))
                .font(LoopDS.Typography.caption2.bold())
                .padding(.horizontal, LoopDS.Spacing.sm - 2)
                .padding(.vertical, LoopDS.Spacing.xs / 2)
                .background(chipColor.opacity(0.15))
                .foregroundColor(chipColor)
                .cornerRadius(LoopDS.Radius.sm)
        }
    }

    // MARK: - IRBadge

    private struct IRBadge: View {
        let multiplier: Double

        private var badgeColor: Color {
            if multiplier < 1.1 { return LoopDS.Colors.glucoseSafe }
            if multiplier < 1.5 { return LoopDS.Colors.glucoseWarning }
            return LoopDS.Colors.glucoseUrgent
        }

        var body: some View {
            Text(String(format: "IR \u{00D7}%.2f", multiplier))
                .font(LoopDS.Typography.caption.bold())
                .padding(.horizontal, LoopDS.Spacing.sm)
                .padding(.vertical, LoopDS.Spacing.xs)
                .background(badgeColor.opacity(0.18))
                .foregroundColor(badgeColor)
                .cornerRadius(LoopDS.Radius.sm)
                .accessibilityLabel(
                    String(
                        format: NSLocalizedString(
                            "Insulin resistance multiplier %.2f",
                            comment: "IR badge accessibility label"
                        ),
                        multiplier
                    )
                )
        }
    }
}
