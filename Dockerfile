FROM openjdk:13.0.3-jdk-slim-stretch as builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --system nonroot
USER nonroot
RUN mkdir -p /home/nonroot/build
WORKDIR /home/nonroot/build

COPY src src
COPY build.sh build.sh

RUN ./build.sh

FROM panga/alpine:3.7-glibc2.25

COPY --from=builder /home/nonroot/build/target/greetingsapp /opt/greetingsapp

ENV LANG=C.UTF-8 \
    PATH=${PATH}:/opt/greetingsapp/bin

ARG JVM_OPTS
ENV JVM_OPTS=${JVM_OPTS}

CMD java ${JVM_OPTS} --module com.greetings
