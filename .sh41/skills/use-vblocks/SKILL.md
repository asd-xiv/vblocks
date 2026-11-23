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
  - To change part of a config, import it from `@asd14/vblocks/postcss` or
    `@asd14/vblocks/webpack` in a config of the same name in the app folder,
    change it, and return it
  - For an advanced use, eg. a micro-frontend, eject the default with
    `vblocks eject` and edit the copy
- Put each concern that `src/index.tsx` imports in its own
  `src/index.<concern>.tsx`, eg. `index.app.tsx` defines `App`

## Index

<!-- sh41: scripts/get-skill-index-lines --write, in the write-sh41-skill skill,
recomputes the lines and the counts after each edit of the docs -->

Paths are relative to the package root: the VBlocks repo, or
`node_modules/@asd14/vblocks/` in the project folder.

**`README.md`**, 614 lines:

- "## Quick Start" L:72-120
- "### Keep several apps in one project" L:124-167
- "### Use `.env` variables" L:169-193
- "### Import from `src/` with `@self`" L:195-216
- "### Use CSS Modules" L:218-243
- "### Import a file as text" L:245-256
- "### Write a page in Markdown or MDX" L:258-321
  - "#### `code` meta as props" L:275-321
- "### Pick the browsers" L:323-340
- "### Replace a config" L:342-379
- "### Extend a config" L:381-440
  - "#### PostCSS" L:388-420
  - "#### Webpack" L:422-440
- "### Style with Tailwind" L:442-497
- "### Send UI annotations to an AI agent" L:499-517
- "### Open the page from another device" L:519-526
- "### Build a single HTML file" L:528-539
- "### Add VBlocks to an existing project" L:541-578
- "## More docs" L:580-589
- "## Develop" L:591-610

**`docs/REFERENCE.md`**, 605 lines:

- "## Domain Vocabulary" L:27-35
- "### `vblocks`" L:39-75
- "### `vblocks init`" L:77-129
- "### `vblocks serve`" L:131-189
- "### `vblocks build`" L:191-264
- "### `vblocks eject`" L:266-304
- "### `webpack.config.js`" L:314-354
- "### `postcss.config.js`" L:356-409
- "### `.swcrc`" L:411-461
- "### `.browserslistrc`" L:463-483
- "### `@asd14/vblocks/postcss`" L:489-526
- "### `@asd14/vblocks/webpack`" L:528-580
- "## Templates" L:582-597
- "## Environment variables" L:599-605

**`template/`**:

- **`_common/README.md`**, 49 lines:
  - "## Plumbing" L:9-25
  - "## App" L:27-49
- **`plain/README.md`**, 19 lines
- **`xyflow/README.md`**, 27 lines
- **`xyflow-tabs/README.md`**, 32 lines

**`docs/decisions/`**:

- `01.resolve-dependency-vblocks-folder.md`, 43 lines
- `02.read-browserslist-config.md`, 36 lines
- `03.pass-code-meta-as-props.md`, 44 lines

**`types/`**:

- `client.d.ts`, 145 lines
