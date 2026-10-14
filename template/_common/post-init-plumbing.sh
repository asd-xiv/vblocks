#!/bin/sh

# Runs in the project root, after `vblocks init` copies the plumbing files.
# vblocks exports VB_VERSION

set -eu

# npm leaves every `.gitignore` out of the package, so the template ships
# `_gitignore`
mv -- _gitignore .gitignore

npm pkg set \
  "name=$(basename "$PWD")" \
  "devDependencies.@asd14/vblocks=^${VB_VERSION}"
