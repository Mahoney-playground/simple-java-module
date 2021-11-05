#!/bin/sh

exec java \
  $JAVA_OPTS \
  "-XX:SharedArchiveFile=$shared_archive_file" \
  -Xshare:on \
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/tmp/jvm_heap_dump.hprof \
  -XX:+ErrorFileToStderr \
  --module-path "$module_path" \
  --module $module \
  "$@"
