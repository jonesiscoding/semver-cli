#!/bin/bash

[[ -z "$selfVer"  ]] && selfVer=x.x.x
[[ -z "$selfName" ]] && selfName=$(basename "${BASH_SOURCE[0]}")
readonly selfVer
readonly selfName
readonly selfUsage

function out::version() {
  if $flagQ; then
    echo "$selfVer"
  else
    echo "$selfName v$selfVer"
    [[ -n "$selfRepo" ]] && echo "($selfRepo)"
  fi
}

function out::help() {
  if [[ -z "$selfUsage" ]] && ! $flagQ; then
    out::version
  elif ! $flagQ; then
    echo "$selfUsage"
  fi
}

read -r flagQ flagV flagH flagVer <<< "false false false false"
in=()
while [ "$1" != "" ]; do
  case "$1" in
    -q | --quiet )   flagQ=true;     ;;
    -v | --verbose ) flagV=true;     ;;
    -h | --help )    flagH=true;     ;;
    --version )      flagVer=true;   ;;
    *)               in+=("$1")      ;;
  esac
  shift
done
readonly flagQ flagV flagH flagVer
set -- "${in[@]}"

if [ ${#selfFlags[@]} -gt 0 ]; then
  for flag in "${selfFlags[@]}"; do
    flag="$(echo "${flag:0:1}" | tr '[:lower:]' '[:upper:]')${flag:1}"
    case "$flag" in
      Quiet | Verbose | Help | Q | H )       ;;
      *:) printf -v "flag${flag%?}" "%s" ""  ;;
      *)  printf -v "flag${flag}" "%s" false ;;
    esac
  done
fi
