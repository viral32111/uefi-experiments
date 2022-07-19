// https://wiki.osdev.org/GNU-EFI
// https://wiki.osdev.org/UEFI#Developing_with_GNU-EFI

#include <efi/efi.h>
#include <efi/efilib.h>

/*
export GNUEFI='/opt/gnuefi'

gcc -I${GNUEFI}/include -fpic -ffreestanding -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone -maccumulate-outgoing-args -c with-lib.c -o with-lib.o
ld -shared -Bsymbolic -L${GNUEFI}/lib -T${GNUEFI}/elf_x86_64_efi.lds ${GNUEFI}/crt0-efi-x86_64.o with-lib.o -o with-lib.so -lgnuefi -lefi
objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc --target efi-app-x86_64 --subsystem=10 with-lib.so with-lib.efi

gcc with-lib.c -c -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -I ${GNUEFI}/include -I ${GNUEFI}/include/x86_64 -DEFI_FUNCTION_WRAPPER -o with-lib.o
ld with-lib.o ${GNUEFI}/crt0-efi-x86_64.o -nostdlib -znocombreloc -T ${GNUEFI}/elf_x86_64_efi.lds -shared -Bsymbolic -L ${GNUEFI}/lib -l:libgnuefi.a -l:libefi.a -o with-lib.so
objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .reloc --target=efi-app-x86_64 with-lib.so with-lib.efi
*/

EFI_STATUS EFIAPI efi_main( EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable ) {
	InitializeLib( ImageHandle, SystemTable );

	Print( L"Hello World!\n" );

	return EFI_SUCCESS;
}
