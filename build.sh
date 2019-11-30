#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

function main {
    mkdir -p target/classes
    # shellcheck disable=SC2046
    javac -d target/classes --module-source-path src $(find src -name '*.java')

    mkdir -p target/lib
    jar --create --file=target/lib/org.astro@1.0.jar -C target/classes/org.astro .
    jar --create --file=target/lib/com.greetings.jar --main-class=com.greetings.Main -C target/classes/com.greetings .

    rm -rf target/greetingsapp
    # This takes 13+ seconds on my machine; shame we can't reuse an existing stripped down one in some way?
    jlink \
      --add-modules com.greetings \
      --module-path target/lib \
      --strip-debug \
      --compress 2 \
      --no-header-files \
      --no-man-pages \
      --output target/greetingsapp
}

main
