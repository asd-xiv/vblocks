#!/bin/sh

# webpack.sh - The primitives of serve and build: the --mode and --log-level
# guards, the defaults, the summary and the Webpack run

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

# _print_summary <app-dir> <webpack-config> <postcss-config> <swc-config> <robots-file> <favicon-file>
#
# Print the app folder, the VBlocks folder and the files Webpack runs with. An
# empty <robots-file> prints no Robots line.
_print_summary() {
  # The icons of the tools and the files, only on a terminal
  ps_webpack_icon="" ps_postcss_icon="" ps_swc_icon=""
  ps_robots_icon="" ps_favicon_icon=""
  if [ -n "$_IS_TERMINAL" ]; then
    ps_webpack_icon=" "
    ps_postcss_icon=" "
    ps_swc_icon="󱡮 "
    ps_robots_icon="󰚩 "
    ps_favicon_icon=" "
  fi

  printf '%s\t%s\n' "${_BOLD}\$APP_DIR${_RESET}" "$(_shorten_home "$1")"
  printf '%s\t%s\n' "${_BOLD}\$VBLOCKS_DIR${_RESET}" "${_GRAY}$(_shorten_home "$_VB_DIR")${_RESET}"
  printf '\n'
  printf '%s\t%s\n' "${ps_webpack_icon}${_BOLD}Webpack${_RESET}" "$(_print_file_path "$2" "$1")"
  printf '%s\t%s\n' "${ps_postcss_icon}${_BOLD}PostCSS${_RESET}" "$(_print_file_path "$3" "$1")"
  printf '%s\t%s\n' "${ps_swc_icon}${_BOLD}SWC${_RESET}" "$(_print_file_path "$4" "$1")"
  if [ -n "$5" ]; then
    printf '%s\t%s\n' "${ps_robots_icon}${_BOLD}Robots${_RESET}" "$(_print_file_path "$5" "$1")"
  fi
  printf '%s\t%s\n' "${ps_favicon_icon}${_BOLD}Favicon${_RESET}" "$(_print_file_path "$6" "$1")"
  printf '\n'
}

# _run_webpack <action> <webpack-config> [<webpack option>...]
#
# Run `webpack <action>` with <webpack-config> and the options, through the
# webpack-cli of VBlocks.
#
# EXIT
#   2   Webpack rejected an option or the config
#   3   Webpack failed
_run_webpack() {
  rw_action=$1
  rw_config=$2
  shift 2

  # Run the webpack-cli of VBlocks, the version VBlocks depends on. npx
  # would run the first one it finds from the current folder, or offer to
  # install one
  rw_cli_file=$(node -p \
    'require.resolve("webpack-cli/bin/cli.js", { paths: [process.argv[1]] })' \
    "$_VB_DIR") || _fail 3 "Could not find the webpack-cli of VBlocks"

  rw_status=0
  node "$rw_cli_file" "$rw_action" --config "$rw_config" "$@" || rw_status=$?

  # webpack-cli exits 1 when the build has errors, 2 when an option or the
  # config is wrong
  case "$rw_status" in
    0) return 0 ;;
    2) _fail 2 "Webpack rejected an option or the config" ;;
    *) _fail 3 "Webpack failed" ;;
  esac
}
