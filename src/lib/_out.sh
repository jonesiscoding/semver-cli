#!/bin/zsh

# Terminal cs
myLog="$HOME/build.log"
[[ "$(uname)" == "Darwin" ]] && myLog="${HOME}/Library/Logs/build.log"
myLogDate=$(/bin/date "+%Y-%m-%d %H:%M:%S")

# Tracking File
out_v=$(mktemp)
jq -n '{ notify: "false", context: ""}' > "$out_v"
trap "rm -f '$out_v'" EXIT

if [[ -n "$NO_COLOR" || "$TERM" =~ ^(dumb|emacs)$ || -n "$CI" ]] || ! command -v tput >/dev/null 2>&1; then
  RED="" && GREEN="" && YELLOW="" && BLUE="" && MAGENTA="" && CYAN="" && WHITE="" && RESET=""
else
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4)
  MAGENTA=$(tput setaf 5)
  CYAN=$(tput setaf 6)
  WHITE=$(tput setaf 7)
  RESET=$(tput sgr0)
fi
declare -r RED GREEN YELLOW BLUE MAGENTA CYAN WHITE RESET

state_read() {
  local key="$1"
  local def="${2:-empty}"

  # Use the most basic jq path possible to rule out // logic errors
  jq -r ".\"$key\"//$def" "$out_v"
}

function state_write() {
  local key="$1"
  local val="$2"
  local tmp_file="${out_v}.tmp"

  if jq --arg key "$key" --arg val "$val" '.[$key] = $val' "$out_v" > "$tmp_file"; then
    mv "$tmp_file" "$out_v"
  fi
}
# @description Ask a yes/no question and return a boolean answer.
# @arg $1 string The yes/no Question
# @stdout string The question, printed in blue
# @exitcode 0 Yes
# @exitcode 1 No
function ask() {
  local reply

  echo -e -n "${YELLOW}$1${RESET} [y/n] "
  read -r reply </dev/tty
  case "$reply" in
  Y*|y*) return 0 ;;
  N*|n*) return 1 ;;
  esac
}

# @description Outputs question text in yellow, and waits for the user to type a reply
# followed by the enter key.
#
#   Example:
#     response=$(output::question::text "What is your quest?")
#
# @arg $1 string The question
# @arg $2 string The default answer
# @stdout string The response
function ask-text() {
  local ANSWER
  local QUESTION
  local DEFAULT

  DEFAULT="$2"
  QUESTION="${YELLOW}$1${RESET} ${DEFAULT:+ [$DEFAULT]}"

  read -r -ep "$QUESTION: " ANSWER </dev/tty || return 1

  echo "${ANSWER:-$DEFAULT}"
  return 0
}

function notify() {
  local line
  local padding="---------------------------------------------------------------------------"

  state_write "notify" "true"
  while IFS= read -r line; do
    if $flagV; then
      echo "$line"
    elif ! $flagQ; then
      printf "${BLUE}%s${RESET}%s " "$line" "${padding:${#line}}"
    fi
    echo "Trying: $line" | log
  done
}

function success() {
  state_write "context" "$GREEN"
  while IFS= read -r line; do
    echo "$line"
  done
}

function error() {
  state_write "context" "$RED"
  while IFS= read -r line; do
    echo  "$line"
  done
}

function default() {
  state_write "context" "$WHITE"
  while IFS= read -r line; do
    echo "$line"
  done
}

function badge() {
  local myContext isNotify
  while IFS= read -r line; do
    [ -z "$myContext" ] && myContext="$(state_read "context")"
    [ -z "$isNotify" ] && isNotify=$(state_read "notify" "false")
    if $isNotify; then
      ! $flagQ && printf "[%s%s%s]\n" "$myContext" "$line" "$RESET"
    fi
  done
  state_write notify false
  state_write context ""
  return 0
}

function out() {
  local line myContext
  if $flagQ; then
    while IFS= read -r line; do
      echo "$line" | log
    done
  else
    while IFS= read -r line; do
      myContext="$(state_read "context")"
      printf "%s%s%s\n" "$myContext" "$line" "$RESET"
    done
  fi
  state_write "context" ""
}

function verbose() {
  local line myContext
  myContext=$(state_read "context")
  if $flagV; then
    while IFS= read -r line; do
      echo "${myContext}$line${RESET}"
    done
  else
    while IFS= read -r line; do
      echo "$line" | log
    done
  fi
  state_write "context" ""
}
function log() {
  local line
  while IFS= read -r line; do echo "[$myLogDate] $line" >> "$myLog"; done
}

function cronic() {
  local tmp status
  tmp=$(mktemp)

  isNotify=$(state_read notify false)
  if ! $flagV; then
    # Run the command and redirect everything to a temp file
    "$@" > "$tmp" 2>&1
    status=$?

    # Only print the file content if the command failed
    if [ "$status" -ne 0 ]; then
      $isNotify && ! $flagQ && echo "ERROR" | error | badge
      ! $flagV && ! $flagQ && echo "$HR"
      ! $flagQ && cat "$tmp"
      ! $flagV && ! $flagQ && echo "$HR"
    fi

    rm -f "$tmp"
  else
    echo "$HR"
    "$@"
    status=$?
    echo "$HR"
  fi

  return "$status"
}
