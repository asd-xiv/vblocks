---
name: write-vblocks-app
description: |
  Writes, serves and builds a React app with @asd14/vblocks: zero-config
  builds, as a static site or a single HTML file. Use when the User wants to
  create a React app or build a React page into one HTML file, or when the
  project's package.json has @asd14/vblocks.
metadata:
  version: "0.1.0"
---

VBlocks builds and serves a React app with zero config, as a static site or a
single HTML file. VBlocks is not Vite or Next.js

## Features

<!-- sh41: copied from the features at the top of README.md. Update both
together -->

- An app needs only `src/index.tsx` and `src/index.html`
- VBlocks supports SWC, PostCSS, CSS Modules, MDX, React Refresh and `.env`
  files
- Several apps can share one `package.json` and `node_modules/`
- In development, the Agentation toolbar sends UI annotations to an agent

## TL;DR

- Scaffold an app, from the template `plain`, `xyflow` or `xyflow-tabs`:\
  `npx @asd14/vblocks init {{path/to/app}} --template {{plain}}`
- Add VBlocks to an existing project, with `react` and `react-dom` 18 or 19:\
  `npm install --save-dev @asd14/vblocks`
- Start the development server, at `http://localhost:8080` or the next free
  port. It opens the browser:\
  `npx vblocks serve`
- Start it on a port, without the browser. Webpack takes each option after
  `--`:\
  `npx vblocks serve -- --port {{8099}} --no-open`
- Start the server of one app, in a project folder that contains several:\
  `npx vblocks serve --prefix {{path/to/app}}`
- Build the production bundle into `dist/`:\
  `npx vblocks build`
- Build one standalone `dist/index.html`, every asset inlined:\
  `npx vblocks build --single-file`
- Typecheck. SWC strips the types without checking them:\
  `npx tsc --noEmit`
- Import from the app's `src/` through `@self`, a path alias, not a package:\
  `import { {{Button}} } from "@self/{{components/button.tsx}}"`
- Read a variable of the `.env` in the app folder:\
  `process.env["{{NAME}}"]`
- Import a file as text:\
  `import {{text}} from "{{./note.txt}}?raw"`

## Conventions

- Never write a Webpack, PostCSS or SWC config. `vblocks eject` prints a
  default, for the rare app that must replace it
- `src/index.tsx` mounts the app. Each `src/index.<concern>.tsx` defines one
  concern of it, eg. `index.app.tsx` defines App

## References

Paths are relative to the package root: the VBlocks repo, or
`node_modules/@asd14/vblocks/` in an app.

**`README.md`**, 470 lines:

- "### Keep several apps in one project" L:119-162
- "### Use `.env` variables" L:164-188
- "### Import from `src/` with `@self`" L:190-211
- "### Use CSS Modules" L:213-238
- "### Import a file as text" L:240-251
- "### Pick the browsers" L:253-270
- "### Replace a default config" L:272-302
- "### Style with Tailwind" L:304-360
- "### Send UI annotations to an AI agent" L:362-380
- "### Open the page from another device" L:382-389
- "### Build a single HTML file" L:391-402
- "### Add VBlocks to an existing project" L:404-441

**`docs/REFERENCE.md`**, 322 lines:

- "## Domain Vocabulary" L:19-27
- "### `vblocks`" L:31-69
- "### `vblocks init`" L:71-123
- "### `vblocks serve`" L:125-182
- "### `vblocks build`" L:184-257
- "### `vblocks eject`" L:259-297
- "## Templates" L:299-314
- "## Environment variables" L:316-322

**`template/_common/README.md`**, 49 lines:

- "## Plumbing" L:9-25
- "## App" L:27-49

**Each template**:

- `template/plain/README.md`, 19 lines
- `template/xyflow/README.md`, 28 lines
- `template/xyflow-tabs/README.md`, 33 lines

**Decisions**:

- `docs/DECISIONS.md`, 4 lines: one link per decision in `docs/decisions/`
