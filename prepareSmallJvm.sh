#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

main() {
  local base_modules=$1
  local build_jvm_dir=$2

  jlink \
      --add-modules "$base_modules" \
      --strip-debug \
      --compress 2 \
      --no-header-files \
      --no-man-pages \
      --output "$build_jvm_dir"

  "$build_jvm_dir/bin/java" -Xshare:dump
}

main "$@"
