#!/bin/sh

# webpack.sh - The primitives of serve and build: the --mode and --log-level
# guards, the defaults, the summary and the Webpack run
#
# Needs lib/log.sh and vblocks.sh. The command needs to source it before this file.

# ╭───
# │ Domain primitives
# ╰───

# _guard_log_level <level>
#
# EXIT
#   2   <level> is empty or not one of --log-level: error, warn, info or verbose
_guard_log_level() {
  gll_levels="error,warn,info,verbose"
  case "$1" in
    error | warn | info | verbose) ;;
    "") _fail 2 -v available_levels "$gll_levels" "--log-level needs a level" ;;
    *) _fail 2 -v level "$1" -v available_levels "$gll_levels" "Unknown level" ;;
  esac
}

# _guard_mode <mode>
#
# EXIT
#   2   <mode> is empty or not one of --mode: development or production
_guard_mode() {
  gm_modes="development,production"
  case "$1" in
    development | production) ;;
    "") _fail 2 -v available_modes "$gm_modes" "--mode needs a mode" ;;
    *) _fail 2 -v mode "$1" -v available_modes "$gm_modes" "Unknown mode" ;;
  esac
}

# _pick_file <app-dir> <path>
#
# Print <path> in <app-dir> when the file exists, otherwise the default of
# VBlocks at the same <path> in defaults/. defaults/ is laid out like an app
# folder.
_pick_file() {
  if [ -f "$1/$2" ]; then
    printf '%s\n' "$1/$2"
  else
    printf '%s\n' "$_VB_DIR/defaults/$2"
  fi
}

# _resolve_vblocks_file <request>
#
# Print the absolute path of <request>, eg. `webpack-cli/bin/cli.js`, as Node
# resolves it from the VBlocks folder. npm nests or hoists each dependency of
# VBlocks so that this lookup finds it.
_resolve_vblocks_file() {
  node -p 'require.resolve(process.argv[1], { paths: [process.argv[2]] })' \
    "$1" "$_VB_DIR"
}

# _find_browserslist <app-dir>
#
# Print the first source browserslist finds for the browsers of <app-dir>:
# BROWSERSLIST=<query>, BROWSERSLIST_CONFIG=<file>, or the config file from
# <app-dir> up. Print nothing when browserslist finds none.
#
# EXIT
#   2   browserslist could not read a config, eg. one folder has both a
#       .browserslistrc and the browserslist field of package.json
#   3   Could not find the browserslist of VBlocks
_find_browserslist() {
  fb_lib_file=$(_resolve_vblocks_file browserslist) ||
    _fail 3 "Could not find the browserslist of VBlocks"

  # loadConfig follows the order of browserslist, so VBlocks does not repeat
  # it. VBlocks reads the two variables only to label the source. loadConfig
  # reads them before any file, so the first one set is the source
  # shellcheck disable=SC2016 # JavaScript, not shell
  fb_source=$(node -e '
    const browserslist = require(process.argv[1])
    const appDir = process.argv[2]
    try {
      if (browserslist.loadConfig({ path: appDir }) === undefined) {
        console.log("none")
      } else if (process.env.BROWSERSLIST) {
        console.log(`BROWSERSLIST=${process.env.BROWSERSLIST}`)
      } else if (process.env.BROWSERSLIST_CONFIG) {
        console.log(`BROWSERSLIST_CONFIG=${process.env.BROWSERSLIST_CONFIG}`)
      } else {
        console.log(browserslist.findConfigFile(appDir))
      }
    } catch (error) {
      console.log(`error ${error.message}`)
    }
  ' "$fb_lib_file" "$1")

  case "$fb_source" in
    none) ;;
    "error "*) _fail 2 -v reason "${fb_source#error }" "browserslist could not read the browsers of the app" ;;
    *) printf '%s\n' "$fb_source" ;;
  esac
}

# _pick_browserslist <app-dir>
#
# Export BROWSERSLIST_CONFIG with the VBlocks default, when browserslist finds
# no config for <app-dir>. SWC, Webpack and postcss-preset-env then read it.
#
# EXIT
#   2   browserslist could not read a config, see _find_browserslist
#   3   Could not find the browserslist of VBlocks
_pick_browserslist() {
  pb_source=$(_find_browserslist "$1")
  if [ -z "$pb_source" ]; then
    BROWSERSLIST_CONFIG="$_VB_DIR/defaults/.browserslistrc"
    export BROWSERSLIST_CONFIG
  fi
}

# _print_browserslist_source <source> <app-dir>
#
# Print <source>, what _find_browserslist prints: a file as _print_file_path
# does, the VBlocks default in gray, and a variable the User set as it is.
_print_browserslist_source() {
  case "$1" in
    BROWSERSLIST_CONFIG="$_VB_DIR/defaults/.browserslistrc") _print_file_path "${1#BROWSERSLIST_CONFIG=}" "$2" ;;
    BROWSERSLIST=* | BROWSERSLIST_CONFIG=*) printf '%s\n' "$1" ;;
    *) _print_file_path "$1" "$2" ;;
  esac
}

# _print_file_path <file> <app-dir>
#
# Print the path of <file>, its folder as $APP_DIR, or as $VBLOCKS_DIR in gray
# for a default of VBlocks.
_print_file_path() {
  case "$1" in
    "$2"/*) printf '%s\n' "\$APP_DIR/${1#"$2"/}" ;;
    "$_VB_DIR"/*) printf '%s\n' "${_GRAY}\$VBLOCKS_DIR/${1#"$_VB_DIR"/}${_RESET}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# _print_summary <app-dir> <webpack-config> <postcss-config> <swc-config> <robots-file> <favicon-file> <browserslist-source>
#
# Print the app folder, the VBlocks folder, the files Webpack runs with and the
# source of the browsers. An empty <robots-file> prints no Robots line.
# <browserslist-source> is what _find_browserslist prints.
_print_summary() {
  # The icons of the tools and the files, only on a terminal
  ps_webpack_icon="" ps_postcss_icon="" ps_swc_icon=""
  ps_robots_icon="" ps_favicon_icon="" ps_browsers_icon=""
  if [ -n "$_IS_TERMINAL" ]; then
    ps_webpack_icon=" "
    ps_postcss_icon=" "
    ps_swc_icon="󱡮 "
    ps_robots_icon="󰚩 "
    ps_favicon_icon=" "
    ps_browsers_icon="󰖟 "
  fi

  printf '%s\t%s\n' "${_BOLD}\$APP_DIR${_RESET}" "$(_shorten_home "$1")"
  printf '%s\t%s\n' "${_BOLD}\$VBLOCKS_DIR${_RESET}" "${_GRAY}$(_shorten_home "$_VB_DIR")${_RESET}"
  printf '\n'
  printf '%s\t%s\n' "${ps_webpack_icon}${_BOLD}Webpack${_RESET}" "$(_print_file_path "$2" "$1")"
  printf '%s\t%s\n' "${ps_postcss_icon}${_BOLD}PostCSS${_RESET}" "$(_print_file_path "$3" "$1")"
  printf '%s\t%s\n' "${ps_swc_icon}${_BOLD}SWC${_RESET}" "$(_print_file_path "$4" "$1")"
  printf '%s\t%s\n' "${ps_browsers_icon}${_BOLD}Browsers${_RESET}" "$(_print_browserslist_source "$7" "$1")"
  if [ -n "$5" ]; then
    printf '%s\t%s\n' "${ps_robots_icon}${_BOLD}Robots${_RESET}" "$(_print_file_path "$5" "$1")"
  fi
  printf '%s\t%s\n' "${ps_favicon_icon}${_BOLD}Favicon${_RESET}" "$(_print_file_path "$6" "$1")"
  printf '\n'
}

# _run_webpack <action> <webpack-config> [<webpack option>...]
#
# Run `webpack <action>` with <webpack-config> and the options. Use the
# webpack-cli, the webpack and the webpack-dev-server of VBlocks.
#
# EXIT
#   2   Webpack rejected an option or the config
#   3   Could not find a package of VBlocks, or Webpack failed
_run_webpack() {
  rw_action=$1
  rw_config=$2
  shift 2

  # Run the webpack-cli of VBlocks, the version VBlocks depends on. npx
  # would run the first one it finds from the current folder, or offer to
  # install one
  rw_cli_file=$(_resolve_vblocks_file webpack-cli/bin/cli.js) ||
    _fail 3 "Could not find the webpack-cli of VBlocks"

  # Pass webpack-cli the webpack and the webpack-dev-server of VBlocks.
  # webpack-cli resolves both from its own folder, where npm can place another
  # copy. webpack-cli declares webpack-dev-server only as an optional peer, so
  # npm can place none there
  rw_webpack_file=$(_resolve_vblocks_file webpack) ||
    _fail 3 "Could not find the webpack of VBlocks"
  rw_dev_server_file=$(_resolve_vblocks_file webpack-dev-server) ||
    _fail 3 "Could not find the webpack-dev-server of VBlocks"

  # The path picks the copy of VBlocks, but that copy first resolves
  # webpack-cli from the current folder, and runs any other copy it finds.
  # WEBPACK_CLI_SKIP_IMPORT_LOCAL skips that check
  rw_status=0
  WEBPACK_CLI_SKIP_IMPORT_LOCAL=true \
    WEBPACK_PACKAGE=$rw_webpack_file \
    WEBPACK_DEV_SERVER_PACKAGE=$rw_dev_server_file \
    node "$rw_cli_file" "$rw_action" --config "$rw_config" "$@" ||
    rw_status=$?

  # webpack-cli exits 1 when the build has errors, 2 when an option or the
  # config is wrong
  case "$rw_status" in
    0) return 0 ;;
    2) _fail 2 "Webpack rejected an option or the config" ;;
    *) _fail 3 "Webpack failed" ;;
  esac
}
