/* https://wiki.osdev.org/Bare_bones#Bootstrap_Assembly */

/*
 Symbols for the Multiboot header flags that describe our architecture.
 https://www.gnu.org/software/grub/manual/multiboot/multiboot.html#Header-magic-fields
*/
.set MULTIBOOT_FLAG_ALIGN, 1 << 0
.set MULTIBOOT_FLAG_MEMINFO, 1 << 1

/*
 Symbols for the Multiboot header.
 https://wiki.osdev.org/Multiboot
 https://www.gnu.org/software/grub/manual/multiboot/multiboot.html#Header-layout
*/
.set MULTIBOOT_MAGIC, 0x1BADB002 /* The magic number for version 1. */
.set MULTIBOOT_FLAGS, MULTIBOOT_FLAG_ALIGN | MULTIBOOT_FLAG_MEMINFO /* The flags that describe us. */
.set MULTIBOOT_CHECKSUM, -( MULTIBOOT_MAGIC + MULTIBOOT_FLAGS ) /* The checksum of the two fields above. */

/*
 Declare the Multiboot header at a 4 byte alignment so that GRUB can boot us.
 GRUB will search through the first 8 KiB of a kernel file aligned at 4 bytes (32-bits) for a Multiboot header.
*/
.section .multiboot
	.align 4
	.long MULTIBOOT_MAGIC
	.long MULTIBOOT_FLAGS
	.long MULTIBOOT_CHECKSUM

/*
 Allocate room for a stack by creating a symbol at the bottom, skipping ahead by 16 KiB, then creating a symbol at the top.
 The Multiboot standard does not define the value of the Stack Pointer register (ESP), thus it is up to us to create the stack.
 The stack grows downwards on the x86 architecture, and it must be aligned to 16 bytes to comply with the System V ABI standard.
 This is defined in its own section so it can be marked as nobits, which makes the file smaller as it does not contain the uninitialized stack.
 https://wiki.osdev.org/System_V_ABI

 The Block Starting Symbol (BSS) section contains statically allocated variables that are declared, but have not been initialized with a value.
*/
.bss
	.align 16
	stack_bottom:
	.skip 16384
	stack_top:

/* Change to the text section. */
.text

	/*
	 Declare the exported entry-point symbol as a function.

	 The bootloader jumps to this position once the kernel has been loaded.
	 Do not return from this function as the bootloader is no longer available.

	 The linker script controls the name of this function (_start in this case).
	*/
	.global _start
	.type _start, @function

	/* Begin the entry-point. */
	_start:

		/*
		 We are now in 32-bit protected mode for this x86 system.
		 Processor interrupts and paging is disabled.
		 The processor state is defined in the Multiboot standard.
		 There are no security restrictions or debugging mechanisms.
		 Floating point instructions & instruction set extensions are not initialized.

		 We have absolute control over the system.

		 There is no printf function as that is part of the C standard library.
		*/

		/*
		 Setup the Stack Pointer register to reference the top of the uninitalized stack we made.
		 This has to be done before calling our C entry-point as C requires a stack.
		*/
		mov $stack_top, %esp

		/*
		 Call the C entry-point function.
		 
		 The System V ABI standard requires that the stack is still aligned to 16 bytes when this is called.
		 However, our original alignment of 16 bytes is still preserved as we have not pushed any bytes onto the stack yet.
		*/
		call kernel_main

		/*
		 Put the system into an infinite loop once everything has finished.
		 Ideally we should never get here, as our kernel should always have something to do.

		 The infinite loop is done by disabling interrupts, waiting until the next interrupt, then jumping back to that wait until next interrupt.
		 The jump is required in the event of a non-maskable interrupt occuring.
		*/
		cli /* Clear interrupt enable flag */
		wait_for_interrupt: hlt /* Wait for interrupt */
		jmp wait_for_interrupt /* Jump back to the line above */

/*
 Set the size of the entry-point symbol to the current position minus itself.
 This is apparently useful for debugging or when implementing call tracing.
*/
.size _start, . - _start
