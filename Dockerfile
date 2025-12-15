FROM debian:bullseye-slim

WORKDIR /
ARG DEBIAN_FRONTEND=noninteractive
ENV VCPKG_FORCE_SYSTEM_BINARIES=1

RUN apt update -y && apt install -y --no-install-recommends bash ca-certificates clang curl g++ gcc git libasound2-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgtk-3-dev libpam0g-dev libpulse-dev libssl-dev  \
    libxcb-randr0-dev libxcb-shape0-dev libxcb-xfixes0-dev libxdo-dev libxfixes-dev make nasm ninja-build sudo tar unzip wget yasm zip \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/Kitware/CMake/releases/download/v3.30.6/cmake-3.30.6.tar.gz --no-check-certificate && \
    tar xzf cmake-3.30.6.tar.gz && cd cmake-3.30.6 && ./configure  --prefix=/usr/local && make -j $(nproc) &&  \
    make install -j $(nproc) && cd .. && rm -rf cmake-3.30.6.tar.gz && cmake --version && which cmake

RUN git config --global advice.detachedHead false && git config --global http.postBuffer 1048576000 \
&& git config --global http.lowSpeedLimit 0 && git config --global http.lowSpeedTime 99999 \
&& git config --global http.maxFileSize 524288000 && git config --global core.compression 9 \
&& git config --global core.looseCompression 9 && git config --global core.compressionAlgorithm zlib \
&& git clone --branch 2023.04.15 --depth=1 https://github.com/microsoft/vcpkg && \
  /vcpkg/bootstrap-vcpkg.sh -disableMetrics && /vcpkg/vcpkg --disable-metrics install libvpx libyuv opus aom

RUN groupadd -r user && useradd -r -g user user --home /home/user && mkdir -p /home/user/rustdesk && chown -R user: /home/user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/user

WORKDIR /home/user

COPY ./entrypoint.sh /

RUN chmod +x /entrypoint.sh && chmod 777 /entrypoint.sh && ls /home/user/rustdesk/ \
  && wget -t 3 -O libsciter-gtk.so "https://raw.githubusercontent.com/c-smile/sciter-sdk/master/bin.lnx/x64/libsciter-gtk.so"

USER user
RUN git config --global advice.detachedHead false && git config --global http.postBuffer 1048576000 \
&& git config --global http.lowSpeedLimit 0 && git config --global http.lowSpeedTime 99999 \
&& git config --global http.maxFileSize 524288000 && git config --global core.compression 9 \
&& git config --global core.looseCompression 9 && git config --global core.compressionAlgorithm zlib \
&& wget --tries=3 --https-only --secure-protocol=TLSv1_2 -O rustup.sh https://sh.rustup.rs && chmod +x rustup.sh && ./rustup.sh -y

USER root
ENV HOME=/home/user

ENTRYPOINT ["/entrypoint.sh"]