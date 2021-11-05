#!/usr/bin/env bash

base_modules=java.base,java.sql
module_path=target/deps:target/lib
module=com.greetings
shared_archive_file=target/app-cds.jsa

rm -rf target

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
  --output target/image

./target/image/bin/java -Xshare:dump

# Separate dependency changes (infrequent) from src changes (frequent)
./downloadDependencies.sh target/deps

./build.sh

./checkModules.sh com.greetings $base_modules

./target/image/bin/java \
  -XX:ArchiveClassesAtExit=$shared_archive_file \
  --module-path $module_path \
  --module $module

./target/image/bin/java \
  -XX:SharedArchiveFile=$shared_archive_file \
  --module-path $module_path \
  --module $module
