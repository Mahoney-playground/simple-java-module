FROM openjdk:13.0.1-jdk-slim as builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --system nonroot
USER nonroot
RUN mkdir -p /home/nonroot/build
WORKDIR /home/nonroot/build

RUN jlink \
    --add-modules java.base,java.sql \
    --strip-debug \
    --compress 2 \
    --no-header-files \
    --no-man-pages \
    --output target/image

COPY build.sh build.sh
COPY src src

RUN ./build.sh

FROM panga/alpine:3.7-glibc2.25 as runner

ENV LANG=C.UTF-8 \
    PATH=${PATH}:/opt/jdk/bin

COPY --from=builder /home/nonroot/build/target/image /opt/jdk

RUN adduser -S nonroot

USER nonroot

ARG JVM_OPTS
ENV JVM_OPTS=${JVM_OPTS}

CMD java ${JVM_OPTS} --upgrade-module-path /opt/app/modules --module com.greetings

COPY --from=builder /home/nonroot/build/target/lib/* /opt/app/modules/
