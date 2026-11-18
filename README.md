[![Release](https://github.com/asd-xiv/vblocks/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/asd-xiv/vblocks/actions/workflows/main.yml)
[![npm version](https://img.shields.io/npm/v/@asd14/vblocks.svg)](https://www.npmjs.com/package/@asd14/vblocks)

# @asd14/vblocks

> Zero-config React builds of an SPA (single-page application), as a folder or a
> single HTML file

VBlocks is a zero-config React bundler, like Create React App or Parcel. It has
no SSR (server-side rendering) or SSG (static site generation), as Next.js does.

**✂️ Zero config**

- Needs only `src/index.tsx` and `src/index.html`

<!--
Using "Maximal support" to pair with "Zero config" above: nothing to set up, and
everything set up.
-->

**🔋 Maximal support**

- SWC, PostCSS, CSS Modules, MDX, React Refresh, `.env` files

**📦 Several apps, one install**

- Apps share one `package.json` and `node_modules/`. A new app reuses the
  installed packages

**🤖 Built for AI agents**

- **[`write-vblocks-app`](.sh41/skills/write-vblocks-app/SKILL.md) skill**:
  teaches an agent to write, serve and build a VBlocks app
- **[Agentation](https://www.agentation.com) in development**: click an element
  and write what to change. The agent gets the annotation with the element's
  selector, text and React components
- **Small context**:
  - By default, the agent does not write, read or fix a Webpack, PostCSS or SWC
    config
  - VBlocks shows you color, icons and a header in a terminal. When an agent
    runs VBlocks, it gets the same facts without them

## Table of contents

<!-- vim-markdown-toc GFM -->

- [Quick Start](#quick-start)
- [How to](#how-to)
  - [Keep several apps in one project](#keep-several-apps-in-one-project)
  - [Use `.env` variables](#use-env-variables)
  - [Import from `src/` with `@self`](#import-from-src-with-self)
  - [Use CSS Modules](#use-css-modules)
  - [Import a file as text](#import-a-file-as-text)
  - [Write a page in Markdown or MDX](#write-a-page-in-markdown-or-mdx)
  - [Pick the browsers](#pick-the-browsers)
  - [Replace a default config](#replace-a-default-config)
  - [Style with Tailwind](#style-with-tailwind)
  - [Send UI annotations to an AI agent](#send-ui-annotations-to-an-ai-agent)
  - [Open the page from another device](#open-the-page-from-another-device)
  - [Build a single HTML file](#build-a-single-html-file)
  - [Add VBlocks to an existing project](#add-vblocks-to-an-existing-project)
- [More docs](#more-docs)
- [Develop](#develop)
- [License](#license)

<!-- vim-markdown-toc -->

## Quick Start

> [!IMPORTANT]\
> VBlocks needs Node `^22.22.3`, `^24.15.0` or `>=26.0`.

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
    │    ├─ index.tsx       # mounts App, and the Agentation toolbar in development
    │    ├─ index.app.tsx   # App, your code starts here
    │    ├─ index.html
    │    └─ index.css
    ├─ .env.example
    ├─ .gitignore
    ├─ tsconfig.json
    └─ package.json      # react, react-dom, agentation and the vblocks scripts
   ```

2. **Start a development server**

   ```sh
   npx vblocks serve
   ```

   The server runs at `http://localhost:8080`, or the next free port. It opens
   the page in the browser.

3. **Build**

   ```sh
   npx vblocks build # production bundle in dist/
   ```

## How to

### Keep several apps in one project

Several apps, eg. demos or MVP sketches, can share one `package.json` and one
`node_modules/`. The [project folder](docs/REFERENCE.md#domain-vocabulary)
contains the plumbing, and each
[app folder](docs/REFERENCE.md#domain-vocabulary) contains one app:

1. **Create the project folder**

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
   + │   ├─ .env.example
   + │   ├─ postcss.config.js
   + │   └─ tsconfig.json
     ├─ .gitignore
   ! └─ package.json      # + @xyflow/react, tailwindcss, @tailwindcss/postcss,
   !                      # cssnano, agentation
   ```

3. **Start a development server for one app**

   ```sh
   npx vblocks serve --prefix flow-diagram
   ```

### Use `.env` variables

1. **Create a `.env` file in your app folder**

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

> [!WARNING]\
> Never expose a secret, eg. an API key, through `process.env`. Anyone who loads
> the page can read it.

> [!NOTE]\
> The [client types](types/client.d.ts) declare only `process.env`. The browser
> has no other part of Node's `process`.

### Import from `src/` with `@self`

VBlocks resolves `@self` to the `src/` of your app folder:

```tsx
// Instead of: import { Button } from "../../../components/button.tsx"
import { Button } from "@self/components/button.tsx"
```

> [!NOTE]\
> VBlocks compiles TypeScript with SWC and does not typecheck. Run `tsc`
> yourself. Your `tsconfig.json` needs the same alias as Webpack.  
> The `tsconfig.json` that [`vblocks init`](docs/REFERENCE.md#vblocks-init)
> writes already has it. Otherwise, add:
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

   export const Button = () => <button className={styles["primaryButton"]} />
   ```

Each class name is a bare hash in `production` mode, and `[local]__[hash]` in
`development` mode.

> [!NOTE]\
> The [client types](types/client.d.ts) declare each `*.module.css` import as an
> object of class names.

### Import a file as text

Add `?raw` to the import path, as in Vite:

```tsx
import greeting from "./greeting.txt?raw"
// greeting => "Hello from a text file\n"
```

> [!NOTE]\
> The [client types](types/client.d.ts) declare each `?raw` import as a
> `string`.

### Write a page in Markdown or MDX

Import an `.md` or `.mdx` file as a React component:

```tsx
import Intro from "./intro.mdx"

const App = () => <Intro />
```

Pass `components` to replace the element MDX renders for a tag, eg. each `#`
heading:

```tsx
<Intro components={{ h1: Title }} />
```

> [!NOTE]\
> The [client types](types/client.d.ts) declare each `.md` and `.mdx` import as
> a React component.

### Pick the browsers

SWC, Webpack and `postcss-preset-env` compile for the browsers of the app's
browserslist config, from the app folder up:

- a `.browserslistrc`
- or the `browserslist` field of `package.json`

Without one, they compile for the VBlocks default, `> 0.25%, not dead`.

1. **Eject the default into your app folder**

   ```sh
   npx vblocks eject browserslist > .browserslistrc
   ```

2. **Update the query**, see
   [the queries of browserslist](https://github.com/browserslist/browserslist#queries)

### Replace a default config

A config in your app folder replaces the VBlocks default of the same name:

- `webpack.config.js`
- `postcss.config.js`, the default runs:
  - `postcss-preset-env`, which compiles nesting, `oklch()` and `color-mix()`
    for older browsers and adds vendor prefixes
  - `cssnano` in `production`
- `.swcrc`
- `.browserslistrc`, the default `> 0.25%, not dead`

1. **[Eject](docs/REFERENCE.md#vblocks-eject) the default into your app folder**

   ```sh
   cd my-vblocks-app
   npx vblocks eject swc > .swcrc
   ```

   An ejected config loads its plugins and loaders from the project folder, not
   from VBlocks. Install them there.

2. **Update the ejected file**

> [!NOTE]\
> VBlocks does not merge your config with the default, with two exceptions:
>
> - `.swcrc -> env.path`: VBlocks adds the app folder when yours is missing, so
>   SWC reads the browserslist config
> - `.swcrc -> jsc.transform.react.refresh`: VBlocks adds the React Refresh
>   transform when `serve` runs in `development` mode

### Style with Tailwind

VBlocks does not include Tailwind. Add it through a `postcss.config.js` in your
app folder:

> [!NOTE]\
> The `xyflow` and `xyflow-tabs` templates of
> [`vblocks init`](docs/REFERENCE.md#vblocks-init) have this setup.

1. **Install Tailwind, its PostCSS plugin and cssnano, which the ejected config
   imports**

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

> [!IMPORTANT]\
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

   - Without it, Tailwind scans the folder you run VBlocks from. With
     [`--prefix`](docs/REFERENCE.md#vblocks-build), that is the project folder,
     which contains every app. Each app's CSS then also gets the classes of the
     other apps

### Send UI annotations to an AI agent

[Agentation](https://www.agentation.com) is a toolbar to send annotations on the
UI to a coding agent. `vblocks init` writes it into `src/index.tsx`. The toolbar
shows in `development` mode, the default of `serve`.

1. **Configure the agentation-mcp server**, see
   [Agentation's docs](https://www.agentation.com/mcp)

2. **Set `AGENTATION_ENDPOINT` in the `.env` of the app folder**, as in
   `.env.example`

   ```env
   AGENTATION_ENDPOINT=http://localhost:4747
   ```

> [!NOTE]\
> Agentation's license is PolyForm Shield 1.0.0, not MIT. To remove Agentation,
> remove its lines from `src/index.tsx` and run `npm uninstall agentation`.

### Open the page from another device

The server listens on `localhost`, so another device cannot open the page. Pass
`-- --host 0.0.0.0` to expose it to the network:

```sh
npx vblocks serve -- --host 0.0.0.0
```

### Build a single HTML file

`--single-file` builds one standalone `dist/index.html`, every asset inlined,
with no `robots.txt`:

```sh
npx vblocks build --single-file
```

> [!IMPORTANT]\
> A browser opens it from disk. There, `history.pushState` to another path
> throws, so keep the route in the URL hash.

### Add VBlocks to an existing project

1. **Install VBlocks**

   ```sh
   npm install --save-dev @asd14/vblocks    # needs react and react-dom ^18 or ^19
   ```

2. **Add the [client types](types/client.d.ts) and the
   [`@self`](#import-from-src-with-self) alias to your `tsconfig.json`**

   ```diff
    {
      "compilerOptions": {
   +    "types": ["@asd14/vblocks/client"],
   +    "paths": { "@self/*": ["./src/*"] }
      }
    }
   ```

> [!NOTE]\
> An import may name the file tsc emits, eg. `./button.js` for `button.tsx`, as
> TypeScript's `nodenext` resolution requires. VBlocks resolves it to
> `button.tsx`.

3. **Put your entry at `src/index.tsx` and your page at `src/index.html`**

4. **Remove the tag that loads your entry from `src/index.html`**, eg. Vite's
   `<script type="module" src="/src/main.tsx"></script>`

   VBlocks builds `dist/index.html` from `src/index.html` and adds the script
   and stylesheet tags to it.

5. **Start a development server**

   ```sh
   npx vblocks serve
   ```

## More docs

- **Reference**: every command, template and environment variable, in
  [docs/REFERENCE.md](docs/REFERENCE.md)
- **Decisions**: why the code is this way, in
  [docs/DECISIONS.md](docs/DECISIONS.md)
- **Release history**: what each version added, fixed and removed, in
  [GitHub releases](https://github.com/asd-xiv/vblocks/releases)

## Develop

```text
vblocks/
├── bin/         # vblocks, and one file per command in vblocks.d/
├── defaults/    # the configs that eject prints
├── template/    # the templates of init
└── types/       # client.d.ts
```

| Script              | Does                                                               |
| :------------------ | :----------------------------------------------------------------- |
| `npm run lint`      | Runs ESLint                                                        |
| `npm run typecheck` | Typechecks the code and the client types                           |
| `npm run unit-test` | Typechecks, builds and serves every template `vblocks init` writes |

## License

MIT
