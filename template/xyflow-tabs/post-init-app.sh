#!/bin/sh

# Runs in the app folder, after `vblocks init` copies the app files. npm commands
# write in the nearest package.json, ie. project root

set -eu

npm pkg set \
  "dependencies.@xyflow/react=^12" \
  "devDependencies.@tailwindcss/postcss=^4" \
  "devDependencies.cssnano=^9" \
  "devDependencies.tailwindcss=^4"

# Name the page in the browser tab.
# `sed -i` differs between GNU and BSD, so write a copy and move it over
sed 's|<title>.*</title>|<title>xyflow-tabs :: VBlocks</title>|' src/index.html >src/index.html.tmp
mv -- src/index.html.tmp src/index.html
