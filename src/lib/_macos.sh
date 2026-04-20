#!/bin/bash

function get_version_from_app() {
  local plist verCur

  if [ -d "$1" ] && [[ "${1##*.}" == "app" ]]; then
    plist="$1/Contents/Info.plist"
    if [[ -f "$plist" ]]; then
      verCur=$(defaults read "$plist" CFBundleShortVersionString | grep -v "does not exist")
      [[ -z "$versionCur" ]] && verCur=$(defaults read "$plist" CFBundleVersion | grep -v "does not exist")
      [[ -n "$verCur" ]] && echo "$verCur" && return 0
    fi
  fi

  return 1
}