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
