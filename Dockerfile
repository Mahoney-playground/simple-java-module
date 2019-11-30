FROM openjdk:13.0.1-jdk-slim as builder

RUN adduser --system nonroot
USER nonroot
RUN mkdir -p /home/nonroot/build
WORKDIR /home/nonroot/build

COPY build.sh build.sh
COPY src src

RUN ./build.sh

FROM slimjre:13.0.1-java.sql

USER nonroot

ARG JVM_OPTS
ENV JVM_OPTS=${JVM_OPTS}

CMD java ${JVM_OPTS} --upgrade-module-path /opt/app/modules --module com.greetings

COPY --from=builder /home/nonroot/build/target/lib/* /opt/app/modules/
