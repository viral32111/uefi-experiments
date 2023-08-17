gcc -fpic -ffreestanding -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone -maccumulate-outgoing-args -c uefi.c -o uefi.o

ld -shared -Bsymbolic -e EfiMain uefi.o -o bootx64.efi

docker container run --name gcc --interactive --tty --mount type=bind,source="$PWD",target=/repo --workdir /repo --user 1000:1000 --rm ghcr.io/viral32111/gcc:i686-elf

i686-elf-gcc -fpic -ffreestanding -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone -maccumulate-outgoing-args -c source.c -o object.o
i686-elf-ld -nostdlib -znocombreloc -shared -Bsymbolic -e EfiMain object.o -o application.efi
i686-elf-strip application.efi

qemu-system-x86_64 -L ~/QEMU/ -pflash /usr/share/edk2/x64/OVMF.fd -hda image.iso -net none
