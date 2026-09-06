#!/bin/zsh
set -euo pipefail
project_dir=${0:A:h:h}
cd "$project_dir"
./build.sh --universal
python3 tools/check.py
lipo 'build/Voiceover Studio.app/Contents/MacOS/Voiceover Studio' -verify_arch arm64 x86_64
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)
stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/voiceover-dmg.XXXXXX")
trap 'rm -rf "$stage_dir"' EXIT
ditto 'build/Voiceover Studio.app' "$stage_dir/Voiceover Studio.app"
ln -s /Applications "$stage_dir/Applications"
cp docs/INSTALL.txt "$stage_dir/READ ME FIRST.txt"
cp LICENSE "$stage_dir/LICENSE.txt"
image_path="$project_dir/build/Voiceover-Studio-${version}-universal.dmg"
hdiutil create -volname 'Voiceover Studio' -srcfolder "$stage_dir" -format UDZO -ov "$image_path"
hdiutil verify "$image_path"
(cd build && shasum -a 256 "${image_path:t}" > SHA256SUMS.txt)
echo "$image_path"
