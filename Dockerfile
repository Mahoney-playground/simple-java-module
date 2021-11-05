ARG module=com.greetings

FROM eclipse-temurin:17_35-jdk-alpine as builder

RUN apk add --update \
    binutils \
    curl \
    bash

RUN adduser --system build
USER build
RUN mkdir -p /home/build/dev
WORKDIR /home/build/dev

COPY checkModules.sh checkModules.sh
COPY downloadDependencies.sh downloadDependencies.sh
COPY build.sh build.sh

ARG base_modules=java.base,java.sql

RUN jlink \
    --add-modules $base_modules \
    --strip-debug \
    --compress 2 \
    --no-header-files \
    --no-man-pages \
    --output target/image

RUN ./target/image/bin/java -Xshare:dump

# Separate dependency changes (infrequent) from src changes (frequent)
COPY dependencies.txt dependencies.txt
RUN ./downloadDependencies.sh target/deps

COPY src src
RUN ./build.sh

ARG module
RUN ./checkModules.sh $module $base_modules

FROM alpine:3.14.2 as runner

RUN adduser -S app
USER app

ARG deps_path=/opt/app/deps
ARG lib_path=/opt/app/lib

ARG module_path=$deps_path:$lib_path
ENV module_path=${module_path}

ARG module
ENV module=${module}

ARG shared_archive_file=/tmp/app-cds.jsa
ENV shared_archive_file=${shared_archive_file}

ARG jdk_path=/opt/jdk

ENV LANG=C.UTF-8 \
    PATH=${PATH}:${jdk_path}/bin

# Separate jdk changes (infrequent) from dependency changes (frequent)
COPY --from=builder /home/build/dev/target/image $jdk_path

# Separate dependency changes (infrequent) from src changes (frequent)
COPY --from=builder /home/build/dev/target/deps/* $deps_path/

COPY --from=builder /home/build/dev/target/lib/* $lib_path/

# Create a shared archive file to speed up cold start
RUN java \
      -XX:ArchiveClassesAtExit=$shared_archive_file \
      --module-path $module_path \
      --module $module

ENTRYPOINT java \
  -XX:SharedArchiveFile=$shared_archive_file \
  -Xshare:on \
  --module-path $module_path \
  --module $module
