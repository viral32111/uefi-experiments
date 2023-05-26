gcc -fpic -ffreestanding -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone -maccumulate-outgoing-args -c uefi.c -o uefi.o

ld -shared -Bsymbolic -e EfiMain uefi.o -o bootx64.efi
