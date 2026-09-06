# Download page

Source for the bilingual Voiceover Studio download page. The live page is linked from the main README. The primary page and DMG are hosted at https://playrito.site/voiceOver/. GitHub Releases also keeps a copy of each DMG.

```sh
npm ci
npm run dev
```

Requires Node.js 22.13+. `npm run lint`, `npx tsc --noEmit` and `npm run build` validate the site. The shared UI components are generated Shadcn components; app-specific lint checks exclude the unmodified component catalog.

This mirror intentionally omits the live Sites project ID. Register your own Sites project if deploying a fork; the checked-in hosting configuration contains no private service bindings. Update the GitHub repository, download URL and site metadata for a fork.

The application screenshot shows an isolated demonstration project, not private recordings. App icon and screenshot are included locally. Onest is supplied through `next/font/google` and served locally by the resulting build.

## Self-hosted static page

```sh
npm ci
npm run build:self-hosted
```

The complete static page is generated in `dist/client/voiceOver/`, including HTML, JavaScript, CSS, images and locally served fonts. Publish only that directory. No Node.js process is required on the server. Place the release DMG and `SHA256SUMS.txt` in its `downloads/` subdirectory before publishing.

The public path is case-sensitive: `/voiceOver/`. `/voiceOver` redirects to it. Update `basePath` in `next.config.ts`, the download URL in `app/page.tsx` and metadata in `app/layout.tsx` when changing the destination.

On the production server, files live under `/var/www/voiceover-studio/releases/`, and `/var/www/voiceover-studio/current` points at the active release. The domain's HTTPS server block contains:

```nginx
location = /voiceOver {
    return 301 /voiceOver/;
}
location ^~ /voiceOver/ {
    alias /var/www/voiceover-studio/current/;
    index index.html;
    autoindex off;
}
```

For an update, upload a complete release to a new directory, verify its files and checksums, then atomically replace the `current` symlink. Keep the previous release to permit rollback. This directory is separate from the main Playrito site's document root.
