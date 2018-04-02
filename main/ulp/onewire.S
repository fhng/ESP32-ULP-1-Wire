#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"

#include "stack.S"

/* RTC_GPIO_9 maps to GPIO 32 */
.macro GPIO_read
	READ_RTC_REG(RTC_GPIO_IN_REG, RTC_GPIO_IN_NEXT_S + 9, 1)
.endm

/* Set pin high-impedance state (input mode) */
/* high imedance pin has an indeterminate state. it is nether high or low which is also commonly referred as "floating" or "tri-stated". To set it to high or low, it has to be driven by an external source */
.macro GPIO_H
	WRITE_RTC_REG(RTC_GPIO_ENABLE_W1TC_REG, RTC_GPIO_ENABLE_W1TC_S + 9, 1, 1)
.endm

/* Output mode */
.macro GPIO_L
	WRITE_RTC_REG(RTC_GPIO_ENABLE_W1TS_REG, RTC_GPIO_ENABLE_W1TS_S + 9, 1, 1)
.endm

/* These two marco for set bus high and set low when GPIO_L is called, enable W1TS. */
.macro GPIO_high
	WRITE_RTC_REG(RTC_GPIO_OUT_W1TS_REG, RTC_GPIO_OUT_DATA_W1TS_S + 9, 1, 1)
.endm

.macro GPIO_low
	WRITE_RTC_REG(RTC_GPIO_OUT_W1TC_REG, RTC_GPIO_OUT_DATA_W1TC_S + 9, 1, 1)
.endm


	/* Define variables, which go into .bss section (zero-initialized data) */
	.bss
	.global stack
stack:
	.skip 24
	.global stackEnd
stackEnd:
	.long 0

	.global temperatureC
temperatureC:
	.long 0
	
	.global temperatureF
temperatureF:
	.long 0

	.global crc8_check
crc8_check:
	.long 0
	.global crc8_value
crc8_value:
	.long 0
	
	.global scratchpad_memory
scratchpad_memory:	// Return 9 Bytes of data after an 0xBE command.
	.long 0		// Byte 0: Temperature LSB
	.long 0		// Byte 1: Temperature MSB
	.long 0		// Byte 2: Th Register
	.long 0		// Byte 3: Tl Register
	.long 0 	// Byte 4: Configuraion Register
	.long 0		// Byte 5: Reserved 
	.long 0		// Byte 6: Reserved
	.long 0		// Byte 7: Reserved
	.long 0		// Byte 8: CRC value


	/* Code goes into .text section */
	.text
	.global entry
entry:

/* Register general usage: */
/* R1 is used for scratech register: So, don't use it if you are push/pop/psr/ret */
/* R3 is used as stack pointer: DON'T USE */
/* R0 is sometime used for JUMPR .... */
/* R2 is free to use: Here, R2 is either used as passing para or as a return var. */

	move r3, stackEnd

	psr
	jump get_temp

	move r1, temperatureC
	st r0, r1, 0

	psr 
	jump get_temp

	move r1, temperatureF
	st r0, r1, 0


	jump exit_wake 

exit:
	/* ULP will restart when half */
	halt

exit_wake:
        READ_RTC_REG(RTC_CNTL_DIAG0_REG, 19, 1)
        and r0, r0, 1
        jump exit, eq

        /* Wake up the SoC and stop ULP program */
	wake
        /* Stop the wakeup timer so it does not restart ULP */
        /* WRITE_RTC_FIELD(RTC_CNTL_STATE0_REG, RTC_CNTL_ULP_CP_SLP_TIMER_EN, 0) */
        halt

/* Use send_rom_id for multiple devices enviorment */
/* Use read_from_single_device to get a single device ROM-ID on the bus. */
/* R2: rom-id location, set your own .global var to store your ROM-ID.*/
/*
send_rom_id:

        move r0, 0
send_rom_id_loop:
        move r1, r2
        add r1, r1, r0
        push r2
        ld r2, r1, 0
        push r0

        psr
        jump send_byte
        
        pop r0
        pop r2
        add r0, r0, 1
        jumpr send_rom_id_loop, 8, lt

        ret
*/

/* Find the 64 bit ROM code when only a single device is on the bus. Can't do  multiple devices search. */
/* Working, uncomment to use, ROM ID is store in a .global romID_8Bytes var. */
/*
read_rom_single_device:
        psr
        jump rst_pulse

        move r2, 0x33
        psr
        jump send_byte

        move r0, 0
read_rom_loop:
        push r0 // remember to push r0 before call routine
        psr
        jump read_byte
        move r1, romID_8Bytes //create romID_8Bytes at your .bss section
        pop r0
        add r1, r1, r0
        st r2, r1, 0
        add r0, r0, 1
        jumpr read_rom_loop, 8, lt

        ret
*/


rst_pulse:
	/* set OUTPUT_W1TS for output */
	GPIO_L
	/* ULP running at 8mhz, 8mhz  = 8us per cycle, thats 0.125 cpu over 1us.  */
	/* So, 500us delay = 500/0.125 => 4,000 cpu cycles. */
	/* wait 500 microsecond, 1000 ms = 1 millisecon */
	GPIO_low
	wait(4000) /* 500 us */
	
	GPIO_high
	GPIO_H
	wait(240) /* 30us */
	GPIO_read /* r0 holds input result */
	wait(3760) /* 470us */
	ret
	
/* R0 - (16bit) temperature is store in R0 on return. */
/* This work with one device on the bus, for multiple devicse you should send ROM-ID after rst_pulse */
get_temp:
	psr
	jump rst_pulse
	
	/* send 0xCC and 0x44 command */
	move r2, 0xCC
	psr
	jump send_byte
	move r2, 0x44
	psr
	jump send_byte
	

	/* delay 750ms, looping 750x in delay_ms */
	/* 0x44 convert command: convertion is slow, 750 milliseconds */
	psr
	jump delay_ms
	
	psr
	jump rst_pulse

	/* sent 0xCC and 0xBE command */
	move r2, 0xCC
	psr
	jump send_byte
	move r2, 0xBE 	// read scratchpad(9 bytes, last byte is CRC)
	psr
	jump send_byte

	/* read 9 bytes from scratchpad memory,*/
	stage_rst
	move r0, scratchpad_memory

get_temp_9bytes:
	push r0

	psr
	jump read_byte
	
	pop r0
	st r2, r0, 0
	add r0, r0, 1
	stage_inc 1
	jumps get_temp_9bytes, 9, LT

	psr
	jump rst_pulse

	/* check CRC value against 8 data bytes and store result in check8_check */
	/* Just store the result for now, no reread temperature if there is an error */
	psr
	jump checkCRC8_bytes
	move r1, crc8_check
	st r2, r1, 0

	/* load temperature from scatchpad_memory[0] and scatchpad_memory[1] */
	move r1, scratchpad_memory
	ld r0, r1, 0
	add r1, r1, 1
	ld r2, r1, 0

/* old way without CRC check
	psr 
	jump read_byte
	move r0, r2 	// Temp store read_byte into R0 
	push r0

	psr 
	jump read_byte 	// R0 store this read_byte 

	psr
	jump rst_pulse

	pop r0
*/

	/* Return the combined temperature data in R0 */
	/* First read_byte is bitpos [7-0] */
	/* Second read_byte is bitpos [15-8] */
	/* Have to div 16 to make a dec number */
	lsh r2, r2, 8
	or r0, r0, r2
	
	/* load CRC8 value from scratchpad memory at Byte 9 */
	add r1, r1, 7
	ld r1, r1, 0
	move r2, crc8_value
	st r1, r2, 0

	
	ret

/* R2: (8bits) read_byte stores in R2 on return. */
read_byte:
	/*
	psr
	jump read_bit
	move r2, r0
	wait(120)  15 us 
	move r0, 1
	*/
	move r2, 0
	move r0, 0

read_byte_loop:
	push r0
	psr
	jump read_bit
	move r1, r0
	pop r0

	lsh r1, r1, r0
	or r2, r2, r1

	wait(120) /* 15 us */
	add r0, r0, 1
	jumpr read_byte_loop, 8, LT

	ret

/* R0: (1bit) stores GPIO input on return. */
/* since R2 is used to store all the bits */
read_bit:
	GPIO_L
	GPIO_low
	wait(16) /* 2 us */
	GPIO_high
	wait(120) /* 15 us */
	GPIO_H
	GPIO_read 
	
	ret

/* R0 is used to counter, R1 is used by psr, R3 is used by stack */
/* R2: stores the (8bits) beging sent. */
send_byte:
	move r1, r2
	move r0, 0
send_byte_loop:
	rsh r2, r1, r0
	and r2, r2, 0x01
	/* r2 hold the bit to be sent */
	
	push r0
	push r1

	psr
	jump send_bit

	pop r1
	pop r0

	add r0, r0, 1
	jumpr send_byte_loop, 8, LT
	
	wait(800) /* 100us */
	ret

/* R2: Stores the one bit being sent. */
send_bit:
	GPIO_L
	GPIO_low
	wait(40) /* 5us */
	sub r2, r2, 0
	jump send_bit_low, eq
send_bit_high:
	GPIO_high
	
send_bit_low:
	wait(640) /* 80us */
	GPIO_high

	ret

delay_ms:
	/* delay 750 mill sec, wait 0.75 sec, 1000 millisecond = 1 second */
	/* 1ms = 1,000 us */
	move r0, 750
	delay_ms_loop:

	sub r0, r0, 1
	wait(7990) /* 1millsecond = 1000 microsecond */
	jumpr delay_ms_loop, 1, GE
	ret

