## ESP32 ULP 1-Wire example
Using GIPO 32 (RTC_GOIO 9) for 1-wire. A pull-up 1.5kohm between 3.3v and GPIO 32 and a magnetic Temperature sensor DS18B20 waterproof 1m Cable at the end of GPIO.


DS18B20: data line to GPIO 32, Ground to Ground, Power to Power.


Testing, playing with ESP32 ULP for learning purpose. Below are the resources I used to code this. app_main() init ULP and sets it on a timer and it goes to sleep. ULP gets temperature from ds18b20, wakes up app_main() then halt. app_main() prints the output and go to sleep. Timer wakes ULP and the cycle repeats again. 

## Subroutines

- get_temp : Return a 2 bytes temperature data from device in R0.
- rst_pulse : Set bus low for 500us, then high for 240 and read device presence.
- read_byte : Read one byte from device by calling read_bit, return input in R2.
- read_bit : Read one bit by pulling bus low for 2us and pull high for 15us then read device, return bit store in R0
- send_byte : R2 stores out going byte, calls send_bit to send bit by bit.
- send_bit : R2 stores the bit being sent, pulling bus low for 5us ( low bit: wait 80us then pull high, High bit: pull high)
- delay_ms : delay for 750 millisecond

## In general, codes in ULP do this:

Send command 0xCC // Send skip ROM command; ignore device IDs

Send command 0x44 // start conversion command - produce 2 bytes and this process is slow, 750 milliseconds.

reset pulse

wait 750 milliseconds

Send command 0xCC // Send skip ROM command

Send command 0xBE // Send Read Scratch Pad and return it

read one byte from bus

read one byte from bus

combine these two byte into temperature data



***********************************************************************************************************

## --Update April 4 2018 --
- Added CRC8-Maxium checking, file "ulp/cr8Maxim.S"

Can check data error against RomID(8 bytes) and Scatchpad Memory (9 bytes) if you need.

It is a simple loop XOR on Data with CRC8-Maxium polynomial (b10001100<-- reflected). Since size matters in ULP I decided to use loop instead of a LUT which it is faster(skipping the shifting of XOR 8bits). LUT uses at least 256 bytes more memory.

Since there is no XOR in ULP I created a macro for it. Xor = ( X or Y) + ( X and Y)


## --Update March 19 2018--

- Added **"read_rom_single_device"** subroutine - to get a DS18B20 64bit ROM-ID

- Added **"send_rom_id"** subroutine - So you can talk to multiple DS18B20 with their ROM-IDs.

I am using 4 to 6 DS18B20 devices. So I am manually reading each device with read_rom_single_device and copy down the ROM IDs and init them in my appMain() before calling ULP. ULP can loop through these ROM-IDs for multiple devices environment.   

*RTC_SLOW_MEMORY is 8kb in size, thats the reason I don't do a search for ROM-IDs for multiple devices. ULP code is getting too big as is. Beside I want to have as much memory as possible to store temperature datas to save battery life. 

*Probabaly will add search for ROM-IDs function in C, not in ULP. It is getting big and a bit messy. I want to keep this as a ULP sample code.

These two subroutines are commented out. Uncomment to use as you need.

***********************************************************************************************************





## Resources:

1)Used espresssif/esp-idf/system/ulp as a starting template.

2)All the ds18b20 code is a direct port from feelfreelinux/ds18b20 https://github.com/feelfreelinux/ds18b20

3)Also, stack.S and subrotines call are from tomtor/up-i2c https://github.com/tomtor/ulp-i2c

Tomtor's ulp-i2c code is very helpful for understsanding ULP.


Note:


*the comments in the code are meant for myself at the time of writing them. If they are confusing to you feel free to ask question.


## Example output

Note: GPIO15 is connected to GND to disable ROM bootloader output.

Not ULP wakeup, inititializing ULP

Entering deep sleep


<<<<<< Result: 1 >>>>>>

----- Temperature in C ----- 24.44

----- Temperature in F ----- 75.99

Entering deep sleep


<<<<<< Result: 2 >>>>>>

----- Temperature in C ----- 24.44

----- Temperature in F ----- 75.99

Entering deep sleep



<<<<<< Result: 3 >>>>>>

----- Temperature in C ----- 24.44

----- Temperature in F ----- 75.99

Entering deep sleep



<<<<<< Result: 4 >>>>>>

----- Temperature in C ----- 24.44

----- Temperature in F ----- 75.99

Entering deep sleep


<<<<<< Result: 5 >>>>>>

----- Temperature in C ----- 24.44

----- Temperature in F ----- 75.99

Entering deep sleep

