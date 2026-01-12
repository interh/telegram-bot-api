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

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8081/ || exit 1

# 默认命令（会被railway.toml的startCommand覆盖）
CMD ["telegram-bot-api", "--help"]
