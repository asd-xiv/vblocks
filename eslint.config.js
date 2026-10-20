import path from "node:path"
import { tsConfig, getIgnorePatterns } from "@asd14/eslint-config/ts"

const GIT_IGNORE_PATTERNS = getIgnorePatterns(
  path.join(import.meta.dirname, ".gitignore")
)
const SRC_FILES = ["defaults/**/*.js", "bin/**/*.js", "types/*.ts"]
const DEV_FILES = ["eslint.config.js"]

/** @type {import("eslint").Linter.Config[]} */
export default [
  {
    ignores: [...GIT_IGNORE_PATTERNS, "template/"],
  },
  {
    ...tsConfig,
    files: [...SRC_FILES, ...DEV_FILES],
  },
]
