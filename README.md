![Alt text](ds18b20.jpg?raw=true "DS18B20")
![Alt text](ds18b20_.jpg?raw=true "DS18B20")

install and test run:

1) git clone https://github.com/fhng/ESP32-ULP-1-Wire.git
2) cd to project file and 
3) make menuconfig
4) make flash monitor
5) Feel free to ask questions.


## ESP32 ULP 1-Wire example

Using GIPO 32 (RTC_GOIO 9) for 1-wire. A pull-up 1.5kohm between 3.3v and GPIO 32 and a magnetic Temperature sensor DS18B20 waterproof 1m Cable at the end of GPIO.


DS18B20: data line(green/blue) to GPIO 32, Ground to Ground(black), Power to Power(red).


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

## --Update April 6 2018 --

\** **its here https://github.com/fhng/DS18B20-Search-RomIDs : Its too big to fit everything in ULP, so I separated it from main project. Both project is the same but added search_rom subroutine and some memory space for devices' romID.**

-- Added Search Rom subroutine - It look for the unique 64bit ROM identification for each devices on the bus thus its able to communicate with number of devices on the bus. Again with ULP 8K memory restriction, not all of these subroutines would fit. So select whats important to you and only use those thats needed. *I already tried to include all these subroutines and when I do MAKE it complains there isn't enough room and simply not allow to do so.

. I tested it with setting it to return only 2 romIDs since I only have two DS18B20. I am going to add 6, in total, later on. So, for now it is only tested with two. When I have 6 DS18B20 I will probably run it once then hard code the six romIDs to ULP and not include this and some of the other subroutines because of the 8K limit. Or do this in the regluar cpu in C then pass it to ULP.

. The implementation side of it(might help someone and its fun): It simply a Btree search. Find the location of discrepancy or conflicting bits on devices romID and remember it. Split and keeping going down the tree to the end and then return back to discrepancy point and search down again on this device until the end. Repeat and Repeat until no more devices.

. On the device side: After you send command 0xF0 "Search Rom", each devices will respond by sending back its first bit of their romID. The result is the logical AND of all devices on the bus. Lets we have 3 devices and bits from the devices are "1", "0" and "0" => 1 AND 0 AND 0 = 0. Then these devcies will send another bit which is the complement of the first bit of their RomID, again result is the logical AND of all. So, now we have a combined bits(2 bits) of "00" : 00 means devices have conflicting bits, 01 means All devcies have a 0 bit at this position, 10 means All devices have a 1 bit at this position, 11 means no devices. And after that you send a bit "0" or "1" to select and deselect the devices. For example, send bit "0", will keep devices that has romID with a "0" at this position and deselect those with "1" at this position. Repeat this process 64 times to get one 64 bits romID and repeat again to get next romID of another device and so on.

. Below is btree trace on: ROM1 10101100 (blue), ROM2 01010101 (red), ROM3 10101111 (yellow), ROM4 10001000 (green) (RomID is 64bits, this is just an shorten example) \* **DS18B20 sends bits from LSB to MSB. So for ROM4 is 0->0->0->1->0->0->0->1**
![Alt text](btree.png?raw=true "DS18B20")

## --Update April 2 2018 --
- Added CRC8-Maxium checking, file "ulp/cr8Maxim.S"

Can check data error against RomID(8 bytes) and Scatchpad Memory (9 bytes) if you need.

It is a simple loop XOR on Data with CRC8-Maxium polynomial (b10001100<-- reflected). Since memory size matters in ULP I decided to use loop instead of a LUT which is **a lot faster** (skipping the shifting of 8bits and no calculation). LUT uses at least 256 bytes more memory.

Since there is no XOR in ULP I created a macro for it. Xor = (X or Y) + (X and Y)


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

2)Some of the ds18b20 code is a direct port from feelfreelinux/ds18b20 https://github.com/feelfreelinux/ds18b20

3)Also, stack.S and subrotines call are from tomtor/up-i2c https://github.com/tomtor/ulp-i2c

Tomtor's ulp-i2c code is very helpful for understsanding ULP.


Note:


*the comments in the code are meant for myself at the time of writing them. If they are confusing to you feel free to ask question.


## Example output

Note: GPIO15 is connected to GND to disable ROM bootloader output.
```
Not ULP wakeup, initializing ULP
Entering deep sleep

<<<<<< Result: 1 >>>>>>
----- Temperature in C ----- 24.25
----- Temperature in F ----- 75.65
----- CRC8 Scratchpad value ---- 0x72
----- CRC8 Checked result ---- 0x72
Entering deep sleep

<<<<<< Result: 2 >>>>>>
----- Temperature in C ----- 24.25
----- Temperature in F ----- 75.76
----- CRC8 Scratchpad value ---- 0x5f
----- CRC8 Checked result ---- 0x5f
Entering deep sleep

<<<<<< Result: 3 >>>>>>
----- Temperature in C ----- 24.25
----- Temperature in F ----- 75.76
----- CRC8 Scratchpad value ---- 0x5f
----- CRC8 Checked result ---- 0x5f
Entering deep sleep

<<<<<< Result: 4 >>>>>>
----- Temperature in C ----- 24.25
----- Temperature in F ----- 75.65
----- CRC8 Scratchpad value ---- 0x72
----- CRC8 Checked result ---- 0x72
Entering deep sleep

<<<<<< Result: 5 >>>>>>
----- Temperature in C ----- 24.25
----- Temperature in F ----- 75.65
----- CRC8 Scratchpad value ---- 0x72
----- CRC8 Checked result ---- 0x72
Entering deep sleep

<<<<<< Result: 6 >>>>>>
----- Temperature in C ----- 24.31
----- Temperature in F ----- 75.65
----- CRC8 Scratchpad value ---- 0x72
----- CRC8 Checked result ---- 0x72
Entering deep sleep

<<<<<< Result: 7 >>>>>>
----- Temperature in C ----- 24.25
----- Temperature in F ----- 75.65
----- CRC8 Scratchpad value ---- 0x72
----- CRC8 Checked result ---- 0x72
Entering deep sleep

```

