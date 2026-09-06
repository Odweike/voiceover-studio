#!/usr/bin/env python3
"""Verify the distributable app bundle; behavior is covered by swift test."""
import json
import plistlib
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
app = root / "build/Voiceover Studio.app"
contents = app / "Contents"
blocks = json.loads((contents / "Resources/scenario.json").read_text(encoding="utf-8"))
assert blocks and all({"id", "number", "russian", "english"} <= b.keys() for b in blocks)
assert len({b["id"] for b in blocks}) == len(blocks)
assert (contents / "MacOS/Voiceover Studio").is_file()
with (contents / "Info.plist").open("rb") as stream:
    info = plistlib.load(stream)
assert info["LSMinimumSystemVersion"] == "14.4"
assert info["NSMicrophoneUsageDescription"]
assert info["CFBundleIconFile"] == "AppIcon"
assert (contents / "Resources/AppIcon.icns").is_file()
assert (contents / "Resources/scenario.json").read_bytes() == (root / "Resources/scenario.json").read_bytes()
subprocess.run(["codesign", "--verify", "--strict", str(app)], check=True)
print("Voiceover Studio bundle check passed")
