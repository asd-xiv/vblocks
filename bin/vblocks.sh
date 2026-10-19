#!/bin/sh

set -eu

# NAME
#   vblocks - Write a project or an app, then serve or build it with Webpack
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
#   webpack.config.js, postcss.config.js or .swcrc, replaces the VBlocks
#   default of the same name.
#
#     init    Write a template into <directory>, which must be missing or
#             empty. A template has two parts: the plumbing, which holds
#             the files of the project folder, and the app. Without --only,
#             write both.
#             After each part, run its post-init hooks in <directory>.
#             Print each file it adds, updates or drops, then the next
#             steps.
#     serve   Start the development server
#     build   Build the app into dist/ in the app folder. Print each file
#             in dist/, its size and the total
#     eject   Print a default config, to save in the app folder
#
#   serve and build pass every option not listed under OPTIONS to Webpack.
#
# OPTIONS
#   --template <name>       init: plain, xyflow or xyflow-tabs (default: plain)
#   --only <app|plumbing>   init: write only the app or only the plumbing.
#                           With app, init adds the app's dependencies to
#                           the package.json in the parent folder of
#                           <directory>. Without that file, init exits 3
#   --mode <mode>           serve, build: the Webpack mode, development or
#                           production (default: development for serve,
#                           production for build)
#   --prefix <directory>    serve, build: the app folder (default: the
#                           current folder)
#   --single-file           build: one standalone dist/index.html, every
#                           asset inlined
#   --analyze               serve: run the bundle analyzer, on a free port
#   --log-level <level>     serve, build: how much Webpack and its dev server
#                           print: error, warn, info or verbose (default:
#                           warn)
#   -h, --help              Print this help
#
# ENVIRONMENT
#   NO_COLOR   When non-empty, print without color, the tool icons or the
#              header
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
#   3   Could not run: a missing tool or parent package.json, a folder init
#       could not add, or a failed copy, hook or Webpack run
#
# SEE ALSO
#   webpack, npm

# npm links the command to this file, so "$0" names the link. realpath follows
# it to the package
_VB_DIR=$(dirname "$(dirname "$(realpath "$0")")")

# tools/update-lib downloads it from @asd14/posix-utils. Never edit it here
# shellcheck source=lib.sh
. "$_VB_DIR/bin/lib.sh"

# _log reads them. VBlocks logs only errors, through _fail. The time adds no
# fact to an error
LOG_NAMESPACE="vblocks"
LOG_LEVEL="info"
NO_LOG_TIME="true"

# `cd` follows an exported CDPATH and prints the folder it picked, which
# `$(cd ... && pwd)` would capture
unset CDPATH

# ╭───
# │ Settings
# ╰───

_COMMAND=""           # init, serve, build or eject
_INIT_DIR=""          # init <directory>
_TEMPLATE="plain"     # init --template
_PARTS="plumbing app" # init --only: "plumbing", "app" or "plumbing app"
_PREFIX_DIR=""        # serve/build --prefix, the app folder
_LOG_LEVEL="warn"     # serve/build --log-level, error, warn, info or verbose
_EJECT_CONFIG=""      # eject <config>

# ╭───
# │ Primitives
# ╰───

# _pick_file <file> <default-file>
#
# Print <file> when it exists, otherwise <default-file>.
_pick_file() {
  if [ -f "$1" ]; then
    printf '%s\n' "$1"
  else
    printf '%s\n' "$2"
  fi
}

# _shorten_home <path>
#
# Print <path> with the home folder as "~".
_shorten_home() {
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

# _shorten_path <absolute-path>
#
# Print <absolute-path> relative to the current folder when it is inside it,
# otherwise with the home folder as "~".
_shorten_path() {
  case "$1" in
    "$PWD") printf '.\n' ;;
    "$PWD"/*) printf '%s\n' "${1#"$PWD"/}" ;;
    *) _shorten_home "$1" ;;
  esac
}

# ╭───
# │ Domain primitives
# ╰───

# _list_templates
#
# Print the template names, one per line. A template is a folder in
# `template/` whose name has no `_` prefix.
_list_templates() {
  for lt_dir in "$_VB_DIR"/template/*/; do
    [ -d "$lt_dir" ] || continue
    lt_name=$(basename "$lt_dir")

    case "$lt_name" in
      _*) ;;
      *) printf '%s\n' "$lt_name" ;;
    esac
  done
}

# _init_project <directory> <template> <parts>
#
# For each of <parts>, copy it from <template> into <directory>, then run its
# hooks there. <parts> is "plumbing", "app" or "plumbing app". A template's file
# replaces the `_common` file of the same path.
#
# EXIT
#   3   A copy or a hook failed
_init_project() {
  ip_dir=$1
  ip_template=$2

  for ip_part in $3; do
    for ip_source in "$_VB_DIR/template/_common" "$_VB_DIR/template/$ip_template"; do
      [ -d "$ip_source/$ip_part" ] || continue

      cp -R -- "$ip_source/$ip_part/." "$ip_dir" \
        || _fail 3 -v file "$ip_source/$ip_part" "Could not copy"
    done

    for ip_source in "$_VB_DIR/template/_common" "$_VB_DIR/template/$ip_template"; do
      ip_hook="$ip_source/post-init-$ip_part.sh"
      [ -f "$ip_hook" ] || continue

      # A hook reads VB_VERSION, and nothing else of this script
      (cd -- "$ip_dir" && VB_VERSION="$_VB_VERSION" sh "$ip_hook") \
        || _fail 3 -v hook "$ip_hook" "The hook failed"
    done
  done
}

# _show_config_file <config-file> <app-dir>
#
# Print <config-file> with its folder as $APP_DIR, or as $VBLOCKS_DIR in
# gray for a default config.
_show_config_file() {
  case "$1" in
    "$2"/*) printf '%s\n' "\$APP_DIR/${1#"$2"/}" ;;
    "$_VB_DIR"/*) printf '%s\n' "${_GRAY}\$VBLOCKS_DIR/${1#"$_VB_DIR"/}${_RESET}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# _print_title_box <title>
#
# Print the name and the version of VBlocks in the top border, then <title>,
# then close the box. The lines after it hold the details. Print nothing
# unless _IS_TERMINAL is set. The header holds no fact a reader acts on.
_print_title_box() {
  [ -n "$_IS_TERMINAL" ] || return 0

  printf '╭───────────┤ %s\n' "${_GREEN} VBlocks v${_VB_VERSION}${_RESET}"
  printf '│ %s\n' "$1"
  printf '╰──┤\n'
}

# _snapshot_folder <dir>
#
# Print one line per file in <dir>: its checksum and size, a tab, its path
# relative to <dir>. Skip node_modules/, dist/ and .git/. init never writes there. They
# can hold thousands of files.
_snapshot_folder() {
  (cd -- "$1" && find . \( -name node_modules -o -name dist -o -name .git \) \
    -prune -o -type f -print) \
    | sed 's|^\./||' \
    | LC_ALL=C sort \
    | while IFS= read -r sf_file; do
      printf '%s\t%s\n' "$(cksum <"$1/$sf_file")" "$sf_file"
    done
}

# _print_snapshot_diff <before-snapshot> <after-snapshot>
#
# Print "add", "update" or "drop" for each file that differs between two
# snapshots of the project folder, with its path relative to that folder.
_print_snapshot_diff() {
  # Every snapshot line has a tab. The AFTER line has none, so it marks where
  # the second snapshot starts
  {
    printf '%s\n' "$1"
    printf 'AFTER\n'
    printf '%s\n' "$2"
  } | awk -F '\t' \
    -v add="${_GREEN}add${_RESET}" \
    -v update="${_YELLOW}update${_RESET}" \
    -v drop="${_RED}drop${_RESET}" '
    # The color codes take no column, so pad by the plain verb
    function verb(styled, plain) {
      return styled substr("        ", 1, 8 - length(plain))
    }

    NF < 2 { is_after = 1; next }
    !is_after { before[$2] = $1; next }
    {
      seen[$2] = 1
      if (!($2 in before)) printf "%s%s\n", verb(add, "add"), $2
      else if (before[$2] != $1) printf "%s%s\n", verb(update, "update"), $2
    }
    END {
      for (path in before) {
        if (!(path in seen)) printf "%s%s\n", verb(drop, "drop"), path
      }
    }
  '
}

# _print_build_files <app-dir>
#
# Print each file in the dist/ of <app-dir> as $APP_DIR/dist/..., a tab and its
# size, then the total size. Webpack empties dist/ before each build, so every
# file there is from the last build.
_print_build_files() {
  # An ejected config can write elsewhere
  [ -d "$1/dist" ] || return 0

  (cd -- "$1/dist" && find . -type f | LC_ALL=C sort) \
    | while IFS= read -r pbf_file; do
      printf '%s\t%s\n' "$(wc -c <"$1/dist/$pbf_file")" "${pbf_file#./}"
    done \
    | awk -F '\t' -v gray="$_GRAY" -v bold="$_BOLD" -v reset="$_RESET" '
      function format_size(bytes) {
        if (bytes < 1024) return bytes " B"
        if (bytes < 1024 * 1024) return sprintf("%.1f KiB", bytes / 1024)
        return sprintf("%.1f MiB", bytes / 1024 / 1024)
      }

      {
        total += $1
        printf "$APP_DIR/dist/%s\t%s%s%s\n", $2, gray, format_size($1), reset
      }
      END { printf "\n%sTotal%s\t%s\n", bold, reset, format_size(total) }
    '
}

# _print_init_summary <parts> <template> <project-dir>
#
# Print the header to stderr, then the project folder to stdout. The paths
# that follow on stdout are relative to it.
_print_init_summary() {
  case "$1" in
    plumbing) pis_parts="plumbing" ;;
    app) pis_parts="app, $2" ;;
    *) pis_parts="plumbing and app, $2" ;;
  esac

  _print_title_box "${_BOLD}init${_RESET}: $pis_parts" >&2
  printf '%s\t%s\n' "${_BOLD}\$PROJECT_DIR${_RESET}" "$(_shorten_home "$3")"
  printf '\n'
}

# _print_summary <app-dir> <webpack-config> <postcss-config> <swc-config>
#
# Print the header to stderr, then the app folder, the VBlocks folder and the
# configs Webpack runs with to stdout.
_print_summary() {
  _print_title_box "${_BOLD}󱆃 POSIX +  Webpack, an unlikely story!${_RESET}" >&2
  printf '%s\t%s\n' "${_BOLD}\$APP_DIR${_RESET}" "$(_shorten_home "$1")"
  printf '%s\t%s\n' "${_BOLD}\$VBLOCKS_DIR${_RESET}" "${_GRAY}$(_shorten_home "$_VB_DIR")${_RESET}"
  printf '\n'
  printf '%s\t%s\n' "${_WEBPACK_ICON}${_BOLD}Webpack${_RESET}" "$(_show_config_file "$2" "$1")"
  printf '%s\t%s\n' "${_POSTCSS_ICON}${_BOLD}PostCSS${_RESET}" "$(_show_config_file "$3" "$1")"
  printf '%s\t%s\n' "${_SWC_ICON}${_BOLD}SWC${_RESET}" "$(_show_config_file "$4" "$1")"
  printf '\n'
}

# _run_webpack <action> <app-dir> <webpack-config> [<webpack option>...]
#
# Run `webpack <action>` for the app in <app-dir>.
#
# EXIT
#   2   Webpack rejected an option or the config
#   3   Webpack failed
_run_webpack() {
  rw_action=$1
  rw_app_dir=$2
  rw_config=$3
  shift 3

  rw_robots_file=$(_pick_file \
    "$rw_app_dir/src/public/robots.txt" "$_VB_DIR/src/public/robots.txt")
  rw_favicon_file=$(_pick_file \
    "$rw_app_dir/src/public/favicon.svg" "$_VB_DIR/src/public/favicon.svg")

  # Run the webpack-cli of VBlocks, the version it ships and tests with. npx
  # would run the first one it finds from the current folder, or offer to
  # install one
  rw_cli_file=$(node -p \
    'require.resolve("webpack-cli/bin/cli.js", { paths: [process.argv[1]] })' \
    "$_VB_DIR") || _fail 3 "Could not find the webpack-cli of VBlocks"

  rw_status=0
  # The Webpack config takes the levels of --log-level, and maps them to its
  # stats and infrastructureLogging
  node "$rw_cli_file" "$rw_action" \
    --config "$rw_config" \
    --env "entryDir=$rw_app_dir" \
    --env "logLevel=$_LOG_LEVEL" \
    --env "robotsPath=$rw_robots_file" \
    --env "faviconPath=$rw_favicon_file" \
    "$@" || rw_status=$?

  # webpack-cli exits 1 when the build has errors, 2 when an option or the
  # config is wrong
  case "$rw_status" in
    0) return 0 ;;
    2) _fail 2 "Webpack rejected an option or the config" ;;
    *) _fail 3 "Webpack failed" ;;
  esac
}

# ╭───
# │ Bootstrap
# ╰───

case "${1:-}" in
  -h | --help)
    _show_help "$0"
    exit 0
    ;;
  "")
    _show_help "$0"
    exit 2
    ;;
esac

_require_cmd node

_VB_VERSION=$(node -p 'require(process.argv[1]).version' "$_VB_DIR/package.json")

# Style the summary and the file lists, and show the tool icons and the header,
# only when stdout and stderr are both terminals that show color. A pipe on
# either one, eg. `| tee` or an agent that reads the output, means plain text
# with only the facts
_IS_TERMINAL=""
_BOLD="" _GREEN="" _YELLOW="" _RED="" _GRAY="" _RESET=""
_WEBPACK_ICON="" _POSTCSS_ICON="" _SWC_ICON=""
if _has_color 1 && _has_color 2; then
  _IS_TERMINAL="true"
  _BOLD=$(printf '\033[1m')
  _GREEN=$(printf '\033[32m')
  _YELLOW=$(printf '\033[33m')
  _RED=$(printf '\033[31m')
  _GRAY=$(printf '\033[90m')
  _RESET=$(printf '\033[0m')
  _WEBPACK_ICON=" "
  _POSTCSS_ICON=" "
  _SWC_ICON="󱡮 "
fi

# ╭───
# │ Flags and positionals
# ╰───

_COMMAND=$1
shift

case "$_COMMAND" in
  init)
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --template)
          [ "$#" -lt 2 ] && _fail 2 -v available_templates "$(_list_templates)" "--template needs a name"
          # A template is a folder name. A slug also rules out a newline, which
          # grep would read as a second pattern
          _is slug "$2" \
            || _fail 2 -v template "$2" -v available_templates "$(_list_templates)" "Unknown template"
          _TEMPLATE=$2
          shift 2
          ;;
        --only)
          [ "$#" -lt 2 ] && _fail 2 -v available_parts "app,plumbing" "--only needs a part"
          case "$2" in
            app | plumbing) _PARTS=$2 ;;
            *) _fail 2 -v part "$2" -v available_parts "app,plumbing" "Unknown part" ;;
          esac
          shift 2
          ;;
        --)
          shift
          if [ "$#" -ne 1 ] || [ -n "$_INIT_DIR" ]; then
            _fail 2 "init takes one folder"
          fi
          _INIT_DIR=$1
          shift
          ;;
        -?*)
          _fail 2 -v flag "$1" "Unknown flag"
          ;;
        *)
          [ -n "$_INIT_DIR" ] && _fail 2 "init takes one folder"
          _INIT_DIR=$1
          shift
          ;;
      esac
    done

    [ -z "$_INIT_DIR" ] && _fail 2 "init needs a folder"

    # One shape for the printed paths: no trailing "/", and no leading "-" that
    # a command would read as a flag
    while [ "$_INIT_DIR" != "/" ] && [ "${_INIT_DIR%/}" != "$_INIT_DIR" ]; do
      _INIT_DIR=${_INIT_DIR%/}
    done
    case "$_INIT_DIR" in
      -*) _INIT_DIR="./$_INIT_DIR" ;;
    esac

    # `grep -q` stops reading at the first match, and _list_templates then
    # writes to a closed pipe
    if ! _list_templates | grep -xF -- "$_TEMPLATE" >/dev/null; then
      _fail 2 -v template "$_TEMPLATE" -v available_templates "$(_list_templates)" "Unknown template"
    fi
    ;;
  serve | build)
    # Take the flags of VBlocks out of the arguments. Webpack gets the rest
    _ARG_COUNT=$#
    while [ "$_ARG_COUNT" -gt 0 ]; do
      _ARG=$1
      shift
      _ARG_COUNT=$((_ARG_COUNT - 1))

      case "$_ARG" in
        --prefix)
          [ "$_ARG_COUNT" -eq 0 ] && _fail 2 "--prefix needs a folder"
          _PREFIX_DIR=$1
          shift
          _ARG_COUNT=$((_ARG_COUNT - 1))
          ;;
        --log-level)
          [ "$_ARG_COUNT" -eq 0 ] && _fail 2 -v available_levels "error,warn,info,verbose" "--log-level needs a level"
          case "$1" in
            error | warn | info | verbose) _LOG_LEVEL=$1 ;;
            *) _fail 2 -v level "$1" -v available_levels "error,warn,info,verbose" "Unknown level" ;;
          esac
          shift
          _ARG_COUNT=$((_ARG_COUNT - 1))
          ;;
        --single-file)
          [ "$_COMMAND" = "build" ] || _fail 2 "--single-file works only with build"
          # The default Webpack config reads env.single. An ejected config
          # supports the flag only if it reads env.single too
          set -- "$@" --env single
          ;;
        --analyze)
          [ "$_COMMAND" = "serve" ] || _fail 2 "--analyze works only with serve"
          # The default Webpack config reads env.analyze. An ejected config
          # supports the flag only if it reads env.analyze too
          set -- "$@" --env analyze
          ;;
        *)
          set -- "$@" "$_ARG"
          ;;
      esac
    done

    if [ -n "$_PREFIX_DIR" ] && [ ! -d "$_PREFIX_DIR" ]; then
      _fail 2 -v prefix "$_PREFIX_DIR" "--prefix is not a folder"
    fi
    ;;
  eject)
    [ "$#" -ne 1 ] && _fail 2 -v available_configs "webpack,postcss,swc" "eject needs one config"

    case "$1" in
      webpack) _EJECT_CONFIG="webpack.config.js" ;;
      postcss) _EJECT_CONFIG="postcss.config.js" ;;
      swc) _EJECT_CONFIG=".swcrc" ;;
      *) _fail 2 -v config "$1" -v available_configs "webpack,postcss,swc" "Unknown config" ;;
    esac
    ;;
  *)
    _fail 2 -v command "$_COMMAND" -v available_commands "init,serve,build,eject" "Unknown command"
    ;;
esac

# ╭───
# │ Main
# ╰───

case "$_COMMAND" in
  init)
    if [ -e "$_INIT_DIR" ]; then
      if [ ! -d "$_INIT_DIR" ] || [ -n "$(ls -A -- "$_INIT_DIR")" ]; then
        _fail 2 -v folder "$_INIT_DIR" "The folder exists and is not empty"
      fi
    fi
    # An app lives in the project folder, its parent. The app hooks write to
    # the package.json there
    _PROJECT_DIR=""
    if [ "$_PARTS" = "app" ]; then
      _PARENT_DIR=$(dirname -- "$_INIT_DIR")
      [ -f "$_PARENT_DIR/package.json" ] \
        || _fail 3 -v folder "$_PARENT_DIR" -v next "npx @asd14/vblocks init <directory> --only plumbing" "No package.json in the parent folder"
      _PROJECT_DIR=$(cd -- "$_PARENT_DIR" && pwd)
    fi

    mkdir -p -- "$_INIT_DIR" || _fail 3 -v folder "$_INIT_DIR" "Could not add the folder"
    _INIT_ABS_DIR=$(cd -- "$_INIT_DIR" && pwd)

    case "$_PARTS" in
      plumbing)
        _PROJECT_DIR=$_INIT_ABS_DIR
        _APP_DIR=""
        _APP_SUBDIR=""
        ;;
      app)
        _APP_DIR=$_INIT_ABS_DIR
        _APP_SUBDIR=${_APP_DIR#"$_PROJECT_DIR"/}
        ;;
      *)
        _PROJECT_DIR=$_INIT_ABS_DIR
        _APP_DIR=$_INIT_ABS_DIR
        _APP_SUBDIR="."
        ;;
    esac

    _BEFORE_SNAPSHOT=$(_snapshot_folder "$_PROJECT_DIR")
    _init_project "$_INIT_DIR" "$_TEMPLATE" "$_PARTS"
    _AFTER_SNAPSHOT=$(_snapshot_folder "$_PROJECT_DIR")

    _print_init_summary "$_PARTS" "$_TEMPLATE" "$_PROJECT_DIR"
    _print_snapshot_diff "$_BEFORE_SNAPSHOT" "$_AFTER_SNAPSHOT"

    case "$_PARTS" in
      plumbing)
        printf '\nNext, add an app:\n'
        printf '  npx @asd14/vblocks init %s/<app> --only app\n' "$_INIT_DIR"
        ;;
      app)
        printf '\nNext:\n'
        if [ "$_PROJECT_DIR" != "$PWD" ]; then
          printf '  cd %s\n' "$(_shorten_path "$_PROJECT_DIR")"
        fi
        printf '  npm install\n'
        printf '  npx vblocks serve --prefix %s\n' "$_APP_SUBDIR"
        ;;
      *)
        printf '\nNext:\n'
        printf '  cd %s\n' "$_INIT_DIR"
        printf '  npm install\n'
        printf '  npx vblocks serve\n'
        ;;
    esac
    exit 0
    ;;
  serve | build)
    _APP_DIR=$(cd -- "${_PREFIX_DIR:-.}" && pwd)
    _WEBPACK_CONFIG=$(_pick_file "$_APP_DIR/webpack.config.js" "$_VB_DIR/src/webpack.config.js")

    # webpack.config.js reads them
    VB_POSTCSS_CONFIG=$(_pick_file "$_APP_DIR/postcss.config.js" "$_VB_DIR/src/postcss.config.js")
    VB_SWC_CONFIG=$(_pick_file "$_APP_DIR/.swcrc" "$_VB_DIR/src/.swcrc")
    export VB_POSTCSS_CONFIG VB_SWC_CONFIG

    _print_summary "$_APP_DIR" "$_WEBPACK_CONFIG" "$VB_POSTCSS_CONFIG" "$VB_SWC_CONFIG"

    # Without a mode, Webpack takes `production`, also for `serve`. A --mode in
    # "$@" comes later, so it overrides this one
    if [ "$_COMMAND" = "build" ]; then
      _run_webpack build "$_APP_DIR" "$_WEBPACK_CONFIG" --mode production "$@"
      printf '\n'
      _print_build_files "$_APP_DIR"
    else
      _run_webpack serve "$_APP_DIR" "$_WEBPACK_CONFIG" --mode development "$@"
    fi
    exit 0
    ;;
  eject)
    cat -- "$_VB_DIR/src/$_EJECT_CONFIG"
    exit 0
    ;;
esac
