#!/bin/bash

# Exit if there are any errors
set -e

# Start a Docker container if we are not in one
if [[ ! -f /.dockerenv ]]; then
	docker container run \
		--name kernel-builder \
		--hostname kernel-builder \
		--mount type=bind,source=$PWD,target=/kernel,readonly \
		--workdir /tmp \
		--entrypoint /kernel/build.bash \
		--interactive \
		--tty \
		viral32111/uefi-experiments:uefi

	# Could also just move the kernel files into the /kernel directory, but then it would have to be read-write
	docker container cp kernel-builder:/tmp/kernel.efi ./kernel.efi
	docker container cp kernel-builder:/tmp/kernel.iso ./kernel.iso

	docker container rm kernel-builder > /dev/null

	exit 0
fi

# Add the cross-assembler & cross-linker to the binaries path
export PATH="/opt/i686-elf/binutils/i686-elf/bin:$PATH"

# Assemble the pre-kernel assembly code
i686-elf-as /kernel/source/boot.s -o ./boot.o

# Compile the kernel C code as freestanding & C99 standard
i686-elf-gcc -c /kernel/source/kernel.c -o ./kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra

# Link the above files into one file using the linker script (compiler is used because it gives greater control compared to the regular linker)
i686-elf-gcc -T /kernel/linker.ld -o ./kernel.efi -ffreestanding -O2 -nostdlib ./boot.o ./kernel.o -lgcc

# Display information about the kernel file
file ./kernel.efi
sha1sum ./kernel.efi

if ! grub-file --is-x86-multiboot ./kernel.efi; then
	echo "Kernel is NOT Multiboot compliant."
	exit 1
fi

# Create a bootable GRUB image with the kernel file
mkdir --verbose --parents ./iso/boot/grub
cp --verbose ./kernel.efi ./iso/boot/kernel.efi
cp --verbose /kernel/grub.cfg ./iso/boot/grub/grub.cfg
grub-mkrescue -o ./kernel.iso ./iso

# Display information about the bootable image
file ./kernel.iso
sha1sum ./kernel.iso
