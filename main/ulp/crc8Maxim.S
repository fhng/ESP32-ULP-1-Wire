/*
 * CRC 8 Maxium for 1-Wire, Polynomial is X^8+X^5+X^4+X^0 (0b1 0011 0001)
 * Reflected INPUT and OUTPUT: Thus using reflected Polynomial and Shifting the CRC Shift register to the right.
 * Reflected Polynomial: 0b1000 1100 from 0b0011 0001
 */

#include "stack.S"

/*
// Since there is no build-in XOR defining my own.
// xor = (X or Y) - (X and Y)
// or r0, r2, r3
// and r1, r2, r3
// sub r2, r0, r1
*/

.macro xor rs rx ry
        or \rs, \rx, \ry
        push \rs
        and \rs, \rx, \ry
        move \ry, \rs
        pop \rx
        sub \rs, \rx, \ry
.endm


	.bss

        .set polynomial, 0b00110001
        .set polynomial_reflected, 0b10001100

	.data
	.global romid
romid:
        .long 0x28              // bit 1
        .long 0x9B              // bit 2
        .long 0x58              // bit 3
        .long 0xAF              // bit 4
        .long 0x06              // bit 5
        .long 0x00              // bit 6
        .long 0x00              // bit 7
        .long 0x1E              // bit 8: CRC8-Maxim value


	.text

// Loop through a byte or a series of bytes and returns a CRC value.
// Will return a CRC8-Maxim value if array of bytes doesn't have the CRC value.
// If array of byte has a CRC value the result will be zero (if no CRC ERROR).

// R2: always hold the CRC Shift register.
// R0: Tracking the number of Bytes.
// R1: Reference to the locatoin of Bytes, RomID.

.global checkCRC8_bytes
checkCRC8_bytes:
        move r2, 0x00   		// init CRC Shift register to zero
        move r0, 0      		// Bytes counter
        // move r1, romid  		// Where Bytes are stored
        move r1, scratchpad_memory	// Where Bytes are stored

checkCRC8_bytes_loop:
        push r0         // Save counter and reuse R0 for other things
        ld r0, r1, 0
        add r1, r1, 1   // Go to next Byte
        push r1         // Save romid reference and reuse R1 for XOR
        xor r1, r2, r0  // XOR Macro needs three registers in order to work
        move r2, r1     // Move result back to R2, R2 always store CRC shift register

        psr
        jump checkCRC8_oneByte

        pop r1
        pop r0

        add r0, r0, 1
	// Loop through all data and CRC value to check result against zero
	// Or Loop through data only to get CRC value
	// RomID has 8 bytes, Scatchpad Memory has 9 bytes
        jumpr checkCRC8_bytes_loop, 8, lt 

        ret


// Right shifting a byte of zero, 1 at a time, to the CRC shift register.
// R2: always contains the CRC shift register.
// R0: used for holding the fall-off bit.
// R1: holds the reflected polnomial (CRC8-Maxim's INPUT reflected and OUTPUT reflected)

checkCRC8_oneByte:
        stage_rst

one_byte_loop:
        move r1, polynomial_reflected
        and r0, r2, 0x01                // Loads fall-off bit before rsh.
        rsh r2, r2, 1                   // Shifting right by 1 bit, this fall-off bit was saved.

        jumpr bit0_no_XOR, 1, lt

bit1_do_XOR:
        xor r0, r2, r1
        move r2, r0

bit0_no_XOR:
        stage_inc 1
        jumps one_byte_loop, 8, LT

        ret
