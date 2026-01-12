# Dockerfile for building and running Theron++ AMQDistribution example
# This requires C++23 support, Qpid Proton, cxxopts, and nlohmann/json

FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies and required packages
RUN apt-get update && apt-get install -y \
    build-essential \
    make \
    cmake \
    git \
    pkg-config \
    software-properties-common \
    ccache \
    libboost-dev \
    libssl-dev \
    libuuid1 \
    uuid-dev \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update && apt-get install -y \
    g++-13 \
    && rm -rf /var/lib/apt/lists/*

# Set g++-13 as default compiler
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 100 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100

# Build and install Qpid Proton from source
WORKDIR /tmp
RUN git clone --depth 1 --branch 0.40.0 https://github.com/apache/qpid-proton.git && \
    cd qpid-proton && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr \
             -DCMAKE_BUILD_TYPE=Release \
             -DBUILD_PYTHON=OFF \
             -DBUILD_RUBY=OFF \
             -DBUILD_PERL=OFF \
             -DBUILD_GO=OFF \
             -DBUILD_LUA=OFF \
    && make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd / && \
    rm -rf /tmp/qpid-proton

# Create directories for external dependencies
WORKDIR /opt

# Install nlohmann/json (header-only library)
RUN git clone --depth 1 https://github.com/nlohmann/json.git nlohmann-json && \
    cp -r nlohmann-json/include/nlohmann /usr/include/

# Install cxxopts (header-only library)
RUN git clone --depth 1 https://github.com/jarro2783/cxxopts.git cxxopts && \
    mkdir -p /usr/include/cxxopts && \
    cp -r cxxopts/include/cxxopts.hpp /usr/include/cxxopts/

# Set working directory to project root
WORKDIR /app

# Copy the entire project
COPY . .

# Create Bin directory for object files
RUN mkdir -p Bin

# Build the Theron++ library
RUN make Library

# Build AMQDistribution example
WORKDIR /app/Examples
RUN g++ AMQDistribution.cpp -o AMQDistribution \
    -std=c++23 \
    -Wall \
    -ggdb \
    -D_DEBUG \
    -I. \
    -I/usr/include \
    -I/app \
    -I/usr/include/cxxopts \
    -MMD -MP \
    -fuse-ld=gold \
    -pthread \
    /app/Theron++.a \
    -lqpid-proton-cpp

# Set the working directory back to project root
WORKDIR /app

# Default command - show help
CMD ["./Examples/AMQDistribution", "--help"]

