ARG module=com.greetings
ARG build_dir=/home/build/dev
ARG target_dir=$build_dir/target
ARG build_deps_dir="$target_dir/deps"
ARG build_lib_dir="$target_dir/lib"

FROM ghcr.io/graalvm/graalvm-ce:java17-21.3.0-b1 as builder
ARG module
ARG build_dir
ARG build_lib_dir
ARG build_deps_dir

RUN gu install native-image

RUN adduser --system build
RUN mkdir -p "$build_dir" && chown build:build "$build_dir"
USER build
WORKDIR "$build_dir"

# Separate dependency changes (infrequent) from src changes (frequent)
COPY downloadDependencies.sh .
COPY dependencies.txt dependencies.txt
RUN ./downloadDependencies.sh "$build_deps_dir"

COPY src src
COPY build.sh .
RUN ./build.sh "$build_lib_dir" "$build_deps_dir"

ARG module_path="$build_deps_dir/:$build_lib_dir/"

RUN native-image \
    --static \
    # This is a no-op GC suitable for very short lived commands
    --gc=epsilon \
    --no-fallback \
    --module-path "$module_path" \
    --module $module

FROM alpine:3.14.2 as usercreator
RUN adduser -S app

FROM scratch as runner
ARG build_dir
ARG module

COPY --from=usercreator /etc/passwd /etc/passwd
USER app

#ENV LANG=C.UTF-8
COPY --from=builder --chown=app "$build_dir/$module" /

ENTRYPOINT [ "/com.greetings" ]
