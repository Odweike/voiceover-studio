import SwiftUI

struct StudioView: View {
    @ObservedObject var studio: Studio
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
        studio.blocks.filter {
            let value = studio.status(for: $0)
            return value == "Озвучено" || value == "Утверждено"
        }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(studio.projectName).font(.title2.bold()).lineLimit(1).help(studio.projectName)
                    Text("\(voicedCount) из \(studio.blocks.count) блоков озвучено")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(minWidth: 150, alignment: .leading)
                Spacer()
                TextField("Поиск в сценарии", text: $search)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
                Button("Показать проект", systemImage: "folder") { studio.revealFolder() }
                Toggle("Монтаж", systemImage: "film", isOn: $showVideoColumns)
                    .toggleStyle(.button)
                Button("Открыть проект", systemImage: "folder") { studio.openProject() }
                    .disabled(studio.locked)
                Button("Импорт сценария", systemImage: "tablecells") { studio.importScenario() }
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
                                  needsRecording: studio.needsRecording(block), visibleLines: visibleTextLines)
                }
                .width(min: 260, ideal: 380, max: 760)

                TableColumn("АУДИО / РУССКИЙ") { block in
                    VoiceTextCell(value: block.russian, block: block,
                                  needsRecording: studio.needsRecording(block), visibleLines: visibleTextLines)
                }
                .width(min: 220, ideal: 300, max: 760)

                TableColumn("СТАТУС") { block in
                    StatusCell(status: studio.status(for: block))
                }
                .width(min: 102, ideal: 112, max: 126)

                TableColumn("АУДИОФАЙЛЫ") { block in
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
                Text("WAV · mono · 48 kHz").font(.caption).foregroundStyle(.secondary)
                if studio.pendingTake != nil {
                    Button("Отменить", systemImage: "xmark", role: .destructive) { studio.cancelRecording() }
                    Button(studio.recording ? "Сохранить" : "Повторить сохранение", systemImage: "checkmark") {
                        studio.stopRecording()
                    }.buttonStyle(.borderedProminent)
                } else if let block = studio.selectedBlock {
                    Button("Записать следующую реплику", systemImage: "mic.fill") { studio.record(block) }
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

    private var segments: [VoiceSegment] {
        VoiceSegment.parse(value, fallbackID: block.id, fallbackLabel: block.number)
    }

    var body: some View {
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
}

struct StatusCell: View {
    let status: String

    private var color: Color {
        switch status {
        case "Утверждено", "Озвучено": .green
        case "Есть дубли", "Проверить и обрезать", "В работе": .orange
        case "Запись": .red
        case "Нужно записать", "Нужно перезаписать", "Не записано", "Ошибка разметки": .red
        default: .secondary
        }
    }

    var body: some View {
        HStack(spacing: 7) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(status).font(.caption.weight(.medium)).lineLimit(1)
        }
        .foregroundStyle(color)
        .accessibilityElement(children: .combine)
    }
}

struct AudioCell: View {
    @ObservedObject var studio: Studio
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
    let block: ScriptBlock
    let segment: VoiceSegment
    let showLabel: Bool

    private var isCurrent: Bool { studio.selectedRecordingID == segment.id }
    private var isRecording: Bool { studio.recording && isCurrent }

    var body: some View {
        let takes = studio.takes(for: segment.id)
        VStack(alignment: .leading, spacing: 7) {
            if showLabel {
                Text(segment.text)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)

                if isRecording {
                    Label("Идёт запись", systemImage: "record.circle.fill")
                        .foregroundStyle(.red)
                        .font(.caption.weight(.semibold))
                } else if takes.isEmpty {
                    Text("Не записано").foregroundStyle(.secondary).font(.caption)
                } else {
                    Label("Есть дубль", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption.weight(.semibold))
                }
            }

            if isRecording {
                RecordingStrip(audio: studio.audio, save: studio.stopRecording, cancel: studio.cancelRecording)
            } else if takes.isEmpty {
                if block.voiceStatus == "Озвучено" {
                    Text("На таймлайне").font(.caption).foregroundStyle(.secondary)
                } else if block.voiceStatus == "Проверить и обрезать" {
                    Text("Проверить в Premiere").font(.caption).foregroundStyle(.orange)
                } else {
                    Button("Записать эту реплику", systemImage: "mic") {
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
                        Label("Дубль \(chosenIndex)", systemImage: studio.playingID == chosen.id ? "pause.fill" : "play.fill")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(chosen.selected ? .green : .secondary)
                    .disabled(studio.locked)
                    .contextMenu {
                        Button("Выбрать лучшим", systemImage: "checkmark.circle") { studio.select(chosen) }
                        Divider()
                        Button("Удалить", systemImage: "trash", role: .destructive) { studio.delete(chosen) }
                    }

                    if takes.count > 1 {
                        Menu("\(takes.count)") {
                            ForEach(Array(takes.enumerated()), id: \.element.id) { index, take in
                                Button("Прослушать дубль \(index + 1)", systemImage: take.selected ? "checkmark.circle.fill" : "play.fill") {
                                    studio.togglePlayback(take)
                                }
                                Button("Выбрать дубль \(index + 1)", systemImage: "checkmark") { studio.select(take) }
                                if index < takes.count - 1 { Divider() }
                            }
                        }
                        .menuStyle(.borderlessButton)
                    }
                    Button("Новый дубль", systemImage: "mic.badge.plus") {
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
            if takes.isEmpty {
                Button("Записать эту реплику", systemImage: "mic") {
                    studio.record(block, segment: segment)
                }
                .disabled(studio.locked)
            } else if takes.count == 1, let take = takes.first {
                Button("Прослушать запись", systemImage: "play.fill") { studio.togglePlayback(take) }
                Button("Выбрать лучшей", systemImage: "checkmark.circle") { studio.select(take) }
                Divider()
                Button("Удалить запись", systemImage: "trash", role: .destructive) { studio.delete(take) }
                    .disabled(studio.locked)
            } else {
                ForEach(Array(takes.enumerated()), id: \.element.id) { index, take in
                    Menu("Дубль \(index + 1)") {
                        Button("Прослушать", systemImage: "play.fill") { studio.togglePlayback(take) }
                        Button("Выбрать лучшим", systemImage: "checkmark.circle") { studio.select(take) }
                        Divider()
                        Button("Удалить", systemImage: "trash", role: .destructive) { studio.delete(take) }
                            .disabled(studio.locked)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(showLabel ? "\(segment.label). \(segment.text)" : "Аудиофайлы")
    }
}

struct RecordingStrip: View {
    @ObservedObject var audio: AudioController
    let save: () -> Void
    let cancel: () -> Void

    private var elapsed: String {
        let seconds = Int(audio.recordingDuration)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Text(elapsed)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(width: 38, alignment: .leading)

                RecordingWaveform(samples: audio.levelHistory)
                    .frame(maxWidth: .infinity)
            }

            HStack(spacing: 8) {
                Spacer()
                Button("Отменить", systemImage: "xmark", role: .destructive, action: cancel)
                    .buttonStyle(.bordered)
                    .help("Остановить и удалить эту запись")
                Button("Сохранить", systemImage: "checkmark", action: save)
                    .buttonStyle(.borderedProminent)
            }
            .controlSize(.small)
        }
        .padding(9)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.24), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Идёт запись, \(elapsed)")
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
        .frame(height: 36)
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

    var body: some View {
        Form {
            Picker("Текст в ячейках", selection: $scriptTextLineLimit) {
                Text("Показывать полностью").tag(0)
                Text("Не более 6 строк").tag(6)
                Text("Не более 3 строк").tag(3)
            }
            .pickerStyle(.radioGroup)

            Text("Текст переносится внутри текущей ширины столбца. Ширину можно менять перетаскиванием границы заголовка.")
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
