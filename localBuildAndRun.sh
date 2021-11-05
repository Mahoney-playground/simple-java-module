#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

export module=com.greetings
target_dir=target
build_jvm_dir="$target_dir/jvm"
build_deps_dir="$target_dir/deps"
build_lib_dir="$target_dir/lib"
base_modules=java.base,java.sql
export module_path="$build_deps_dir:$build_lib_dir"
export shared_archive_file=$target_dir/app-cds.jsa

rm -rf "$target_dir"

javaVersion() {
  java -version 2>&1 >/dev/null | grep version | tr -d '"' | cut -d' ' -f3 | cut -d'.' -f1
}

if [[ $(javaVersion) != 17 ]]; then
  java_home="$(/usr/libexec/java_home -v 17)"
  if [ $? -eq 0 ]; then
    export JAVA_HOME="$java_home"
  else
    echo "Failed to set java to 17" >&2
    exit 1
  fi
fi

./prepareSmallJvm.sh "$base_modules" "$build_jvm_dir"

# Separate dependency changes (infrequent) from src changes (frequent)
./downloadDependencies.sh "$build_deps_dir"

./build.sh "$build_lib_dir" "$build_deps_dir"

./checkModules.sh "$module" "$module_path" "$base_modules"

export PATH="$build_jvm_dir/bin:$PATH"

java \
  "-XX:ArchiveClassesAtExit=$shared_archive_file" \
  --module-path "$module_path" \
  --module "$module"

./runner.sh
