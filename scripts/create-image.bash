#!/bin/bash

# Requires: udev, parted, dosfstools, mtools

# Exit if there are any errors & print each line
set -e -x

# ------------------------ #

# Create 40 MB empty image for GPT
dd if=/dev/zero of=/tmp/image.img bs=1000000 count=40

# Initialise GPT
parted /tmp/image.img --script --align minimal mktable gpt

# Create EFI system partition from beginning to end
# NOTE: Start is actually at 17,408 bytes due to GPT reserved
parted /tmp/image.img --script --align minimal mkpart EFI FAT32 0 100%

# Enable boot flag for EFI system partition
parted /tmp/image.img --script --align minimal toggle 1 boot

# ------------------------ #

# Create 38 MB empty partition for FAT32 filesystem
# NOTE: Must be smaller than image due to 17,408 byte GPT reserved
# NOTE: Minimum FAT32 size is 32 MiB / 33.5 MB / 33,548,800 bytes
dd if=/dev/zero of=/tmp/partition.img bs=1000000 count=38

# Format the partition as FAT32 filesystem
mkfs.fat -v -F 32 /tmp/partition.img

# Copy the applications into the root of the FAT32 filesystem
mcopy -i /tmp/partition.img /tmp/hello-world/with-lib.efi ::/hello-world-with-lib.efi
mcopy -i /tmp/partition.img /tmp/hello-world/without-lib.efi ::/hello-world-without-lib.efi

# Write the entire partition to the image from the end of the 17,408 byte GPT reserved
dd if=/tmp/partition.img of=/tmp/image.img bs=1 seek=17408 count=32000000 conv=notrunc

# ------------------------ #

# Display the final structure of the image
parted /tmp/image.img --script --align minimal print all
