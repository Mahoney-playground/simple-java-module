ARG module=com.greetings
ARG build_dir=/home/build/dev
ARG target_dir=$build_dir/target
ARG build_jvm_dir="$target_dir/jvm"
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

ARG base_modules=java.base,java.sql
COPY prepareSmallJvm.sh .
RUN ./prepareSmallJvm.sh "$base_modules" "$build_jvm_dir"

# Separate dependency changes (infrequent) from src changes (frequent)
COPY downloadDependencies.sh .
COPY dependencies.txt dependencies.txt
RUN ./downloadDependencies.sh "$build_deps_dir"

COPY src src
COPY build.sh .
RUN ./build.sh "$build_lib_dir" "$build_deps_dir"

COPY checkModules.sh .
RUN ./checkModules.sh "$module" "$build_deps_dir:$build_lib_dir" "$base_modules"

FROM alpine:3.14.2 as runner
ARG module
ARG build_jvm_dir
ARG build_deps_dir
ARG build_lib_dir

RUN adduser -S app
USER app

ARG deps_dir=/opt/app/deps
ARG lib_dir=/opt/app/lib

ARG module_path="$deps_dir:$lib_dir"
ENV module_path="$module_path"

ENV module="$module"

ARG shared_archive_file=/tmp/app-cds.jsa
ENV shared_archive_file="$shared_archive_file"

ARG jvm_dir=/opt/jvm

ENV LANG=C.UTF-8 \
    PATH="${PATH}:${jvm_dir}/bin"

# Separate jdk changes (infrequent) from dependency changes (frequent)
COPY --from=builder "$build_jvm_dir" "$jvm_dir"

# Separate dependency changes (infrequent) from src changes (frequent)
COPY --from=builder "$build_deps_dir/*" "$deps_dir/"

COPY --from=builder "$build_lib_dir/*" "$lib_dir/"

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
