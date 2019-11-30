#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

function main {

  local depsDir=$1
  mkdir -p "$depsDir"

  while read -r dependency; do
    local g
    g=$(echo "$dependency" | cut -d':' -f1)
    local a
    a=$(echo "$dependency" | cut -d':' -f2)
    local v
    v=$(echo "$dependency" | cut -d':' -f3)

    local path
    path="https://search.maven.org/remotecontent?filepath=${g//.//}/$a/$v/$a-$v.jar"

    curl -fsSL "$path" > "$depsDir/$a-$v.jar"
  done <dependencies.txt
}

main "$@"
