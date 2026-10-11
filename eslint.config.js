import { tsConfig, commonIgnores } from "@asd14/eslint-config/ts"

const SRC_FILES = ["src/**/*.js", "bin/**/*.js"]
const TEST_FILES = ["src/**/*.test.ts"]
const DEV_FILES = ["eslint.config.js"]

/** @type {import("eslint").Linter.Config[]} */
export default [
  {
    ignores: [...commonIgnores],
  },
  {
    ...tsConfig,
    files: [...SRC_FILES, ...DEV_FILES, ...TEST_FILES],
  },
]
