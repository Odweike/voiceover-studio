# Contributing

Use macOS 14.4+ and Swift 6+. Open `Package.swift` in Xcode or use the command line.

Before sending a pull request:

```sh
swift test
./build.sh
python3 tools/check.py
```

Add regression tests for changes to recording identity, deletion, imports or persistence. Keep the app dependency-free unless a concrete feature justifies a dependency.

Manual audio check, using a disposable project:

1. Allow/deny microphone permission and check the message.
2. Record, save, listen, pause and resume.
3. Make three takes, delete the middle one, record again, and verify the retained audio.
4. During recording, try selecting another row and importing/opening a project; the recording must stay attached to its original line.
5. Cancel a take, then quit during another take and reopen the project.
6. Import another script with the same row numbers; it must have no old takes.
7. Test an unavailable input device and a project folder that becomes unwritable.

Tests use temporary folders and do not request microphone permission. Real microphone/device behavior must also be checked manually before a binary release.

Do not commit local recordings, working spreadsheets, build products, `.local-backup`, `.artifact`, or `outputs`. The ignored legacy workbook helpers are personal tooling and are not part of the app.
