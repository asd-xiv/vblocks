import tailwindcss from "@tailwindcss/postcss"
import cssnano from "cssnano"

/**
 * Import the plugins, so Node resolves them from this file's folder
 *
 * @param {{ mode: "production" | "development" | "none" }} api
 */
export default ({ mode }) => ({
  plugins: [
    tailwindcss({ optimize: mode === "production" }),
    ...(mode === "production" ? [cssnano({ preset: "default" })] : []),
  ],
})
