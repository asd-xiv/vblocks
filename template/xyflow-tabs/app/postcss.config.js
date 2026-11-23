import { getPostcssConfig } from "@asd14/vblocks/postcss"
import tailwindcss from "@tailwindcss/postcss"

/**
 * Return the PostCSS config of the app: Tailwind, and cssnano in `production`.
 * Tailwind compiles nesting and adds vendor prefixes itself, so it replaces
 * `postcss-preset-env`
 *
 * @param {{ mode: "production" | "development" | "none" }} api
 */
export default api => {
  const {
    plugins: [, cssnano],
  } = getPostcssConfig(api)

  return {
    plugins: [
      tailwindcss({ optimize: api.mode === "production" }),
      ...(cssnano ? [cssnano] : []),
    ],
  }
}
