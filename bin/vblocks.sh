#!/usr/bin/env sh

# =============================================================================
# VBLOCKS - Webpack with opinionated configs
# =============================================================================
# This script helps JavaScript developers run common Webpack tasks without
# needing to remember complex command line arguments.
#
# Available Commands:
# ---
# build: Creates a production-ready build of your project
# serve: Starts a development server with live reload
# eject: Copies default webpack and swc configs to your project for customization
#
# Usage Examples:
# ---
# npx vblocks build    # Build for production
# npx vblocks serve    # Start dev server
# npx vblocks eject    # Copy config files to your project
# =============================================================================

# Directory where this script is located and
# default configuration file paths (from this package).
export VB_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"

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
export VB_TAILWIND_CONFIG="$(select_config "tailwind.config.js")"
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

# Copy config files to your project
copy_config_files() {
  project_path="$PROJECT_DIR/$1"
  default_path=$(realpath "$VB_DIR/$1")

  if [ ! -f "$project_path" ]; then
    cp "$default_path" "$project_path" \
      && echo "Created $1 in your project" >&2
  fi
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
  printf "│ %b\n" " Tailwind: $(format_config_path "$VB_TAILWIND_CONFIG")"
  printf "│ %b\n" "󱡮 SWC: $(format_config_path "$VB_SWC_CONFIG")"
  printf "╰──┤\n\n"
}

# ╭──────────────────────
# │ Main
# ╰────────

print_hero

case "$1" in
  build)
    shift
    run_webpack build "$@"
    ;;
  serve)
    shift
    run_webpack serve "$@"
    ;;
  eject)
    shift
    file=$1

    case "$file" in
      webpack)
        cat "$VB_DIR/webpack.config.js"
        ;;
      *)
        echo "Unknown config file to eject. Available: webpack, postcss, tailwind and swc" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    echo "Usage: $0 {build|serve|eject}" >&2
    exit 1
    ;;
esac
