#!/bin/sh

# vblocks.sh - What every command of vblocks shares:
# - lib.sh, the folders, the styles of the output and the header

# The caller sets _SCRIPT_DIR to the folder of vblocks.sh, then sources it
: "${_SCRIPT_DIR:?the caller sets _SCRIPT_DIR before it sources vblocks.sh}"

_VB_DIR=$(dirname "$(dirname "$_SCRIPT_DIR")")

# tools/update-lib downloads lib.sh from @asd14/posix-utils. Never edit lib.sh
# here
# shellcheck source=lib.sh
. "$_SCRIPT_DIR/lib.sh"

# _log reads LOG_NAMESPACE, LOG_LEVEL and NO_LOG_TIME. VBlocks logs only errors,
# through _fail. The time adds no fact to an error
LOG_NAMESPACE="vblocks"
LOG_LEVEL="info"
NO_LOG_TIME="true"

# `cd` follows an exported CDPATH and prints the folder it picked, which
# `$(cd ... && pwd)` would capture
unset CDPATH

# ╭───
# │ Primitives
# ╰───

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

# ╭───
# │ Domain primitives
# ╰───

# _export_version
#
# Read the version of VBlocks from its package.json, and export it as
# VB_VERSION: the commands pass it to the header, and the post-init hooks read
# it. Guard node before the call.
_export_version() {
  VB_VERSION=$(node -p 'require(process.argv[1]).version' "$_VB_DIR/package.json")
  export VB_VERSION
}

# _print_header <version> <title>
#
# Print the name of VBlocks and <version> in the top border, then <title>, then
# close the box. The lines after it hold the details. Print nothing unless
# _IS_TERMINAL is set. The header holds no fact a reader acts on.
_print_header() {
  [ -n "$_IS_TERMINAL" ] || return 0

  printf '╭───────────┤ %s\n' "${_GREEN} VBlocks v$1${_RESET}"
  printf '│ %s\n' "$2"
  printf '╰──┤\n'
}

# ╭───
# │ Bootstrap
# ╰───

# Style the summary and the file lists, and show the header, only when stdout
# and stderr are both terminals that show color. A pipe on either one, eg.
# `| tee` or an agent that reads the output, means plain text with only the
# facts
_IS_TERMINAL=""
_BOLD="" _GREEN="" _YELLOW="" _RED="" _GRAY="" _RESET=""
if _has_color 1 && _has_color 2; then
  _IS_TERMINAL="true"
  _BOLD=$(printf '\033[1m')
  _GREEN=$(printf '\033[32m')
  _YELLOW=$(printf '\033[33m')
  _RED=$(printf '\033[31m')
  _GRAY=$(printf '\033[90m')
  _RESET=$(printf '\033[0m')
fi
