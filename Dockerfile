FROM --platform=linux/amd64 swiftlang/swift:nightly-main-jammy

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        gcc-arm-none-eabi \
        libnewlib-arm-none-eabi \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt
WORKDIR /opt
RUN wget https://download.panic.com/playdate_sdk/Linux/PlaydateSDK-latest.tar.gz \
    && tar -zxvf PlaydateSDK-latest.tar.gz \
    && rm PlaydateSDK-latest.tar.gz \
    && mv PlaydateSDK-* PlaydateSDK \
    && chmod -R 755 /opt

ENV PLAYDATE_SDK_PATH=/opt/PlaydateSDK \
    ARM_NONE_EABI_GCC_PATH=/usr/lib/gcc/arm-none-eabi/10.3.1 \
    ARM_NONE_EABI_SYSROOT_PATH=/usr/lib/arm-none-eabi

RUN mkdir /.swiftpm /.cache && chmod 777 /.swiftpm /.cache

RUN mkdir -p /mnt
VOLUME /mnt
WORKDIR /mnt
