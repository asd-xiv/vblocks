---
name: use-vblocks
description: |
  Writes, serves and builds a React app with @asd14/vblocks. Use when the User
  wants to create a React app or build a React page into one HTML file, or when
  the project's package.json has @asd14/vblocks.
metadata:
  version: "0.1.0"
---

VBlocks is a zero-config React bundler, like Create React App or Parcel. It
builds and serves an SPA (single-page application), as a folder or a single HTML
file. It has no SSR (server-side rendering) or SSG (static site generation), as
Next.js does.

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
  `npx tsc`
- Import from the app's `src/` through `@self`, a path alias, not a package:\
  `import { {{Button}} } from "@self/{{components/button.tsx}}"`
- Read a variable of the `.env` in the app folder:\
  `process.env["{{NAME}}"]`
- Import a file as text:\
  `import {{text}} from "{{./note.txt}}?raw"`
- Import a Markdown or MDX file as a component:\
  `import {{Intro}} from "{{./intro.mdx}}"`

## Conventions

- Write no Webpack, PostCSS or SWC config. The defaults cover a React app
  - For an advanced use, eg. a micro-frontend, eject the default with
    `vblocks eject` and edit the copy
- Put each concern that `src/index.tsx` imports in its own
  `src/index.<concern>.tsx`, eg. `index.app.tsx` defines `App`

## Index

<!-- sh41: tools/get-skill-index-lines --write recomputes the lines and the
counts after each edit of the docs -->

Paths are relative to the package root: the VBlocks repo, or
`node_modules/@asd14/vblocks/` in the project folder.

**`README.md`**, 544 lines:

- "## Quick Start" L:69-117
- "### Keep several apps in one project" L:121-164
- "### Use `.env` variables" L:166-190
- "### Import from `src/` with `@self`" L:192-213
- "### Use CSS Modules" L:215-240
- "### Import a file as text" L:242-253
- "### Write a page in Markdown or MDX" L:255-318
  - "#### `code` meta as props" L:272-318
- "### Pick the browsers" L:320-337
- "### Replace a default config" L:339-369
- "### Style with Tailwind" L:371-427
- "### Send UI annotations to an AI agent" L:429-447
- "### Open the page from another device" L:449-456
- "### Build a single HTML file" L:458-469
- "### Add VBlocks to an existing project" L:471-508
- "## More docs" L:510-519
- "## Develop" L:521-540

**`docs/REFERENCE.md`**, 321 lines:

- "## Domain Vocabulary" L:19-27
- "### `vblocks`" L:31-67
- "### `vblocks init`" L:69-121
- "### `vblocks serve`" L:123-181
- "### `vblocks build`" L:183-256
- "### `vblocks eject`" L:258-296
- "## Templates" L:298-313
- "## Environment variables" L:315-321

**`template/`**:

- **`_common/README.md`**, 49 lines:
  - "## Plumbing" L:9-25
  - "## App" L:27-49
- **`plain/README.md`**, 19 lines
- **`xyflow/README.md`**, 28 lines
- **`xyflow-tabs/README.md`**, 33 lines

**`docs/decisions/`**:

- `01.resolve-dependency-vblocks-folder.md`, 43 lines
- `02.read-browserslist-config.md`, 36 lines
- `03.pass-code-meta-as-props.md`, 44 lines

**`types/`**:

- `client.d.ts`, 145 lines
