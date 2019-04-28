FROM openjdk:11.0.3-jdk-slim-stretch as builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --system nonroot
USER nonroot

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

RUN javac -d mods --module-source-path src $(find src -name "*.java") && \
    jar --create --file=mlib/org.astro@1.0.jar -C mods/org.astro . && \
    jar --create --file=mlib/com.greetings.jar --main-class=com.greetings.Main -C mods/com.greetings .

RUN jlink \
    --add-modules java.base \
    --verbose \
    --strip-debug \
    --compress 2 \
    --no-header-files \
    --no-man-pages \
    --output /tmp/jre-minimal \
    && strip -p --strip-unneeded $(find /tmp/jre-minimal -name *.so)

FROM panga/alpine:3.7-glibc2.25

COPY --from=builder /tmp/jre-minimal /opt/jre-minimal

ENV LANG=C.UTF-8 \
    PATH=${PATH}:/opt/jre-minimal/bin

ADD mlib /opt/app/modules

ARG JVM_OPTS
ENV JVM_OPTS=${JVM_OPTS}

CMD time java ${JVM_OPTS} --upgrade-module-path /opt/app/modules --module com.greetings
