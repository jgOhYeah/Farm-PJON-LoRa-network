; IrrigationWaterDetector.bas
; A remote LoRa water detector for use with flood irrigation
; Jotham Gates, November 2021
; https://github.com/jgOhYeah/PICAXE-Libraries-Extras

#picaxe 18M2
#terminal 38400
#define VERSION "v0.1.0"
#NO_DATA

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
symbol PIN_WATER = B.2
symbol PIN_LED = B.1
symbol IN_PIN_RATE_SELECT = pinB.3
symbol MASK_RATE_SELECT = %00001000

init:
    ; Initial setup
    setfreq m32
    pullup MASK_RATE_SELECT
    ;#sertxd("Irrigation water detector ", VERSION, cr, lf, "By Jotham Gates, Compiled ", ppp_date_uk, cr, lf)
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

main:
    ; Measure the capacitance and send it
    high PIN_LED
    ;#sertxd("Sending packet", cr, lf)
    gosub begin_pjon_packet

    ; Water level
    @bptrinc = "w"
    setfreq m4 ; touch reading varies with clock speed
    touch16 PIN_WATER, rtrn
    setfreq m32
    ;#sertxd("touch16=")
    sertxd(#rtrn, cr, lf)
    gosub add_word

    ; Send the packet
    param1 = UPRSTEAM_ADDRESS
    gosub end_pjon_packet ; Stack is 6
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

    ;#sertxd("Packet sent. Entering sleep mode", cr, lf)
	gosub sleep_lora

    ; Sleep for a while
    setfreq m4
    if IN_PIN_RATE_SELECT = 0 then
        ;#sertxd("Fast mode enabled", cr, lf)
        pause 10000
    else
        pause 60000
        pause 60000
    endif
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
	high PIN_LED
	pause 4000
	low PIN_LED
	pause 4000
	goto failed


; Libraries that will not be run first thing.
#INCLUDE "include/LoRa.basinc"
#INCLUDE "include/PJON.basinc"