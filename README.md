[![Release](https://github.com/asd-xiv/vblocks/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/asd-xiv/vblocks/actions/workflows/main.yml)
[![npm version](https://img.shields.io/npm/v/@asd14/vblocks.svg)](https://www.npmjs.com/package/@asd14/vblocks)

# @asd14/vblocks

> Zero-config React builds, as a static site or a single HTML file

**✂️ Zero config**  
Needs only `src/index.tsx` and `src/index.html`

<!--
Using "Maximal support" to answer "Zero config" above: nothing to set up, and
everything set up.
-->

**🔋 Maximal support**  
SWC, PostCSS (CSS Modules configured), MDX, React Refresh, Dotenv

<!--
PARKED until SSG is finished, then name both outputs: SPA and SSG.

**📄 Static website**
Builds to `dist/`, for any static host
-->

**📦 Several apps, one install**  
Apps share one `package.json` and `node_modules/`, a new app reuses the
installed packages

**🤖 Optimized for AI agents**  
No config to write, so an agent spends its tokens on the content, not on the
setup

> [!IMPORTANT]  
> VBlocks needs Node `^22.22.3`, `^24.15.0` or `>=26.0`.

## Table of contents

<!-- vim-markdown-toc GFM -->

- [Quick Start](#quick-start)
  - [Several apps in one project](#several-apps-in-one-project)
- [Vocabulary](#vocabulary)
- [How to](#how-to)
  - [Use environment variables](#use-environment-variables)
  - [Stop using `../../../` everywhere](#stop-using--everywhere)
  - [Use CSS Modules](#use-css-modules)
  - [Replace a default config](#replace-a-default-config)
  - [Style with Tailwind](#style-with-tailwind)
  - [Add VBlocks to an existing project](#add-vblocks-to-an-existing-project)
- [Commands](#commands)
  - [`vblocks init`](#vblocks-init)
  - [`vblocks serve`](#vblocks-serve)
  - [`vblocks build`](#vblocks-build)
  - [`vblocks eject`](#vblocks-eject)
- [License](#license)

<!-- vim-markdown-toc -->

<!--
Order this README by three principles. Each settles one decision:

- **Pain relief**, the order of sections. The section that relieves the most
  pain for the least reading comes first
- **Progressive disclosure**, the depth of a section. A section uses only what
  the sections above it showed
- **Colocation**, the place of a fact. A caveat sits on the step or option it
  limits, in a NOTE when it is tangential or points at another section

Each section is one Diátaxis type (https://diataxis.fr): Quick Start is a
tutorial, How to is how-to guides, Vocabulary and Commands are reference.
-->

## Quick Start

<!--
Diátaxis: tutorial. The fewest steps to a working build. It shows enough of
VBlocks for the reader to decide whether VBlocks fits their project.
-->

<!--
Using "scaffold", the field's word for what `init` does, eg. Yeoman and
create-vite use it.
-->

1. **Scaffold a minimal React project**

   ```sh
   npx @asd14/vblocks init my-vblocks-app
   cd my-vblocks-app
   npm install
   ```

   ```text
   my-vblocks-app/
    ├─ src/
    │    ├─ index.tsx
    │    ├─ index.html
    │    └─ index.css
    ├─ .gitignore
    ├─ tsconfig.json
    └─ package.json      # react, react-dom and the vblocks scripts
   ```

2. **Start a development server**

   ```sh
   npx vblocks serve
   ```

3. **Build**

   ```sh
   npx vblocks build               # production bundle in dist/
   npx vblocks build --single-file # one dist/index.html, every asset inlined
   ```

### Several apps in one project

Several apps, eg. demos or MVP sketches, can share one `package.json` and one
`node_modules/`:

1. **Add the plumbing**

   ```sh
   npx @asd14/vblocks init sketches --only plumbing
   ```

   ```text
   sketches/
    ├─ .gitignore
    └─ package.json
   ```

2. **Add an app**

   ```sh
   npx @asd14/vblocks init sketches/flow-diagram --template xyflow --only app
   cd sketches
   npm install
   ```

   ```diff
    sketches/
   + ├─ flow-diagram/
   + │   ├─ src/
   + │   │   ├─ index.tsx
   + │   │   ├─ index.html
   + │   │   └─ index.css
   + │   ├─ postcss.config.js
   + │   └─ tsconfig.json
     ├─ .gitignore
   ! └─ package.json      # + @xyflow/react, tailwindcss, @tailwindcss/postcss
   ```

3. **Start a development server for one app**

   ```sh
   npx vblocks serve --prefix flow-diagram
   ```

## Vocabulary

<!--
Vocabulary follows Quick Start. The reader sees the terms used, then reads
their definitions. How to is the first section that assumes the reader knows
them.
-->

| Term               | Means                                                         |
| :----------------- | :------------------------------------------------------------ |
| **Project folder** | The folder with `package.json`                                |
| **App folder**     | The folder with `src/index.tsx` and `src/index.html`          |
| **Plumbing**       | The project files `init` writes: `package.json`, `.gitignore` |

## How to

<!--
Diátaxis: how-to. Each ### names a pain as the task that relieves it. Order
the guides by how early the Quick Start reader has the pain. A guide for
another reader, eg. one with an existing app, goes last.
-->

### Use environment variables

1. **Add a `.env` file to your app folder**

   ```env
   API_URL=https://api.example.com
   ```

2. **Read the variable in your code**

   ```tsx
   const apiUrl = process.env["API_URL"]
   ```

Webpack replaces each `process.env["NAME"]` with the value of `NAME`, and
`undefined` when `.env` does not set it. The build leaves out every variable
your code does not read.

> [!WARNING]  
> Never expose a secret, eg. an API key, through `process.env`. Anyone who loads
> the page can read it.

> [!NOTE]  
> The [client types](src/types/client.d.ts) declare `process.env` and nothing
> else from Node, because Webpack replaces nothing else. With the client types,
> `tsc` fails on `process.cwd()` and `Buffer`.

### Stop using `../../../` everywhere

VBlocks resolves `@self` to the `src/` of your app folder:

```tsx
// Instead of: import { Component } from "../../../components"
import { Component } from "@self/components"
```

> [!NOTE]  
> VBlocks never reads your `tsconfig.json`, so `tsc` needs the alias too. The
> one scaffolded by [`vblocks init`](#vblocks-init) already has it. Otherwise,
> add:
>
> ```json
> {
>   "compilerOptions": {
>     "paths": { "@self/*": ["./src/*"] }
>   }
> }
> ```

### Use CSS Modules

1. **Name the file `*.module.css`**

   ```css
   /* src/button.module.css */
   .primary-button {
     color: tomato;
   }
   ```

2. **Import it as an object**

   ```tsx
   /* src/button.tsx */
   import styles from "./button.module.css"

   export const Button = () => <button className={styles.primaryButton} />
   ```

- **camelCase exports** - `.primary-button` becomes `styles.primaryButton`
- **Class names** - a bare hash in `production` mode, `[local]__[hash]` in
  `development` mode
- **Global CSS** - a file without `.module` stays global,
  `import "./styles.css"`

> [!NOTE]  
> The [client types](src/types/client.d.ts) declare `.css` imports.

### Replace a default config

Each of these configs in your app folder replaces the default of the same name:

- `webpack.config.js`
- `postcss.config.js`
- `.swcrc`

1. **[Eject](#vblocks-eject) the default into your app folder**

   ```sh
   npx vblocks eject postcss > flow-diagram/postcss.config.js
   ```

2. **Update the ejected file**

> [!NOTE]  
> VBlocks does not merge your config with the default, with two exceptions:
>
> - `.swcrc -> env.targets`: VBlocks adds the default when yours is missing
> - `.swcrc -> jsc.transform.react.refresh`: VBlocks adds the React Refresh
>   transform when `serve` runs in `development` mode

### Style with Tailwind

VBlocks does not include Tailwind. Add it through a `postcss.config.js` in your
app folder:

> [!NOTE]  
> The `xyflow` template of [`vblocks init`](#vblocks-init) has this setup.

1. **Install Tailwind and the Tailwind plugin for PostCSS**

   ```sh
   npm install --save-dev tailwindcss @tailwindcss/postcss
   ```

2. **Eject the default PostCSS config into your app folder**

   ```sh
   npx vblocks eject postcss > postcss.config.js
   ```

3. **Replace `postcss-preset-env` with the Tailwind plugin**

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
> Tailwind 4
> [compiles nesting and adds vendor prefixes](https://tailwindcss.com/docs/compatibility)
> itself. With both plugins, `postcss-preset-env` rewrites Tailwind's `@layer`
> rules into `:not(#\#)` selectors. The CSS file grows.

4. **Add the Tailwind import to `src/index.css`**

   ```css
   @import "tailwindcss" source(".");
   ```

   `source(".")` limits Tailwind's class scan to the folder of the CSS file,
   `src/`.

> [!NOTE]  
> Without `source(".")`, Tailwind scans the current folder. With
> [`--prefix`](#vblocks-build), you run VBlocks from the project folder, which
> holds every app. Each app's CSS then also gets the classes of the other apps.

### Add VBlocks to an existing project

1. **Install VBlocks**

   ```sh
   npm install --save-dev @asd14/vblocks    # needs react and react-dom ^18 or ^19
   ```

2. **Ensure `index.tsx` and `index.html` are in `src/`**

> [!NOTE]  
> VBlocks builds `dist/index.html` from `src/index.html` and adds the script and
> stylesheet tags to it. Drop the tag that loads your entry, eg. Vite's
> `<script type="module" src="/src/main.tsx"></script>`.

3. **Start a development server**

   ```sh
   npx vblocks serve
   ```

## Commands

<!--
Diátaxis: reference. Mirror SYNOPSIS and OPTIONS of `vblocks --help`, in the
same words. Each option and operand is a term, a line break, then its
description, like OPTIONS in a man page.
-->

### `vblocks init`

Write a template's plumbing, app, or both into `<directory>`.

```text
vblocks init <directory> [--template <name>] [--only <app|plumbing>]
```

- `<directory>`\
  The folder to write into. It must be missing or empty
- `--template <name>`\
  `plain`, or `xyflow` with React Flow and Tailwind (default: `plain`)
- `--only <app|plumbing>`\
  Write one part of the template (default: both)
  - `plumbing`: `package.json`, `.gitignore`
  - `app`: `src/`, `tsconfig.json` and the template's configs. `init` adds the
    template's dependencies to the nearest `package.json` above `<directory>`.
    Without one, `init` fails

**Example**:

<!--
Using the `my-vblock-` prefix, so a reader who tries several scaffolders spots
the folder at a glance, as with `vite-project` and `nuxt-app`.
-->

```sh
npx @asd14/vblocks init my-vblock-flow --template xyflow
cd my-vblock-flow
npm install
```

### `vblocks serve`

Start the development server.

- The server runs at `http://localhost:8080`. It opens the page in the browser
- The bundle analyzer runs at `http://127.0.0.1:8888`

```text
vblocks serve [--mode <mode>] [--prefix <directory>] [<webpack option>...]
```

- `--mode <mode>`\
  The Webpack mode, `development` or `production` (default: `development`).
  React Refresh runs only in `development`
- `--prefix <directory>`\
  The [app folder](#vocabulary), which must exist (default: the current folder)
- `<webpack option>`\
  Any other [`webpack serve`](https://webpack.js.org/api/cli/) option. VBlocks
  passes it to Webpack unchanged

**Example**:

```sh
cd my-vblock-flow
npx vblocks serve
#        ↓↓↓
# npx webpack serve --config <webpack config> \
#   --env entryDir=<app folder> \
#   --mode development \
#   ...
```

### `vblocks build`

Build the app into `dist/` in the app folder. Without `--single-file`, the
build:

- Writes JS and CSS files with content-hashed names
- Writes a `react` chunk, and a `vendors` chunk when your other dependencies
  total over 20 KB (10 KB in `development`)

```text
vblocks build [--mode <mode>] [--prefix <directory>] [--single-file] [<webpack option>...]
```

- `--mode <mode>`\
  The Webpack mode, `development` or `production` (default: `production`). In
  `production`, the build minifies JS and HTML, and cssnano, in the default
  PostCSS config, minifies CSS
- `--prefix <directory>`\
  The [app folder](#vocabulary), which must exist (default: the current folder)
- `--single-file`\
  The build writes one standalone `dist/index.html`, every asset inlined
  - A browser opens the file from disk, with no server and no network
  - The build leaves `robots.txt` out
  - Keep the route in the URL hash. On `file://`, `history.pushState` to another
    path throws
- `<webpack option>`\
  Any other [`webpack build`](https://webpack.js.org/api/cli/) option, eg.
  `--stats errors-only`. VBlocks passes it to Webpack unchanged

**Example**:

```sh
cd my-vblock-flow
npx vblocks build
#        ↓↓↓
# npx webpack build --config <webpack config> \
#   --env entryDir=<app folder> \
#   --mode production \
#   ...
```

### `vblocks eject`

Print a default config to stdout.

```text
vblocks eject <webpack|postcss|swc>
```

- `<webpack|postcss|swc>`\
  The config to print

Save the output in your app folder to
[replace the default](#replace-a-default-config):

```sh
npx vblocks eject webpack > webpack.config.js
npx vblocks eject postcss > postcss.config.js
npx vblocks eject swc > .swcrc
```

<!--
PARKED: sort each fact below into an existing section or a new one, or drop
it. The client types and the PostCSS default have no home yet.

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

    > [!NOTE]
    > The `tsconfig.json` that [`vblocks init`](#vblocks-init) writes has the client
    > types and the [`@self`](#stop-using--everywhere) alias.

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

    ### Asset Handling

    - **Images** - the build inlines `jpg`, `gif`, `png` and `svg` files up to 10 KB
    - **Fonts** - the build writes `woff`, `woff2`, `ttf` and `eot` files to
      `dist/fonts/`
    - **Favicon and `robots.txt`** - yours or the default. With `--single-file`, the
      build inlines the favicon and leaves `robots.txt` out

    ## How It Works

    VBlocks is a POSIX shell script that runs Webpack. The script exports
    `VB_POSTCSS_CONFIG` and `VB_SWC_CONFIG`, the paths of the configs it picked. The
    Webpack config reads them.
-->

## License

MIT
