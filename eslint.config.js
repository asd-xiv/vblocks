import { tsNodeConfig, devFilesConfig } from "@asd14/eslint-config"

/** @type {import("eslint").Linter.Config[]} */
export default [
  {
    ...tsNodeConfig,
    files: ["src/**/*.{js,ts}", "eslint.config.js"],
    languageOptions: {
      ...tsNodeConfig.languageOptions,
      parserOptions: {
        ...tsNodeConfig.languageOptions.parserOptions,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    ...devFilesConfig,
    files: ["eslint.config.js"],
  },
]
