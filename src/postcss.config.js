/**
 * @param {{ mode: "production" | "development" | "none" }} api
 */
export default ({ mode }) => ({
  plugins: {
    "postcss-preset-env": {
      stage: 2,
    },
    "cssnano": mode === "production" && {
      preset: "default",
    },
  },
})
