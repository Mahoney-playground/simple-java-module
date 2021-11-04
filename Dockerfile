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
    --add-modules $base_modules\
    --strip-debug \
    --compress 2 \
    --no-header-files \
    --no-man-pages \
    --output target/image

# Separate dependency changes (infrequent) from src changes (frequent)
COPY dependencies.txt dependencies.txt
RUN ./downloadDependencies.sh target/deps

COPY src src
RUN ./build.sh

RUN ./checkModules.sh com.greetings $base_modules

FROM alpine:3.14.2 as runner

ENV LANG=C.UTF-8 \
    PATH=${PATH}:/opt/jdk/bin

RUN adduser -S app
USER app

COPY --from=builder /home/build/dev/target/image /opt/jdk

ARG JVM_OPTS
ENV JVM_OPTS=${JVM_OPTS}

# Separate dependency changes (infrequent) from src changes (frequent)
COPY --from=builder /home/build/dev/target/deps/* /opt/app/

COPY --from=builder /home/build/dev/target/lib/* /opt/app/

RUN java -Xshare:dump --module-path /opt/app --module com.greetings

CMD java ${JVM_OPTS} --module-path /opt/app --module com.greetings
