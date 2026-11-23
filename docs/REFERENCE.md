# Reference - @asd14/vblocks

## Table of contents

<!-- vim-markdown-toc GFM -->

- [Domain Vocabulary](#domain-vocabulary)
- [Commands](#commands)
  - [`vblocks`](#vblocks)
  - [`vblocks init`](#vblocks-init)
  - [`vblocks serve`](#vblocks-serve)
  - [`vblocks build`](#vblocks-build)
  - [`vblocks eject`](#vblocks-eject)
- [Configs](#configs)
  - [`webpack.config.js`](#webpackconfigjs)
  - [`postcss.config.js`](#postcssconfigjs)
  - [`.swcrc`](#swcrc)
  - [`.browserslistrc`](#browserslistrc)
- [Exports](#exports)
  - [`@asd14/vblocks/postcss`](#asd14vblockspostcss)
  - [`@asd14/vblocks/webpack`](#asd14vblockswebpack)
- [Templates](#templates)
- [Environment variables](#environment-variables)

<!-- vim-markdown-toc -->

## Domain Vocabulary

| Term               | Means                                                                                  |
| :----------------- | :------------------------------------------------------------------------------------- |
| **Plumbing**       | `package.json` and `.gitignore`, for the project folder                                |
| **App**            | `src/`, `.env.example`, `tsconfig.json` and the template's configs, for the app folder |
| **Template**       | A named set of files that `init` writes, eg. `plain`                                   |
| **Project folder** | The folder with `package.json`                                                         |
| **App folder**     | The folder with `src/index.tsx` and `src/index.html`                                   |

## Commands

### `vblocks`

Zero-config React builds of an SPA (single-page application), as a folder or a
single HTML file

```text
vblocks <command> [OPTIONS]
vblocks -h | --help
```

<details>
<summary>Example, inputs, exit codes</summary>

```sh
npx @asd14/vblocks init my-app
npx vblocks serve --help
```

| Name           | Description                                      |
| :------------- | :----------------------------------------------- |
| `command`      | `init`: Write a template into a folder           |
|                | `serve`: Start the development server of an app  |
|                | `build`: Build an app into `dist/` in its folder |
|                | `eject`: Print a default config of VBlocks       |
| `-h`, `--help` | Print this help                                  |

| Exit code | Means                             |
| :-------- | :-------------------------------- |
| `0`       | Done                              |
| `2`       | No command, or an unknown command |

- Each command prints its own help with `--help`.

See also: [`vblocks init`](#vblocks-init), [`vblocks serve`](#vblocks-serve),
[`vblocks build`](#vblocks-build), [`vblocks eject`](#vblocks-eject)

</details>

### `vblocks init`

Write a template into a folder

```text
vblocks init <folder>
  [--template <name>]
  [--only <app|plumbing>]
vblocks init --list
```

<details>
<summary>Example, inputs, exit codes</summary>

```sh
npx @asd14/vblocks init my-app
npx @asd14/vblocks init --list
npx @asd14/vblocks init demos --only plumbing
npx @asd14/vblocks init demos/flow --template xyflow --only app
```

| Name                | Default | Description                                                                                                                                                                                      |
| :------------------ | :------ | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `folder`            |         | The folder to write into, missing or empty                                                                                                                                                       |
| `--template <name>` | `plain` | The template, one of the names `--list` prints. See [Templates](#templates)                                                                                                                      |
| `--list`            |         | Print the templates, one per line                                                                                                                                                                |
| `--only <part>`     | both    | Write only the app or only the plumbing. With app, `init` adds the template's dependencies to the `package.json` of the project folder, the parent of `<folder>`. That `package.json` must exist |
| `-h`, `--help`      |         | Print this help                                                                                                                                                                                  |

| Exit code | Means                                                                                                                              |
| :-------- | :--------------------------------------------------------------------------------------------------------------------------------- |
| `0`       | Done                                                                                                                               |
| `2`       | Invalid usage, an unknown template, or a `<folder>` that is a file or not empty                                                    |
| `3`       | Could not run: a missing tool, no `package.json` in the project folder, a folder `init` could not create, or a failed copy or hook |

A template has two parts:

| Part       | Writes                                                                                 |
| :--------- | :------------------------------------------------------------------------------------- |
| `plumbing` | `package.json` and `.gitignore`, for the project folder                                |
| `app`      | `src/`, `.env.example`, `tsconfig.json` and the template's configs, for the app folder |

`init` writes each part into its folder, then runs the part's post-init hooks in
`<folder>`. `template/<name>/README.md`, in the VBlocks folder, lists the files
and hooks of each template.

Print the project folder, each file `init` creates, updates or deletes, then the
next step.

See also: [`vblocks`](#vblocks), [`vblocks serve`](#vblocks-serve), `node`,
`npm`

</details>

### `vblocks serve`

Start the development server of an app

```text
vblocks serve
  [--mode <development|production>]
  [--prefix <folder>]
  [--analyze]
  [--log-level <error|warn|info|verbose>]
  [-- <webpack option>...]
```

<details>
<summary>Example, inputs, exit codes</summary>

```sh
npx vblocks serve
npx vblocks serve --prefix flow -- --host 0.0.0.0
npx vblocks serve -- --port 8099 --no-open
```

| Name                     | Default            | Description                                                                                                              |
| :----------------------- | :----------------- | :----------------------------------------------------------------------------------------------------------------------- |
| `--mode <mode>`          | `development`      | The Webpack mode, `development` or `production`                                                                          |
| `--prefix <folder>`      | the current folder | The app folder, which must exist                                                                                         |
| `--analyze`              |                    | Run the bundle analyzer, on a free port. An ejected `webpack.config.js` runs the analyzer only if it reads `env.analyze` |
| `--log-level <level>`    | `warn`             | How much Webpack and its development server print: `error`, `warn`, `info` or `verbose`                                  |
| `-- <webpack option>...` |                    | Pass each option to Webpack, unchanged                                                                                   |
| `-h`, `--help`           |                    | Print this help                                                                                                          |

| Exit code | Means                                                                                            |
| :-------- | :----------------------------------------------------------------------------------------------- |
| `0`       | Done                                                                                             |
| `2`       | Invalid usage, Webpack rejected an option or the config, or browserslist could not read a config |
| `3`       | Could not run: a missing tool, or a failed Webpack run                                           |

The app folder contains `src/index.tsx` and `src/index.html`. A config in it,
`webpack.config.js`, `postcss.config.js`, `.swcrc` or `.browserslistrc`,
replaces the VBlocks default of the same name. So do `src/public/robots.txt` and
`src/public/favicon.svg`.

Print the app folder, the VBlocks folder, the files Webpack runs with and the
source of the browsers, then start the server.

SWC, Webpack and `postcss-preset-env` compile for the browsers of the app's
browserslist config. browserslist reads `BROWSERSLIST`, `BROWSERSLIST_CONFIG`,
then a `.browserslistrc` or the `browserslist` field of `package.json`, from the
app folder up. Without any of them, browserslist reads the VBlocks default,
`defaults/.browserslistrc`.

The server runs at `http://localhost:8080`, or the next free port. It opens the
page in the browser. It listens on `localhost`, so another device cannot open
the page. Pass `-- --host 0.0.0.0` to expose it to the network.

See also: [`vblocks`](#vblocks), [`vblocks build`](#vblocks-build),
[`vblocks eject`](#vblocks-eject), `webpack`

</details>

### `vblocks build`

Build an app into `dist/` in its folder

```text
vblocks build
  [--mode <development|production>]
  [--prefix <folder>]
  [--single-file|--single]
  [--log-level <error|warn|info|verbose>]
  [-- <webpack option>...]
```

<details>
<summary>Example, inputs, exit codes</summary>

```sh
npx vblocks build
cd demos && npx vblocks build --prefix flow --single-file
npx vblocks build -- --devtool source-map
```

| Name                        | Default            | Description                                                                                                                                                                                                                                                                         |
| :-------------------------- | :----------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--mode <mode>`             | `production`       | The Webpack mode, `development` or `production`                                                                                                                                                                                                                                     |
| `--prefix <folder>`         | the current folder | The app folder, which must exist                                                                                                                                                                                                                                                    |
| `--single-file`, `--single` |                    | Build one standalone `dist/index.html`, every asset inlined, with no `robots.txt`. A browser opens it from disk. There, `history.pushState` to another path throws, so keep the route in the URL hash. An ejected `webpack.config.js` builds one file only if it reads `env.single` |
| `--log-level <level>`       | `warn`             | How much Webpack prints: `error`, `warn`, `info` or `verbose`                                                                                                                                                                                                                       |
| `-- <webpack option>...`    |                    | Pass each option to Webpack, unchanged                                                                                                                                                                                                                                              |
| `-h`, `--help`              |                    | Print this help                                                                                                                                                                                                                                                                     |

| Exit code | Means                                                                                            |
| :-------- | :----------------------------------------------------------------------------------------------- |
| `0`       | Done                                                                                             |
| `2`       | Invalid usage, Webpack rejected an option or the config, or browserslist could not read a config |
| `3`       | Could not run: a missing tool, or a failed Webpack run                                           |

The app folder contains `src/index.tsx` and `src/index.html`. A config in it,
`webpack.config.js`, `postcss.config.js`, `.swcrc` or `.browserslistrc`,
replaces the VBlocks default of the same name. So do `src/public/robots.txt` and
`src/public/favicon.svg`.

Print the app folder, the VBlocks folder, the files Webpack runs with and the
source of the browsers, then build. Print each file in `dist/`, its size and the
total.

SWC, Webpack and `postcss-preset-env` compile for the browsers of the app's
browserslist config. browserslist reads `BROWSERSLIST`, `BROWSERSLIST_CONFIG`,
then a `.browserslistrc` or the `browserslist` field of `package.json`, from the
app folder up. Without any of them, browserslist reads the VBlocks default,
`defaults/.browserslistrc`.

Without `--single-file`, `dist/` contains:

```text
index.html
favicon.svg
robots.txt
js/main.<hash>.js
js/react.<hash>.js      react and react-dom
js/vendors.<hash>.js    the rest of node_modules
js/*.LICENSE.txt        the license comments of each chunk
css/main.<hash>.css
fonts/<name>.<ext>      each font
<hash>.<ext>            each image over 10 KiB
```

Webpack inlines an image up to 10 KiB. It splits `react` and `vendors` out of
`main`, so the browser keeps them cached across builds.

See also: [`vblocks`](#vblocks), [`vblocks serve`](#vblocks-serve),
[`vblocks eject`](#vblocks-eject), `webpack`

</details>

### `vblocks eject`

Print a default config of VBlocks

```text
vblocks eject <config>
```

<details>
<summary>Example, inputs, exit codes</summary>

```sh
npx vblocks eject postcss > postcss.config.js
```

| Name           | Description                                                     |
| :------------- | :-------------------------------------------------------------- |
| `config`       | `webpack`: Save it as [`webpack.config.js`](#webpackconfigjs)   |
|                | `postcss`: Save it as [`postcss.config.js`](#postcssconfigjs)   |
|                | `swc`: Save it as [`.swcrc`](#swcrc)                            |
|                | `browserslist`: Save it as [`.browserslistrc`](#browserslistrc) |
| `-h`, `--help` | Print this help                                                 |

| Exit code | Means         |
| :-------- | :------------ |
| `0`       | Done          |
| `2`       | Invalid usage |

`eject` prints the config to stdout. Save it in the app folder. `serve` and
`build` then run with it in place of the VBlocks default.

Node resolves the packages an ejected config imports from the project folder,
not from the VBlocks folder. Install them there. `serve` and `build` still run
the `webpack-cli`, `webpack` and `webpack-dev-server` of VBlocks.

See also: [`vblocks`](#vblocks), [`vblocks serve`](#vblocks-serve),
[`vblocks build`](#vblocks-build), [Configs](#configs)

</details>

## Configs

A config in the app folder replaces the VBlocks default of the same name.
[`vblocks eject`](#vblocks-eject) prints a default.

To change part of the webpack or postcss default instead of replacing it, extend
it with an [export](#exports).

### `webpack.config.js`

Bundle `src/index.tsx`, `src/index.css` if it exists, and `src/index.html` into
`dist/`

```sh
npx vblocks eject webpack > webpack.config.js
```

<details>
<summary>Loaders, plugins</summary>

| Files                                   | Loaders, in the order they run, or the output                                                                                   |
| :-------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------ |
| `*.ts`, `*.tsx`, outside `node_modules` | `swc-loader`, with [`.swcrc`](#swcrc)                                                                                           |
| `*.md`, `*.mdx`, outside `node_modules` | `@mdx-js/loader`, with `rehype-mdx-code-props`, then `swc-loader`                                                               |
| `*.css`                                 | `postcss-loader`, with [`postcss.config.js`](#postcssconfigjs), then `css-loader`, then the loader of `mini-css-extract-plugin` |
| `*.module.css`                          | the same, and `css-loader` renames each class to a unique name, see [Use CSS Modules](../README.md#use-css-modules)             |
| `*.jpg`, `*.gif`, `*.png`, `*.svg`      | a data URL up to 10 KiB, a file above it. With `--single-file`, a data URL                                                      |
| `*.woff`, `*.woff2`, `*.ttf`, `*.eot`   | a file in `dist/fonts/`. With `--single-file`, a data URL                                                                       |
| a `?raw` import                         | the text of the file                                                                                                            |

- `html-webpack-plugin` writes `dist/index.html` from `src/index.html`, with
  `favicon.svg`
- `mini-css-extract-plugin` writes the CSS into `dist/css/`
- `dotenv-webpack` replaces each `process.env["NAME"]` with its value in the
  `.env` of the app folder
- `copy-webpack-plugin` copies `robots.txt` into `dist/`, except with
  `--single-file`
- With `--single-file`, the build puts every script, stylesheet and the favicon
  into `dist/index.html`
- `serve` prints each file of the build that changed since the last compile
- `@pmmmwh/react-refresh-webpack-plugin` runs in `serve`, in `development`
- `webpack-bundle-analyzer` runs with `serve --analyze`

[`vblocks build`](#vblocks-build) lists what `dist/` contains.

To change part of it, extend it with
[`@asd14/vblocks/webpack`](#asd14vblockswebpack).

</details>

### `postcss.config.js`

Compile nesting, `oklch()` and `color-mix()` for the browsers of
[`.browserslistrc`](#browserslistrc), and add vendor prefixes. Minify the CSS in
`production`

```sh
npx vblocks eject postcss > postcss.config.js
```

<details>
<summary>The default</summary>

```js
import cssnano from "cssnano"
import postcssPresetEnv from "postcss-preset-env"

/**
 * Return the PostCSS config of the app: `postcss-preset-env`, and `cssnano` in
 * `production`.
 *
 * Node resolves the plugins from the folder of this file.
 * In an app, install them: `npm install --save-dev postcss-preset-env cssnano`.
 * To keep the VBlocks plugins and add yours, import `getPostcssConfig` from
 * `@asd14/vblocks/postcss` instead.
 *
 * @param {{ mode: "production" | "development" | "none" }} api
 * @returns {{ plugins: import("postcss").AcceptedPlugin[] }}
 *
 * @example
 * // postcss.config.js, in the app folder
 * import { getPostcssConfig } from "@asd14/vblocks/postcss"
 *
 * export default api => {
 *   const { plugins: [presetEnv, cssnano] } = getPostcssConfig(api)
 *
 *   return { plugins: [presetEnv, ...(cssnano ? [cssnano] : [])] }
 * }
 */
const getPostcssConfig = ({ mode }) => ({
  plugins: [
    postcssPresetEnv({ stage: 2 }),
    // `preset` stops cssnano from reading a config file in the current folder
    ...(mode === "production" ? [cssnano({ preset: "default" })] : []),
  ],
})

export { getPostcssConfig as default, getPostcssConfig }
```

To change part of it, extend it with
[`@asd14/vblocks/postcss`](#asd14vblockspostcss).

</details>

### `.swcrc`

Compile TypeScript and TSX, with the automatic runtime of React, for the
browsers of [`.browserslistrc`](#browserslistrc)

```sh
npx vblocks eject swc > .swcrc
```

<details>
<summary>The default, and the keys VBlocks sets</summary>

```json
{
  "$schema": "https://swc.rs/schema.json",
  "minify": false,
  "sourceMaps": true,
  "env": {
    "mode": "entry",
    "coreJs": "3.22"
  },
  "jsc": {
    "externalHelpers": true,
    "minify": {
      "format": {
        "comments": "all"
      }
    },
    "parser": {
      "syntax": "typescript",
      "tsx": true,
      "dynamicImport": true
    },
    "transform": {
      "react": {
        "runtime": "automatic"
      }
    }
  }
}
```

VBlocks sets these keys on the `.swcrc`, the default or yours:

| Key                                                              | Value                                                                                                                                                 |
| :--------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `swcrc`                                                          | `false`: SWC reads no other `.swcrc`, eg. the one in the project folder                                                                               |
| `env.path`                                                       | the app folder, unless yours sets one, so SWC reads the browserslist config from there up                                                             |
| `jsc.transform.react.development`, `jsc.transform.react.refresh` | `true` in `serve`, in `development`, for React Refresh. Without the React Refresh plugin, `refresh: true` breaks the page, so leave it unset in yours |

</details>

### `.browserslistrc`

The browsers that SWC, Webpack and `postcss-preset-env` compile for

```sh
npx vblocks eject browserslist > .browserslistrc
```

<details>
<summary>The default, and where browserslist reads it</summary>

```text
> 0.25%, not dead
```

browserslist reads `BROWSERSLIST`, `BROWSERSLIST_CONFIG`, then a
`.browserslistrc` or the `browserslist` field of `package.json`, from the app
folder up. Without any of them, browserslist reads the VBlocks default,
`defaults/.browserslistrc`. See [Environment variables](#environment-variables).

</details>

## Exports

Each export is a module. It exports its function by name and as the default.

### `@asd14/vblocks/postcss`

Return the PostCSS config of the app: `postcss-preset-env`, and `cssnano` in
`production`.

```ts
getPostcssConfig(api: {
  mode: "production" | "development" | "none"
}): { plugins: AcceptedPlugin[] }
```

<details>
<summary>Example, inputs, returns</summary>

```js
// postcss.config.js, in the app folder
import { getPostcssConfig } from "@asd14/vblocks/postcss"

export default api => {
  const { plugins: [presetEnv, cssnano] } = getPostcssConfig(api)

  return { plugins: [presetEnv, ...(cssnano ? [cssnano] : [])] }
}
```

| Name       | Type                                      | Description                                                                                           |
| :--------- | :---------------------------------------- | :---------------------------------------------------------------------------------------------------- |
| `api.mode` | `"production" \| "development" \| "none"` | The Webpack mode, `production`, `development` or `none`. With `production`, the config adds `cssnano` |

Returns `{ plugins: AcceptedPlugin[] }`: `postcss-preset-env`, then `cssnano` in
`production`. `cssnano` is `undefined` outside `production`.

Node resolves the plugins from the VBlocks folder. Install only the plugins you
add.

See also: [`postcss.config.js`](#postcssconfigjs)

</details>

### `@asd14/vblocks/webpack`

Return the Webpack config of the app.

```ts
getWebpackConfig(
  environment: VBlocksEnvironment,
  props: { mode: "production" | "development" }
): WebpackConfiguration
```

<details>
<summary>Example, inputs, returns</summary>

```js
// webpack.config.js, in the app folder
import { getWebpackConfig } from "@asd14/vblocks/webpack"

export default (environment, props) => {
  const config = getWebpackConfig(environment, props)
  config.watchOptions = { aggregateTimeout: 200 }

  return config
}
```

VBlocks passes the environment and the props, so an app's own
`webpack.config.js` passes them on.

`environment` has these fields:

| Name                | Type                                       | Default  | Description                                                                        |
| :------------------ | :----------------------------------------- | :------- | :--------------------------------------------------------------------------------- |
| `entryDir`          | `string`                                   |          | The app folder: `--prefix`, or the folder VBlocks runs in                          |
| `postcssConfigPath` | `string`                                   |          | Path to the PostCSS config, the app's own or the default                           |
| `swcConfigPath`     | `string`                                   |          | Path to the SWC config, the app's own or the default                               |
| `robotsPath`        | `string`                                   |          | Path to the robots.txt copied to the output folder, missing in a single-file build |
| `faviconPath`       | `string`                                   |          | Path to the favicon.svg copied to the output folder                                |
| `single`            | `boolean`                                  |          | Build one standalone index.html, every asset inlined                               |
| `analyze`           | `boolean`                                  |          | Run the bundle analyzer next to the dev server                                     |
| `logLevel`          | `"error" \| "warn" \| "info" \| "verbose"` | `"warn"` | How much Webpack and its dev server print                                          |
| `WEBPACK_SERVE`     | `boolean`                                  |          | webpack-cli sets it for `serve`, and its aliases `server` and `s`                  |

`props` has one field, `mode`: `production` or `development`.

Returns the Webpack `Configuration` that VBlocks runs.

Node resolves its loaders and plugins from the VBlocks folder. Install only the
packages you add.

See also: [`webpack.config.js`](#webpackconfigjs)

</details>

## Templates

```sh
npx @asd14/vblocks init --list
# => plain
# => xyflow
# => xyflow-tabs
```

Each template starts from [the common files](../template/_common/README.md).

| Template                                           | Description                                                    |
| :------------------------------------------------- | :------------------------------------------------------------- |
| [`plain`](../template/plain/README.md)             | A "Hello World!" heading.                                      |
| [`xyflow`](../template/xyflow/README.md)           | One diagram, and a details panel for the selected node or edge |
| [`xyflow-tabs`](../template/xyflow-tabs/README.md) | One tab per diagram, each with its own details panel           |

## Environment variables

| Name                  | Values               | Default | Description                                                                                                        |
| :-------------------- | :------------------- | :------ | :----------------------------------------------------------------------------------------------------------------- |
| `NO_COLOR`            | non-empty            |         | `init`: print without color or the header. `serve`, `build`: print without color, the icons or the header          |
| `BROWSERSLIST`        | a browserslist query |         | `serve`, `build`: the browsers, as a browserslist query. It overrides every config file                            |
| `BROWSERSLIST_CONFIG` | a file path          |         | `serve`, `build`: the path of a browserslist config, in place of the one browserslist finds from the app folder up |
