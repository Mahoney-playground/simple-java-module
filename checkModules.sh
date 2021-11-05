#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

function find_java_deps {
  local module_name=$1
  local module_path=$2
  jdeps --module-path "$module_path" -m "$module_name" -R -s \
    | grep java \
    | sed 's/^[^-]*-//' \
    | cut -c 3- \
    | sort -u \
    | paste -sd "," -
}

function main {
  local module_name=$1
  local module_path=$2
  local expected_deps=$3

  local java_deps
  java_deps=$(find_java_deps "$module_name" "$module_path")

  if [ "$java_deps" != "$expected_deps" ]; then
    >&2 echo "Project depends on $java_deps not $expected_deps"
    >&2 echo "Update jlink to bring in exactly:"
    >&2 echo "$java_deps"
    exit 1
  fi
}

main "$@"
