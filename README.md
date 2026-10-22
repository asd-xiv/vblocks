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
SWC, PostCSS, CSS Modules, MDX, React Refresh, Dotenv

<!--
PARKED until SSG is finished, then name both outputs: SPA and SSG.

**📄 Static website**
Builds to `dist/`, for any static host
-->

**📦 Several apps, one install**  
Apps share one `package.json` and `node_modules/`. A new app reuses the
installed packages

**🤖 Optimized for AI agents**  
The agent's context holds only the app: no Webpack, PostCSS or TypeScript config
to write, read or fix

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
- [References](#references)
  - [Commands](#commands)
    - [`vblocks init`](#vblocks-init)
    - [`vblocks serve`](#vblocks-serve)
    - [`vblocks build`](#vblocks-build)
    - [`vblocks eject`](#vblocks-eject)
  - [Templates](#templates)
    - [`plain`](#plain)
    - [`xyflow`](#xyflow)
    - [`xyflow-tabs`](#xyflow-tabs)
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

Each section is one Diátaxis type (https://diataxis.fr):
- Quick Start -> Tutorial
- How to -> How-to guides
- Vocabulary, Commands and Templates -> Reference
-->

## Quick Start

<!--
Using "scaffold", the field's word for what `init` does, eg. Yeoman and
create-vite use it.

Using the `my-vblocks-` prefix, the package name, so a reader who tries several
scaffolders spots the folder at a glance, as with `vite-project` and
`nuxt-app`.
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
   + │   ├─ src/          # the files of the xyflow template
   + │   ├─ postcss.config.js
   + │   └─ tsconfig.json
     ├─ .gitignore
   ! └─ package.json      # + @xyflow/react, tailwindcss, @tailwindcss/postcss, cssnano
   ```

3. **Start a development server for one app**

   ```sh
   npx vblocks serve --prefix flow-diagram
   ```

## Vocabulary

<!--
Keep Vocabulary after Quick Start since the reader has no context to place
the definitions in.
-->

| Term               | Means                                                         |
| :----------------- | :------------------------------------------------------------ |
| **Plumbing**       | The project files `init` writes: `package.json`, `.gitignore` |
| **Project folder** | The folder with `package.json`                                |
| **App folder**     | The folder with `src/index.tsx` and `src/index.html`          |
| **Bundle**         | The files `build` writes to `dist/`                           |

## How to

<!--
Each ### names a pain as the task that relieves it. Order the guides by how
early the Quick Start reader has the pain.
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
`undefined` when `.env` does not set it. Webpack leaves out of the bundle every
variable your code does not read.

> [!WARNING]  
> Never expose a secret, eg. an API key, through `process.env`. Anyone who loads
> the page can read it.

> [!NOTE]  
> The [client types](types/client.d.ts) declare `process.env` and nothing else
> from Node, because Webpack replaces nothing else.

### Stop using `../../../` everywhere

VBlocks resolves `@self` to the `src/` of your app folder:

```tsx
// Instead of: import { Component } from "../../../components"
import { Component } from "@self/components"
```

> [!NOTE]  
> VBlocks compiles TypeScript with SWC and does not typecheck. Run `tsc`
> yourself. Your `tsconfig.json` needs the same alias as Webpack.  
> The `tsconfig.json` that [`vblocks init`](#vblocks-init) writes already has
> it. Otherwise, add:
>
> ```diff
>  {
>    "compilerOptions": {
> +    "paths": { "@self/*": ["./src/*"] }
>    }
>  }
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

- **camelCase keys** - `.primary-button` becomes `styles.primaryButton`
- **Class names** - a bare hash in `production` mode, `[local]__[hash]` in
  `development` mode

> [!NOTE]  
> The [client types](types/client.d.ts) declare `.css`, image and font imports.

### Replace a default config

Each config in your app folder replaces the default of the same name:

- `webpack.config.js`
- `postcss.config.js`
  - `postcss-preset-env`, which compiles nesting, `oklch()` and `color-mix()`
    for older browsers and adds vendor prefixes
  - `cssnano` in `production`
- `.swcrc`
  - browser targets `> 0.25%, not dead`

1. **[Eject](#vblocks-eject) the default into your app folder**

   ```sh
   cd flow-diagram
   npx vblocks eject swc > .swcrc
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
> The `xyflow` and `xyflow-tabs` templates of [`vblocks init`](#vblocks-init)
> have this setup.

1. **Install Tailwind, the Tailwind plugin for PostCSS and cssnano, which the
   ejected config imports**

   ```sh
   npm install --save-dev tailwindcss @tailwindcss/postcss cssnano
   ```

2. **Eject the default PostCSS config into your app folder**

   ```sh
   npx vblocks eject postcss > postcss.config.js
   ```

3. **Replace `postcss-preset-env` with the Tailwind plugin**

   ```diff
   +import tailwindcss from "@tailwindcss/postcss"
    import cssnano from "cssnano"
   -import postcssPresetEnv from "postcss-preset-env"

    export default ({ mode }) => ({
      plugins: [
   -    postcssPresetEnv({ stage: 2 }),
   +    tailwindcss({ optimize: mode === "production" }),
        ...(mode === "production" ? [cssnano({ preset: "default" })] : []),
      ],
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

2. **Add the [client types](types/client.d.ts) and the
   [`@self`](#stop-using--everywhere) alias to your `tsconfig.json`**

   ```diff
    {
      "compilerOptions": {
   +    "types": ["@asd14/vblocks/client"],
   +    "paths": { "@self/*": ["./src/*"] }
      }
    }
   ```

3. **Ensure `index.tsx` and `index.html` are in `src/`**

> [!NOTE]  
> VBlocks builds `dist/index.html` from `src/index.html` and adds the script and
> stylesheet tags to it. Drop the tag that loads your entry, eg. Vite's
> `<script type="module" src="/src/main.tsx"></script>`.

4. **Start a development server**

   ```sh
   npx vblocks serve
   ```

## References

### Commands

Each command prints its own help with `--help`, eg. `npx vblocks serve --help`.

#### `vblocks init`

Write a template's plumbing, app, or both into `<directory>`.

```text
vblocks init <directory>
  [--template <plain|xyflow|xyflow-tabs>]
  [--only <app|plumbing>]
```

- `<directory>`
  - The folder to write into. It must be missing or empty
- `--template` (default: `plain`)
  - The template to write, see [Templates](#templates)
- `--only` (default: both)
  - Write one part of the template
  - `plumbing`: `package.json`, `.gitignore`
  - `app`: `src/`, `tsconfig.json` and the template's configs. `init` adds the
    template's dependencies to the `package.json` of the
    [project folder](#vocabulary), the parent of `<directory>`. Without a
    `package.json` there, `init` fails

#### `vblocks serve`

Start the development server.

- Runs at `http://localhost:8080`, or the next free port
- Listens on `localhost`, so another device on your network, eg. a phone, cannot
  open the page
- Opens the page in the browser

```text
vblocks serve
  [--mode <development|production>]
  [--prefix <directory>]
  [--analyze]
  [--log-level <error|warn|info|verbose>]
  [-- <webpack option>...]
```

- `--mode` (default: `development`)
  - The Webpack mode
  - React Refresh runs only in `development`
- `--prefix` (default: the current folder)
  - The [app folder](#vocabulary), which must exist
- `--analyze`
  - Run the bundle analyzer, on a free port
- `--log-level` (default: `warn`)
  - How much Webpack and its development server print
- `-- <webpack option>...`
  - Any [`webpack serve`](https://webpack.js.org/api/cli/) option
  - `serve` passes each one to Webpack unchanged
  - eg. `-- --host 0.0.0.0`, to listen on the network

#### `vblocks build`

Build the app into a bundle in the `dist/` of the app folder.

By default, `build`:

- Writes JS and CSS files with content-hashed names
- Writes a `react` chunk, and a `vendors` chunk when your other dependencies
  total over 20 KB (10 KB in `development`)
- Inlines `jpg`, `gif`, `png` and `svg` files up to 10 KB
- Writes larger images to `dist/` with content-hashed names
- Writes `woff`, `woff2`, `ttf` and `eot` files to `dist/fonts/`
- Copies `src/public/favicon.svg` and `src/public/robots.txt` of your app, or
  the defaults of VBlocks

```text
vblocks build
  [--mode <development|production>]
  [--prefix <directory>]
  [--single-file|--single]
  [--log-level <error|warn|info|verbose>]
  [-- <webpack option>...]
```

- `--mode` (default: `production`)
  - The Webpack mode
  - In `production`, `build` minifies JS, HTML and, with the default PostCSS
    config, CSS
- `--prefix` (default: the current folder)
  - The [app folder](#vocabulary), which must exist
- `--single-file|--single`
  - Write one standalone `dist/index.html`, every asset inlined
  - A browser opens the file from disk, with no server and no network
  - The bundle has no `robots.txt`
  - Keep the route in the URL hash
    - On `file://`, `history.pushState` to another path throws
- `--log-level` (default: `warn`)
  - How much Webpack prints
- `-- <webpack option>...`
  - Any [`webpack build`](https://webpack.js.org/api/cli/) option
  - `build` passes each one to Webpack unchanged
  - eg. `-- --devtool source-map`, to write source maps

#### `vblocks eject`

Print a default config to stdout.

```text
vblocks eject <webpack|postcss|swc>
```

- `<webpack|postcss|swc>`
  - The config to print

Run it in your app folder and save the output there, to
[replace the default](#replace-a-default-config):

```sh
npx vblocks eject webpack > webpack.config.js
npx vblocks eject postcss > postcss.config.js
npx vblocks eject swc > .swcrc
```

An ejected config loads its plugins and loaders from your project. Install them
in the project folder, eg. `postcss-preset-env` and `cssnano` for the PostCSS
config.

### Templates

All templates scaffold `src/index.html`, `src/index.css` and `tsconfig.json`.

#### `plain`

"Hello World!" in `src/index.tsx`.

- Adds no packages

#### `xyflow`

One diagram, and a details panel for the selected node or edge.

- Adds `@xyflow/react`, `tailwindcss`, `@tailwindcss/postcss` and `cssnano` to
  the `package.json` of the project folder
- Writes a `postcss.config.js` that configures Tailwind

```text
src/
├── index.tsx           # the layout: header, diagram, details panel, the selected id
├── diagram.tsx         # the nodes and edges, placed and sized in grid cells
├── details.tsx         # the panel for the selected node or edge
└── utils/grid.ts       # CELL_SIZE and toPixels
```

#### `xyflow-tabs`

One tab per diagram, each with its own details panel.

- Adds the same packages and `postcss.config.js` as `xyflow`

```text
src/
├── index.tsx              # the layout: header, tab bar, details panel, the selected id
├── pages/
│   ├── build/
│   │   ├── diagram.tsx    # the nodes and edges of one tab, in grid cells
│   │   └── details.tsx    # the panel for its selected node or edge
│   └── serve/             # the same two files
├── ui/zoom-level.tsx      # the zoom level, and a Reset to 100%
└── utils/grid.ts          # CELL_SIZE and toPixels
```

## License

MIT
