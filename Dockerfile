FROM ubuntu:24.04 AS builder

# 安装构建依赖
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    cmake \
    gperf \
    libssl-dev \
    zlib1g-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# 克隆并构建
WORKDIR /build
RUN git clone --recursive https://github.com/tdlib/telegram-bot-api.git

WORKDIR /build/telegram-bot-api
RUN mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr/local .. && \
    cmake --build . --target install -j$(nproc)

# 运行阶段
FROM ubuntu:24.04

# 安装运行时依赖
RUN apt-get update && \
    apt-get install -y \
    libssl3 \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

# 从构建阶段复制二进制文件
COPY --from=builder /usr/local/bin/telegram-bot-api /usr/local/bin/

# 创建工作目录
RUN mkdir -p /var/lib/telegram-bot-api
WORKDIR /var/lib/telegram-bot-api

# 暴露端口
EXPOSE 8081 8082

# telegram-bot-api会自动从环境变量读取凭证
CMD ["telegram-bot-api", "--http-port=8081", "--local", "--verbosity=3"]
