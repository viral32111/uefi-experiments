// These headers are part of the compiler, not the C standard library
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>
//#include <stdarg.h>
//#include <float.h>

// Prevent compiling on a native compiler
#if defined( __linux__ ) || !defined( __i386__ )
	#error "Must be compiled using an i686-elf (32-bit) cross-compiler"
#endif

// Define constants for the colors on VGA (hardware) text mode
enum VGA_COLOR {
	VGA_COLOR_BLACK = 0,
	VGA_COLOR_BLUE = 1,
	VGA_COLOR_GREEN = 2,
	VGA_COLOR_CYAN = 3,
	VGA_COLOR_RED = 4,
	VGA_COLOR_MAGENTA = 5,
	VGA_COLOR_BROWN = 6,
	VGA_COLOR_LIGHT_GREY = 7,
	VGA_COLOR_DARK_GREY = 8,
	VGA_COLOR_LIGHT_BLUE = 9,
	VGA_COLOR_LIGHT_GREEN = 10,
	VGA_COLOR_LIGHT_CYAN = 11,
	VGA_COLOR_LIGHT_RED = 12,
	VGA_COLOR_LIGHT_MAGENTA = 13,
	VGA_COLOR_LIGHT_BROWN = 14,
	VGA_COLOR_WHITE = 15
};

// Calculates the VGA color value of a foreground and background color combination
uint8_t vga_calculate_color( enum VGA_COLOR foreground_color, enum VGA_COLOR background_color ) {
	return foreground_color | background_color << 4;
}

// Calculates the VGA character value of a character and a VGA color value
uint16_t vga_calculate_character( unsigned char character, uint8_t color ) {
	return ( uint16_t ) character | ( uint16_t ) color << 8;
}

// Calculates the length of a string by counting until a null terminator
size_t string_length( const char *string ) {
	size_t length = 0;

	while ( string[ length ] != 0x00 ) {
		length++;
	}

	return length;
}

// Resolution of the VGA text mode buffer
const size_t VGA_WIDTH = 80;
const size_t VGA_HEIGHT = 25;

// Stores the current cursor position & color
size_t current_terminal_row;
size_t current_terminal_column;
uint8_t current_terminal_color;

// Stores a pointer to the VGA text mode buffer
uint16_t *terminal_buffer;

// Sets up the terminal
void initialize_terminal() {
	
	// Initalise the global variables to their defaults
	current_terminal_row = 0;
	current_terminal_column = 0;
	current_terminal_color = vga_calculate_color( VGA_COLOR_WHITE, VGA_COLOR_BLACK );

	// Set to a reference of where the VGA text mode buffer is located on BIOS
	terminal_buffer = ( uint16_t * ) 0xB8000;

	// Fill the buffer with spaces (basically empty characters)
	for ( size_t position_y = 0; position_y < VGA_HEIGHT; position_y++ ) {
		for ( size_t position_x = 0; position_x < VGA_WIDTH; position_x++ ) {
			const size_t index = position_y * VGA_WIDTH + position_x;
			terminal_buffer[ index ] = vga_calculate_character( ' ', current_terminal_color );
		}
	}

}

// Sets the VGA color value to use for characters
void set_terminal_color( uint8_t color ) {
	current_terminal_color = color;
}

// Writes a character to a specific position
void put_character_at( char character, uint8_t color, size_t position_x, size_t position_y ) {
	const size_t index = position_y * VGA_WIDTH + position_x;
	terminal_buffer[ index ] = vga_calculate_character( character, color );
}

// Writes a character to the current position
void put_character( char character ) {
	put_character_at( character, current_terminal_color, current_terminal_column, current_terminal_row );

	// Reset the column and row position if they are at their ends of the available space
	if ( ++current_terminal_column == VGA_WIDTH ) {
		current_terminal_column = 0;

		if ( ++current_terminal_row == VGA_HEIGHT ) {
			current_terminal_row = 0;
		}
	}
}

// Write arbitrary data
void write_data( char *data, size_t size ) {
	for ( size_t index = 0; index < size; index++ ) {
		put_character( data[ index ] );
	}
}

// Write a string of characters
void write_string( char *string ) {
	write_data( string, string_length( string ) );
}

// The main entry-point
void kernel_main() {

	// Initialize the terminal
	initialize_terminal();

	// Write an example string
	write_string( "Hello World" );

}
