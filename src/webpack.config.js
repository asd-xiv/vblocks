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

const VB_SWC_CONFIG = process.env["VB_SWC_CONFIG"]
const VB_POSTCONFIG_PATH = process.env["VB_POSTCSS_CONFIG"]

if (!VB_SWC_CONFIG)
  throw new Error("VB_SWC_CONFIG environment variable is not defined")

if (!VB_POSTCONFIG_PATH)
  throw new Error("VB_POSTCSS_CONFIG environment variable is not defined")

/**
 * Load, parse and provide targets defaults for SWC configuration
 *
 * @param {{ hasReactRefresh: boolean }} options
 */
const loadSwcConfig = ({ hasReactRefresh }) => {
  const content = fs.readFileSync(VB_SWC_CONFIG, "utf8")
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
          // SWC marks components and their hooks, `ReactRefreshWebpackPlugin`
          // loads the runtime that reads the marks. One without the other
          // breaks the page
          ...(hasReactRefresh ? { development: true, refresh: true } : {}),
        },
      },
    },
  }
}

/**
 * CSS module configuration shared between global and local styles
 *
 * @param {boolean} isProduction
 */
const createCssModuleConfig = isProduction => ({
  // import styles from './styles.module.css'
  // instead of
  // import * as styles from './styles.module.css'
  namedExport: false,

  // Use camelCase when referring to CSS classes in JavaScript code
  // Example: styles.myClass in JS maps to .my-class in CSS
  exportLocalsConvention: "camelCase",

  // Use a unique hash in production, but include class names
  // in development for easier debugging
  localIdentName: isProduction ? "[hash:base64:8]" : "[local]__[hash:base64:5]",
})

/**
 * Replace every script, stylesheet and icon tag of the HTML with the content
 * of the file it points at, then drop that file from the output.
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
          // The HTML parser reads `</script` and `<!--` inside a script, a
          // `\x3C` means the same `<` to JavaScript and nothing to the parser
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
            // `bin/vblocks.sh` only ever passes a `favicon.svg`
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
 * @property {string} entryDir - Target directory from where vblocks cmd was called
 * @property {string} robotsPath - Path to robots.txt copied to the output directory
 * @property {string} faviconPath - Path to favicon.ico copied to the output directory
 * @property {boolean} [single] - Build one standalone index.html, every asset inlined
 * @property {boolean} [analyze] - Run the bundle analyzer next to the dev server
 */

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
  { entryDir, robotsPath, faviconPath, single, analyze },
  { mode }
) => {
  const isProduction = mode === "production"
  const isServe = process.argv[2] == "serve"
  const isSingle = Boolean(single) && !isServe
  const isAnalyze = Boolean(analyze) && isServe
  const hasReactRefresh = isServe && mode === "development"
  const swcConfig = loadSwcConfig({ hasReactRefresh })
  const commonPostCSSConfigs = createCssModuleConfig(isProduction)

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
    // The order of entries matters.
    // The global CSS file needs to be first in the array to ensure its
    // styles are loaded before any component-specific styles.
    entry: [
      ...(fs.existsSync(paths.globalCssEntry) ? [paths.globalCssEntry] : []),
      paths.appEntry,
    ],

    mode: mode,

    // Keep the summary of VBlocks on screen, `--stats` overrides it
    stats: "errors-warnings",

    output: {
      // A standalone file opens from disk, where "/" is the filesystem root
      publicPath: isSingle ? "" : "/",
      path: paths.output,
      // Cannot use 'contenthash' when hot reloading is enabled.
      filename: isServe ? "js/[name].js" : "js/[name].[contenthash].js",
      // Delete existing files in the output directory before building
      clean: true,
    },

    devtool: isServe ? "eval-source-map" : false,

    // Both Webpack and SWC should use the same browserslist configuration
    // with .swcrc as source of truth
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
          use: [
            {
              loader: MiniCssExtractPlugin.loader,
            },
            {
              loader: "css-loader",
              options: {
                // Enable/disable @import resolving.
                import: true,

                // Apply "postcss-loader" on imported css files before
                // processing them with "css-loader"
                importLoaders: 1,

                modules: {
                  ...commonPostCSSConfigs,
                  mode: "local",
                },
              },
            },
            {
              loader: "postcss-loader",
              options: {
                postcssOptions: {
                  config: VB_POSTCONFIG_PATH,
                },
              },
            },
          ],
        },
        {
          test: /\.css$/,
          exclude: /\.module\.css$/,
          use: [
            {
              loader: MiniCssExtractPlugin.loader,
            },
            {
              loader: "css-loader",
              options: {
                // Enable/disable @import resolving.
                import: true,

                // Apply "postcss-loader" on imported css files before
                // processing them with "css-loader"
                importLoaders: 1,

                modules: {
                  ...commonPostCSSConfigs,
                  mode: "global",
                },
              },
            },
            {
              loader: "postcss-loader",
              options: {
                postcssOptions: {
                  config: VB_POSTCONFIG_PATH,
                },
              },
            },
          ],
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
          // When using the HTML5 History API, the index.html page will likely
          // have to be served in place of any 404 responses.
          historyApiFallback: true,

          // Hot Module Replacement (HMR) exchanges, adds, or removes modules
          // while an application is running, without a full reload.
          // https://webpack.js.org/concepts/hot-module-replacement/
          hot: true,

          // Tells dev-server to open the browser after server had been started.
          open: true,
          client: {
            overlay: true,
          },
        }
      : undefined,

    plugins: [
      new HtmlWebPackPlugin({
        template: paths.htmlTemplate,
        favicon: paths.favicon,
        // An inline script ignores `defer` and runs where it stands, so it
        // must stand after the element the app renders into
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

      // A dynamic `import()` would otherwise emit a second file
      isSingle && new webpack.optimize.LimitChunkCountPlugin({ maxChunks: 1 }),

      isSingle && inlineAssets,

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
      // Enable tree shaking for unused exports
      usedExports: true,

      // Merge runtime.js into main.js for fewer HTTP request
      runtimeChunk: false,

      // Extract node_module dependencies into a separate chunk for better caching
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
    },
  }
}
