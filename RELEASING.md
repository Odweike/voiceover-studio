# Releasing Voiceover Studio

## Prepare

1. Update the version/build number in `Info.plist`.
2. Update the versioned download links in both READMEs and on the download page.
3. Run `swift test` and the manual checklist in `CONTRIBUTING.md`.
4. Run `./tools/package-dmg.sh` with full Xcode selected.

This builds both `arm64` and `x86_64`, validates the bundle and creates:

- `build/Voiceover-Studio-<version>-universal.dmg`
- `build/SHA256SUMS.txt`

The DMG contains the app, a link to Applications, the MIT license and bilingual installation instructions. `hdiutil verify` and architecture checks run during packaging. Test on both types of Mac before claiming both were tested.

## Publish

Commit the source, create a version tag, push it, then create a GitHub Release with the DMG and checksum. For example, replace `<version>` with the release version:

```sh
git tag -a v<version> -m "Voiceover Studio <version>"
git push origin main --tags
gh release create v<version> --verify-tag \
  "build/Voiceover-Studio-<version>-universal.dmg" build/SHA256SUMS.txt \
  --title "Voiceover Studio <version>" --notes-file release-notes.md
```

Use notes that describe the actual changes, compatibility and remaining limitations. Keep the release's assets and source tag aligned. Do not upload the entire development directory; ignored working spreadsheets, recordings and backups are private local materials.

## Signing

The default build is ad-hoc signed, **not notarized**. The download page and release notes must state this. Public binaries can be signed/notarized with your own Developer ID certificate and Apple's distribution tools when that identity is available. Do not use an Apple Development certificate as a substitute for Developer ID distribution signing. Never commit signing credentials.

## Website

The download page is published with Sites; its public URL is linked in both READMEs and the repository's About section. The page's source is mirrored under `website/` for open-source access; the deployment-specific hosting manifest is not part of that mirror. Release assets are served by GitHub Releases.
