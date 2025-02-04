export default {
  plugins: {
    "postcss-preset-env": {
      stage: 2,
    },
    "tailwindcss": {
      config: process.env["VB_TAILWIND_CONFIG"],
    },
    // "cssnano": {
    //   preset: "default",
    // },
  },
}
