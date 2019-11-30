#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

function main {
    mkdir -p target/classes
    # shellcheck disable=SC2046
    javac -d target/classes --module-source-path src --module-path target/deps $(find src -name '*.java')

    mkdir -p target/lib
    jar --create --file=target/lib/org.astro@1.0.jar -C target/classes/org.astro .
    jar --create --file=target/lib/com.greetings.jar --main-class=com.greetings.Main -C target/classes/com.greetings .
}

main
