#!/usr/bin/env bash

module=com.greetings
target_dir=target
build_jvm_dir="$target_dir/jvm"
build_deps_dir="$target_dir/deps"
build_lib_dir="$target_dir/lib"
base_modules=java.base,java.sql
module_path="$build_deps_dir:$build_lib_dir"
shared_archive_file=$target_dir/app-cds.jsa

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

jlink \
  --add-modules $base_modules \
  --strip-debug \
  --compress 2 \
  --no-header-files \
  --no-man-pages \
  --output "$build_jvm_dir"

"$build_jvm_dir/bin/java" -Xshare:dump

# Separate dependency changes (infrequent) from src changes (frequent)
./downloadDependencies.sh "$build_deps_dir"

./build.sh "$build_lib_dir" "$build_deps_dir"

./checkModules.sh "$module" "$module_path" "$base_modules"

"$build_jvm_dir/bin/java" \
  -XX:ArchiveClassesAtExit=$shared_archive_file \
  --module-path $module_path \
  --module $module

"$build_jvm_dir/bin/java" \
  -XX:SharedArchiveFile=$shared_archive_file \
  --module-path $module_path \
  --module $module
