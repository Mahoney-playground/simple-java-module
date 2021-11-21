ARG module=com.greetings
ARG builder=build
ARG builder_home=/home/$builder
ARG build_dir=$builder_home/dev
ARG target_dir=$build_dir/target
ARG build_deps_dir="$target_dir/deps"
ARG build_lib_dir="$target_dir/lib"

FROM ghcr.io/graalvm/graalvm-ce:java17-21.3.0-b1 as builder
ARG module
ARG builder
ARG builder_home
ARG build_dir
ARG build_lib_dir
ARG build_deps_dir

RUN gu install native-image

RUN adduser --system $builder
RUN mkdir -p "$builder_home" && chown $builder "$builder_home"

USER $builder
RUN mkdir -p "$build_dir"
WORKDIR "$build_dir"

# Separate dependency changes (infrequent) from src changes (frequent)
COPY downloadDependencies.sh .
COPY dependencies.txt dependencies.txt
RUN ./downloadDependencies.sh "$build_deps_dir"

COPY src src
COPY build.sh .
RUN ./build.sh "$build_lib_dir" "$build_deps_dir"

RUN native-image \
    --static \
    # This is a no-op GC suitable for very short lived commands
    --gc=epsilon \
    --no-fallback \
    --module-path "$build_deps_dir/:$build_lib_dir/" \
    --module $module

FROM alpine:3.14.2 as usercreator
RUN adduser -S app

FROM scratch
ARG build_dir
ARG module

COPY --from=usercreator /etc/passwd /etc/passwd
USER app

ENV LANG=C.UTF-8
COPY --from=builder --chown=app "$build_dir/$module" /

ENTRYPOINT [ "/com.greetings" ]
