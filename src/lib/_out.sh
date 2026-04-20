#!/bin/zsh

# Terminal cs
isQuiet=false
isVerbose=true
isNotify=false
myLog="/var/log/vat.log"
[[ "$(uname)" == "Darwin" ]] && myLog="${HOME}/Library/Logs/vat.log"
myLogDate=$(/bin/date "+%Y-%m-%d %H:%M:%S")

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
  isNotify=true
  while IFS= read -r line; do
    if $isVerbose; then
      echo "$line"
    elif ! $isQuiet; then
      printf "${BLUE}%s${RESET}%s " "$line" "${padding:${#line}}"
    fi
    echo "Trying: $line" | log
  done
}

function success() {
  myContext="$GREEN" && badge < /dev/stdin
}

function error() {
  myContext="$RED" && badge < /dev/stdin
}

function default() {
  myContext="$WHITE" && badge < /dev/stdin
}

function badge() {
  while IFS= read -r line; do
    if $isNotify; then
      ! $isQuiet && $isNotify && echo -e "[${myContext}${line}${RESET}]"
      isNotify=false

      return 0
    fi
  done
}

function out() {
  local line
  if $isQuiet; then
    while IFS= read -r line; do
      echo "$line" | log
    done
  else
    while IFS= read -r line; do
      echo "${myContext}$line${RESET}"
    done
  fi
}

function verbose() {
  local line
  if $isVerbose; then
    while IFS= read -r line; do
      echo "${myContext}$line${RESET}"
    done
  else
    while IFS= read -r line; do
      echo "$line" | log
    done
  fi
}
function log() {
  local line
  while IFS= read -r line; do echo "[$myLogDate] $line" >> "$myLog"; done
}

function cronic() {
  local tmp status
  tmp=$(mktemp)

  if ! $isVerbose; then
    # Run the command and redirect everything to a temp file
    "$@" > "$tmp" 2>&1
    status=$?

    # Only print the file content if the command failed
    if [ "$status" -ne 0 ]; then
      ! $isNotify && ! $isQuiet && echo "ERROR" | error | badge
      ! $isVerbose && ! $isQuiet && echo "$HR"
      ! $isQuiet && cat "$tmp"
      ! $isVerbose && ! $isQuiet && echo "$HR"
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