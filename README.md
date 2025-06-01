# Custom Rust Kernel

This repository is my first go at embedded programming with Rust, where I make an operating system from scratch. It is
written for ARM64 architecture devices, targeting the M-Cortex Raspberry PI 4 Board. There are no tests for any other
ARM64 devices like the Raspberry PI 3 or 5. A docker container is used to fully automate the quite verbose
cross-compilation toolchain and emulation of the kernel, so I can focus on writing rust code. Clone the
official [RaspberryPi Firmware Repository](https://github.com/raspberrypi/firmware) to get access to the firmware needed
to boot the kernel image.

This isn't a course or tutorial, but I'm using this repository as a way to keep track of what I've learned overtime,
and I figured I'd make it public for everyone.

## Project Prerequisites

#### [Raspberry Pi 4 Model B](https://www.amazon.com/dp/B07TC2BK1X)

Target board for ARM64 development. This particular board is the only one I've tested with, so if you purchase a
different raspberry pi, expect problems out of the scope of this repository.

#### [Micro SD Card](https://www.amazon.com/dp/B0B1JJ664M)

Used to boot and store the kernel image. An affordable 32GB Micro SD card.

#### [5V 3.5A USB-C Power Supply](https://www.amazon.com/CanaKit-Raspberry-Power-Supply-USB-C/dp/B07TYQRXTK)

Must supply clean 5.0V at 3.5A. Avoid phone or laptop chargers. The power supply must reliably output at least 5.0V at
3.0A to avoid undervoltage issues, which can cause crashes or subtle instability.

#### [Micro-HDMI Cable](https://www.amazon.com/dp/B08C2PVP7J)

The Raspberry Pi 4B uses micro-HDMI ports. Ensure you have the correct micro-HDMI to HDMI cable, **not** *mini-HDMI*.
USB-to-HDMI adapters are not necessary unless your monitor doesn't have HDMI input available.

#### [Computer & Monitor](https://imgs.search.brave.com/pg5WhsK5WkaPdqlv6jBu1H2rWMnieBM6yztiLSW9nz4/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly9pLnBp/bmltZy5jb20vb3Jp/Z2luYWxzLzZjLzIz/L2MxLzZjMjNjMWM4/YmEyN2QyYjYyY2Ex/ODI3YzhmYzZjNmU3/LmpwZw)

Any average computer will work. We'll basically just be cross-compiling for ARM64 and running a Docker
container for building the kernel. And you'll need the monitor to connect the raspberry pi to for video output. It's
more than likely your monitor supports HDMI, but if it only has display port, you'll need an active [HDMI-to-DisplayPort
Adapter](https://www.amazon.com/DisplayPort-Adapter-Converter-Gold-Plated-Compatible/dp/B017Q8ZVWK).

### Optional but Recommended

#### [USB-to-TTL Serial Adapter](https://www.amazon.com/HiLetgo-CP2102-Converter-Adapter-Downloader/dp/B00LODGRV8#averageCustomerReviewsAnchor)

Enables serial communication and debugging before video output is functional. This can save significant amounts time
during development.

#### [MicroSD Card Reader](https://www.amazon.com/Reader-Adapter-Camera-Memory-Wansurs/dp/B0B9QZ4W4Y?sr=8-4)

Needed to format and write kernel binaries to the SD card. Most computers these days don't have SD Card readers, so you
might have to spend the extra $5 bucks.

## Build Instructions

1. Install the official [Rust](https://www.rust-lang.org/tools/install) programming language.
2. Install [Docker Engine](https://www.docker.com/products/docker-desktop/)
   and [Docker Compose](https://docs.docker.com/compose/install/) for containerization to automate the build process.
3. Install the code editor or IDE of your. I use [Rust Rover](https://www.jetbrains.com/rust/), and during the time
   I'm writing this, it's free for non-commercial uses. But most people probably are comfortable
   with [Visual Studio Code](https://code.visualstudio.com/) and that'll work just fine.

Now that we have the necessary dev tools, let's build and run the docker container.

Clone the repository:

```shell
git clone https://github.com/itsmicah722/rpi4_os.git && cd rpi4_os
```

Run `docker-compose` to build the container:

```shell
docker compose -f docker/docker-compose.yml up -d
```

Once the docker container is running, attach to its shell via `exec -it`

```shell
docker exec -it rpi4-os /bin/sh
```

To compile & link the kernel into a bootable image, use GNU Make to execute the build process:

```shell
make all
```

To emulate a running instance of the generated kernel image, use `qemu` *(quick-emulator)* to test:

```shell
make qemu
```

And that's it, now we have a working kernel image. Of course, if you wanted to actually run the kernel on the physical
raspberry PI board and see the output on a screen in realtime, the process will be much less trivial and more involved,
but I will make a section for that soon.

#### TODO:

Make the build instructions more comprehensive and add a section for running on REAL hardware without QEMU emulation

## Credits:

All credit goes to
the [Rust RaspberryPI-OS Tutorials Repository](https://github.com/rust-embedded/rust-raspberrypi-OS-tutorials) and
their [Contributors](https://github.com/rust-embedded/rust-raspberrypi-OS-tutorials/graphs/contributors) who made
my rust embedded journey possible. Most of the code in this project either comes directly from or was heavily
inspired by them, so thank you :)

Happy coding