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
 * import cssnano from "cssnano"
 *
 * // The default preset, which also removes the `/*!` comments
 * const CSSNANO_OPTIONS = {
 *   preset: ["default", { discardComments: { removeAll: true } }],
 * }
 *
 * export default api => {
 *   const {
 *     plugins: [presetEnv],
 *   } = getPostcssConfig(api)
 *
 *   return {
 *     plugins: [
 *       presetEnv,
 *       ...(api.mode === "production" ? [cssnano(CSSNANO_OPTIONS)] : []),
 *     ],
 *   }
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
