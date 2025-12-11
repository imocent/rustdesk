FROM debian:bullseye-slim

WORKDIR /

ARG DEBIAN_FRONTEND=noninteractive
ENV VCPKG_FORCE_SYSTEM_BINARIES=1
ENV GITHUB_RUI="https://ghfast.top/https://github.com"

RUN sed -i "s!http://deb.debian.org!http://mirrors.tuna.tsinghua.edu.cn!g" /etc/apt/sources.list \
    && apt update -y && apt install -y --no-install-recommends ca-certificates clang curl g++ gcc git libasound2-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgtk-3-dev libpam0g-dev libpulse-dev libssl-dev  \
    libxcb-randr0-dev libxcb-shape0-dev libxcb-xfixes0-dev libxdo-dev libxfixes-dev make nasm sudo tar unzip wget yasm zip && \
    git config --global advice.detachedHead false && \
    git config --global http.postBuffer 524288000 && \
    git config --global http.lowSpeedLimit 0 && \
    git config --global http.lowSpeedTime 99999 && \
    git config --global http.maxFileSize 524288000 && \
    rm -rf /var/lib/apt/lists/*

RUN wget $GITHUB_RUI/Kitware/CMake/releases/download/v3.30.6/cmake-3.30.6.tar.gz --no-check-certificate && \
    tar xzf cmake-3.30.6.tar.gz && cd cmake-3.30.6 && ./configure  --prefix=/usr/local && make -j $(nproc) &&  \
    make install -j $(nproc) && cd .. && rm -rf cmake-3.30.6.tar.gz && cmake --version && which cmake

RUN git config --global url."$GITHUB_RUI/".insteadOf "https://github.com/" && \
    git config --global url."$GITHUB_RUI/webmproject/libwebm".insteadOf "https://chromium.googlesource.com/webm/libwebm" && \
    git config --global url."https://gitclone.com/".insteadOf "https://googlesource.com/" && \
    git clone --branch 2023.04.15 --depth=1 $GITHUB_RUI/microsoft/vcpkg && \
    sed -i.bak "s|https://github.com|$GITHUB_RUI|g" vcpkg/scripts/bootstrap.sh && \
    sed -i.bak "s|https://github.com|$GITHUB_RUI|g" vcpkg/scripts/vcpkgTools.xml && \
    find vcpkg/ports -name "*.json" -type f -exec sed -i 's|https://github.com|$GITHUB_RUI|g' {} + && \
    mkdir -p vcpkg/downloads && \
    wget "https://gitee.com/imocence/source-address/releases/download/v1/aom-9a83c6a5a55c176adbce740e47d3512edfc9ae71.tar.gz" -O \
    vcpkg/downloads/aom-9a83c6a5a55c176adbce740e47d3512edfc9ae71.tar.gz && \
    wget "https://gitee.com/imocence/source-address/releases/download/v1/libyuv-0faf8dd0e004520a61a603a4d2996d5ecc80dc3f.tar.gz" -O \
    vcpkg/downloads/libyuv-0faf8dd0e004520a61a603a4d2996d5ecc80dc3f.tar.gz && \
    wget "$GITHUB_RUI/xiph/opus/archive/5c94ec3205c30171ffd01056f5b4622b7c0ab54c.tar.gz" -O \
    vcpkg/downloads/xiph-opus-5c94ec3205c30171ffd01056f5b4622b7c0ab54c.tar.gz && \
    wget "$GITHUB_RUI/ninja-build/ninja/releases/download/v1.10.2/ninja-linux.zip" -O vcpkg/downloads/ninja-linux-1.10.2.zip && \
    wget "$GITHUB_RUI/libjpeg-turbo/libjpeg-turbo/archive/2.1.5.1.tar.gz" -O vcpkg/downloads/libjpeg-turbo-libjpeg-turbo-2.1.5.1.tar.gz && \
    wget "$GITHUB_RUI/webmproject/libvpx/archive/v1.12.0.tar.gz" -O vcpkg/downloads/webmproject-libvpx-v1.12.0.tar.gz && \
    /vcpkg/bootstrap-vcpkg.sh -disableMetrics && /vcpkg/vcpkg --disable-metrics install libvpx libyuv opus aom

RUN groupadd -r user && useradd -r -g user user --home /home/user && \
    mkdir -p /home/user/rustdesk && chown -R user: /home/user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/user

WORKDIR /home/user
RUN curl -LO https://gitee.com/imocence/source-address/releases/download/v1/libsciter-gtk.so

USER user
RUN curl --retry 3 --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

USER root
ENV HOME=/home/user
COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]