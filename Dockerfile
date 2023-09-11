FROM ubuntu:22.04 AS build-env

ARG RUNNER=local

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /root

RUN if [ "${RUNNER}" != "github" ]; then \
        sed -i -E 's/(archive|security|ports).ubuntu.(org|com)/mirrors.aliyun.com/g' /etc/apt/sources.list; \
    fi \   
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get -y install make git zlib1g-dev libssl-dev gperf \
    cmake clang-14 libc++-dev libc++abi-dev \
    && git clone --recursive https://github.com/tdlib/telegram-bot-api.git \
    && cd telegram-bot-api \
    && rm -rf build \
    && mkdir build \
    && cd build \
    && CXXFLAGS="-stdlib=libc++" CC=/usr/bin/clang-14 CXX=/usr/bin/clang++-14 cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=.. .. \
    && cmake --build . --target install 

FROM ubuntu:22.04

ARG RUNNER=local

ENV DEBIAN_FRONTEND=noninteractive

# 修正中文显示
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app

COPY --from=build-env /root/telegram-bot-api/bin/telegram-bot-api /app

RUN if [ "${RUNNER}" != "github" ]; then \
        sed -i -E 's/(archive|security|ports).ubuntu.(org|com)/mirrors.aliyun.com/g' /etc/apt/sources.list; \
    fi \   
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y ca-certificates libc++-dev locales tzdata dumb-init \
    && locale-gen en_US.UTF-8  \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/bin/dumb-init", "--"]