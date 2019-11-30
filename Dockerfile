FROM openjdk:13.0.1-jdk-slim as builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --system nonroot
USER nonroot
RUN mkdir -p /home/nonroot/build
WORKDIR /home/nonroot/build

# These need to be updated as you depend on more base java modules
# Run `jdeps -R -s --module-path . -m <your_root_module>` to find out what you
# depend on
ARG base_modules=java.base,java.sql

RUN jlink \
    --add-modules $base_modules\
    --strip-debug \
    --compress 2 \
    --no-header-files \
    --no-man-pages \
    --output target/image

COPY build.sh build.sh
COPY src src

RUN ./build.sh

FROM panga/alpine:3.7-glibc2.25 as runner

COPY --from=builder /home/nonroot/build/target/image /opt/jdk

ENV LANG=C.UTF-8 \
    PATH=${PATH}:/opt/jdk/bin

RUN adduser -S nonroot
USER nonroot

ARG JVM_OPTS
ENV JVM_OPTS=${JVM_OPTS}

CMD java ${JVM_OPTS} --upgrade-module-path /opt/app/modules --module com.greetings

COPY --from=builder /home/nonroot/build/target/lib/* /opt/app/modules/
