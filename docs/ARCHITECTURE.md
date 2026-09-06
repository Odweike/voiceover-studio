# Architecture and project storage


Projects are stored under `~/Movies/Voiceover Studio/Projects/`:

```text
Scenario-<UUID>/
  scenario.json
  manifest.json
  Recordings/
    <take-UUID>.wav
```

`manifest.json` contains each take's UUID, recording ID (`blockID`), file name, ISO 8601 creation date and best-take flag (`selected`). With markers, `blockID` is `voice:<marker>`; otherwise it is the script block's ID. UUID file names stay unique after deletions.

A temporary `pending-take.json` journal is written before recording. If saving fails, the WAV and journal remain and the app offers **Повторить сохранение**. Reopening the project recovers an existing pending WAV exactly once. An interrupted WAV may need inspection or repair; recovery preserves the file, it does not guarantee valid audio after a crash or disk failure.

The original personal-app layout (`scenario.json`, `manifest.json`, `Recordings` directly in `~/Movies/Voiceover Studio`) is opened in place when no saved project exists. No automatic rewrite or deletion of old recordings is performed. Close older versions before opening the same project with this version. Invalid manifests are reported instead of being replaced with empty data.

One project can be opened by one instance at a time. A `.voiceover.lock` file is expected and can remain after quitting. The OS releases its lock automatically.

Back up the entire project folder. Missing files are reported; the app cannot reconstruct deleted audio. There is no automatic Premiere integration, Excel write-back, audio trimming, or cloud sync. WAV files can be imported manually into an editor.

## Architecture

- `Models.swift`: script, markers, take metadata and validation.
- `XLSXReader.swift`: bounded ZIP/XML import using the system `unzip` and Foundation.
- `ProjectStore.swift`: project files, atomic manifest writes and recovery journal.
- `ProjectLease.swift`: exclusive project ownership between app instances.
- `AudioController.swift`: recording, playback and metering on the main actor.
- `Studio.swift`: user actions, project selection and visible application state.
- `StudioView.swift`: SwiftUI components; live meters observe audio state directly.
- `App.swift`: one application window and save-on-quit handling.

No database, dependency-injection framework or third-party runtime libraries are required. Swift 6 concurrency checking is enabled. XLSX parsing runs off the UI actor; small JSON writes are synchronous so UI state changes only after a successful commit.

For an isolated development launch, set `VOICEOVER_STUDIO_DATA_DIR` to a temporary directory when launching the executable inside the built `.app`. Project selection is remembered separately for each data directory.
