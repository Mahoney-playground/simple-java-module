#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

function main {
    local lib_dir=$1
    local deps_dir=$2
    local classes_dir=${3:-target/classes}

    mkdir -p "$classes_dir"
    # shellcheck disable=SC2046
    javac -d "$classes_dir" --module-source-path src --module-path "$deps_dir" $(find src -name '*.java')

    mkdir -p "$lib_dir"
    jar --create --file="$lib_dir"/org.astro@1.0.jar -C "$classes_dir"/org.astro .
    jar --create --file="$lib_dir"/com.greetings.jar --main-class=com.greetings.Main -C "$classes_dir"/com.greetings .
}

main "$@"
