import cssnano from "cssnano"
import postcssPresetEnv from "postcss-preset-env"

/**
 * Import the plugins, so Node resolves them from this file's folder
 *
 * @param {{ mode: "production" | "development" | "none" }} api
 */
export default ({ mode }) => ({
  plugins: [
    postcssPresetEnv({ stage: 2 }),
    ...(mode === "production" ? [cssnano({ preset: "default" })] : []),
  ],
})
