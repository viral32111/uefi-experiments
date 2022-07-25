#!/bin/bash

# Exit if there are any errors & print each line
set -e -x

# GNU-EFI headers, libraries & scripts
GNUEFI='/opt/gnuefi'

# Create required directories
mkdir --verbose --parents /tmp/hello-world

# Hello World (with library)
gcc -I${GNUEFI}/include -fpic -ffreestanding -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone -maccumulate-outgoing-args -c /applications/hello-world/with-lib.c -o /tmp/hello-world/with-lib.o
ld -shared -Bsymbolic -L${GNUEFI}/lib -T${GNUEFI}/elf_x86_64_efi.lds ${GNUEFI}/crt0-efi-x86_64.o /tmp/hello-world/with-lib.o -o /tmp/hello-world/with-lib.so -lgnuefi -lefi
objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc --target efi-app-x86_64 --subsystem=10 /tmp/hello-world/with-lib.so /tmp/hello-world/with-lib.efi

# Hello World (without library)
gcc -I${GNUEFI}/include -fpic -ffreestanding -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone -maccumulate-outgoing-args -c /applications/hello-world/without-lib.c -o /tmp/hello-world/without-lib.o
ld -shared -Bsymbolic -L${GNUEFI}/lib -T${GNUEFI}/elf_x86_64_efi.lds ${GNUEFI}/crt0-efi-x86_64.o /tmp/hello-world/without-lib.o -o /tmp/hello-world/without-lib.so -lgnuefi -lefi
objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc --target efi-app-x86_64 --subsystem=10 /tmp/hello-world/without-lib.so /tmp/hello-world/without-lib.efi
