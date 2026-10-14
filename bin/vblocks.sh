#!/usr/bin/env sh

# =============================================================================
# VBLOCKS - Webpack with opinionated configs
# =============================================================================
# This script helps JavaScript developers run common Webpack tasks without
# needing to remember complex command line arguments.
#
# Available Commands:
# ---
# init: Creates a new project from the template
# build: Creates a production-ready build of your project
# serve: Starts a development server with live reload
# eject: Prints a default config, save it in your project to customize it
#
# Usage Examples:
# ---
# npx vblocks init my-app                         # Create a project in ./my-app
# npx vblocks init my-flow --template xyflow      # Create a project with a specific template
# npx vblocks build                               # Build for production
# npx vblocks serve                               # Start dev server
# npx vblocks eject webpack > webpack.config.js   # Customize a config
# =============================================================================

# Directory where this script is located and
# default configuration file paths (from this package).
export VB_DIR="$(dirname "$(dirname "$(realpath "$0")")")"

# Project directory (where you run the command from) and
# project-specific config file paths.
export PROJECT_DIR="$(pwd)"

# Choose between project-specific and default configs. Project files take precedence.
select_config() {
  project_path="$PROJECT_DIR/$1"
  default_path=$(realpath "$VB_DIR/src/$1")
  [ -f "$project_path" ] && echo "$project_path" || echo "$default_path"
}

# Determine config files location.
export VB_WEBPACK_CONFIG="$(select_config "webpack.config.js")"
export VB_POSTCSS_CONFIG="$(select_config "postcss.config.js")"
export VB_SWC_CONFIG="$(select_config ".swcrc")"

# Wrap webpack command with custom configs
run_webpack() {
  action=$1
  shift 1

  robots_path="$PROJECT_DIR/src/public/robots.txt"
  if [ ! -f "$robots_path" ]; then
    robots_path="$VB_DIR/src/public/robots.txt"
  fi

  favicon_path="$PROJECT_DIR/src/public/favicon.svg"
  if [ ! -f "$favicon_path" ]; then
    favicon_path="$VB_DIR/src/public/favicon.svg"
  fi

  npx webpack "$action" --config "$VB_WEBPACK_CONFIG" \
    --env "entryDir=$PROJECT_DIR" \
    --env "robotsPath=$robots_path" \
    --env "faviconPath=$favicon_path" \
    "$@"
}

# Print the template names, one per line. A template is a folder in
# `template/` whose name has no `_` prefix
list_templates() {
  for list_dir in "$VB_DIR"/template/*/; do
    [ -d "$list_dir" ] || continue
    list_name=$(basename "$list_dir")

    case "$list_name" in
      _*) ;;
      *) printf '%s\n' "$list_name" ;;
    esac
  done
}

# Copy `template/_common`, then one template over it, into a directory that
# is missing or empty
init_project() {
  init_usage="Usage: vblocks init <directory> [--template <name>]"
  init_dir=""
  init_template="plain"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --template)
        if [ "$#" -lt 2 ]; then
          echo "$init_usage" >&2
          exit 1
        fi
        init_template=$2
        shift 2
        ;;
      -*)
        echo "$init_usage" >&2
        exit 1
        ;;
      *)
        if [ -n "$init_dir" ]; then
          echo "$init_usage" >&2
          exit 1
        fi
        init_dir=$1
        shift
        ;;
    esac
  done

  if [ -z "$init_dir" ]; then
    echo "$init_usage" >&2
    exit 1
  fi

  init_templates=$(list_templates)
  if ! printf '%s\n' "$init_templates" | grep -qxF -- "$init_template"; then
    printf 'Unknown template "%s". Available: %s\n' "$init_template" \
      "$(printf '%s\n' "$init_templates" | paste -sd, - | sed 's/,/, /g')" >&2
    exit 1
  fi

  if [ -e "$init_dir" ] && [ -n "$(ls -A -- "$init_dir")" ]; then
    printf '%s exists and is not empty\n' "$init_dir" >&2
    exit 1
  fi

  mkdir -p -- "$init_dir" || exit 1
  cp -R -- "$VB_DIR/template/_common/." "$init_dir" || exit 1
  cp -R -- "$VB_DIR/template/$init_template/." "$init_dir" || exit 1

  # npm leaves every `.gitignore` out of the package, so the template ships
  # `_gitignore`
  mv -- "$init_dir/_gitignore" "$init_dir/.gitignore" || exit 1

  init_name=$(basename "$(realpath "$init_dir")")
  init_version=$(node -p "require('$VB_DIR/package.json').version")

  (
    cd -- "$init_dir" \
      && npm pkg set "name=$init_name" \
        "devDependencies.@asd14/vblocks=^$init_version"
  ) || exit 1

  printf 'Created %s. Next:\n\n' "$init_name"
  printf '  cd %s\n' "$init_dir"
  printf '  npm install\n'
  printf '  npm start\n'
}

print_hero() {
  version=$(node -p "require('$VB_DIR/package.json').version")
  bold='\033[1m'
  green='\033[32m'
  blue='\033[34m'
  gray='\033[90m'
  reset='\033[0m'

  bold() { echo "${bold}$1${reset}"; }
  blue() { echo "${blue}$1${reset}"; }
  green() { echo "${green}$1${reset}"; }
  gray() { echo "${gray}$1${reset}"; }
  replace_home() { echo "$1" | sed "s|$HOME|~|g"; }
  replace_config_base() { echo "$1" | sed "s|$PROJECT_DIR|\$PROJECT_DIR|g" | sed "s|$VB_DIR|\$VBLOCKS_DIR|g"; }
  format_config_path() {
    if echo "$1" | grep -q "^$VB_DIR"; then
      gray "$(replace_config_base "$1")"
    else
      replace_config_base "$1"
    fi
  }

  printf "╭───────────┤ %b\n" "$(green " VBlocks v${version}")"
  printf "│ %b\n" "$(bold "󱆃 POSIX +  Webpack, an unlikely story!")"
  printf "│\n"
  printf "│ %b\n" "\$PROJECT_DIR: $(replace_home "$PROJECT_DIR")"
  printf "│ %b\n" "\$VBLOCKS_DIR: $(gray "$(replace_home "$VB_DIR")")"
  printf "│\n"
  printf "│ %b\n" " Webpack: $(format_config_path "$VB_WEBPACK_CONFIG")"
  printf "│ %b\n" " PostCSS: $(format_config_path "$VB_POSTCSS_CONFIG")"
  printf "│ %b\n" "󱡮 SWC: $(format_config_path "$VB_SWC_CONFIG")"
  printf "╰──┤\n\n"
}

# ╭──────────────────────
# │ Main
# ╰────────

# stdout carries the config `eject` prints, keep the hero out of it
print_hero >&2

case "$1" in
  init)
    shift
    init_project "$@"
    ;;
  build)
    shift
    # Without a mode Webpack falls back to `production`, also for `serve`.
    # A `--mode` in "$@" comes later, so it wins.
    run_webpack build --mode production "$@"
    ;;
  serve)
    shift
    run_webpack serve --mode development "$@"
    ;;
  eject)
    shift
    file=$1

    case "$file" in
      webpack)
        cat "$VB_DIR/src/webpack.config.js"
        ;;
      postcss)
        cat "$VB_DIR/src/postcss.config.js"
        ;;
      swc)
        cat "$VB_DIR/src/.swcrc"
        ;;
      *)
        echo "Unknown config file to eject. Available: webpack, postcss and swc" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    echo "Usage: $0 {init|build|serve|eject}" >&2
    exit 1
    ;;
esac
