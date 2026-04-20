#!/bin/bash

function version::major() {
  local value
  value=$(/usr/bin/awk -F. '{print $1}' <<< "$1")

  echo "${value:-1}"
}

function version::minor() {
  local value
  value=$(/usr/bin/awk -F. '{print $2}' <<< "$1")

  echo "${value:-0}"
}

function version::patch() {
  local value
  value=$(/usr/bin/awk -F. '{print $3}' <<< "$1")

  echo "${value:-0}"
}

function version::is::minor() {
  local value
  value=$(/usr/bin/awk -F. '{print $2}' <<< "$1")

  [ -n "$value" ] && return 0
  return 1
}

function version::is::patch() {
  local value
  value=$(/usr/bin/awk -F. '{print $3}' <<< "$1")

  [ -n "$value" ] && return 0
  return 1
}

function version::pre() {
  echo "$1" | awk -F'-' '{split($2, a, /\+/); print a[1]}'
}

function version::build() {
  echo "$1" | awk -F'+' '{split($2, a, "-"); print a[1]}'
}

# shellcheck disable=SC2001
function version::format() {
  local formatted tVer tPre tBuild tVerOnly tMajor tMinor tPatch tExtra
  # Major = %M
  formatted="%M.%N.%R-%p+%b"
  if [ ! -t 0 ]; then
    formatted=$(cat)
  fi

  tVer="$1"
  tPre=$(version::pre "$tVer")
  tBuild=$(version::build "$tVer")
  tVerOnly=$(version::only "$tVer")
  tMajor=$(version::major "$tVerOnly")
  tMinor=$(version::minor "$tVerOnly")
  tPatch=$(version::patch "$tVerOnly")
  tExtra=$(version::extra "$tVerOnly")

  formatted=$(echo "$formatted" | sed "s#%F#$tVerOnly#")
  formatted=$(echo "$formatted" | sed "s#%M#$tMajor#")
  formatted=$(echo "$formatted" | sed "s#%N#$tMinor#")
  formatted=$(echo "$formatted" | sed "s#%R#$tPatch#")

  if ! version::is::patch "$tVerOnly"; then
    formatted=$(echo "$formatted" | sed "s#\.%r##")
    if ! version::is::minor "$tVerOnly"; then
      formatted=$(echo "$formatted" | sed "s#\.%n##")
    fi
  else
    formatted=$(echo "$formatted" | sed "s#%\.r#$tPatch#")
  fi

  if version::is::minor "$tVerOnly"; then
    formatted=$(echo "$formatted" | sed "s#%\.n#$tMinor#")
  fi

  formatted=$(echo "$formatted" | sed "s#%P#$tPre#")
  if [ -n "$tPre" ]; then
    formatted=$(echo "$formatted" | sed -E "s#([\-]?)%p#\1${tPre}#")
  else
    formatted=$(echo "$formatted" | sed -E "s#([\-]?)%p##")
  fi

  formatted=$(echo "$formatted" | sed "s#%B#${tBuild}#")
  if [ -z "$tPre" ]; then
    formatted=$(echo "$formatted" | sed -E "s#([\+]?)%b#\1${tBuild}#")
  else
    formatted=$(echo "$formatted" | sed -E "s#([\+]?)%b##")
  fi

  formatted=$(echo "$formatted" | sed "s#%E#$tExtra#")

  if echo "$formatted" | grep -q "%"; then
    return 1
  fi

  echo "$formatted" && return 0
}

function version::only() {
  local tBuild tPre
  tBuild=$(version::build "$1")
  tPre="$(version::pre "$1")"
  echo "$1" | sed "s#+$tBuild##" | sed "s#-$tPre##" | cut -d'.' -f1-3
}

function version::extra() {
  local tBuild tPre

  tBuild=$(version::build "$1")
  tPre="$(version::pre "$1")"

  echo "$1" | sed "s#+$tBuild##" | sed "s#-$tPre##" | cut -d'.' -f4- | xargs
}
