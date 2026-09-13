import Foundation
import SwiftUI

/// Interface languages supported by the app.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case en, es, fr, ru

    var id: String { rawValue }

    /// Name in the language itself, so the settings picker is readable in any UI language.
    var nativeName: String {
        switch self {
        case .en: "English"
        case .es: "Español"
        case .fr: "Français"
        case .ru: "Русский"
        }
    }

    /// The user's choice persisted in UserDefaults; falls back to the system language.
    static var current: AppLanguage {
        get {
            UserDefaults.standard.string(forKey: "interfaceLanguage")
                .flatMap(AppLanguage.init(rawValue:)) ?? .systemDefault
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "interfaceLanguage")
        }
    }

    static var systemDefault: AppLanguage {
        for code in Locale.preferredLanguages {
            if code.hasPrefix("ru") { return .ru }
            if code.hasPrefix("es") { return .es }
            if code.hasPrefix("fr") { return .fr }
            if code.hasPrefix("en") { return .en }
        }
        return .en
    }
}

/// Every user-facing string in the app. The memberwise initializer forces all four
/// languages to define every key, so a translation can never be missing.
struct Strings: Sendable {
    // General buttons
    let cancel: String
    let cancelRecording: String
    let save: String
    let retrySave: String
    let delete: String
    let deleteRecording: String

    // Toolbar
    let searchPlaceholder: String
    let showProject: String
    let editingToggle: String
    let openProject: String
    let importScript: String
    let voicedProgress: @Sendable (_ voiced: Int, _ total: Int) -> String
    let formatSpec: String
    let recordNextLine: String

    // Table columns (the bilingual data columns stay as-is: "AUDIO / ENGLISH" etc.)
    let colStatus: String
    let colAudioFiles: String

    // Computed block statuses
    let statusRecording: String
    let statusApproved: String
    let statusInProgress: String
    let statusHasTakes: String
    let statusNotRecorded: String
    let statusMarkerError: String

    // Segment audio cell
    let recordingNow: String
    let hasTake: String
    let onTimeline: String
    let checkInPremiere: String
    let recordThisLine: String
    let takeN: @Sendable (_ index: Int) -> String
    let markBest: String
    let markBestRecording: String
    let playTakeN: @Sendable (_ index: Int) -> String
    let chooseTakeN: @Sendable (_ index: Int) -> String
    let newTake: String
    let playRecording: String
    let play: String
    let copyText: String
    let splitIntoSentences: String
    let audioFilesA11y: String
    let recordingA11y: @Sendable (_ elapsed: String) -> String
    let stopDeleteHelp: String

    // Settings
    let interfaceLanguage: String
    let cellText: String
    let showFullText: String
    let maxLines: @Sendable (_ lines: Int) -> String
    let cellTextHint: String

    // Studio status messages and alerts
    let readyToRecord: String
    let projectOpened: String
    let missingAudio: @Sendable (_ count: Int) -> String
    let myScript: String
    let scriptNBlocks: @Sendable (_ count: Int) -> String
    let finishRecordingFirst: String
    let openPanelHint: String
    let importPanelHint: String
    let projectCreated: String
    let allowMicrophone: String
    let recordingInProgress: String
    let takeSaved: String
    let recordingCancelled: String
    let bestTakeSelected: String
    let takeMovedToTrash: String
    let waitForOperation: String
    let couldNotSaveTake: String
    let checkFolderAccess: String
    let error: @Sendable (_ description: String) -> String
    let fixMarkupFirst: @Sendable (_ number: String) -> String
    let blockSplit: @Sendable (_ number: String, _ count: Int) -> String
    let splitAlertTitle: @Sendable (_ number: String, _ count: Int) -> String
    let splitAlertBody: String
    let splitAlertConfirm: String
    let noSampleScript: String
    let audioNotCreated: String

    // Model, store and device errors
    let errBadAudioName: String
    let errSymlinks: String
    let errOutsideProject: String
    let errFinishPreviousSave: String
    let errDuplicateTakes: String
    let errNoFolderAccess: String
    let errProjectAlreadyOpen: String
    let errScriptEmpty: String
    let errBlockIDs: String
    let errBlockNoText: @Sendable (_ number: String) -> String
    let blockError: @Sendable (_ number: String, _ issue: String) -> String
    let errDuplicateLineID: @Sendable (_ id: String) -> String
    let markerPreamble: String
    let markerInvalid: String
    let markerUnique: String
    let markerMismatch: String
    let splitOneSentence: @Sendable (_ number: String) -> String
    let splitMismatch: @Sendable (_ number: String, _ russian: Int, _ english: Int) -> String
    let xlsxTemplate: String
    let xlsxTooBig: String
    let errAlreadyRecording: String
    let errMicNoStart: String
    let errFinishRecording: String
    let errPlayback: String
    let errStoppedByDevice: String
    let errInterrupted: String
    let errAudioEncode: String

    /// Strings in the currently chosen language. Safe to call from any thread.
    static var current: Strings { Strings(AppLanguage.current) }
}

extension Strings {
    /// Declared in an extension so the memberwise initializer used by the
    /// language tables below stays available.
    init(_ language: AppLanguage) {
        switch language {
        case .en: self = .en
        case .es: self = .es
        case .fr: self = .fr
        case .ru: self = .ru
        }
    }
}

/// Publishes interface language changes so every observing view re-renders at once.
@MainActor
final class InterfaceLanguage: ObservableObject {
    static let shared = InterfaceLanguage()

    @Published private(set) var language: AppLanguage = .current

    private init() {}

    func set(_ language: AppLanguage) {
        AppLanguage.current = language
        self.language = language
    }

    var s: Strings { Strings(language) }
}

extension Strings {
    static let en = Strings(
        cancel: "Cancel", cancelRecording: "Cancel", save: "Save", retrySave: "Retry save",
        delete: "Delete", deleteRecording: "Delete recording",
        searchPlaceholder: "Search script", showProject: "Show Project", editingToggle: "Editing",
        openProject: "Open Project", importScript: "Import Script",
        voicedProgress: { "\($0) of \($1) blocks voiced" },
        formatSpec: "WAV · mono · 48 kHz", recordNextLine: "Record next line",
        colStatus: "STATUS", colAudioFiles: "AUDIO FILES",
        statusRecording: "Recording", statusApproved: "Approved", statusInProgress: "In progress",
        statusHasTakes: "Has takes", statusNotRecorded: "Not recorded", statusMarkerError: "Markup error",
        recordingNow: "Recording", hasTake: "Take recorded", onTimeline: "On timeline",
        checkInPremiere: "Check in Premiere", recordThisLine: "Record this line",
        takeN: { "Take \($0)" }, markBest: "Mark as best", markBestRecording: "Mark as best",
        playTakeN: { "Play take \($0)" }, chooseTakeN: { "Choose take \($0)" },
        newTake: "New take", playRecording: "Play recording", play: "Play",
        copyText: "Copy text", splitIntoSentences: "Split into sentences",
        audioFilesA11y: "Audio files", recordingA11y: { "Recording, \($0)" },
        stopDeleteHelp: "Stop and delete this recording",
        interfaceLanguage: "Interface language", cellText: "Text in cells", showFullText: "Show in full",
        maxLines: { "Up to \($0) lines" },
        cellTextHint: "Text wraps within the current column width. Drag a header border to change it.",
        readyToRecord: "Ready to record", projectOpened: "Project opened",
        missingAudio: { "Missing audio files: \($0). Restore them from a backup" },
        myScript: "My Script", scriptNBlocks: { "Script · \($0) blocks" },
        finishRecordingFirst: "Finish recording or saving first",
        openPanelHint: "Choose a folder with scenario.json, manifest.json and Recordings",
        importPanelHint: "Create a separate project from JSON or XLSX. Existing recordings are kept",
        projectCreated: "Created a separate project. The folder is available via “Show Project”",
        allowMicrophone: "Allow microphone access in System Settings",
        recordingInProgress: "Recording…", takeSaved: "Take saved", recordingCancelled: "Recording cancelled",
        bestTakeSelected: "Best take selected", takeMovedToTrash: "Take moved to Trash",
        waitForOperation: "Wait for the operation to finish", couldNotSaveTake: "Couldn't save the take",
        checkFolderAccess: "Check access to the project folder and try saving again.",
        error: { "Error: \($0)" },
        fixMarkupFirst: { "Block \($0): fix the [voice:...] markup first" },
        blockSplit: { "Block \($0) split into lines: \($1)" },
        splitAlertTitle: { "Block \($0) has takes: \($1)" },
        splitAlertBody: "To split the block into sentences, the takes will be moved to Trash.",
        splitAlertConfirm: "Delete takes and split",
        noSampleScript: "Sample script not found. Open a project or import JSON/XLSX",
        audioNotCreated: "Audio file wasn't created. Cancel this take and check the microphone",
        errBadAudioName: "Invalid audio file name",
        errSymlinks: "Symbolic links to audio files are not supported",
        errOutsideProject: "Audio file is outside the project",
        errFinishPreviousSave: "Finish saving the previous recording first",
        errDuplicateTakes: "The manifest contains duplicate takes or file names",
        errNoFolderAccess: "No access to the project folder",
        errProjectAlreadyOpen: "This project is already open in another window or app instance",
        errScriptEmpty: "The script is empty",
        errBlockIDs: "Block IDs must be non-empty and unique",
        errBlockNoText: { "Block \($0) has no text" },
        blockError: { "Block \($0): \($1)" },
        errDuplicateLineID: { "Duplicate line ID: \($0)" },
        markerPreamble: "Text before the first marker is not allowed",
        markerInvalid: "Invalid or empty [voice:...] marker",
        markerUnique: "Markers must be unique",
        markerMismatch: "Markers in the Russian and English texts don't match",
        splitOneSentence: { "Block \($0) has a single sentence, nothing to split" },
        splitMismatch: { "Block \($0): \($1) sentences in Russian, \($2) in English. Split manually with [voice:...] markers" },
        xlsxTemplate: "Expected XLSX template: headers in row 1, Russian text in column D, English in column E",
        xlsxTooBig: "XLSX sheet is too large (16 MB XML limit)",
        errAlreadyRecording: "Already recording", errMicNoStart: "The microphone didn't start recording",
        errFinishRecording: "Finish recording first", errPlayback: "Couldn't play the take",
        errStoppedByDevice: "Recording was stopped by the device",
        errInterrupted: "The device interrupted recording; check the saved audio",
        errAudioEncode: "Audio recording error"
    )

    static let ru = Strings(
        cancel: "Отмена", cancelRecording: "Отменить", save: "Сохранить", retrySave: "Повторить сохранение",
        delete: "Удалить", deleteRecording: "Удалить запись",
        searchPlaceholder: "Поиск в сценарии", showProject: "Показать проект", editingToggle: "Монтаж",
        openProject: "Открыть проект", importScript: "Импорт сценария",
        voicedProgress: { "\($0) из \($1) блоков озвучено" },
        formatSpec: "WAV · моно · 48 кГц", recordNextLine: "Записать следующую реплику",
        colStatus: "СТАТУС", colAudioFiles: "АУДИОФАЙЛЫ",
        statusRecording: "Запись", statusApproved: "Утверждено", statusInProgress: "В работе",
        statusHasTakes: "Есть дубли", statusNotRecorded: "Не записано", statusMarkerError: "Ошибка разметки",
        recordingNow: "Идёт запись", hasTake: "Есть дубль", onTimeline: "На таймлайне",
        checkInPremiere: "Проверить в Premiere", recordThisLine: "Записать эту реплику",
        takeN: { "Дубль \($0)" }, markBest: "Выбрать лучшим", markBestRecording: "Выбрать лучшей",
        playTakeN: { "Прослушать дубль \($0)" }, chooseTakeN: { "Выбрать дубль \($0)" },
        newTake: "Новый дубль", playRecording: "Прослушать запись", play: "Прослушать",
        copyText: "Копировать текст", splitIntoSentences: "Разбить на предложения",
        audioFilesA11y: "Аудиофайлы", recordingA11y: { "Идёт запись, \($0)" },
        stopDeleteHelp: "Остановить и удалить эту запись",
        interfaceLanguage: "Язык интерфейса", cellText: "Текст в ячейках", showFullText: "Показывать полностью",
        maxLines: { "Не более \($0) строк" },
        cellTextHint: "Текст переносится внутри текущей ширины столбца. Ширину можно менять перетаскиванием границы заголовка.",
        readyToRecord: "Готово к записи", projectOpened: "Проект открыт",
        missingAudio: { "Не найдены аудиофайлы: \($0). Восстановите их из резервной копии" },
        myScript: "Мой сценарий", scriptNBlocks: { "Сценарий · \($0) блоков" },
        finishRecordingFirst: "Сначала завершите запись или сохранение",
        openPanelHint: "Выберите папку с scenario.json, manifest.json и Recordings",
        importPanelHint: "Создать отдельный проект из JSON или XLSX. Существующие записи сохранятся",
        projectCreated: "Создан отдельный проект. Папка доступна через «Показать проект»",
        allowMicrophone: "Разрешите микрофон в Системных настройках",
        recordingInProgress: "Идёт запись…", takeSaved: "Дубль сохранён", recordingCancelled: "Запись отменена",
        bestTakeSelected: "Лучший дубль выбран", takeMovedToTrash: "Дубль перемещён в Корзину",
        waitForOperation: "Дождитесь завершения операции", couldNotSaveTake: "Не удалось сохранить дубль",
        checkFolderAccess: "Проверьте доступ к папке проекта и повторите сохранение.",
        error: { "Ошибка: \($0)" },
        fixMarkupFirst: { "Блок \($0): сначала исправьте разметку [voice:...]" },
        blockSplit: { "Блок \($0) разбит на реплики: \($1)" },
        splitAlertTitle: { "У блока \($0) есть дубли: \($1)" },
        splitAlertBody: "Чтобы разбить блок на предложения, дубли будут перемещены в Корзину.",
        splitAlertConfirm: "Удалить дубли и разбить",
        noSampleScript: "Не найден пример сценария. Откройте проект или импортируйте JSON/XLSX",
        audioNotCreated: "Аудиофайл не создан. Отмените этот дубль и проверьте микрофон",
        errBadAudioName: "Некорректное имя аудиофайла",
        errSymlinks: "Символические ссылки на аудиофайлы не поддерживаются",
        errOutsideProject: "Аудиофайл находится вне проекта",
        errFinishPreviousSave: "Сначала завершите сохранение предыдущей записи",
        errDuplicateTakes: "В manifest найдены повторяющиеся дубли или имена файлов",
        errNoFolderAccess: "Нет доступа к папке проекта",
        errProjectAlreadyOpen: "Этот проект уже открыт в другом окне или экземпляре приложения",
        errScriptEmpty: "Сценарий пуст",
        errBlockIDs: "Идентификаторы блоков должны быть непустыми и уникальными",
        errBlockNoText: { "Блок \($0) не содержит текста" },
        blockError: { "Блок \($0): \($1)" },
        errDuplicateLineID: { "Повтор идентификатора реплики: \($0)" },
        markerPreamble: "Текст перед первым маркером не допускается",
        markerInvalid: "Некорректный или пустой маркер [voice:...]",
        markerUnique: "Маркеры должны быть уникальными",
        markerMismatch: "Маркеры в русском и английском тексте не совпадают",
        splitOneSentence: { "Блок \($0) содержит одно предложение, разбивка не нужна" },
        splitMismatch: { "Блок \($0): предложений в русском тексте \($1), в английском \($2). Разбейте вручную маркерами [voice:...]" },
        xlsxTemplate: "Ожидается шаблон XLSX: заголовки в первой строке, русский текст в D, английский в E",
        xlsxTooBig: "Лист XLSX слишком большой (лимит 16 МБ XML)",
        errAlreadyRecording: "Запись уже идёт", errMicNoStart: "Микрофон не начал запись",
        errFinishRecording: "Сначала завершите запись", errPlayback: "Не удалось воспроизвести дубль",
        errStoppedByDevice: "Запись остановлена устройством",
        errInterrupted: "Устройство прервало запись; проверьте сохранённый звук",
        errAudioEncode: "Ошибка записи звука"
    )

    static let es = Strings(
        cancel: "Cancelar", cancelRecording: "Cancelar", save: "Guardar", retrySave: "Reintentar guardado",
        delete: "Eliminar", deleteRecording: "Eliminar grabación",
        searchPlaceholder: "Buscar en el guion", showProject: "Mostrar proyecto", editingToggle: "Edición",
        openProject: "Abrir proyecto", importScript: "Importar guion",
        voicedProgress: { "\($0) de \($1) bloques grabados" },
        formatSpec: "WAV · mono · 48 kHz", recordNextLine: "Grabar la línea siguiente",
        colStatus: "ESTADO", colAudioFiles: "ARCHIVOS DE AUDIO",
        statusRecording: "Grabando", statusApproved: "Aprobado", statusInProgress: "En curso",
        statusHasTakes: "Con tomas", statusNotRecorded: "Sin grabar", statusMarkerError: "Error de marcado",
        recordingNow: "Grabando", hasTake: "Toma grabada", onTimeline: "En la línea de tiempo",
        checkInPremiere: "Revisar en Premiere", recordThisLine: "Grabar esta línea",
        takeN: { "Toma \($0)" }, markBest: "Marcar como la mejor", markBestRecording: "Marcar como la mejor",
        playTakeN: { "Escuchar toma \($0)" }, chooseTakeN: { "Elegir toma \($0)" },
        newTake: "Nueva toma", playRecording: "Escuchar la grabación", play: "Escuchar",
        copyText: "Copiar texto", splitIntoSentences: "Dividir en frases",
        audioFilesA11y: "Archivos de audio", recordingA11y: { "Grabando, \($0)" },
        stopDeleteHelp: "Detener y eliminar esta grabación",
        interfaceLanguage: "Idioma de la interfaz", cellText: "Texto en las celdas", showFullText: "Mostrar completo",
        maxLines: { "Hasta \($0) líneas" },
        cellTextHint: "El texto se ajusta al ancho actual de la columna. Arrastra el borde del encabezado para cambiarlo.",
        readyToRecord: "Listo para grabar", projectOpened: "Proyecto abierto",
        missingAudio: { "Faltan archivos de audio: \($0). Restáuralos desde una copia de seguridad" },
        myScript: "Mi guion", scriptNBlocks: { "Guion · \($0) bloques" },
        finishRecordingFirst: "Termina primero la grabación o el guardado",
        openPanelHint: "Elige una carpeta con scenario.json, manifest.json y Recordings",
        importPanelHint: "Crear un proyecto independiente desde JSON o XLSX. Las grabaciones existentes se conservan",
        projectCreated: "Proyecto independiente creado. La carpeta está disponible en «Mostrar proyecto»",
        allowMicrophone: "Permite el acceso al micrófono en Ajustes del Sistema",
        recordingInProgress: "Grabando…", takeSaved: "Toma guardada", recordingCancelled: "Grabación cancelada",
        bestTakeSelected: "Mejor toma seleccionada", takeMovedToTrash: "Toma movida a la Papelera",
        waitForOperation: "Espera a que termine la operación", couldNotSaveTake: "No se pudo guardar la toma",
        checkFolderAccess: "Comprueba el acceso a la carpeta del proyecto y vuelve a intentarlo.",
        error: { "Error: \($0)" },
        fixMarkupFirst: { "Bloque \($0): corrige primero el marcado [voice:...]" },
        blockSplit: { "Bloque \($0) dividido en líneas: \($1)" },
        splitAlertTitle: { "El bloque \($0) tiene tomas: \($1)" },
        splitAlertBody: "Para dividir el bloque en frases, las tomas se moverán a la Papelera.",
        splitAlertConfirm: "Eliminar tomas y dividir",
        noSampleScript: "No se encontró el guion de ejemplo. Abre un proyecto o importa JSON/XLSX",
        audioNotCreated: "El archivo de audio no se creó. Cancela esta toma y comprueba el micrófono",
        errBadAudioName: "Nombre de archivo de audio no válido",
        errSymlinks: "No se admiten enlaces simbólicos a archivos de audio",
        errOutsideProject: "El archivo de audio está fuera del proyecto",
        errFinishPreviousSave: "Termina primero de guardar la grabación anterior",
        errDuplicateTakes: "El manifest contiene tomas o nombres de archivo duplicados",
        errNoFolderAccess: "Sin acceso a la carpeta del proyecto",
        errProjectAlreadyOpen: "Este proyecto ya está abierto en otra ventana o instancia de la app",
        errScriptEmpty: "El guion está vacío",
        errBlockIDs: "Los identificadores de bloque deben ser únicos y no vacíos",
        errBlockNoText: { "El bloque \($0) no contiene texto" },
        blockError: { "Bloque \($0): \($1)" },
        errDuplicateLineID: { "Identificador de línea duplicado: \($0)" },
        markerPreamble: "No se permite texto antes del primer marcador",
        markerInvalid: "Marcador [voice:...] inválido o vacío",
        markerUnique: "Los marcadores deben ser únicos",
        markerMismatch: "Los marcadores de los textos ruso e inglés no coinciden",
        splitOneSentence: { "El bloque \($0) tiene una sola frase, no hace falta dividir" },
        splitMismatch: { "Bloque \($0): \($1) frases en ruso y \($2) en inglés. Divide manualmente con marcadores [voice:...]" },
        xlsxTemplate: "Se espera la plantilla XLSX: encabezados en la fila 1, texto ruso en D, inglés en E",
        xlsxTooBig: "La hoja XLSX es demasiado grande (límite de 16 MB XML)",
        errAlreadyRecording: "Ya se está grabando", errMicNoStart: "El micrófono no inició la grabación",
        errFinishRecording: "Termina primero la grabación", errPlayback: "No se pudo reproducir la toma",
        errStoppedByDevice: "La grabación fue detenida por el dispositivo",
        errInterrupted: "El dispositivo interrumpió la grabación; comprueba el audio guardado",
        errAudioEncode: "Error de grabación de audio"
    )

    static let fr = Strings(
        cancel: "Annuler", cancelRecording: "Annuler", save: "Enregistrer", retrySave: "Réessayer l'enregistrement",
        delete: "Supprimer", deleteRecording: "Supprimer l'enregistrement",
        searchPlaceholder: "Rechercher dans le script", showProject: "Afficher le projet", editingToggle: "Montage",
        openProject: "Ouvrir un projet", importScript: "Importer un script",
        voicedProgress: { "\($0) blocs sur \($1) enregistrés" },
        formatSpec: "WAV · mono · 48 kHz", recordNextLine: "Enregistrer la réplique suivante",
        colStatus: "STATUT", colAudioFiles: "FICHIERS AUDIO",
        statusRecording: "Enregistrement", statusApproved: "Validé", statusInProgress: "En cours",
        statusHasTakes: "Prises disponibles", statusNotRecorded: "Non enregistré", statusMarkerError: "Erreur de balisage",
        recordingNow: "Enregistrement", hasTake: "Prise enregistrée", onTimeline: "Sur la timeline",
        checkInPremiere: "Vérifier dans Premiere", recordThisLine: "Enregistrer cette réplique",
        takeN: { "Prise \($0)" }, markBest: "Choisir comme meilleure", markBestRecording: "Choisir comme meilleure",
        playTakeN: { "Écouter la prise \($0)" }, chooseTakeN: { "Choisir la prise \($0)" },
        newTake: "Nouvelle prise", playRecording: "Écouter l'enregistrement", play: "Écouter",
        copyText: "Copier le texte", splitIntoSentences: "Diviser en phrases",
        audioFilesA11y: "Fichiers audio", recordingA11y: { "Enregistrement, \($0)" },
        stopDeleteHelp: "Arrêter et supprimer cet enregistrement",
        interfaceLanguage: "Langue de l'interface", cellText: "Texte des cellules", showFullText: "Tout afficher",
        maxLines: { "\($0) lignes maximum" },
        cellTextHint: "Le texte s'adapte à la largeur actuelle de la colonne. Faites glisser le bord de l'en-tête pour la modifier.",
        readyToRecord: "Prêt à enregistrer", projectOpened: "Projet ouvert",
        missingAudio: { "Fichiers audio manquants : \($0). Restaurez-les depuis une sauvegarde" },
        myScript: "Mon script", scriptNBlocks: { "Script · \($0) blocs" },
        finishRecordingFirst: "Terminez d'abord l'enregistrement ou la sauvegarde",
        openPanelHint: "Choisissez un dossier contenant scenario.json, manifest.json et Recordings",
        importPanelHint: "Créer un projet séparé depuis JSON ou XLSX. Les enregistrements existants sont conservés",
        projectCreated: "Projet séparé créé. Le dossier est accessible via « Afficher le projet »",
        allowMicrophone: "Autorisez le micro dans Réglages Système",
        recordingInProgress: "Enregistrement…", takeSaved: "Prise enregistrée", recordingCancelled: "Enregistrement annulé",
        bestTakeSelected: "Meilleure prise sélectionnée", takeMovedToTrash: "Prise déplacée dans la Corbeille",
        waitForOperation: "Attendez la fin de l'opération", couldNotSaveTake: "Impossible d'enregistrer la prise",
        checkFolderAccess: "Vérifiez l'accès au dossier du projet et réessayez.",
        error: { "Erreur : \($0)" },
        fixMarkupFirst: { "Bloc \($0) : corrigez d'abord le balisage [voice:...]" },
        blockSplit: { "Bloc \($0) divisé en répliques : \($1)" },
        splitAlertTitle: { "Le bloc \($0) a des prises : \($1)" },
        splitAlertBody: "Pour diviser le bloc en phrases, les prises seront déplacées dans la Corbeille.",
        splitAlertConfirm: "Supprimer les prises et diviser",
        noSampleScript: "Exemple de script introuvable. Ouvrez un projet ou importez JSON/XLSX",
        audioNotCreated: "Le fichier audio n'a pas été créé. Annulez cette prise et vérifiez le micro",
        errBadAudioName: "Nom de fichier audio invalide",
        errSymlinks: "Les liens symboliques vers les fichiers audio ne sont pas pris en charge",
        errOutsideProject: "Le fichier audio est en dehors du projet",
        errFinishPreviousSave: "Terminez d'abord la sauvegarde de l'enregistrement précédent",
        errDuplicateTakes: "Le manifeste contient des prises ou des noms de fichiers en double",
        errNoFolderAccess: "Pas d'accès au dossier du projet",
        errProjectAlreadyOpen: "Ce projet est déjà ouvert dans une autre fenêtre ou instance de l'app",
        errScriptEmpty: "Le script est vide",
        errBlockIDs: "Les identifiants de blocs doivent être non vides et uniques",
        errBlockNoText: { "Le bloc \($0) ne contient pas de texte" },
        blockError: { "Bloc \($0) : \($1)" },
        errDuplicateLineID: { "Identifiant de réplique en double : \($0)" },
        markerPreamble: "Le texte avant le premier marqueur n'est pas autorisé",
        markerInvalid: "Marqueur [voice:...] invalide ou vide",
        markerUnique: "Les marqueurs doivent être uniques",
        markerMismatch: "Les marqueurs des textes russe et anglais ne correspondent pas",
        splitOneSentence: { "Le bloc \($0) contient une seule phrase, rien à diviser" },
        splitMismatch: { "Bloc \($0) : \($1) phrases en russe, \($2) en anglais. Divisez manuellement avec des marqueurs [voice:...]" },
        xlsxTemplate: "Modèle XLSX attendu : en-têtes en ligne 1, texte russe en colonne D, anglais en colonne E",
        xlsxTooBig: "La feuille XLSX est trop grande (limite de 16 Mo XML)",
        errAlreadyRecording: "Enregistrement déjà en cours", errMicNoStart: "Le micro n'a pas démarré l'enregistrement",
        errFinishRecording: "Terminez d'abord l'enregistrement", errPlayback: "Impossible de lire la prise",
        errStoppedByDevice: "L'enregistrement a été arrêté par l'appareil",
        errInterrupted: "L'appareil a interrompu l'enregistrement ; vérifiez l'audio sauvegardé",
        errAudioEncode: "Erreur d'enregistrement audio"
    )
}
