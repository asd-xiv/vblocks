/** @typedef {import("webpack").Configuration} WebpackConfiguration */

import fs from "node:fs"
import "webpack-dev-server"
import ReactRefreshWebpackPlugin from "@pmmmwh/react-refresh-webpack-plugin"
import CopyPlugin from "copy-webpack-plugin"
import DotenvPlugin from "dotenv-webpack"
import HtmlWebPackPlugin from "html-webpack-plugin"
import MiniCssExtractPlugin from "mini-css-extract-plugin"
import webpack from "webpack"
import { BundleAnalyzerPlugin } from "webpack-bundle-analyzer"

/**
 * Read the SWC config, set the browser targets it lacks, and turn on React
 * Refresh when `hasReactRefresh` is true
 *
 * @param {string} path
 * @param {{ hasReactRefresh: boolean }} options
 */
const loadSwcConfig = (path, { hasReactRefresh }) => {
  const content = fs.readFileSync(path, "utf8")
  const config = /** @type {unknown} */ (JSON.parse(content))
  const typedConfig = /** @type {import("@swc/core").Config} */ (config)

  return {
    ...typedConfig,
    env: {
      targets: "> 0.25%, not dead",
      ...typedConfig.env,
    },
    jsc: {
      ...typedConfig.jsc,
      transform: {
        ...typedConfig.jsc?.transform,
        react: {
          ...typedConfig.jsc?.transform?.react,
          // SWC marks components and their hooks. `ReactRefreshWebpackPlugin`
          // loads the runtime that reads the marks. One without the other
          // breaks the page
          ...(hasReactRefresh ? { development: true, refresh: true } : {}),
        },
      },
    },
  }
}

/**
 * The CSS Modules options of css-loader, shared by global and local styles
 *
 * @param {boolean} isProduction
 */
const getCssModuleOptions = isProduction => ({
  // import styles from './styles.module.css'
  // instead of
  // import * as styles from './styles.module.css'
  namedExport: false,

  // Map `.my-class` in CSS to `styles.myClass` in JavaScript
  exportLocalsConvention: "camelCase",

  // Production names a class by its hash alone. Development puts the class
  // name before the hash, for debugging
  localIdentName: isProduction ? "[hash:base64:8]" : "[local]__[hash:base64:5]",
})

/**
 * The loaders of a CSS file. Webpack runs them last to first: PostCSS,
 * css-loader, then the extract into a .css file
 *
 * @param {Object} options
 * @param {"local" | "global"} options.classScope - `local` renames each class
 *   to a unique name, for `*.module.css`. `global` keeps the names as written
 * @param {boolean} options.isProduction
 * @param {string} options.postcssConfigPath
 */
const getCssLoaders = ({ classScope, isProduction, postcssConfigPath }) => [
  {
    loader: MiniCssExtractPlugin.loader,
  },
  {
    loader: "css-loader",
    options: {
      // Resolve @import in CSS files
      import: true,

      // Run postcss-loader on each @import-ed CSS file too, before css-loader
      importLoaders: 1,

      modules: {
        ...getCssModuleOptions(isProduction),
        mode: classScope,
      },
    },
  },
  {
    loader: "postcss-loader",
    options: {
      postcssOptions: {
        config: postcssConfigPath,
      },
    },
  },
]

/**
 * Print one line of VBlocks: a verb, then its subject. The `[vblocks]` prefix
 * lets the reader tell it apart from the lines of Webpack
 *
 * @param {string} verb
 * @param {string} subject
 */
const log = (verb, subject) => {
  process.stdout.write(`[vblocks] ${verb.padEnd(7)} ${subject}\n`)
}

/**
 * Serve prints at most this many files per compile, then a count of the rest
 */
const MAX_REPORTED_FILE_EVENTS = 5

/**
 * In serve, print each file of the build that was updated, added or dropped
 * since the last compile, as $APP_DIR/...
 *
 * @param {string} appDir
 * @returns {(compiler: import("webpack").Compiler) => void}
 */
const reportFileEvents = appDir => compiler => {
  /** @type {Set<string> | undefined} */
  let previousFiles
  /** @type {Array<[string, string]>} */
  let fileEvents = []

  // The watcher also reports editor swap files and folders, eg. the src/ that
  // Tailwind scans. Only a file the last compile used is part of the build
  compiler.hooks.watchRun.tap("VBlocksReportFileEvents", watcher => {
    fileEvents = []
    for (const file of watcher.modifiedFiles ?? []) {
      if (
        previousFiles?.has(file) &&
        fs.statSync(file, { throwIfNoEntry: false })?.isFile()
      ) {
        fileEvents.push(["update", file])
      }
    }
    for (const file of watcher.removedFiles ?? []) {
      if (previousFiles?.has(file)) fileEvents.push(["drop", file])
    }
  })

  // A file joins the build when an import first reaches it. The watcher has
  // no event for that
  compiler.hooks.done.tap("VBlocksReportFileEvents", stats => {
    const files = new Set(stats.compilation.fileDependencies)

    if (previousFiles) {
      const addedFiles = [...files]
        .filter(file => !previousFiles?.has(file))
        .filter(file => !file.includes("/node_modules/"))
        .toSorted()

      for (const file of addedFiles) fileEvents.push(["add", file])
    }
    previousFiles = files

    for (const [verb, file] of fileEvents.slice(0, MAX_REPORTED_FILE_EVENTS)) {
      log(verb, file.replace(appDir, "$APP_DIR"))
    }
    if (fileEvents.length > MAX_REPORTED_FILE_EVENTS) {
      log("…", `and ${fileEvents.length - MAX_REPORTED_FILE_EVENTS} more`)
    }
  })
}

/**
 * Replace every script and stylesheet tag of the HTML with the content of the
 * file it points at. Point the icon tag at a data URL of its file. Then drop
 * each of those files from the output.
 *
 * Lives in this file so an ejected config stays one file.
 *
 * @param {import("webpack").Compiler} compiler
 */
const inlineAssets = compiler => {
  compiler.hooks.compilation.tap("inlineAssets", compilation => {
    /** @param {string} name */
    const takeAsset = name => {
      const content = compilation.getAsset(name)?.source.source() ?? ""

      compilation.deleteAsset(name)

      return content
    }

    /** @param {import("html-webpack-plugin").HtmlTagObject} tag */
    const inlineTag = tag => {
      const { src, href, rel } = tag.attributes

      if (tag.tagName === "script" && typeof src === "string")
        return {
          ...tag,
          attributes: {},
          // The HTML parser reads `</script` and `<!--` inside a script.
          // Inside a JavaScript string, `\x3C` means `<` to JavaScript and
          // nothing to the parser
          innerHTML: takeAsset(src)
            .toString()
            .replaceAll("</script", String.raw`\x3C/script`)
            .replaceAll("<!--", String.raw`\x3C!--`),
        }

      if (rel === "stylesheet" && typeof href === "string")
        return {
          ...tag,
          tagName: "style",
          voidTag: false,
          attributes: {},
          innerHTML: takeAsset(href)
            .toString()
            .replaceAll("</style", String.raw`<\/style`),
        }

      if (rel === "icon" && typeof href === "string")
        return {
          ...tag,
          attributes: {
            rel,
            // `bin/vblocks.d/webpack.sh` only passes a `favicon.svg`
            href: `data:image/svg+xml;base64,${Buffer.from(takeAsset(href)).toString("base64")}`,
          },
        }

      return tag
    }

    HtmlWebPackPlugin.getHooks(compilation).alterAssetTagGroups.tap(
      "inlineAssets",
      data => ({
        ...data,
        headTags: data.headTags.map(tag => inlineTag(tag)),
        bodyTags: data.bodyTags.map(tag => inlineTag(tag)),
      })
    )
  })
}

/**
 * @typedef {Object} VBlocksEnvironment
 *
 * @property {string} entryDir - The app folder: `--prefix`, or the folder VBlocks runs in
 * @property {string} postcssConfigPath - Path to the PostCSS config, the app's own or the default
 * @property {string} swcConfigPath - Path to the SWC config, the app's own or the default
 * @property {string} [robotsPath] - Path to the robots.txt copied to the output folder, missing in a single-file build
 * @property {string} faviconPath - Path to the favicon.svg copied to the output folder
 * @property {boolean} [single] - Build one standalone index.html, every asset inlined
 * @property {boolean} [analyze] - Run the bundle analyzer next to the dev server
 * @property {"error"|"warn"|"info"|"verbose"} [logLevel] - How much Webpack and its dev server print
 */

/**
 * The stats preset of Webpack for each log level of VBlocks
 */
const STATS_BY_LOG_LEVEL = /** @type {const} */ ({
  error: "errors-only",
  warn: "errors-warnings",
  info: "normal",
  verbose: "verbose",
})

/**
 * @typedef {Object} VBlocksProps
 *
 * @property {"production"|"development"} mode
 */

/**
 * @param {VBlocksEnvironment} environment
 * @param {VBlocksProps} props
 * @returns {WebpackConfiguration}
 */
export default (
  {
    entryDir,
    postcssConfigPath,
    swcConfigPath,
    robotsPath,
    faviconPath,
    single,
    analyze,
    logLevel = "warn",
  },
  { mode }
) => {
  const isProduction = mode === "production"
  const isServe = process.argv[2] == "serve"
  const isSingle = Boolean(single) && !isServe
  const isAnalyze = Boolean(analyze) && isServe
  const hasReactRefresh = isServe && mode === "development"
  const swcConfig = loadSwcConfig(swcConfigPath, { hasReactRefresh })

  const paths = {
    appEntry: `${entryDir}/src/index.tsx`,
    globalCssEntry: `${entryDir}/src/index.css`,
    output: `${entryDir}/dist`,
    htmlTemplate: `${entryDir}/src/index.html`,
    favicon: faviconPath,
    robots: robotsPath,
    dotenv: `${entryDir}/.env`,
  }

  return {
    // The global CSS comes first, so component styles load after it and win
    // ties
    entry: [
      ...(fs.existsSync(paths.globalCssEntry) ? [paths.globalCssEntry] : []),
      paths.appEntry,
    ],

    mode: mode,

    // Merge the saves within 100 ms into one compile, eg. those of a codemod.
    // A longer wait would stop an edit from feeling instant
    watchOptions: { aggregateTimeout: 100 },

    // Print little, so the summary of VBlocks stays on screen. `--log-level`
    // picks the stats preset. `--stats` overrides it
    stats: STATS_BY_LOG_LEVEL[logLevel],

    output: {
      // The browser opens a standalone file from disk, where "/" is the
      // filesystem root
      publicPath: isSingle ? "" : "/",
      path: paths.output,
      // Hot Module Replacement breaks on `[contenthash]` names, so serve leaves
      // out the hash
      filename: isServe ? "js/[name].js" : "js/[name].[contenthash].js",
      // Empty the output folder before each build
      clean: true,
    },

    devtool: isServe ? "eval-source-map" : false,

    // Webpack builds for the browser targets of the SWC config, so both tools
    // agree
    target: `browserslist:${swcConfig.env.targets}`,

    module: {
      rules: [
        {
          test: /\.(ts|tsx)$/,
          exclude: /node_modules/,
          use: {
            loader: "swc-loader",
            options: swcConfig,
          },
        },
        {
          test: /\.mdx?$/,
          exclude: /node_modules/,
          use: [
            { loader: "swc-loader", options: swcConfig },
            { loader: "@mdx-js/loader" },
          ],
        },
        {
          test: /\.module\.css$/,
          use: getCssLoaders({
            classScope: "local",
            isProduction,
            postcssConfigPath,
          }),
        },
        {
          test: /\.css$/,
          exclude: /\.module\.css$/,
          use: getCssLoaders({
            classScope: "global",
            isProduction,
            postcssConfigPath,
          }),
        },
        {
          test: /\.(jpg|gif|png|svg)$/,
          ...(isSingle
            ? { type: "asset/inline" }
            : {
                type: "asset",
                parser: {
                  dataUrlCondition: {
                    maxSize: 10 * 1024,
                  },
                },
              }),
        },
        {
          test: /\.(woff|woff2|ttf|eot)$/,
          ...(isSingle
            ? { type: "asset/inline" }
            : {
                type: "asset/resource",
                generator: {
                  filename: "fonts/[name][ext]",
                },
              }),
        },
      ],
    },

    // https://webpack.js.org/configuration/dev-server/
    devServer: isServe
      ? {
          compress: true,
          // Serve index.html in place of a 404, so the router of the app handles
          // every path
          historyApiFallback: true,

          // Hot Module Replacement updates, adds and drops modules in the running
          // app, without a full reload
          // https://webpack.js.org/concepts/hot-module-replacement/
          hot: true,

          // Open the browser once the server starts
          open: true,

          // Only this machine can open the page. `--host 0.0.0.0` exposes it to
          // the network, eg. for a phone
          host: "localhost",

          // Serve only what Webpack builds, not a public/ folder in the
          // folder VBlocks runs in
          static: false,

          // Print the URL once, as the result of serve. At the `warn` log
          // level, the dev server prints no startup lines
          onListening: developmentServer => {
            const address = developmentServer.server?.address()

            // A TCP server gives an object, a pipe server gives a string
            if (typeof address !== "object" || address === null) return

            const { port } = address
            log("serve", `http://localhost:${port}`)

            if (developmentServer.options.host !== "localhost") {
              log("expose", `${developmentServer.options.host}:${port}`)
            }
          },

          client: {
            overlay: true,
          },
        }
      : undefined,

    // At warn, hide the info lines of the dev server, and of the client in the
    // browser console
    infrastructureLogging: { level: logLevel },

    plugins: [
      new HtmlWebPackPlugin({
        template: paths.htmlTemplate,
        favicon: paths.favicon,
        // An inline script ignores `defer` and runs once the parser reaches
        // it. It must come after the element the app renders into
        inject: isSingle ? "body" : "head",
      }),

      new MiniCssExtractPlugin({
        filename: isServe ? "css/[name].css" : "css/[name].[contenthash].css",
      }),

      new DotenvPlugin({
        path: paths.dotenv,
        // Don't spam logs, an app without a .env is common
        silent: true,
      }),

      !isSingle &&
        new CopyPlugin({
          patterns: [
            {
              from: paths.robots,
              to: "robots.txt",
            },
          ],
        }),

      // Without it, Webpack emits a second file for each dynamic `import()`
      isSingle && new webpack.optimize.LimitChunkCountPlugin({ maxChunks: 1 }),

      isSingle && inlineAssets,

      isServe && reportFileEvents(entryDir),

      isAnalyze &&
        new BundleAnalyzerPlugin({
          openAnalyzer: false,
          // Two dev servers would otherwise both take 8888
          analyzerPort: "auto",
        }),

      hasReactRefresh && new ReactRefreshWebpackPlugin(),
    ].filter(Boolean),

    resolve: {
      extensions: [".tsx", ".ts", ".jsx", ".js"],
      alias: {
        "@self": `${entryDir}/src`,
      },
    },

    optimization: {
      // Mark unused exports, so the minifier drops them
      usedExports: true,

      // Merge runtime.js into main.js for fewer HTTP requests
      runtimeChunk: false,

      // Split node_modules into the react and vendors chunks, so the browser
      // keeps them cached across builds of the app
      splitChunks: !isSingle && {
        chunks: "all",
        cacheGroups: {
          react: {
            test: /[/\\]node_modules[/\\]react(-dom)?[/\\]/,
            name: "react",
            chunks: "all",
            priority: 10,
          },
          vendors: {
            test: /[/\\]node_modules[/\\]/,
            name: "vendors",
            chunks: "all",
            priority: 5,
          },
        },
      },
    },

    performance: {
      // A standalone file is over the size limit by design
      hints: isProduction && !isSingle ? "warning" : false,
      // React and react-dom alone are over the 244 KiB default. Vite warns
      // at 500 kB
      maxAssetSize: 500 * 1000,
      maxEntrypointSize: 500 * 1000,
    },
  }
}
