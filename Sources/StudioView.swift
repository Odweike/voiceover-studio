import SwiftUI

struct StudioView: View {
    @ObservedObject var studio: Studio
    @ObservedObject private var l10n = InterfaceLanguage.shared
    @State private var search = ""
    @State private var showVideoColumns = false
    @AppStorage("scriptTextLineLimit") private var scriptTextLineLimit = 0

    private var visibleTextLines: Int? {
        scriptTextLineLimit == 0 ? nil : scriptTextLineLimit
    }

    private var visibleBlocks: [ScriptBlock] {
        guard !search.isEmpty else { return studio.blocks }
        return studio.blocks.filter {
            $0.number.localizedCaseInsensitiveContains(search) ||
            $0.russian.localizedCaseInsensitiveContains(search) ||
            $0.english.localizedCaseInsensitiveContains(search)
        }
    }

    private var voicedCount: Int {
        studio.blocks.filter { block in
            switch studio.status(for: block) {
            case .approved: true
            // Statuses imported from the user's spreadsheet keep their original wording.
            case .imported(let value): value == "Озвучено"
            default: false
            }
        }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(studio.projectName).font(.title2.bold()).lineLimit(1).help(studio.projectName)
                    Text(l10n.s.voicedProgress(voicedCount, studio.blocks.count))
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(minWidth: 150, alignment: .leading)
                Spacer()
                TextField(l10n.s.searchPlaceholder, text: $search)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
                Button(l10n.s.showProject, systemImage: "folder") { studio.revealFolder() }
                Toggle(l10n.s.editingToggle, systemImage: "film", isOn: $showVideoColumns)
                    .toggleStyle(.button)
                Button(l10n.s.openProject, systemImage: "folder") { studio.openProject() }
                    .disabled(studio.locked)
                Button(l10n.s.importScript, systemImage: "tablecells") { studio.importScenario() }
                    .disabled(studio.locked)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            Table(visibleBlocks, selection: Binding<String?>(
                get: { studio.selectedBlockID.isEmpty ? nil : studio.selectedBlockID },
                set: { studio.selectBlock($0 ?? "") }
            )) {
                TableColumn("#") { block in
                    Text(block.number).font(.body.monospacedDigit()).foregroundStyle(.secondary)
                }
                .width(min: 38, ideal: 44, max: 56)

                TableColumn("AUDIO / ENGLISH") { block in
                    VoiceTextCell(value: block.english, block: block, primary: true,
                                  needsRecording: studio.needsRecording(block), visibleLines: visibleTextLines,
                                  splitDisabled: studio.locked) { studio.splitIntoSentences(block) }
                }
                .width(min: 260, ideal: 380, max: 760)

                TableColumn("АУДИО / РУССКИЙ") { block in
                    VoiceTextCell(value: block.russian, block: block,
                                  needsRecording: studio.needsRecording(block), visibleLines: visibleTextLines,
                                  splitDisabled: studio.locked) { studio.splitIntoSentences(block) }
                }
                .width(min: 220, ideal: 300, max: 760)

                TableColumn(l10n.s.colStatus) { block in
                    StatusCell(status: studio.status(for: block))
                }
                .width(min: 102, ideal: 112, max: 126)

                TableColumn(l10n.s.colAudioFiles) { block in
                    AudioCell(studio: studio, block: block)
                }
                .width(min: 280, ideal: 340, max: 520)

                if showVideoColumns {
                    TableColumn("ВИДЕО / МОНТАЖ") { block in
                        CellText(block.videoRussian ?? "", visibleLines: visibleTextLines)
                    }
                    .width(min: 180, ideal: 240)

                    TableColumn("VIDEO / EDIT") { block in
                        CellText(block.videoEnglish ?? "", visibleLines: visibleTextLines)
                    }
                    .width(min: 180, ideal: 240)
                }
            }
            .alternatingRowBackgrounds(.enabled)

            Divider()

            HStack(spacing: 12) {
                Circle()
                    .fill(studio.recording ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                Text(studio.message).font(.callout.weight(.medium))
                if studio.recording {
                    LiveLevelBar(audio: studio.audio).frame(width: 180)
                }
                Spacer()
                Text(l10n.s.formatSpec).font(.caption).foregroundStyle(.secondary)
                if studio.pendingTake != nil {
                    Button(l10n.s.cancelRecording, systemImage: "xmark", role: .destructive) { studio.cancelRecording() }
                    Button(studio.recording ? l10n.s.save : l10n.s.retrySave, systemImage: "checkmark") {
                        studio.stopRecording()
                    }.buttonStyle(.borderedProminent)
                } else if let block = studio.selectedBlock {
                    Button(l10n.s.recordNextLine, systemImage: "mic.fill") { studio.record(block) }
                        .disabled(studio.locked || block.voiceMarkerIssue != nil)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(minWidth: 1120, minHeight: 680)
    }
}

struct CellText: View {
    let value: String
    var primary = false
    var needsRecording = false
    var visibleLines: Int? = nil

    init(_ value: String, primary: Bool = false, needsRecording: Bool = false, visibleLines: Int? = nil) {
        self.value = value
        self.primary = primary
        self.needsRecording = needsRecording
        self.visibleLines = visibleLines
    }

    var body: some View {
        Text(value.isEmpty ? "—" : value)
            .font(.system(size: 12.5, weight: primary ? .medium : .regular))
            .foregroundStyle(value.isEmpty ? .tertiary : .primary)
            .lineLimit(visibleLines)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
        .padding(.vertical, 6)
        .padding(.horizontal, 7)
        .background(needsRecording ? Color.red.opacity(0.13) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6))
    }
}

struct VoiceTextCell: View {
    let value: String
    let block: ScriptBlock
    var primary = false
    var needsRecording = false
    var visibleLines: Int? = nil
    var splitDisabled = false
    var onSplit: (() -> Void)? = nil

    private var segments: [VoiceSegment] {
        VoiceSegment.parse(value, fallbackID: block.id, fallbackLabel: block.number)
    }

    var body: some View {
        Group {
            if block.hasVoiceMarkers {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                        Text(segment.text)
                            .font(.system(size: 12.5, weight: primary ? .medium : .regular))
                            .lineLimit(visibleLines)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                        if index < segments.count - 1 { Divider() }
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 7)
                .background(needsRecording ? Color.red.opacity(0.13) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6))
            } else {
                CellText(value, primary: primary, needsRecording: needsRecording, visibleLines: visibleLines)
            }
        }
        .overlay {
            if let onSplit {
                RightClickMenuOverlay {
                    [
                        ContextMenuAction(Strings.current.copyText, systemImage: "doc.on.doc") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(plainText, forType: .string)
                        },
                        ContextMenuAction(Strings.current.splitIntoSentences, systemImage: "scissors",
                                          enabled: !splitDisabled, handler: onSplit)
                    ]
                }
            }
        }
    }

    /// Text as displayed, without [voice:...] markup.
    private var plainText: String {
        segments.map(\.text).joined(separator: "\n")
    }
}

struct StatusCell: View {
    let status: BlockStatus
    @ObservedObject private var l10n = InterfaceLanguage.shared

    private var color: Color {
        switch status {
        case .approved: .green
        case .hasTakes, .inProgress: .orange
        case .recording, .notRecorded, .markerError: .red
        case .imported(let value):
            // Statuses imported from the user's spreadsheet keep their original colors.
            switch value {
            case "Утверждено", "Озвучено": .green
            case "Есть дубли", "Проверить и обрезать", "В работе": .orange
            case "Запись", "Нужно записать", "Нужно перезаписать", "Не записано", "Ошибка разметки": .red
            default: .secondary
            }
        }
    }

    private var title: String {
        switch status {
        case .markerError: l10n.s.statusMarkerError
        case .recording: l10n.s.statusRecording
        case .approved: l10n.s.statusApproved
        case .inProgress: l10n.s.statusInProgress
        case .hasTakes: l10n.s.statusHasTakes
        case .notRecorded: l10n.s.statusNotRecorded
        case .imported(let value): value
        }
    }

    var body: some View {
        HStack(spacing: 7) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title).font(.caption.weight(.medium)).lineLimit(1)
        }
        .foregroundStyle(color)
        .accessibilityElement(children: .combine)
    }
}

struct AudioCell: View {
    @ObservedObject var studio: Studio
    @ObservedObject private var l10n = InterfaceLanguage.shared
    let block: ScriptBlock

    var body: some View {
        if let issue = block.voiceMarkerIssue {
            Text(issue).font(.caption).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(block.voiceSegments.enumerated()), id: \.offset) { index, segment in
                    SegmentAudioCell(studio: studio, block: block, segment: segment,
                                     showLabel: block.hasVoiceMarkers)
                    if index < block.voiceSegments.count - 1 {
                        Divider().padding(.vertical, 6)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }
}

struct SegmentAudioCell: View {
    @ObservedObject var studio: Studio
    @ObservedObject private var l10n = InterfaceLanguage.shared
    let block: ScriptBlock
    let segment: VoiceSegment
    let showLabel: Bool

    private var isCurrent: Bool { studio.selectedRecordingID == segment.id }
    private var isRecording: Bool { studio.recording && isCurrent }

    var body: some View {
        let takes = studio.takes(for: segment.id)
        VStack(alignment: .leading, spacing: 7) {
            if showLabel {
                // No .textSelection here: selectable Text mis-measures its height inside
                // nested stacks of a Table cell and the line truncates with an ellipsis.
                // The same text stays selectable in the script columns; copy is in the menu below.
                Text(segment.text)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if isRecording {
                    Label(l10n.s.recordingNow, systemImage: "record.circle.fill")
                        .foregroundStyle(.red)
                        .font(.caption.weight(.semibold))
                } else if takes.isEmpty {
                    Text(l10n.s.statusNotRecorded).foregroundStyle(.secondary).font(.caption)
                } else {
                    Label(l10n.s.hasTake, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption.weight(.semibold))
                }
            }

            if isRecording {
                RecordingStrip(audio: studio.audio, save: studio.stopRecording, cancel: studio.cancelRecording)
            } else if takes.isEmpty {
                if block.voiceStatus == "Озвучено" {
                    Text(l10n.s.onTimeline).font(.caption).foregroundStyle(.secondary)
                } else if block.voiceStatus == "Проверить и обрезать" {
                    Text(l10n.s.checkInPremiere).font(.caption).foregroundStyle(.orange)
                } else {
                    Button(l10n.s.recordThisLine, systemImage: "mic") {
                        studio.record(block, segment: segment)
                    }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(studio.locked)
                }
            } else {
                let chosen = studio.selectedTake(for: segment.id) ?? takes[0]
                let chosenIndex = (takes.firstIndex(of: chosen) ?? 0) + 1
                HStack(spacing: 8) {
                    Button {
                        studio.togglePlayback(chosen)
                    } label: {
                        Label(l10n.s.takeN(chosenIndex), systemImage: studio.playingID == chosen.id ? "pause.fill" : "play.fill")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(chosen.selected ? .green : .secondary)
                    .disabled(studio.locked)
                    .contextMenu {
                        Button(l10n.s.markBest, systemImage: "checkmark.circle") { studio.select(chosen) }
                        Divider()
                        Button(l10n.s.delete, systemImage: "trash", role: .destructive) { studio.delete(chosen) }
                    }

                    if takes.count > 1 {
                        Menu("\(takes.count)") {
                            ForEach(Array(takes.enumerated()), id: \.element.id) { index, take in
                                Button(l10n.s.playTakeN(index + 1), systemImage: take.selected ? "checkmark.circle.fill" : "play.fill") {
                                    studio.togglePlayback(take)
                                }
                                Button(l10n.s.chooseTakeN(index + 1), systemImage: "checkmark") { studio.select(take) }
                                if index < takes.count - 1 { Divider() }
                            }
                        }
                        .menuStyle(.borderlessButton)
                    }
                    Button(l10n.s.newTake, systemImage: "mic.badge.plus") {
                        studio.record(block, segment: segment)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .disabled(studio.locked)
                }
            }
        }
        .padding(.horizontal, showLabel ? 7 : 0)
        .padding(.vertical, showLabel ? 7 : 0)
        .background(
            isRecording ? Color.red.opacity(0.13) :
                (isCurrent && showLabel ? Color.accentColor.opacity(0.13) : Color.clear),
            in: RoundedRectangle(cornerRadius: 6)
        )
        .overlay {
            if isCurrent && showLabel {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isRecording ? Color.red.opacity(0.45) : Color.accentColor.opacity(0.45), lineWidth: 1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { studio.selectSegment(block, segment: segment) }
        .contextMenu {
            if showLabel {
                Button(l10n.s.copyText, systemImage: "doc.on.doc") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(segment.text, forType: .string)
                }
                Divider()
            }
            if takes.isEmpty {
                Button(l10n.s.recordThisLine, systemImage: "mic") {
                    studio.record(block, segment: segment)
                }
                .disabled(studio.locked)
            } else if takes.count == 1, let take = takes.first {
                Button(l10n.s.playRecording, systemImage: "play.fill") { studio.togglePlayback(take) }
                Button(l10n.s.markBestRecording, systemImage: "checkmark.circle") { studio.select(take) }
                Divider()
                Button(l10n.s.deleteRecording, systemImage: "trash", role: .destructive) { studio.delete(take) }
                    .disabled(studio.locked)
            } else {
                ForEach(Array(takes.enumerated()), id: \.element.id) { index, take in
                    Menu(l10n.s.takeN(index + 1)) {
                        Button(l10n.s.play, systemImage: "play.fill") { studio.togglePlayback(take) }
                        Button(l10n.s.markBest, systemImage: "checkmark.circle") { studio.select(take) }
                        Divider()
                        Button(l10n.s.delete, systemImage: "trash", role: .destructive) { studio.delete(take) }
                            .disabled(studio.locked)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(showLabel ? "\(segment.label). \(segment.text)" : l10n.s.audioFilesA11y)
    }
}

struct RecordingStrip: View {
    @ObservedObject var audio: AudioController
    @ObservedObject private var l10n = InterfaceLanguage.shared
    let save: () -> Void
    let cancel: () -> Void

    private var elapsed: String {
        let seconds = Int(audio.recordingDuration)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        // Single row, close in height to the record/takes rows it replaces,
        // so the table row does not jump when recording starts or finishes.
        HStack(spacing: 10) {
            Text(elapsed)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.red)
                .frame(width: 38, alignment: .leading)

            RecordingWaveform(samples: audio.levelHistory)
                .frame(maxWidth: .infinity)

            Button(l10n.s.cancelRecording, systemImage: "xmark", role: .destructive, action: cancel)
                .buttonStyle(.bordered)
                .help(l10n.s.stopDeleteHelp)
            Button(l10n.s.save, systemImage: "checkmark", action: save)
                .buttonStyle(.borderedProminent)
        }
        .controlSize(.small)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.24), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(l10n.s.recordingA11y(elapsed))
    }
}

struct RecordingWaveform: View {
    let samples: [Float]

    var body: some View {
        GeometryReader { proxy in
            let visible = Array(samples.suffix(52))
            let spacing: CGFloat = 2
            let width = max(1.5, (proxy.size.width - spacing * CGFloat(visible.count - 1)) / CGFloat(visible.count))

            HStack(alignment: .center, spacing: spacing) {
                ForEach(Array(visible.enumerated()), id: \.offset) { _, sample in
                    Capsule()
                        .fill(Color.red.opacity(0.9))
                        .frame(width: width,
                               height: max(3, proxy.size.height * CGFloat(sample)))
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 22)
        .animation(.linear(duration: 0.06), value: samples)
        .accessibilityHidden(true)
    }
}

struct LevelBar: View {
    let level: Float
    let active: Bool
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.14))
                Capsule().fill(active ? Color.green : Color.secondary.opacity(0.25))
                    .frame(width: max(8, proxy.size.width * CGFloat(level)))
                    .animation(.linear(duration: 0.06), value: level)
            }
        }.frame(height: 8)
    }
}

struct StudioSettingsView: View {
    @AppStorage("scriptTextLineLimit") private var scriptTextLineLimit = 0
    @ObservedObject private var l10n = InterfaceLanguage.shared

    var body: some View {
        Form {
            Picker(l10n.s.interfaceLanguage, selection: Binding(
                get: { l10n.language },
                set: { l10n.set($0) }
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.nativeName).tag(language)
                }
            }

            Picker(l10n.s.cellText, selection: $scriptTextLineLimit) {
                Text(l10n.s.showFullText).tag(0)
                Text(l10n.s.maxLines(6)).tag(6)
                Text(l10n.s.maxLines(3)).tag(3)
            }
            .pickerStyle(.radioGroup)

            Text(l10n.s.cellTextHint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420)
    }
}


struct LiveLevelBar: View {
    @ObservedObject var audio: AudioController
    var body: some View { LevelBar(level: audio.level, active: audio.recording) }
}
