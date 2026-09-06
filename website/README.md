# Download page

Source for the bilingual Voiceover Studio download page. The live page is linked from the main README. Downloads are hosted in GitHub Releases.

```sh
npm ci
npm run dev
```

Requires Node.js 22.13+. `npm run lint`, `npx tsc --noEmit` and `npm run build` validate the site. The shared UI components are generated Shadcn components; app-specific lint checks exclude the unmodified component catalog.

This mirror intentionally omits the live Sites project ID. Register your own Sites project if deploying a fork; the checked-in hosting configuration contains no private service bindings. Update the GitHub repository, download URL and site metadata for a fork.

The application screenshot shows an isolated demonstration project, not private recordings. App icon and screenshot are included locally. Onest is supplied through `next/font/google` and served locally by the resulting build.
