FROM openjdk:11.0.3-jdk-slim-stretch as builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --system nonroot
USER nonroot
RUN mkdir -p /tmp/build && cd /tmp/build

RUN jlink \
    --add-modules java.base \
    --verbose \
    --strip-debug \
    --compress 2 \
    --no-header-files \
    --no-man-pages \
    --output /tmp/jre-minimal \
    && strip -p --strip-unneeded $(find /tmp/jre-minimal -name *.so)

COPY src src

RUN mkdir -p /tmp/build/mods /tmp/build/mlib && \
    javac -d /tmp/build/mods --module-source-path src $(find src -name "*.java") && \
    jar --create --file=/tmp/build/mlib/org.astro@1.0.jar -C /tmp/build/mods/org.astro . && \
    jar --create --file=/tmp/build/mlib/com.greetings.jar --main-class=com.greetings.Main -C /tmp/build/mods/com.greetings .

FROM panga/alpine:3.7-glibc2.25

COPY --from=builder /tmp/jre-minimal /opt/jre-minimal

ENV LANG=C.UTF-8 \
    PATH=${PATH}:/opt/jre-minimal/bin

COPY --from=builder /tmp/build/mlib /opt/app/modules

ARG JVM_OPTS
ENV JVM_OPTS=${JVM_OPTS}

CMD time java ${JVM_OPTS} --upgrade-module-path /opt/app/modules --module com.greetings
