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

RUN ./checkModules.sh com.greetings $base_modules

FROM alpine:3.14.2 as runner

ENV LANG=C.UTF-8 \
    PATH=${PATH}:/opt/jdk/bin

RUN adduser -S app
USER app

# Separate jdk changes (infrequent) from dependency changes (frequent)
COPY --from=builder /home/build/dev/target/image /opt/jdk

# Separate dependency changes (infrequent) from src changes (frequent)
COPY --from=builder /home/build/dev/target/deps/* /opt/app/deps/

COPY --from=builder /home/build/dev/target/lib/* /opt/app/lib/

# Create a shared archive file to speed up cold start
RUN java \
      -XX:ArchiveClassesAtExit=/tmp/app-cds.jsa \
      --module-path /opt/app/deps:/opt/app/lib \
      --module com.greetings

ENTRYPOINT [ "java", \
  "-XX:SharedArchiveFile=/tmp/app-cds.jsa", \
  "-Xshare:on", \
  "--module-path", "/opt/app/deps:/opt/app/lib", \
  "--module", "com.greetings" \
]
