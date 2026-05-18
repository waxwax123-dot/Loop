//
//  BiometricIRDetailView.swift
//  Loop
//

import SwiftUI

enum BiometricTileType: String, CaseIterable, Identifiable {
    case sleep
    case steps
    case hrv
    case exercise
    case rhr

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sleep: return NSLocalizedString("Sleep", comment: "Biometric tile label")
        case .steps: return NSLocalizedString("Steps", comment: "Biometric tile label")
        case .hrv: return NSLocalizedString("HRV", comment: "Biometric tile label")
        case .exercise: return NSLocalizedString("Exercise", comment: "Biometric tile label")
        case .rhr: return NSLocalizedString("Resting HR", comment: "Biometric tile label")
        }
    }

    var icon: String {
        switch self {
        case .sleep: return "moon.fill"
        case .steps: return "figure.walk"
        case .hrv: return "waveform.path.ecg"
        case .exercise: return "heart.fill"
        case .rhr: return "heart.circle.fill"
        }
    }

    var unit: String {
        switch self {
        case .sleep: return NSLocalizedString("hr", comment: "Hours unit abbreviation")
        case .steps: return NSLocalizedString("steps", comment: "Steps unit")
        case .hrv: return NSLocalizedString("ms", comment: "Milliseconds unit abbreviation")
        case .exercise: return NSLocalizedString("min", comment: "Minutes unit abbreviation")
        case .rhr: return NSLocalizedString("bpm", comment: "Beats per minute unit")
        }
    }

    func rawValue(from entry: AppleHealthIREntry) -> Double? {
        switch self {
        case .sleep: return entry.sleepHours
        case .steps: return entry.stepCount
        case .hrv: return entry.hrvSDNN
        case .exercise: return entry.exerciseMinutes
        case .rhr: return entry.heartRate
        }
    }

    func delta(from entry: AppleHealthIREntry) -> Double {
        switch self {
        case .sleep: return entry.sleepDelta
        case .steps: return entry.stepsDelta
        case .hrv: return entry.hrvDelta
        case .exercise: return entry.exerciseDelta
        case .rhr: return entry.rhrDelta
        }
    }
}

struct BiometricIRDetailView: View {
    let tileType: BiometricTileType
    let entry: AppleHealthIREntry?
    let allEntries: [AppleHealthIREntry]

    var body: some View {
        if #available(iOS 16, *) {
            baseView.presentationDetents([.medium, .large])
        } else {
            baseView
        }
    }

    @ViewBuilder private var baseView: some View {
        NavigationView {
            List {
                currentValueSection
                thresholdBandSection
                historySection
            }
            .listStyle(.insetGrouped)
            .navigationTitle(tileType.displayName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var currentValueSection: some View {
        Section {
            if let entry = entry, let raw = tileType.rawValue(from: entry) {
                let delta = tileType.delta(from: entry)
                let deltaColor: Color = delta >= 0 ? LoopDS.Colors.glucoseUrgent : LoopDS.Colors.glucoseSafe
                HStack(alignment: .firstTextBaseline, spacing: LoopDS.Spacing.sm) {
                    // Icon anchors the row with biometric tint
                    Image(systemName: tileType.icon)
                        .font(.title3)
                        .foregroundColor(LoopDS.Colors.biometricTint)
                    // Dominant readout value in monospaced type
                    Text(String(format: "%.1f", raw))
                        .font(LoopDS.Typography.readout)
                        .foregroundColor(LoopDS.Colors.primary)
                    Text(tileType.unit)
                        .font(LoopDS.Typography.subheadline)
                        .foregroundColor(LoopDS.Colors.secondary)
                    Spacer()
                    // Delta badge — color-coded for IR direction
                    Text(String(format: "%+.1f%%", delta))
                        .font(LoopDS.Typography.metric)
                        .padding(.horizontal, LoopDS.Spacing.sm)
                        .padding(.vertical, LoopDS.Spacing.xs)
                        .background(deltaColor.opacity(0.15))
                        .foregroundColor(deltaColor)
                        .cornerRadius(LoopDS.Radius.sm)
                }
                .padding(.vertical, LoopDS.Spacing.xs)
            } else {
                Text(NSLocalizedString("No data", comment: "No biometric data available"))
                    .foregroundColor(LoopDS.Colors.secondary)
            }
        } header: {
            Text(NSLocalizedString("Current", comment: "Section header"))
                .font(LoopDS.Typography.caption.bold())
                .foregroundColor(LoopDS.Colors.secondary)
                .textCase(nil)
        }
    }

    private var thresholdBandSection: some View {
        Section {
            if let entry = entry {
                let t = entry.thresholdsSnapshot
                // Aligned column header row
                HStack(spacing: LoopDS.Spacing.sm) {
                    Text(NSLocalizedString("Zone", comment: "Threshold zone column header"))
                        .frame(width: 56, alignment: .leading)
                    Text(NSLocalizedString("Range", comment: "Threshold range column header"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(NSLocalizedString("Effect", comment: "Threshold effect column header"))
                        .frame(width: 60, alignment: .trailing)
                }
                .font(LoopDS.Typography.caption.bold())
                .foregroundColor(LoopDS.Colors.secondary)
                .padding(.vertical, LoopDS.Spacing.xs)
                ForEach(bands(for: t), id: \.label) { band in
                    ThresholdRow(label: band.label, range: band.range, effect: band.effect)
                }
            }
        } header: {
            Text(NSLocalizedString("Thresholds", comment: "Section header"))
                .font(LoopDS.Typography.caption.bold())
                .foregroundColor(LoopDS.Colors.secondary)
                .textCase(nil)
        }
    }

    private var historySection: some View {
        Section {
            if allEntries.isEmpty {
                Text(NSLocalizedString("No history", comment: "No history entries"))
                    .foregroundColor(LoopDS.Colors.secondary)
            } else {
                ForEach(allEntries.reversed()) { entry in
                    HistoryRow(entry: entry, tileType: tileType)
                }
            }
        } header: {
            Text(NSLocalizedString("Last 24 Hours", comment: "Section header"))
                .font(LoopDS.Typography.caption.bold())
                .foregroundColor(LoopDS.Colors.secondary)
                .textCase(nil)
        }
    }

    private struct BandInfo {
        let label: String
        let range: String
        let effect: Double
    }

    private func bands(for t: AppleHealthIRThresholds) -> [BandInfo] {
        switch tileType {
        case .sleep:
            return [
                BandInfo(label: "Zone 1", range: "< \(format(t.sleepT1))h", effect: t.sleepE1),
                BandInfo(label: "Zone 2", range: "\(format(t.sleepT1))–\(format(t.sleepT2))h", effect: t.sleepE2),
                BandInfo(label: "Zone 3", range: "\(format(t.sleepT2))–\(format(t.sleepT3))h", effect: t.sleepE3),
                BandInfo(label: "Zone 4", range: "\(format(t.sleepT3))–\(format(t.sleepT4))h", effect: t.sleepE4),
            ]
        case .steps:
            return [
                BandInfo(label: "Zone 1", range: "< \(Int(t.stepsT1))", effect: t.stepsE1),
                BandInfo(label: "Zone 2", range: "\(Int(t.stepsT1))–\(Int(t.stepsT2))", effect: t.stepsE2),
                BandInfo(label: "Zone 3", range: "\(Int(t.stepsT2))–\(Int(t.stepsT3))", effect: t.stepsE3),
                BandInfo(label: "Zone 4", range: "\(Int(t.stepsT3))–\(Int(t.stepsT4))", effect: t.stepsE4),
            ]
        case .hrv:
            return [
                BandInfo(label: "Zone 1", range: "< \(Int(t.hrvT1))ms", effect: t.hrvE1),
                BandInfo(label: "Zone 2", range: "\(Int(t.hrvT1))–\(Int(t.hrvT2))ms", effect: t.hrvE2),
                BandInfo(label: "Zone 3", range: "\(Int(t.hrvT2))–\(Int(t.hrvT3))ms", effect: t.hrvE3),
                BandInfo(label: "Zone 4", range: "\(Int(t.hrvT3))–\(Int(t.hrvT4))ms", effect: t.hrvE4),
            ]
        case .exercise:
            return [
                BandInfo(label: "Zone 1", range: "< \(Int(t.exerciseT1))min", effect: t.exerciseE1),
                BandInfo(label: "Zone 2", range: "\(Int(t.exerciseT1))–\(Int(t.exerciseT2))min", effect: t.exerciseE2),
                BandInfo(label: "Zone 3", range: "\(Int(t.exerciseT2))–\(Int(t.exerciseT3))min", effect: t.exerciseE3),
                BandInfo(label: "Zone 4", range: "\(Int(t.exerciseT3))–\(Int(t.exerciseT4))min", effect: t.exerciseE4),
            ]
        case .rhr:
            return [
                BandInfo(label: "Zone 1", range: "< \(Int(t.rhrT1))bpm", effect: 0.0),
                BandInfo(label: "Zone 2", range: "\(Int(t.rhrT1))–\(Int(t.rhrT2))bpm", effect: t.rhrE1),
                BandInfo(label: "Zone 3", range: "\(Int(t.rhrT2))–\(Int(t.rhrT3))bpm", effect: t.rhrE2),
                BandInfo(label: "Zone 4", range: "\(Int(t.rhrT3))–\(Int(t.rhrT4))bpm", effect: t.rhrE3),
                BandInfo(label: "Zone 5", range: "≥ \(Int(t.rhrT4))bpm", effect: t.rhrE4),
            ]
        }
    }

    private func format(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }

    private struct ThresholdRow: View {
        let label: String
        let range: String
        let effect: Double

        private var effectColor: Color {
            effect >= 0 ? LoopDS.Colors.glucoseUrgent : LoopDS.Colors.glucoseSafe
        }

        var body: some View {
            HStack(spacing: LoopDS.Spacing.sm) {
                Text(label)
                    .font(LoopDS.Typography.subheadline.weight(.medium))
                    .foregroundColor(LoopDS.Colors.primary)
                    .frame(width: 56, alignment: .leading)
                Text(range)
                    .font(LoopDS.Typography.subheadline)
                    .foregroundColor(LoopDS.Colors.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(String(format: "%+.0f%%", effect))
                    .font(LoopDS.Typography.metric)
                    .foregroundColor(effectColor)
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.vertical, LoopDS.Spacing.xs)
        }
    }

    private struct HistoryRow: View {
        let entry: AppleHealthIREntry
        let tileType: BiometricTileType

        var body: some View {
            HStack {
                Text(entry.timestamp, style: .time)
                    .foregroundColor(LoopDS.Colors.secondary)
                    .font(LoopDS.Typography.caption)
                Spacer()
                let delta = tileType.delta(from: entry)
                Text(String(format: "%+.1f%%", delta))
                    .foregroundColor(delta >= 0 ? LoopDS.Colors.glucoseUrgent : LoopDS.Colors.glucoseSafe)
                    .font(LoopDS.Typography.metric)
                Text(entry.formattedMultiplier)
                    .font(LoopDS.Typography.caption)
                    .foregroundColor(LoopDS.Colors.secondary)
            }
        }
    }
}
