#!/bin/sh

# Runs in the app folder, after `vblocks init` copies the app files. npm writes
# the nearest package.json, the project root's

set -eu

npm pkg set \
  "dependencies.@xyflow/react=^12" \
  "devDependencies.@tailwindcss/postcss=^4" \
  "devDependencies.tailwindcss=^4"
