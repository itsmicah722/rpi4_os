include common/docker.mk
include common/format.mk
include common/operating_system.mk

##--------------------------------------------------------------------------------------------------
## BSP-specific configuration values
##--------------------------------------------------------------------------------------------------
TARGET            = aarch64-unknown-none-softfloat
KERNEL_BIN        = target/$(TARGET)/release/final_binary/kernel
KERNEL_ELF		  = target/$(TARGET)/release/kernel
QEMU_BINARY       = qemu-system-aarch64
QEMU_MACHINE_TYPE = raspi4b
QEMU_RELEASE_ARGS = -d in_asm -display none
OBJDUMP_BINARY    = aarch64-none-elf-objdump
NM_BINARY         = aarch64-none-elf-nm
READELF_BINARY    = aarch64-none-elf-readelf
LD_SCRIPT_PATH    = $(shell pwd)/src/bsp/raspberrypi
RUSTC_MISC_ARGS   = -C target-cpu=cortex-a72

RUSTFLAGS = $(RUSTC_MISC_ARGS) \
    -C link-arg=--library-path=$(LD_SCRIPT_PATH) \
    -C link-arg=--script=kernel.ld

RUSTFLAGS_PEDANTIC = $(RUSTFLAGS) -D warnings -D missing_docs

FEATURES      = --features bsp_rpi4
COMPILER_ARGS = --target=$(TARGET) $(FEATURES) --release

RUSTC_CMD   = cargo rustc $(COMPILER_ARGS)
CLIPPY_CMD  = cargo clippy $(COMPILER_ARGS)
FORMAT_CMD  = cargo fmt
CLEAN_CMD   = cargo clean

EXEC_QEMU = $(QEMU_BINARY) -M $(QEMU_MACHINE_TYPE) \
            -dtb docker/bcm2711-rpi-4-b.dtb \
            -kernel $(KERNEL_BIN) \
            -append "console=ttyAMA0,115200 root=/dev/mmcblk0p2 rw"

READELF_BINARY = aarch64-none-elf-readelf
OBJDUMP_BINARY = aarch64-none-elf-objdump
NM_BINARY      = aarch64-none-elf-nm

##-------------------------------------------------
## PHONY targets
##-------------------------------------------------
.PHONY: all check kernel qemu doc clippy clean format readelf objdump nm

##-------------------------------------------------
## Default: run checks, then build kernel
##-------------------------------------------------
all: check $(KERNEL_BIN)

##-------------------------------------------------
## “check” just enforces format + clippy
##-------------------------------------------------
check: format clippy

##-------------------------------------------------
## Build the stripped binary
##-------------------------------------------------
$(KERNEL_BIN): $(KERNEL_ELF)
	$(call color_header, "Generating Stripped BINARY")
	@mkdir -p $(dir $(KERNEL_BIN))
	@rust-objcopy --strip-all -O binary $(KERNEL_ELF) $(KERNEL_BIN)
	$(call color_progress_prefix, "Name:")
	@echo $(KERNEL_BIN)
	$(call color_progress_prefix, "Size:")
	$(call disk_usage_KiB, $(KERNEL_BIN))

##-------------------------------------------------
## Compile the kernel ELF itself
##-------------------------------------------------
$(KERNEL_ELF): $(KERNEL_ELF_DEPS)
	$(call color_header, "Compiling kernel ELF")
	@RUSTFLAGS="$(RUSTFLAGS_PEDANTIC)" $(RUSTC_CMD)

##-------------------------------------------------
## Run QEMU: depends on everything in “all”
##-------------------------------------------------
qemu: all
	$(call color_header, "Launching QEMU")
	@$(EXEC_QEMU) $(QEMU_RELEASE_ARGS)

##-------------------------------------------------
## Linting & formatting targets
##-------------------------------------------------
format:
	$(call color_header, "Formatting code")
	@$(FORMAT_CMD)

clippy:
	$(call color_header, "Running Clippy")
	@RUSTFLAGS="$(RUSTFLAGS_PEDANTIC)" $(CLIPPY_CMD)

##-------------------------------------------------
## Other helpers
##-------------------------------------------------
clean:
	$(call color_header, "Cleaning target")
	@$(CLEAN_CMD)

doc:
	$(call color_header, "Generating docs")
	@cargo doc $(COMPILER_ARGS) --document-private-items --open

readelf: $(KERNEL_ELF)
	$(call color_header, "Launching readelf")
	$(READELF_BINARY) --headers $(KERNEL_ELF)

objdump: $(KERNEL_ELF)
	$(call color_header, "Launching objdump")
	$(OBJDUMP_BINARY) --disassemble --demangle \
                --section .text \
                $(KERNEL_ELF) | rustfilt

nm: $(KERNEL_ELF)
	$(call color_header, "Launching nm")
	$(NM_BINARY) --demangle --print-size $(KERNEL_ELF) | sort | rustfilt