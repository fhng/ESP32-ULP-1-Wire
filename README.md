# ESP32 ULP 1-Wire example
Using GIPO 32 (RTC_GOIO 9) for 1-wire. A pull-up 1.5kohm between 3.3v and GPIO 32 and a magnetic Temperature sensor DS18B20 waterproof 1m Cable at the end of GPIO.


DS18B20: data line to GPIO 32, Ground to Ground, Power to Power.


Testing, playing with ESP32 ULP for learning purpose. Below are the resources I used to code this. app_main() init ULP and sets it on a timer and it goes to sleep. ULP gets temperature from ds18b20, wakes up app_main() then halt. app_main() prints the output and go to sleep. Timer wakes ULP and the cycle repeats again. 


In general, codes in ULP do this:

Send command 0xCC // Send skip ROM command; ignore device IDs

Send command 0x44 // start conversion command - produce 2 bytes and this process is slow, 750 milliseconds.

reset pulse

wait 750 milliseconds

Send command 0xCC // Send skip ROM command

Send command 0xBE // Send Read Scratch Pad and return it

read one byte from bus

read one byte from bus

combine these two byte into temperature data




Resources:

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

