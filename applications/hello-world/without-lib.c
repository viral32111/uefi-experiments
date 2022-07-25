// http://x86asm.net/articles/uefi-programming-first-steps/

#include <efi/efi.h>

/*
export GNUEFI='/opt/gnuefi'

gcc -I${GNUEFI}/include -fpic -ffreestanding -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone -maccumulate-outgoing-args -c /applications/hello-world/without-lib.c -o /tmp/hello-world/without-lib.o
ld -shared -Bsymbolic -L${GNUEFI}/lib -T${GNUEFI}/elf_x86_64_efi.lds ${GNUEFI}/crt0-efi-x86_64.o /tmp/hello-world/without-lib.o -o /tmp/hello-world/without-lib.so -lgnuefi -lefi
objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc --target efi-app-x86_64 --subsystem=10 /tmp/hello-world/without-lib.so /tmp/hello-world/without-lib.efi

gcc /applications/hello-world/without-lib.c -c -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -I ${GNUEFI}/include -I ${GNUEFI}/include/x86_64 -DEFI_FUNCTION_WRAPPER -o /tmp/hello-world/without-lib.o
ld /applications/hello-world/without-lib.o ${GNUEFI}/crt0-efi-x86_64.o -nostdlib -znocombreloc -T ${GNUEFI}/elf_x86_64_efi.lds -shared -Bsymbolic -L ${GNUEFI}/lib -l:libgnuefi.a -l:libefi.a -o /tmp/hello-world/without-lib.so
objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym -j .rel -j .rela -j .reloc --target=efi-app-x86_64 /tmp/hello-world/without-lib.so /tmp/hello-world/without-lib.efi
*/

EFI_STATUS EFIAPI efi_main( EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable ) {
	EFI_STATUS outputStatus = uefi_call_wrapper( SystemTable->ConOut->OutputString, 2, SystemTable->ConOut, L"Hello World!\r\n" );

	return outputStatus;
}
