/* The function (symbol) the bootloader will use to start the execution of the assembly code. */
ENTRY( _start )

/* State where the sections of the object files will be put in the final file. */
SECTIONS {

	/* Put everything at 1 MiB, which is a usual place for kernels to be when loaded by the bootloader. */
	. = 1M;

	/* Put the Multiboot header section first, as it needs to be within the first 8 KiB of the file. */
	/* The text section will be placed following it. */
	.text BLOCK( 4K ) : ALIGN( 4K ) {
		*( .multiboot )
		*( .text )
	}
 
	/* Place read-only section, which we are not using anyway. */
	.rodata BLOCK( 4K ) : ALIGN( 4K ) {
		*(.rodata)
	}
 
	/* Place initialized data. */
	.data BLOCK( 4K ) : ALIGN( 4K ) {
		*( .data )
	}
 
	/* Finally place read-write and uninitialized data (our stack). */
	.bss BLOCK( 4K ) : ALIGN( 4K ) {
		*( COMMON )
		*( .bss )
	}

}
