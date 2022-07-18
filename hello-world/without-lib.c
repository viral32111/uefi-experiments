// http://x86asm.net/articles/uefi-programming-first-steps/

#include <efi/efi.h>

EFI_STATUS EFIAPI efi_main( EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable ) {
	SystemTable->ConOut->OutputString( SystemTable->ConOut, L"Hello World!\n" );

	return EFI_SUCCESS;
}
