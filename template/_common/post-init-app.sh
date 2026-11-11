#!/bin/sh

# Runs in the app folder, after `vblocks init` copies the app files. npm commands
# write in the nearest package.json, ie. project root

set -eu

# src/index.tsx renders the Agentation toolbar in development
npm pkg set "devDependencies.agentation=^3"
