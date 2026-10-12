/**
 * @param {{ mode: "production" | "development" | "none" }} api
 */
export default ({ mode }) => ({
  plugins: {
    "@tailwindcss/postcss": {
      optimize: mode === "production",
    },
    "cssnano": mode === "production" && {
      preset: "default",
    },
  },
})
