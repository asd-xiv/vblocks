[![Release](https://github.com/asd-xiv/vblocks/actions/workflows/release.yml/badge.svg?branch=main)](https://github.com/asd-xiv/vblocks/actions/workflows/release.yml)
[![npm version](https://img.shields.io/npm/v/@asd14/vblocks.svg)](https://www.npmjs.com/package/@asd14/vblocks)

# @asd14/vblocks

> 📜 POSIX + 📦 Webpack, an unlikely story!

VBlocks runs Webpack for React single-page applications with default Webpack,
PostCSS and SWC configs. A project needs no config of its own.

## Features

- **No configs** - a project builds from `src/index.tsx` and `src/index.html`
  alone
- **Loaders** - SWC for TypeScript, PostCSS, CSS Modules, MDX
- **Your config replaces the default** - see [Configuration](#configuration)
- **`serve`** - Hot Module Replacement, React Refresh, bundle analyzer
- **`build`** - minified output, a separate `react` chunk, content-hashed JS and
  CSS file names, or one standalone HTML file

<!-- vim-markdown-toc GFM -->

- [Installation](#installation)
  - [Peer Dependencies](#peer-dependencies)
- [Usage](#usage)
  - [Quick Start](#quick-start)
  - [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Commands](#commands)
  - [`vblocks serve`](#vblocks-serve)
  - [`vblocks build`](#vblocks-build)
  - [`vblocks eject`](#vblocks-eject)
- [Features in Detail](#features-in-detail)
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
> VBlocks needs Node 24 or later.

### Peer Dependencies

VBlocks needs React 18 or 19 in your project:

```sh
npm install react react-dom
```

## Usage

### Quick Start

```sh
# Start the dev server
npx vblocks serve

# Build for production
npx vblocks build

# Print the default Webpack config
npx vblocks eject webpack
```

### Project Structure

VBlocks reads `src/` and `.env`, and writes `dist/`:

```text
your-project/
├── src/
│   ├── index.tsx          # Application entry point
│   ├── index.html         # HTML template
│   ├── index.css          # Global CSS, optional
│   └── public/
│       ├── favicon.svg    # Optional, VBlocks has a default
│       └── robots.txt     # Optional, VBlocks has a default
├── .env                   # Optional
└── dist/                  # Build output
```

## Configuration

A config in your project root replaces the default of the same name.

- `webpack.config.js`
- `postcss.config.js`
- `.swcrc`

To replace a default, first [`eject`](#vblocks-eject) it into your project root,
then edit the file:

```sh
npx vblocks eject postcss > postcss.config.js
```

> [!NOTE]  
> VBlocks does not merge your config with the default, with two exceptions:
>
> - `.swcrc -> env.targets`: VBlocks adds the default when yours has none
> - `.swcrc -> jsc.transform.react.refresh`: VBlocks adds the React Refresh
>   transform when `serve` runs in `development` mode

## Commands

### `vblocks serve`

```text
vblocks serve [--mode <mode>] [<webpack option>...]
```

Starts the dev server. Without `--port`, it listens on `http://localhost:8080`.

| Parameter          | Required | Default       | Description                                                                                                                                                    |
| ------------------ | -------- | ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--mode <mode>`    | no       | `development` | The Webpack mode, `development` or `production`. React Refresh runs only in `development`                                                                      |
| `<webpack option>` | no       | none          | Any other [`webpack serve`](https://webpack.js.org/configuration/dev-server/) option, eg. `--port 3000` or `--no-open`. VBlocks passes it to Webpack unchanged |

The dev server:

- Replaces changed modules without a page reload, with Hot Module Replacement
  and React Refresh
- Opens the browser
- Runs the bundle analyzer at `http://127.0.0.1:8888`. VBlocks does not open it
  in the browser
- Serves `index.html` for every unknown path, for applications that use the
  History API

**Runs**:

```sh
npx webpack serve --config <webpack config> \
  --env entryDir=<project root> \
  --mode development \
  [...your arguments]
```

### `vblocks build`

```text
vblocks build [--mode <mode>] [--env single] [<webpack option>...]
```

Builds the project into `dist/`.

| Parameter          | Required | Default      | Description                                                                                                                            |
| ------------------ | -------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------- |
| `--mode <mode>`    | no       | `production` | The Webpack mode, `development` or `production`. The build minifies JS, CSS and HTML only in `production`                              |
| `--env single`     | no       | off          | Build one standalone `dist/index.html`                                                                                                 |
| `<webpack option>` | no       | none         | Any other [`webpack build`](https://webpack.js.org/api/cli/) option, eg. `--stats errors-only`. VBlocks passes it to Webpack unchanged |

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
  --env entryDir=<project root> \
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

Save the output in your project root to [replace the default](#configuration):

```sh
npx vblocks eject webpack > webpack.config.js
npx vblocks eject postcss > postcss.config.js
npx vblocks eject swc > .swcrc
```

## Features in Detail

### TypeScript

VBlocks does not check types or configure TypeScript. It only compiles it with
SWC.

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

`postcss-preset-env` compiles nesting, `oklch()` and `color-mix()` for older
browsers and adds vendor prefixes.

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

VBlocks loads the `.env` file in your project root:

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
`postcss.config.js` in your project root.

1. Install Tailwind and the Tailwind plugin for PostCSS:

```sh
npm install --save-dev tailwindcss @tailwindcss/postcss
```

2. Eject the default PostCSS config into your project root:

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
> `postcss-preset-env` is not needed and conflict with Tailwind 4's built-in CSS
> transforms. See
> [Tailwind's upgrade guide](https://tailwindcss.com/docs/upgrade-guide) for
> details.

4. Add this import to `src/index.css`:

```css
@import "tailwindcss";
```

## License

MIT
