ARG module=com.greetings
ARG build_dir=/home/build/dev
ARG target_dir=$build_dir/target
ARG build_jvm_dir="$target_dir/image"
ARG build_deps_dir="$target_dir/deps"
ARG build_lib_dir="$target_dir/lib"

FROM eclipse-temurin:17_35-jdk-alpine as builder
ARG module
ARG build_dir
ARG build_jvm_dir
ARG build_lib_dir
ARG build_deps_dir

RUN apk add --update \
    binutils \
    curl \
    bash

RUN adduser --system build
USER build

RUN mkdir -p "$build_dir"
WORKDIR "$build_dir"

COPY checkModules.sh .
COPY downloadDependencies.sh .
COPY build.sh .

ARG base_modules=java.base,java.sql
RUN jlink \
    --add-modules "$base_modules" \
    --strip-debug \
    --compress 2 \
    --no-header-files \
    --no-man-pages \
    --output "$build_jvm_dir"

RUN "$build_jvm_dir/bin/java" -Xshare:dump

# Separate dependency changes (infrequent) from src changes (frequent)
COPY dependencies.txt dependencies.txt

RUN ./downloadDependencies.sh "$build_deps_dir"

COPY src src
RUN ./build.sh "$build_lib_dir" "$build_deps_dir"

RUN ./checkModules.sh "$module" "$build_deps_dir:$build_lib_dir" "$base_modules"

FROM alpine:3.14.2 as runner
ARG module
ARG build_jvm_dir
ARG build_deps_dir
ARG build_lib_dir

RUN adduser -S app
USER app

ARG deps_path=/opt/app/deps
ARG lib_path=/opt/app/lib

ARG module_path="$deps_path:$lib_path"
ENV module_path="$module_path"

ENV module="$module"

ARG shared_archive_file=/tmp/app-cds.jsa
ENV shared_archive_file="$shared_archive_file"

ARG jvm_dir=/opt/jdk

ENV LANG=C.UTF-8 \
    PATH="${PATH}:${jvm_dir}/bin"

# Separate jdk changes (infrequent) from dependency changes (frequent)
COPY --from=builder "$build_jvm_dir" "$jvm_dir"

# Separate dependency changes (infrequent) from src changes (frequent)
COPY --from=builder "$build_deps_dir/*" "$deps_path/"

COPY --from=builder "$build_lib_dir/*" "$lib_path/"

# Create a shared archive file to speed up cold start
RUN java \
      "-XX:ArchiveClassesAtExit=$shared_archive_file" \
      --module-path "$module_path" \
      --module "$module"

ENTRYPOINT java \
  "-XX:SharedArchiveFile=$shared_archive_file" \
  -Xshare:on \
  --module-path "$module_path" \
  --module "$module"
