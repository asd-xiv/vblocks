#!/bin/sh

set -eu

# NAME
#   vblocks - Run Webpack with the configs of VBlocks, write a project
#
# SYNOPSIS
#   vblocks init <directory> [--template <name>] [--only <app|plumbing>]
#   vblocks serve [--mode <mode>] [--prefix <directory>] [<webpack option>...]
#   vblocks build [--mode <mode>] [--prefix <directory>] [--single-file]
#                 [<webpack option>...]
#   vblocks eject <webpack|postcss|swc>
#   vblocks -h | --help
#
# DESCRIPTION
#   The app folder holds src/index.tsx and src/index.html. A config in it,
#   webpack.config.js, postcss.config.js or .swcrc, replaces the default of
#   VBlocks with the same name.
#
#     init    Write a template into <directory>, which must be missing or
#             empty. A template has two parts: the plumbing, the files of
#             the project root, and the app. Without --only, write both.
#             After each part, run its post-init hooks in <directory>
#     serve   Start the development server
#     build   Build the app into dist/ in the app folder
#     eject   Print a default config, to save in the app folder
#
#   serve and build pass every option not listed under OPTIONS to Webpack.
#
# OPTIONS
#   --template <name>       init: plain or xyflow (default: plain)
#   --only <part>           init: write only the app or only the plumbing.
#                           The app goes into a project: the nearest folder
#                           above <directory> with a package.json
#   --mode <mode>           serve, build: the Webpack mode, development or
#                           production (default: development for serve,
#                           production for build)
#   --prefix <directory>    serve, build: the app folder (default: the
#                           current folder)
#   --single-file           build: one standalone dist/index.html, every
#                           asset inlined
#   -h, --help              Print this help
#
# ENVIRONMENT
#   NO_COLOR   Disables color in the summary of serve and build when set and
#              non-empty
#
# EXAMPLE
#   npx @asd14/vblocks init my-app
#   npx @asd14/vblocks init demos --only plumbing
#   npx @asd14/vblocks init demos/flow --template xyflow --only app
#   npx vblocks build --prefix flow --single-file
#   npx vblocks eject postcss > postcss.config.js
#
# EXIT CODES
#   0   Done
#   2   Invalid usage, or Webpack rejected an option or the config
#   3   Could not run: a missing tool or project, a failed copy, hook or
#       build
#
# SEE ALSO
#   webpack, npm

# npm links the command to this file, so "$0" names the link. realpath follows
# it to the package
VB_DIR=$(dirname "$(dirname "$(realpath "$0")")")

# `cd` follows an exported CDPATH and prints the folder it picked, which
# `$(cd ... && pwd)` would capture
unset CDPATH

# ╭───
# │ Settings
# ╰───

COMMAND=""           # init, serve, build or eject
INIT_DIR=""          # init <directory>
TEMPLATE="plain"     # init --template
PARTS="plumbing app" # init --only, "plumbing" or "app"
PREFIX=""            # serve/build --prefix, the app folder
EJECT_CONFIG=""      # eject <config>

# ╭───
# │ Primitives
# ╰───

# fail <code> <message>
#
# Print <message> to stderr, then exit with <code>.
fail() {
  printf 'vblocks: %s\n' "$2" >&2
  exit "$1"
}

# show_help
#
# Print the man page: the comment block that starts at the NAME line.
show_help() {
  sed -n '/^# NAME$/,/^$/p' "$0" | sed 's/^# \{0,1\}//'
}

# require_cmd <cmd>...
#
# EXIT
#   3   The shell finds no <cmd>
require_cmd() {
  for require_name in "$@"; do
    command -v "$require_name" >/dev/null 2>&1 \
      || fail 3 "$require_name is not installed"
  done
}

# has_color
#
# RETURNS
#   0   stderr is a terminal that shows color
#   1   It is not, or NO_COLOR is set
has_color() {
  [ -t 2 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != "dumb" ]
}

# pick_file <file> <default-file>
#
# Print <file> when it exists, otherwise <default-file>.
pick_file() {
  if [ -f "$1" ]; then
    printf '%s\n' "$1"
  else
    printf '%s\n' "$2"
  fi
}

# shorten_home <path>
#
# Print <path> with the home folder as "~".
shorten_home() {
  if [ -n "${HOME:-}" ]; then
    case "$1" in
      "$HOME"/*)
        # shellcheck disable=SC2088 # a literal "~", for display
        printf '~/%s\n' "${1#"$HOME"/}"
        return 0
        ;;
    esac
  fi

  printf '%s\n' "$1"
}

# ╭───
# │ Domain primitives
# ╰───

# list_templates
#
# Print the template names, one per line. A template is a folder in
# `template/` whose name has no `_` prefix.
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

# find_project_root <directory>
#
# Print the nearest folder above <directory> that holds a package.json. The
# folders of <directory> need not exist yet.
#
# RETURNS
#   1   No folder above <directory> holds one
find_project_root() {
  case "$1" in
    /*) root_dir=$1 ;;
    *) root_dir="$PWD/$1" ;;
  esac

  while [ "$root_dir" != "/" ]; do
    root_dir=$(dirname "$root_dir")

    if [ -f "$root_dir/package.json" ]; then
      # Drop "." and ".." from the path, the caller compares it with `pwd`
      (cd -- "$root_dir" && pwd)
      return 0
    fi
  done

  return 1
}

# init_project <directory> <template> <parts>
#
# Copy the <parts> of <template> into <directory>, then run the hooks of each
# part in it. <parts> is "plumbing", "app" or "plumbing app". A template's file
# replaces the `_common` file of the same path.
#
# EXIT
#   3   A copy or a hook failed
init_project() {
  init_dir=$1
  init_template=$2

  for init_part in $3; do
    for init_source in "$VB_DIR/template/_common" "$VB_DIR/template/$init_template"; do
      [ -d "$init_source/$init_part" ] || continue

      cp -R -- "$init_source/$init_part/." "$init_dir" \
        || fail 3 "Could not copy $init_source/$init_part"
    done

    for init_source in "$VB_DIR/template/_common" "$VB_DIR/template/$init_template"; do
      init_hook="$init_source/post-init-$init_part.sh"
      [ -f "$init_hook" ] || continue

      # A hook reads VB_VERSION, and nothing else of this script
      (cd -- "$init_dir" && VB_VERSION="$VB_VERSION" sh "$init_hook") \
        || fail 3 "The hook $init_hook failed"
    done
  done
}

# show_config_file <config-file> <app-dir>
#
# Print <config-file> with its folder as $PROJECT_DIR, or as $VBLOCKS_DIR in
# gray for a default config.
show_config_file() {
  case "$1" in
    "$2"/*) printf '%s\n' "\$PROJECT_DIR/${1#"$2"/}" ;;
    "$VB_DIR"/*) printf '%s\n' "${GRAY}\$VBLOCKS_DIR/${1#"$VB_DIR"/}${RESET}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# print_summary <app-dir> <webpack-config> <postcss-config> <swc-config>
#
# Print the version, the app folder and the configs Webpack runs with, to
# stderr.
print_summary() {
  {
    printf '╭───────────┤ %s\n' "${GREEN} VBlocks v${VB_VERSION}${RESET}"
    printf '│ %s\n' "${BOLD}󱆃 POSIX +  Webpack, an unlikely story!${RESET}"
    printf '│\n'
    printf '│ %s\n' "\$PROJECT_DIR: $(shorten_home "$1")"
    printf '│ %s\n' "\$VBLOCKS_DIR: ${GRAY}$(shorten_home "$VB_DIR")${RESET}"
    printf '│\n'
    printf '│ %s\n' " Webpack: $(show_config_file "$2" "$1")"
    printf '│ %s\n' " PostCSS: $(show_config_file "$3" "$1")"
    printf '│ %s\n' "󱡮 SWC: $(show_config_file "$4" "$1")"
    printf '╰──┤\n\n'
  } >&2
}

# run_webpack <action> <app-dir> <webpack-config> [<webpack option>...]
#
# Run `webpack <action>` for the app in <app-dir>.
#
# EXIT
#   2   Webpack rejected an option or the config
#   3   Webpack failed
run_webpack() {
  webpack_action=$1
  webpack_app_dir=$2
  webpack_config=$3
  shift 3

  webpack_robots_file=$(pick_file \
    "$webpack_app_dir/src/public/robots.txt" "$VB_DIR/src/public/robots.txt")
  webpack_favicon_file=$(pick_file \
    "$webpack_app_dir/src/public/favicon.svg" "$VB_DIR/src/public/favicon.svg")

  webpack_status=0
  npx webpack "$webpack_action" --config "$webpack_config" \
    --env "entryDir=$webpack_app_dir" \
    --env "robotsPath=$webpack_robots_file" \
    --env "faviconPath=$webpack_favicon_file" \
    "$@" || webpack_status=$?

  # webpack-cli exits 1 when the build has errors, 2 when an option or the
  # config is wrong
  case "$webpack_status" in
    0) return 0 ;;
    2) fail 2 "Webpack rejected an option or the config" ;;
    *) fail 3 "Webpack failed" ;;
  esac
}

# ╭───
# │ Bootstrap
# ╰───

case "${1:-}" in
  -h | --help)
    show_help
    exit 0
    ;;
  "")
    show_help
    exit 2
    ;;
esac

require_cmd node npx

VB_VERSION=$(node -p 'require(process.argv[1]).version' "$VB_DIR/package.json")

# Color codes for stderr, empty when it shows no color
BOLD="" GREEN="" GRAY="" RESET=""
if has_color; then
  BOLD=$(printf '\033[1m')
  GREEN=$(printf '\033[32m')
  GRAY=$(printf '\033[90m')
  RESET=$(printf '\033[0m')
fi

# ╭───
# │ Flags and positionals
# ╰───

COMMAND=$1
shift

case "$COMMAND" in
  init)
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --template)
          [ "$#" -lt 2 ] && fail 2 "--template needs a name"
          TEMPLATE=$2
          shift 2
          ;;
        --only)
          [ "$#" -lt 2 ] && fail 2 "--only needs a part, app or plumbing"
          case "$2" in
            app | plumbing) PARTS=$2 ;;
            *) fail 2 "Unknown part \"$2\", use app or plumbing" ;;
          esac
          shift 2
          ;;
        --)
          shift
          if [ "$#" -ne 1 ] || [ -n "$INIT_DIR" ]; then
            fail 2 "init takes one directory"
          fi
          INIT_DIR=$1
          shift
          ;;
        -?*)
          fail 2 "Unknown flag $1"
          ;;
        *)
          [ -n "$INIT_DIR" ] && fail 2 "init takes one directory"
          INIT_DIR=$1
          shift
          ;;
      esac
    done

    [ -z "$INIT_DIR" ] && fail 2 "init needs a directory"

    if ! list_templates | grep -qxF -- "$TEMPLATE"; then
      fail 2 "Unknown template \"$TEMPLATE\". Available: $(list_templates | paste -sd ' ' -)"
    fi
    ;;
  serve | build)
    # Take the flags of VBlocks out of the arguments, Webpack gets the rest
    ARG_COUNT=$#
    while [ "$ARG_COUNT" -gt 0 ]; do
      ARG=$1
      shift
      ARG_COUNT=$((ARG_COUNT - 1))

      case "$ARG" in
        --prefix)
          [ "$ARG_COUNT" -eq 0 ] && fail 2 "--prefix needs a directory"
          PREFIX=$1
          shift
          ARG_COUNT=$((ARG_COUNT - 1))
          ;;
        --single-file)
          [ "$COMMAND" = "build" ] || fail 2 "--single-file works only with build"
          # webpack.config.js reads env.single, an ejected one too
          set -- "$@" --env single
          ;;
        *)
          set -- "$@" "$ARG"
          ;;
      esac
    done

    if [ -n "$PREFIX" ] && [ ! -d "$PREFIX" ]; then
      fail 2 "$PREFIX is not a directory"
    fi
    ;;
  eject)
    [ "$#" -ne 1 ] && fail 2 "eject needs one config: webpack, postcss or swc"

    case "$1" in
      webpack) EJECT_CONFIG="webpack.config.js" ;;
      postcss) EJECT_CONFIG="postcss.config.js" ;;
      swc) EJECT_CONFIG=".swcrc" ;;
      *) fail 2 "Unknown config \"$1\", use webpack, postcss or swc" ;;
    esac
    ;;
  *)
    fail 2 "Unknown command \"$COMMAND\", use init, serve, build or eject"
    ;;
esac

# ╭───
# │ Main
# ╰───

case "$COMMAND" in
  init)
    if [ -e "$INIT_DIR" ]; then
      if [ ! -d "$INIT_DIR" ] || [ -n "$(ls -A -- "$INIT_DIR")" ]; then
        fail 2 "$INIT_DIR exists and is not an empty folder"
      fi
    fi

    # An app joins a project, the app hooks write its package.json
    PROJECT_ROOT=""
    if [ "$PARTS" = "app" ]; then
      PROJECT_ROOT=$(find_project_root "$INIT_DIR") \
        || fail 3 "No package.json above $INIT_DIR. Write the project first: npx @asd14/vblocks init <directory> --only plumbing"
    fi

    mkdir -p -- "$INIT_DIR" || fail 3 "Could not create $INIT_DIR"
    init_project "$INIT_DIR" "$TEMPLATE" "$PARTS"

    case "$PARTS" in
      plumbing)
        printf 'Wrote %s. Add an app:\n\n' "$INIT_DIR" >&2
        printf '  npx @asd14/vblocks init %s/<app> --only app\n' "$INIT_DIR" >&2
        ;;
      app)
        APP_DIR=$(cd -- "$INIT_DIR" && pwd)
        printf 'Wrote %s. Next, in %s:\n\n' "$INIT_DIR" "$PROJECT_ROOT" >&2
        printf '  npm install\n' >&2
        printf '  npm start -- --prefix %s\n' "${APP_DIR#"$PROJECT_ROOT"/}" >&2
        ;;
      *)
        printf 'Wrote %s. Next:\n\n' "$INIT_DIR" >&2
        printf '  cd %s\n' "$INIT_DIR" >&2
        printf '  npm install\n' >&2
        printf '  npm start\n' >&2
        ;;
    esac
    exit 0
    ;;
  serve | build)
    APP_DIR=$(cd -- "${PREFIX:-.}" && pwd)
    WEBPACK_CONFIG=$(pick_file "$APP_DIR/webpack.config.js" "$VB_DIR/src/webpack.config.js")

    # webpack.config.js reads them
    VB_POSTCSS_CONFIG=$(pick_file "$APP_DIR/postcss.config.js" "$VB_DIR/src/postcss.config.js")
    VB_SWC_CONFIG=$(pick_file "$APP_DIR/.swcrc" "$VB_DIR/src/.swcrc")
    export VB_POSTCSS_CONFIG VB_SWC_CONFIG

    print_summary "$APP_DIR" "$WEBPACK_CONFIG" "$VB_POSTCSS_CONFIG" "$VB_SWC_CONFIG"

    # Without a mode, Webpack takes `production`, also for `serve`. A --mode in
    # "$@" comes later, so it wins
    if [ "$COMMAND" = "build" ]; then
      run_webpack build "$APP_DIR" "$WEBPACK_CONFIG" --mode production "$@"
    else
      run_webpack serve "$APP_DIR" "$WEBPACK_CONFIG" --mode development "$@"
    fi
    exit 0
    ;;
  eject)
    cat -- "$VB_DIR/src/$EJECT_CONFIG"
    exit 0
    ;;
esac
