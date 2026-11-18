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

| Name           | Description                                  |
| :------------- | :------------------------------------------- |
| `config`       | `webpack`: Save it as `webpack.config.js`    |
|                | `postcss`: Save it as `postcss.config.js`    |
|                | `swc`: Save it as `.swcrc`                   |
|                | `browserslist`: Save it as `.browserslistrc` |
| `-h`, `--help` | Print this help                              |

| Exit code | Means         |
| :-------- | :------------ |
| `0`       | Done          |
| `2`       | Invalid usage |

`eject` prints the config to stdout. Save it in the app folder. `serve` and
`build` then run with it in place of the VBlocks default.

An ejected config loads its plugins and loaders from the project folder, not
from VBlocks. Install them there. `serve` and `build` still run the
`webpack-cli`, `webpack` and `webpack-dev-server` of VBlocks.

See also: [`vblocks`](#vblocks), [`vblocks serve`](#vblocks-serve),
[`vblocks build`](#vblocks-build)

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
