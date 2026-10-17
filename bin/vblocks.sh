#!/bin/sh

set -eu

# NAME
#   vblocks - Run Webpack with the configs of VBlocks, write a project or an app
#
# SYNOPSIS
#   vblocks init <directory>
#     [--template <plain|xyflow|xyflow-tabs>]
#     [--only <app|plumbing>]
#   vblocks serve
#     [--mode <development|production>]
#     [--prefix <directory>]
#     [--analyze]
#     [--log-level <error|warn|info|verbose>]
#     [<webpack option>...]
#   vblocks build
#     [--mode <development|production>]
#     [--prefix <directory>]
#     [--single-file]
#     [--log-level <error|warn|info|verbose>]
#     [<webpack option>...]
#   vblocks eject <webpack|postcss|swc>
#   vblocks -h | --help
#
# DESCRIPTION
#   The app folder holds src/index.tsx and src/index.html. A config in it,
#   webpack.config.js, postcss.config.js or .swcrc, replaces the default of
#   VBlocks with the same name.
#
#     init    Write a template into <directory>, which must be missing or
#             empty. A template has two parts: the plumbing, which holds
#             the files of the project folder, and the app. Without --only,
#             write both.
#             After each part, run its post-init hooks in <directory>.
#             Print each file it adds or updates, then the next steps
#     serve   Start the development server
#     build   Build the app into dist/ in the app folder, then print each
#             file in it
#     eject   Print a default config, to save in the app folder
#
#   serve and build pass every option not listed under OPTIONS to Webpack.
#
# OPTIONS
#   --template <name>       init: plain, xyflow or xyflow-tabs (default: plain)
#   --only <app|plumbing>   init: write only the app or only the plumbing.
#                           init adds the app's dependencies to the
#                           project folder: the nearest folder above
#                           <directory> with a package.json
#   --mode <mode>           serve, build: the Webpack mode, development or
#                           production (default: development for serve,
#                           production for build)
#   --prefix <directory>    serve, build: the app folder (default: the
#                           current folder)
#   --single-file           build: one standalone dist/index.html, every
#                           asset inlined
#   --analyze               serve: run the bundle analyzer, on a free port
#   --log-level <level>     serve, build: how much Webpack, its dev server and
#                           npm print: error, warn, info or verbose (default:
#                           warn)
#   -h, --help              Print this help
#
# ENVIRONMENT
#   NO_COLOR   When set and non-empty, print every summary without color
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
#   3   Could not run: a missing tool or project, or a failed folder, copy,
#       hook or build
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
LOG_LEVEL="warn"     # serve/build --log-level, error, warn, info or verbose
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
#   1   It is not, NO_COLOR is non-empty, or TERM is dumb or unset
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

# shorten_path <absolute-path>
#
# Print <absolute-path> relative to the current folder when it is inside it,
# otherwise with the home folder as "~".
shorten_path() {
  case "$1" in
    "$PWD") printf '.\n' ;;
    "$PWD"/*) printf '%s\n' "${1#"$PWD"/}" ;;
    *) shorten_home "$1" ;;
  esac
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
# Print the nearest folder above <directory> that holds a package.json.
# <directory> and the folders above it need not exist yet.
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
      # Drop "." and ".." from the path. The caller compares it with `pwd`
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
# Print <config-file> with its folder as $APP_DIR, or as $VBLOCKS_DIR in
# gray for a default config.
show_config_file() {
  case "$1" in
    "$2"/*) printf '%s\n' "\$APP_DIR/${1#"$2"/}" ;;
    "$VB_DIR"/*) printf '%s\n' "${GRAY}\$VBLOCKS_DIR/${1#"$VB_DIR"/}${RESET}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# print_title
#
# Print the first line of a summary box: the name and the version.
print_title() {
  printf '╭───────────┤ %s\n' "${GREEN} VBlocks v${VB_VERSION}${RESET}"
}

# snapshot_folder <dir>
#
# Print one line per file in <dir>: its checksum, a tab, its path relative to
# <dir>. Skip node_modules/, dist/ and .git/. init never writes there, and
# they can hold thousands of files.
snapshot_folder() {
  (cd -- "$1" && find . \( -name node_modules -o -name dist -o -name .git \) \
    -prune -o -type f -print) \
    | sed 's|^\./||' \
    | LC_ALL=C sort \
    | while IFS= read -r snapshot_file; do
      printf '%s\t%s\n' "$(cksum <"$1/$snapshot_file")" "$snapshot_file"
    done
}

# print_snapshot_diff <before-snapshot> <after-snapshot> <app-subdir>
#
# Print "add", "update" or "drop" for each file that differs between two
# snapshots of the project folder. A path inside <app-subdir> prints as
# $APP_DIR/..., the rest as $PROJECT_DIR/... <app-subdir> is "." when the app
# is the project folder, empty when there is no app.
print_snapshot_diff() {
  # Every snapshot line has a tab. The AFTER line has none, so it marks where
  # the second snapshot starts
  {
    printf '%s\n' "$1"
    printf 'AFTER\n'
    printf '%s\n' "$2"
  } | awk -F '\t' -v app="$3" '
    function label(path) {
      if (app == ".") return "$APP_DIR/" path
      if (app != "" && index(path, app "/") == 1) {
        return "$APP_DIR/" substr(path, length(app) + 2)
      }
      return "$PROJECT_DIR/" path
    }

    NF < 2 { is_after = 1; next }
    !is_after { before[$2] = $1; next }
    {
      seen[$2] = 1
      if (!($2 in before)) printf "%-8s%s\n", "add", label($2)
      else if (before[$2] != $1) printf "%-8s%s\n", "update", label($2)
    }
    END {
      for (path in before) {
        if (!(path in seen)) printf "%-8s%s\n", "drop", label(path)
      }
    }
  '
}

# print_build_files <app-dir>
#
# Print each file in the dist/ of <app-dir> as $APP_DIR/dist/..., a tab and its
# size, then the total size. Webpack empties dist/ before each build, so every
# file there is from the last build.
print_build_files() {
  # An ejected config can write elsewhere
  [ -d "$1/dist" ] || return 0

  (cd -- "$1/dist" && find . -type f | LC_ALL=C sort) \
    | while IFS= read -r build_file; do
      printf '%s\t%s\n' "$(wc -c <"$1/dist/$build_file")" "${build_file#./}"
    done \
    | awk -F '\t' '
      function format_size(bytes) {
        if (bytes < 1024) return bytes " B"
        if (bytes < 1024 * 1024) return sprintf("%.1f KiB", bytes / 1024)
        return sprintf("%.1f MiB", bytes / 1024 / 1024)
      }

      { total += $1; printf "$APP_DIR/dist/%s\t%s\n", $2, format_size($1) }
      END { printf "\nTotal\t%s\n", format_size(total) }
    '
}

# print_init_summary <parts> <template> <project-dir> <app-dir>
#
# Print the version, the parts of <template> that init writes and their
# folders, to stderr. <app-dir> is empty when init writes no app.
print_init_summary() {
  case "$1" in
    plumbing) summary_parts="plumbing" ;;
    app) summary_parts="app, $2" ;;
    *) summary_parts="plumbing and app, $2" ;;
  esac

  {
    print_title
    printf '│ %s\n' "init: $summary_parts"
    printf '│\n'

    # When plumbing and app share one folder, print it once, as $APP_DIR
    if [ "$3" != "$4" ]; then
      printf '│ %s\n' "\$PROJECT_DIR: $(shorten_home "$3")"
    fi
    if [ -n "$4" ]; then
      printf '│ %s\n' "\$APP_DIR:     $(shorten_home "$4")"
    fi

    printf '╰──┤\n\n'
  } >&2
}

# print_summary <app-dir> <webpack-config> <postcss-config> <swc-config>
#
# Print the version, the app folder and the configs Webpack runs with, to
# stderr.
print_summary() {
  {
    print_title
    printf '│ %s\n' "${BOLD}󱆃 POSIX +  Webpack, an unlikely story!${RESET}"
    printf '│\n'
    printf '│ %s\n' "\$APP_DIR:     $(shorten_home "$1")"
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

  # npm echoes every npx call at notice, the level between warn and info
  case "$LOG_LEVEL" in
    info) webpack_npm_level="notice" ;;
    *) webpack_npm_level=$LOG_LEVEL ;;
  esac

  webpack_status=0
  npx --loglevel="$webpack_npm_level" webpack "$webpack_action" \
    --config "$webpack_config" \
    --env "entryDir=$webpack_app_dir" \
    --env "logLevel=$LOG_LEVEL" \
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
            fail 2 "init takes one folder"
          fi
          INIT_DIR=$1
          shift
          ;;
        -?*)
          fail 2 "Unknown flag $1"
          ;;
        *)
          [ -n "$INIT_DIR" ] && fail 2 "init takes one folder"
          INIT_DIR=$1
          shift
          ;;
      esac
    done

    [ -z "$INIT_DIR" ] && fail 2 "init needs a folder"

    # One shape for the printed paths: no trailing "/", and no leading "-" that
    # a command would read as a flag
    while [ "$INIT_DIR" != "/" ] && [ "${INIT_DIR%/}" != "$INIT_DIR" ]; do
      INIT_DIR=${INIT_DIR%/}
    done
    case "$INIT_DIR" in
      -*) INIT_DIR="./$INIT_DIR" ;;
    esac

    # `grep -q` stops reading at the first match, and list_templates then
    # writes to a closed pipe
    if ! list_templates | grep -xF -- "$TEMPLATE" >/dev/null; then
      fail 2 "Unknown template \"$TEMPLATE\". Available: $(list_templates | paste -sd ' ' -)"
    fi
    ;;
  serve | build)
    # Take the flags of VBlocks out of the arguments. Webpack gets the rest
    ARG_COUNT=$#
    while [ "$ARG_COUNT" -gt 0 ]; do
      ARG=$1
      shift
      ARG_COUNT=$((ARG_COUNT - 1))

      case "$ARG" in
        --prefix)
          [ "$ARG_COUNT" -eq 0 ] && fail 2 "--prefix needs a folder"
          PREFIX=$1
          shift
          ARG_COUNT=$((ARG_COUNT - 1))
          ;;
        --log-level)
          [ "$ARG_COUNT" -eq 0 ] && fail 2 "--log-level needs a level"
          case "$1" in
            error | warn | info | verbose) LOG_LEVEL=$1 ;;
            *) fail 2 "Unknown level \"$1\", use error, warn, info or verbose" ;;
          esac
          shift
          ARG_COUNT=$((ARG_COUNT - 1))
          ;;
        --single-file)
          [ "$COMMAND" = "build" ] || fail 2 "--single-file works only with build"
          # The Webpack config does the work. An ejected config supports the
          # flag only while it reads env.single
          set -- "$@" --env single
          ;;
        --analyze)
          [ "$COMMAND" = "serve" ] || fail 2 "--analyze works only with serve"
          # The Webpack config does the work. An ejected config supports the
          # flag only while it reads env.analyze
          set -- "$@" --env analyze
          ;;
        *)
          set -- "$@" "$ARG"
          ;;
      esac
    done

    if [ -n "$PREFIX" ] && [ ! -d "$PREFIX" ]; then
      fail 2 "$PREFIX is not a folder"
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

    # An app needs a project folder. The app hooks write to its package.json
    PROJECT_DIR=""
    if [ "$PARTS" = "app" ]; then
      PROJECT_DIR=$(find_project_root "$INIT_DIR") \
        || fail 3 "No package.json above $INIT_DIR. Write the project first: npx @asd14/vblocks init <directory> --only plumbing"
    fi

    mkdir -p -- "$INIT_DIR" || fail 3 "Could not add $INIT_DIR"
    INIT_ABS_DIR=$(cd -- "$INIT_DIR" && pwd)

    case "$PARTS" in
      plumbing)
        PROJECT_DIR=$INIT_ABS_DIR
        APP_DIR=""
        APP_SUBDIR=""
        ;;
      app)
        APP_DIR=$INIT_ABS_DIR
        APP_SUBDIR=${APP_DIR#"$PROJECT_DIR"/}
        ;;
      *)
        PROJECT_DIR=$INIT_ABS_DIR
        APP_DIR=$INIT_ABS_DIR
        APP_SUBDIR="."
        ;;
    esac

    BEFORE_SNAPSHOT=$(snapshot_folder "$PROJECT_DIR")
    init_project "$INIT_DIR" "$TEMPLATE" "$PARTS"
    AFTER_SNAPSHOT=$(snapshot_folder "$PROJECT_DIR")

    print_init_summary "$PARTS" "$TEMPLATE" "$PROJECT_DIR" "$APP_DIR"
    print_snapshot_diff "$BEFORE_SNAPSHOT" "$AFTER_SNAPSHOT" "$APP_SUBDIR"

    case "$PARTS" in
      plumbing)
        printf '\nNext, add an app:\n'
        printf '  npx @asd14/vblocks init %s/<app> --only app\n' "$INIT_DIR"
        ;;
      app)
        printf '\nNext:\n'
        if [ "$PROJECT_DIR" != "$PWD" ]; then
          printf '  cd %s\n' "$(shorten_path "$PROJECT_DIR")"
        fi
        printf '  npm install\n'
        printf '  npx vblocks serve --prefix %s\n' "$APP_SUBDIR"
        ;;
      *)
        printf '\nNext:\n'
        printf '  cd %s\n' "$INIT_DIR"
        printf '  npm install\n'
        printf '  npx vblocks serve\n'
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
    # "$@" comes later, so it overrides this one
    if [ "$COMMAND" = "build" ]; then
      run_webpack build "$APP_DIR" "$WEBPACK_CONFIG" --mode production "$@"
      printf '\n'
      print_build_files "$APP_DIR"
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
