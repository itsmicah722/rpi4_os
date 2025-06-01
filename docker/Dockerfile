FROM alpine:latest

# Set up locale
RUN apk add --no-cache \
    musl-locales \
    musl-locales-lang

# Rust docker locations && locale (English US)
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Build & debug tools
RUN apk update && apk add --no-cache \
    bash curl tar xz build-base clang llvm-dev git \
    qemu-system-aarch64 coreutils libc6-compat python3 py3-pip \
    openocd gdb usbutils libusb-dev pkgconfig

# Prebuilt GNU toolchain for ARM64 bare-metal (aarch64-none-elf)
# Since this Alpine container is x86_64, we use the x86_64-hosted cross-compilation which specifically targets AArch64.
# The 'aarch64-none-elf' target means: bare-metal ARM64 with no operating system (e.g., Raspberry Pi 4).
ENV GNU_X86_64_TOOLCHAIN_URL=https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-elf.tar.xz

# Download, extract, and clean up
RUN curl -L $GNU_X86_64_TOOLCHAIN_URL -o /tmp/arm-docker.tar.xz && \
    tar -xf /tmp/arm-docker.tar.xz -C /opt && \
    rm /tmp/arm-docker.tar.xz

# Make the toolchain binary available on system PATH
ENV PATH="/opt/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-elf/bin:$PATH"

# Install Rust + target + helpers
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    rustup target add aarch64-unknown-none && \
    cargo install cargo-binutils rustfilt serial-console

WORKDIR /workspace
CMD ["/bin/sh"]