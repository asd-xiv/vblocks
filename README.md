[![Release](https://github.com/asd-xiv/vblocks/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/asd-xiv/vblocks/actions/workflows/main.yml)
[![npm version](https://img.shields.io/npm/v/@asd14/vblocks.svg)](https://www.npmjs.com/package/@asd14/vblocks)

# @asd14/vblocks

> 📜 POSIX + 📦 Webpack, an unlikely story!

- **Minimal configs** - Needs only `src/index.tsx` and `src/index.html`
- **Built in** - SWC, PostCSS (CSS Modules configured), MDX, React Refresh,
  Dotenv, bundle analyzer

## Table of contents

<!-- vim-markdown-toc GFM -->

- [Installation](#installation)
  - [Peer Dependencies](#peer-dependencies)
- [Quick Start](#quick-start)
  - [Several apps in one project](#several-apps-in-one-project)
- [Configuration](#configuration)
- [Commands](#commands)
  - [`vblocks init`](#vblocks-init)
  - [`vblocks serve`](#vblocks-serve)
  - [`vblocks build`](#vblocks-build)
  - [`vblocks eject`](#vblocks-eject)
- [Details](#details)
  - [TypeScript](#typescript)
  - [PostCSS](#postcss)
  - [CSS Modules Support](#css-modules-support)
  - [Asset Handling](#asset-handling)
  - [Environment Variables](#environment-variables)
  - [Path Alias](#path-alias)
- [How It Works](#how-it-works)
- [FAQ](#faq)
  - [Does VBlocks support Tailwind?](#does-vblocks-support-tailwind)
- [License](#license)

<!-- vim-markdown-toc -->

## Installation

```sh
npm install --save-dev @asd14/vblocks
```

> [!IMPORTANT]  
> VBlocks needs Node `^22.22.3`, `^24.15.0` or `>=26.0`.

### Peer Dependencies

```sh
npm install react react-dom
```

> [!IMPORTANT]  
> VBlocks needs React `^18` or `^19`.

## Quick Start

Create a project and start the dev server:

```sh
npx @asd14/vblocks init my-vblocks-app
cd my-vblocks-app
npm install
npm start
```

```text
my-vblocks-app/
├── src/
│   ├── index.tsx     # Application entry point
│   ├── index.html    # HTML template
│   └── index.css     # Global CSS
├── .gitignore        # Minimal set
├── tsconfig.json     # TypeScript config for React
└── package.json      # Scripts and dependencies (react, react-dom)
```

Run a command in a project that has VBlocks installed:

```sh
# Start the dev server
npx vblocks serve

# Build for production
npx vblocks build

# Save the default Webpack config in your project root
npx vblocks eject webpack > webpack.config.js
```

### Several apps in one project

Several apps, eg. demos, can share one `package.json` and one `node_modules`.
Add the project once, then each app in its own app folder:

```sh
npx @asd14/vblocks init demos --only plumbing
npx @asd14/vblocks init demos/flow --template xyflow --only app
cd demos
npm install
npm start -- --prefix flow
```

```text
demos/
├── flow/
│   ├── src/
│   ├── postcss.config.js
│   └── tsconfig.json
├── .gitignore
└── package.json      # The dependencies of every app
```

## Configuration

A config in your app folder replaces the default of the same name. The app
folder holds `src/`. It is the folder passed to [`--prefix`](#vblocks-build), or
the current folder without it. In a single-app project, the app folder is also
the project root, the folder with `package.json`.

- `webpack.config.js`
- `postcss.config.js`
- `.swcrc`

To replace a default, first [`eject`](#vblocks-eject) it into your app folder,
then edit the file:

```sh
npx vblocks eject postcss > postcss.config.js
```

> [!NOTE]  
> VBlocks does not merge your config with the default, with two exceptions:
>
> - `.swcrc -> env.targets`: VBlocks adds the default when yours is missing
> - `.swcrc -> jsc.transform.react.refresh`: VBlocks adds the React Refresh
>   transform when `serve` runs in `development` mode

## Commands

### `vblocks init`

```text
vblocks init <directory> [--template <name>] [--only <app|plumbing>]
```

Writes a template's project files, app files, or both into `<directory>`.

| Parameter                | Required | Default | Description                                                                                                                                                                                                                                         |
| ------------------------ | -------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `<directory>`            | yes      | none    | The folder to write into. It must be missing or empty                                                                                                                                                                                               |
| `--template <name>`      | no       | `plain` | `plain`, or `xyflow` with React Flow and Tailwind                                                                                                                                                                                                   |
| `--only <app\|plumbing>` | no       | both    | `plumbing` writes the project files: `package.json`, `.gitignore`. `app` writes the app files: `src/`, `tsconfig.json` and the template's configs. With `app`, the template adds its dependencies to the nearest `package.json` above `<directory>` |

**Example**:

```sh
npx @asd14/vblocks init my-vblock-flow --template xyflow
cd my-vblock-flow
npm install
```

### `vblocks serve`

Starts a React Refresh enabled development server.

- Runs at `http://localhost:8080`, auto-opens in browser
- Runs bundle analyzer at `http://127.0.0.1:8888`

```text
vblocks serve [--mode <mode>] [--prefix <directory>] [<webpack option>...]
```

| Parameter              | Required | Default            | Description                                                                                                 |
| ---------------------- | -------- | ------------------ | ----------------------------------------------------------------------------------------------------------- |
| `--mode <mode>`        | no       | `development`      | The Webpack mode, `development` or `production`                                                             |
| `--prefix <directory>` | no       | the current folder | The [app folder](#configuration), relative to the current folder                                            |
| `<webpack option>`     | no       | none               | Any other [`webpack serve`](https://webpack.js.org/api/cli/) option. VBlocks passes it to Webpack unchanged |

**Example**:

```sh
cd my-vblock-flow
vblocks serve
#        ↓↓↓
# npx webpack serve --config <webpack config> \
#   --env entryDir=<app folder> \
#   --mode development
```

### `vblocks build`

```text
vblocks build [--mode <mode>] [--env single] [--prefix <directory>] [<webpack option>...]
```

Builds the app into `dist/` in the app folder.

| Parameter              | Required | Default            | Description                                                                                                                            |
| ---------------------- | -------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------- |
| `--mode <mode>`        | no       | `production`       | The Webpack mode, `development` or `production`. The build minifies JS, CSS and HTML only in `production`                              |
| `--env single`         | no       | off                | Build one standalone `dist/index.html`                                                                                                 |
| `--prefix <directory>` | no       | the current folder | The [app folder](#configuration), relative to the current folder                                                                       |
| `<webpack option>`     | no       | none               | Any other [`webpack build`](https://webpack.js.org/api/cli/) option, eg. `--stats errors-only`. VBlocks passes it to Webpack unchanged |

Without `--env single`, the build:

- Writes JS and CSS files with content-hashed names
- Writes a `react` chunk, and a `vendors` chunk when your other dependencies
  total over 20 KB

With `--env single`:

- `dist/index.html` holds every script, stylesheet, image, font and the favicon
- A browser opens the file from disk, with no server and no network
- Keep the route in the URL hash. On `file://`, `history.pushState` to another
  path throws

**Runs**:

```sh
npx webpack build --config <webpack config> \
  --env entryDir=<app folder> \
  --mode production \
  [...your arguments]
```

### `vblocks eject`

```text
vblocks eject <config>
```

Prints a default config to stdout.

| Parameter  | Required | Default | Description                                        |
| ---------- | -------- | ------- | -------------------------------------------------- |
| `<config>` | yes      | none    | The config to print: `webpack`, `postcss` or `swc` |

Save the output in your app folder to [replace the default](#configuration):

```sh
npx vblocks eject webpack > webpack.config.js
npx vblocks eject postcss > postcss.config.js
npx vblocks eject swc > .swcrc
```

## Details

### TypeScript

VBlocks does not check types and never reads your `tsconfig.json`. It only
compiles TypeScript with SWC.

For convenience, VBlocks provides client types in
[`client.d.ts`](src/types/client.d.ts) for:

- `.css` imports
- Image and font imports
- `process.env`

You can use them in your `tsconfig.json`:

```json
{
  "compilerOptions": {
    "types": ["@asd14/vblocks/client"]
  }
}
```

`tsc` needs the [`@self`](#path-alias) path alias in your `tsconfig.json`:

```diff
{
  "compilerOptions": {
    "types": ["@asd14/vblocks/client"],
+   "paths": { "@self/*": ["./src/*"] }
  }
}
```

The `tsconfig.json` that [`vblocks init`](#vblocks-init) writes has both.

### PostCSS

The default `postcss.config.js`:

```js
/**
 * @param {{ mode: "production" | "development" | "none" }} api
 */
export default ({ mode }) => ({
  plugins: {
    "postcss-preset-env": {
      stage: 2,
    },
    "cssnano": mode === "production" && {
      preset: "default",
    },
  },
})
```

> [!NOTE]  
> `postcss-preset-env` compiles nesting, `oklch()` and `color-mix()` for older
> browsers and adds vendor prefixes.

### CSS Modules Support

- **Global CSS** - `import "./styles.css"`
- **Local CSS Modules** - `import styles from "./component.module.css"`
- **camelCase exports** - `.my-class` becomes `styles.myClass`
- **Class names** - a bare hash in `production` mode, `[local]__[hash]` in
  `development` mode
- **TypeScript** - the [client types](#typescript) declare `.css` imports

### Asset Handling

- **Images** - the build inlines `jpg`, `gif`, `png` and `svg` files up to 10 KB
- **Fonts** - the build writes `woff`, `woff2`, `ttf` and `eot` files to
  `dist/fonts/`
- **Favicon and `robots.txt`** - yours or the default. `--env single` leaves
  `robots.txt` out

### Environment Variables

VBlocks loads the `.env` file in your app folder:

```env
API_URL=https://api.example.com
```

Read a variable in your code:

```tsx
const apiUrl = process.env["API_URL"]
```

Webpack replaces each `process.env` read with the variable's value. A variable
that `.env` does not set reads as `undefined`. The build leaves out every
variable your code does not read.

The [client types](#typescript) declare `process.env` and nothing else from
Node, because Webpack replaces nothing else. With the client types, `tsc` fails
on `process.cwd()` and `Buffer`.

### Path Alias

`@self` points at your `src/` directory:

```tsx
// Instead of: import { Component } from "../../../components"
import { Component } from "@self/components"
```

`tsc` needs the same alias in your `tsconfig.json`. See
[TypeScript](#typescript).

## How It Works

VBlocks is a POSIX shell script that runs Webpack. The script exports
`VB_POSTCSS_CONFIG` and `VB_SWC_CONFIG`, the paths of the configs it picked. The
Webpack config reads them.

## FAQ

### Does VBlocks support Tailwind?

Yes, VBlocks supports Tailwind but does not include it, so you need a
`postcss.config.js` in your app folder.

1. Install Tailwind and the Tailwind plugin for PostCSS:

```sh
npm install --save-dev tailwindcss @tailwindcss/postcss
```

2. Eject the default PostCSS config into your app folder:

```sh
npx vblocks eject postcss > postcss.config.js
```

3. Replace `postcss-preset-env` with the Tailwind plugin:

```diff
 export default ({ mode }) => ({
   plugins: {
-    "postcss-preset-env": {
-      stage: 2,
-    },
+    "@tailwindcss/postcss": {
+      optimize: mode === "production",
+    },
     "cssnano": mode === "production" && {
       preset: "default",
     },
   },
 })
```

> [!IMPORTANT]  
> You do not need `postcss-preset-env`. Tailwind 4
> [compiles nesting and adds vendor prefixes](https://tailwindcss.com/docs/compatibility)
> itself. With both plugins, `postcss-preset-env` rewrites Tailwind's `@layer`
> rules into `:not(#\#)` selectors. The CSS file grows.

4. Add this import to `src/index.css`:

```css
@import "tailwindcss" source(".");
```

`source(".")` limits Tailwind's class scan to the folder of the CSS file,
`src/`. Without it, Tailwind scans the folder Webpack runs in. With
[`--prefix`](#vblocks-build), Webpack runs in the project root, which holds
every app. Each app's CSS then also gets the classes of the other apps.

The `xyflow` template of [`vblocks init`](#vblocks-init) has this setup.

## License

MIT
