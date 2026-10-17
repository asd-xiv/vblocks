#!/bin/sh

# Runs in the app folder, after `vblocks init` copies the app files

set -eu

# Name the page in the browser tab.
# `sed -i` differs between GNU and BSD, so write a copy and move it over
sed 's|<title>.*</title>|<title>Hello World :: VBlocks</title>|' src/index.html >src/index.html.tmp
mv -- src/index.html.tmp src/index.html
