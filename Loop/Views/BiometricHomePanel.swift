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
        VStack(spacing: LoopDS.Spacing.xs) {
            HStack(spacing: LoopDS.Spacing.xs) {
                ForEach(BiometricTileType.allCases) { tile in
                    MetricButton(tile: tile, snapshot: latestSnapshot)
                        .onTapGesture { selectedTile = tile }
                }
                IRBadgeButton(multiplier: currentMultiplier)
            }
            .padding(.horizontal, LoopDS.Spacing.sm)
        }
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

    // MARK: - Metric Button

    private struct MetricButton: View {
        let tile: BiometricTileType
        let snapshot: BiometricSnapshot?

        private var rawValue: Double? {
            guard let snapshot else { return nil }
            switch tile {
            case .sleep:    return snapshot.sleepHours
            case .steps:    return snapshot.stepCount
            case .hrv:      return snapshot.hrvSDNN
            case .exercise: return snapshot.exerciseMinutes
            case .rhr:      return snapshot.heartRate
            }
        }

        private var formattedValue: String {
            guard let raw = rawValue else { return "--" }
            switch tile {
            case .steps:
                return raw >= 1000 ? String(format: "%.1fk", raw / 1000) : String(format: "%.0f", raw)
            case .sleep:
                return String(format: "%.1f", raw)
            default:
                return String(format: "%.0f", raw)
            }
        }

        var body: some View {
            VStack(spacing: 3) {
                Image(systemName: tile.icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(LoopDS.Colors.biometricTint)
                Text(formattedValue)
                    .font(LoopDS.Typography.metric)
                    .foregroundColor(rawValue == nil ? LoopDS.Colors.secondary : LoopDS.Colors.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(tile.unit)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(LoopDS.Colors.tertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LoopDS.Spacing.sm)
            .background(LoopDS.Colors.surface)
            .cornerRadius(LoopDS.Radius.md)
            .accessibilityLabel("\(tile.displayName): \(formattedValue) \(tile.unit)")
        }
    }

    // MARK: - IR Badge Button

    private struct IRBadgeButton: View {
        let multiplier: Double

        private var color: Color {
            if multiplier < 1.1 { return LoopDS.Colors.glucoseSafe }
            if multiplier < 1.5 { return LoopDS.Colors.glucoseWarning }
            return LoopDS.Colors.glucoseUrgent
        }

        var body: some View {
            VStack(spacing: 3) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(color)
                Text(String(format: "×%.2f", multiplier))
                    .font(LoopDS.Typography.metric)
                    .foregroundColor(color)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("IR")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(LoopDS.Colors.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LoopDS.Spacing.sm)
            .background(color.opacity(0.12))
            .cornerRadius(LoopDS.Radius.md)
            .accessibilityLabel(String(format: "Insulin resistance multiplier %.2f", multiplier))
        }
    }
}
