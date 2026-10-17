#!/bin/sh

# Runs in the app folder, after `vblocks init` copies the app files. npm writes
# the nearest package.json, the project root's

set -eu

npm pkg set \
  "dependencies.@xyflow/react=^12" \
  "devDependencies.@tailwindcss/postcss=^4" \
  "devDependencies.tailwindcss=^4"

# Name the page in the browser tab.
# `sed -i` differs between GNU and BSD, so write a copy and move it over
sed 's|<title>.*</title>|<title>xyflow :: VBlocks</title>|' src/index.html >src/index.html.tmp
mv -- src/index.html.tmp src/index.html
