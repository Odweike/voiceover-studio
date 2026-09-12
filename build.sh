#!/bin/zsh
set -euo pipefail
project_dir=${0:A:h}
cd "$project_dir"
# SwiftPM fixes the deployment target and enables Swift 6 concurrency checking.
build_args=(-c release)
if [[ "${1:-}" == "--universal" ]]; then
  build_args+=(--arch arm64 --arch x86_64)
fi
swift build "${build_args[@]}"
bin_dir=$(swift build "${build_args[@]}" --show-bin-path)
app_dir="$project_dir/build/Voiceover Studio.app"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$bin_dir/VoiceoverStudio" "$app_dir/Contents/MacOS/Voiceover Studio"
cp Info.plist "$app_dir/Contents/Info.plist"
cp Resources/AppIcon.icns "$app_dir/Contents/Resources/AppIcon.icns"
cp Resources/scenario.json "$app_dir/Contents/Resources/scenario.json"
codesign --force --sign - "$app_dir"
echo "$app_dir"

# Keep exactly one installed copy, always the freshest build.
target="$HOME/Applications/Voiceover Studio.app"
if pgrep -f "/Voiceover Studio.app/Contents/MacOS/" >/dev/null; then
  # Graceful quit lets the app save a pending take before we replace the bundle.
  osascript -e 'tell application "Voiceover Studio" to quit' >/dev/null 2>&1 || true
  for _ in {1..50}; do
    pgrep -f "/Voiceover Studio.app/Contents/MacOS/" >/dev/null || break
    sleep 0.1
  done
fi
if pgrep -f "/Voiceover Studio.app/Contents/MacOS/" >/dev/null; then
  echo "Voiceover Studio ещё запущен — закрой его и повтори сборку" >&2
  exit 1
fi
rm -rf "$target"
ditto "$app_dir" "$target"
# Replacing the bundle in place leaves LaunchServices with a stale icon; re-register.
touch "$target"
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f "$target" >/dev/null 2>&1 || true
echo "Установлена свежая версия: $target"
