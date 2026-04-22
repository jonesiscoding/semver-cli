#!/bin/bash

# @file  _git.sh
# @brief Git related functions
# @license
#
#   Copyright 2026-04 AMJones <am@jonesiscoding.com>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.

#   You may obtain a copy of the License and Author's Notice at
#
#      https://github.com/jonesiscoding/semver-cli/blob/main/LICENSE
#      https://github.com/jonesiscoding/semver-cli/blob/main/NOTICE
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

gitX=$(which git)
[[ -z "$gitX" ]] && gitX="/usr/local/bin/git"
[[ ! -f "$gitX" ]] && gitX="/opt/homebrew/bin/git"
[[ ! -f "$gitX" ]] && gitX="/opt/local/bin/git"

exitGit=5
exitRepo=10

function git::is() {
  $gitX rev-parse --is-inside-work-tree 2>/dev/null
}

function git::version() {
  local tag branches

  if ! $gitX; then
    return $exitGit
  elif ! git::is; then
    return $exitRepo
  else
    tag=$($gitX describe --tags --abbrev=0 --first-parent 2>/dev/null | sed 's/^v//');
    if [[ -z "$tag" ]]; then
      while IFS= read -r tag; do
        branches=$($gitX branch -a --contains "$tag" 2>/dev/null)
        if [ -z "$branches" ]; then
          echo "$tag" | sed 's/^v//' && return 0
        fi
      done < <($gitX tag --sort=-v:refname)
    else
      echo "$tag" && return 0
    fi
  fi

  return 1
}
