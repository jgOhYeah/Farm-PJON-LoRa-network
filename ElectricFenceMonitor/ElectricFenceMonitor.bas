; ElectricFenceMonitor.bas
; A remote LoRa electric fence monitor.
; Jotham Gates, December 2024
; https://github.com/jgOhYeah/Farm-PJON-LoRa-network

#picaxe 14M2
#terminal 38400
#define VERSION "v0.0.0"
#no_data

#include "include/symbols.basinc"
#include "include/generated.basinc"

#define ENABLE_LORA_RECEIVE
#define ENABLE_PJON_RECEIVE
#define ENABLE_LORA_TRANSMIT
#define ENABLE_PJON_TRANSMIT

#define TABLE_SERTXD_ADDRESS_VAR w6 ; b12, b13
#define TABLE_SERTXD_ADDRESS_END_VAR w7 ; b14, b15
#define TABLE_SERTXD_TMP_BYTE b16

; Pins
symbol PIN_ADC_REF = B.1
symbol PIN_FENCE_SW = B.2
symbol PIN_FENCE_PEAK = B.3
symbol PIN_LED = B.4

; Calibration
symbol CAL_OFFSET = 55
symbol CAL_NUM = 7
symbol CAL_DEN = 82

symbol SLEEP_INTERVALS = 130 ; 5 min for testing.
init:
    ; Initial setup
    setfreq m32
	high PIN_LED
	nap 4
    ;#sertxd("Electric fence monitor ", VERSION, cr, lf, "By Jotham Gates, Compiled ", ppp_date_uk, cr, lf, "Transmit interval is ")
	sertxd(#SLEEP_INTERVALS, "*2.3s", cr, lf)
    ; Attempt to start the module
	gosub begin_lora
	if rtrn = 0 then
		;#sertxd("Failed to start LoRa",cr,lf)
		goto failed
	else
		;#sertxd("LoRa Started",cr,lf)
	endif

	; Set the spreading factor
	gosub set_spreading_factor

	; gosub idle_lora ; 4.95mA
	gosub sleep_lora ; 3.16mA
	LOW PIN_LED

main:
    ; Measure the capacitance and send it
    ; // #sertxd("Sending packet", cr, lf)
	high PIN_LED
	high PIN_FENCE_SW
	adcconfig %010 ; Use the PIN_ADC_REF as the positive reference.
    gosub begin_pjon_packet
	low PIN_LED

    ; Fence voltage measurement
    @bptrinc = "k"
	readadc PIN_FENCE_PEAK, param1 ; Clear any previous values in the mux.
    param1 = 0
    for tmpwd = 1 to 7000
        readadc PIN_FENCE_PEAK, param2
        if param2 > param1 then
            param1 = param2
        endif
    next tmpwd

	; Return back to normal and scale result
	low PIN_FENCE_SW
	adcconfig %000 ; Set positive reference back to normal.
	if param1 < CAL_OFFSET then ; Stop underflow.
		param1 = CAL_OFFSET
	endif
	; @bptrinc = param1 * CAL_NUM / CAL_DEN
	@bptrinc = param1

	; Battery voltage
	@bptrinc = "V"
	calibadc rtrn ; Do twice to try to make a bit more stable?
	; calibadc rtrn ; No point trying to do a 10 bit read as the output resolution is limited.
	; ; rtrn = 10476/rtrn ; Simple, but integer rounds down.
	; ; More complicated, but rounds as expected:
	; ; voltage = (int(vref*max_reading)*10 + adc//2)//adc
	; rtrn = rtrn / 2 + 2621 / rtrn ; ((rtrn / 2) + 2621) / rtrn
	gosub read_vdd
	start_time = rtrn ; Save for later.
	rtrn = rtrn + 50 / 100
	gosub add_word

	; Temperature
	@bptrinc = "T"
	gosub read_temp ; start_time contains the voltage.
	gosub convert_temp
	gosub add_word

    ; Send the packet
    param1 = UPRSTEAM_ADDRESS
    gosub end_pjon_packet ; Stack is 6
	high PIN_LED

	if rtrn = 0 then ; Something went wrong. Attempt to reinitialise the radio module.
		;#sertxd("LoRa dropped out.")
		for tmpwd = 0 to 15
			toggle PIN_LED
			pause 4000
		next tmpwd

		gosub begin_lora ; Stack is 6
		if rtrn != 0 then ; Reconnected ok. Set up the spreading factor.
			;#sertxd("Reconnected ok")
			param1 = LORA_SPREADING_FACTOR
			gosub set_spreading_factor
		else
			;#sertxd("Could not reconnect")
		endif
	endif

	low PIN_LED

    ; // #sertxd("Packet sent. Entering sleep mode", cr, lf)
	gosub sleep_lora

    ; Sleep for a while
	disablebod
	sleep SLEEP_INTERVALS
	enablebod
    setfreq m32
    goto main

add_word:
	; Adds a word to @bptr in little endian format.
	; rtrn contains the word to add (it is a word)
	@bptrinc = rtrn & 0xff
	tmpwd = rtrn / 0xff
	@bptrinc = tmpwd
	return

failed:
	; Flashes the LED on and off to give an indication it isn't happy.
	for rtrn = 1 to 120
		;#sertxd("Failed", cr, lf)
		high PIN_LED
		pause 4000
		low PIN_LED
		pause 4000
	next rtrn
	;#sertxd("Resetting and trying again.", cr, lf, cr, lf)
	reset


; Libraries that will not be run first thing.
#INCLUDE "include/LoRa.basinc"
#INCLUDE "include/PJON.basinc"
#INCLUDE "include/chiptemp.basinc"