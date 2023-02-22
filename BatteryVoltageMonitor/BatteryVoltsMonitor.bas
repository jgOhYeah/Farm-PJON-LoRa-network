; BatteryVoltsMonitor.bas
; A remote LoRa battery monitor and electric fence energiser switch.
; Written by Jotham Gates
; Created Jan 2021
; Modified 22/02/2023
;
; https://github.com/jgOhYeah/Farm-PJON-LoRa-network
;
; FLASH MODES:
; Sleeping: One flash ~once per minute
; Actively listening: One flash every half second
; Cannot connect to LoRa module on start: Constant long flashes (on half second, off half second).
;
#INCLUDE "include/symbols.basinc"
#INCLUDE "include/generated.basinc"
#DEFINE ENABLE_LORA_RECEIVE
#DEFINE ENABLE_PJON_RECEIVE
#DEFINE ENABLE_LORA_TRANSMIT
#DEFINE ENABLE_PJON_TRANSMIT
#PICAXE 14M2
#TERMINAL 38400
; #COM /dev/ttyUSB0

; Sensors
#DEFINE ENABLE_TEMP
; #DEFINE ENABLE_FVR

; Sensors and control
symbol BATTERY_PIN = B.2
#IFDEF ENABLE_TEMP
symbol TEMPERATURE_PIN = B.1
#ENDIF
symbol FENCE_PIN = B.4

; Status LED
symbol LED_PIN = B.3

; Variables unique to this - see symbols.basinc for the rest
symbol fence_enable = bit0
symbol transmit_enable = bit1
symbol iterations_count = w8 ; b16 and b17
symbol tx_intervals = b18
symbol tx_interval_count = b19

; TableSertxd extension settings
; Before conversion to tablesertxd: 2005
; After conversion to tablesertxd: 1765
#DEFINE TABLE_SERTXD_ADDRESS_VAR w6 ; b12, b13
#DEFINE TABLE_SERTXD_ADDRESS_END_VAR w7 ; b14, b15
#DEFINE TABLE_SERTXD_TMP_BYTE b16

; Constants
symbol LISTEN_TIME = 30 ; Listen for 15s (number of 0.5s counts) after each transmission and every so often
symbol SLEEP_TIME = 65 ; Roughly 2.5 mins (65*2.3s)
#DEFINE RESET_PERIODICALLY
symbol RESET_ITERATIONS_COUNT = 481 ; Roughly 24 hours with 2.5 min sleep and 30s receive.
symbol FAILED_RESET_ITERATIONS_COUNT = 60 ; 1 minute of 1s period flashes
symbol RECEIVE_FLASH_INT = 1 ; Every half second
symbol RESET_CODE = 101 ; Needs to be present as the payload of the reset command in order to reset.
symbol TEMP_DIFFERENCE_THRESHOLD = 63

; Temperature and battery voltage calibration
symbol CAL_BATT_NUMERATOR = 58
symbol CAL_BATT_DENOMINATOR = 85

#MACRO UPDATE_EEPROM(ADDRESS,VALUE,TMP_VAR)
	read ADDRESS, TMP_VAR
	if TMP_VAR != VALUE then
		write ADDRESS, VALUE
	endif
#ENDMACRO

symbol EEPROM_FENCE_ENABLED = 0
symbol EEPROM_TX_ENABLED = 1
symbol EEPROM_TX_INTERVALS = 2

init:
	; Initial setup
	setfreq m32
	high FENCE_PIN ; Fence is fail deadly to keep cattle in at all costs :)
	high LED_PIN

	; Load settings from EEPROM
	read EEPROM_FENCE_ENABLED, fence_enable
	read EEPROM_TX_ENABLED,  transmit_enable
	read EEPROM_TX_INTERVALS, tx_intervals

	iterations_count = 0

	;#sertxd("Electric Fence Controller", cr, lf, "Jotham Gates, Jun 2021", cr, lf)
	; Attempt to start the module
	gosub begin_lora
	if rtrn = 0 then
		;#sertxd("LoRa Failed",cr,lf)
		goto failed
	else
		;#sertxd("LoRa Started",cr,lf)
	endif

	; Set the spreading factor
	gosub set_spreading_factor

	; gosub idle_lora ; 4.95mA
	; gosub sleep_lora ; 3.16mA
	gosub setup_lora_receive ; 14mA
	; Everything in sleep ; 0.18 to 0.25mA
	; Finish setup
	low LED_PIN
	
main:
	; Create and send a packet with the temperature and measured battery voltage
	if transmit_enable = 1 then
		gosub send_status
	endif
	;#sertxd("Sent packet", cr, lf)

	; Alternate between sleeping and receiving for a while
	for tx_interval_count = 1 to tx_intervals
		gosub receive_mode ; Listen for 30s ; Stack is now at 8 for this branch. Cannot add any more levels to this branch.
		gosub sleep_mode ; Sleep for 2.5m
	next tx_interval_count

	inc iterations_count
	sertxd(iterations_count)
	;#sertxd(" iterations", cr, lf)
	if iterations_count = RESET_ITERATIONS_COUNT then
		;#sertxd("Timed reset", cr, lf)
		reset
	endif
	goto main

receive_mode:
	; Go into listen mode
	; Listens for the designated time and handles incoming packets
	; Maximum stack depth used: 7

	pulsout LED_PIN, 10000
	gosub setup_lora_receive ; Stack depth 4
	start_time = time
	rtrn = time ; Start time for led flashing
	do
		; Handle packets arriving
		if LORA_RECEIVED then
			gosub read_pjon_packet ; Stack depth 4
			if rtrn != PJON_INVALID_PACKET then
				;#sertxd("Valid packet received", cr, lf)
				; Valid packet
				high LED_PIN
				; Processing and actions
				level = 0 ; Whether to send the status back
				do while rtrn > 0 ; rtrn is the length left
					mask = @bptrinc ; Field is stored in mask
					dec rtrn
					select mask
						case 0xC6 ; "F" | 0x80 ; Fence on and off
							; 1 byte, 0 for off, anything else for on.
							;#sertxd("Fence ")
							if rtrn > 0 then
								if @bptrinc = 0 then
									;#sertxd("Off", cr, lf)
									fence_enable = 0
									low FENCE_PIN
								else
									;#sertxd("On", cr, lf)
									fence_enable = 1
									high FENCE_PIN
								endif
								UPDATE_EEPROM(EEPROM_FENCE_ENABLED, fence_enable, tmpwd_l)
								dec rtrn
							endif
							level = 1
						case 0xF2 ; "r" | 0x80 ; Radio transmissions on and off
							; 1 byte, 0 for off, anything else for on.
							;#sertxd("Transmit ")
							if rtrn > 0 then
								if @bptrinc = 0 then
									;#sertxd("Off", cr, lf)
									transmit_enable = 0
								else
									;#sertxd("On", cr, lf)
									transmit_enable = 1
								endif
								UPDATE_EEPROM(EEPROM_TX_ENABLED, transmit_enable, tmpwd_l)
								dec rtrn
							endif
							level = 1
						case 201 ; "I" | 0x80 ; Interval between transmissions
							; 1 byte, number of 5 minute blocks to .
							;#sertxd("Transmit interval is ")
							if rtrn > 0 then
								if @bptr != 0 then
									tx_intervals = @bptrinc
									sertxd(#tx_intervals)
									;#sertxd(" *3 minutes", cr, lf)
									UPDATE_EEPROM(EEPROM_TX_INTERVALS, tx_intervals, tmpwd_l)
								else
									inc bptr
									;#sertxd("invalid. Ignoring", cr, lf)
								endif
								dec rtrn
							endif
							level = 1
						case 0xF3 ; "s" | 0x80 ; Request status, msb is high as it is an instruction
							; No payload.
							;#sertxd("Status", cr, lf)
							level = 1
						case 0xD8 ; "X" | 0x80 ; Reset
							if rtrn > 0 then
								if @bptrinc = RESET_CODE then
									;#sertxd("Resetting", cr, lf)
									reset
								else
									;#sertxd("Bad code", cr, lf)
								endif
								dec rtrn
							endif
						else
							; Something not recognised or implemented
							; NOTE: Should the rest of the packet be discarded to ensure any possible data of unkown length is not treated as a field?
							;#sertxd("Field ")
							sertxd(#mask)
							;#sertxd(" unkown", cr, lf)
					endselect
				loop

				; Send a message back if needed.
				if level = 1 then
					;#sertxd("Replying with status", cr, lf)
					nap 5 ; Wait for things to settle (576ms)
					gosub send_status ; Reply with the current settings if needed
					gosub setup_lora_receive ; Go back to listening
					; Reset interval counter as we just send a packet back
					tx_interval_count = 1

				endif

				low LED_PIN
				start_time = time ; Reset the time. ; NOTE Possible security risk of being able to keep the box in high power state?
				rtrn = time
			else
				;#sertxd("Invalid packet recieved. Ignoring", cr, lf)
			endif
		endif

		; Flash the LED every half second
		tmpwd = time - rtrn
		if tmpwd >= RECEIVE_FLASH_INT then
			pulsout LED_PIN, 10000
			rtrn = time
		endif
		tmpwd = time - start_time
	loop while tmpwd < LISTEN_TIME
	return

sleep_mode:
	; Go into power saving mode
	gosub sleep_lora
	low LED_PIN
	
	disablebod
	sleep SLEEP_TIME
	enablebod
	return

send_status:
	; Sends the monitor's status
	; Maximum stack depth used: 6
	high LED_PIN
	;#sertxd("Sending state", cr, lf)
	gosub begin_pjon_packet

	; Battery voltage
	@bptrinc = "V"
	gosub get_voltage
	sertxd(#rtrn)
	;#sertxd(" (*0.1) V", cr, lf)
	gosub add_word

	; Temperature
#IFDEF ENABLE_TEMP
	@bptrinc = "T"
	gosub get_temperature
	gosub add_word
	sertxd(#rtrn)
	;#sertxd("*0.1 C", cr, lf)
#ENDIF

	; Fence enable
	;#sertxd("Fence: ")
	sertxd(#fence_enable, cr, lf)
	@bptrinc = "F"
	@bptrinc = fence_enable

	; Transmit enable
	;#sertxd("Transmit: ")
	sertxd(#transmit_enable, cr, lf)
	@bptrinc = "r"
	@bptrinc = transmit_enable

	; TX interval
	;#sertxd("TX Interval: ")
	sertxd(#tx_intervals, cr, lf)
	@bptrinc = "I"
	@bptrinc = tx_intervals

	param1 = UPRSTEAM_ADDRESS
	gosub end_pjon_packet ; Stack is 6
	if rtrn = 0 then ; Something went wrong. Attempt to reinitialise the radio module.
		;#sertxd("LoRa dropped out.")
		for tmpwd = 0 to 15
			toggle LED_PIN
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
	low LED_PIN
	return

failed:
	; Flashes the LED on and off to give an indication it isn't happy.
	high LED_PIN
	pause 4000
	low LED_PIN
	pause 4000
	if time > FAILED_RESET_ITERATIONS_COUNT then goto init
	goto failed

get_voltage:
	; Calculates the supply voltage in 0.1V steps (255 = 25.5V)
	; fvrsetup FVR2048 ; set FVR as 2.048V
	; adcconfig %011 ; set FVR as ADC Vref+, 0V Vref-
	; readadc10 BATTERY_PIN, rtrn
#IFDEF ENABLE_FVR
	fvrsetup FVR2048 ; set FVR as 2.048V
	adcconfig %011 ; set FVR as ADC Vref+, 0V Vref-
#ENDIF
	readadc10 BATTERY_PIN, rtrn ; Do it twice to try and avoid croos talk from the first reading
	rtrn = rtrn * CAL_BATT_NUMERATOR / CAL_BATT_DENOMINATOR
	return

#IFDEF ENABLE_TEMP
get_temperature: ; DS18B20
	; sertxd("Temp ADC: ",#rtrn)
	; Attempt to get two fairly close together readings (avoid the 51.1C issue / read errors hopefully).
	readtemp12 TEMPERATURE_PIN, rtrn
	readtemp12 TEMPERATURE_PIN, tmpwd
	; Calculate the difference between readings
	if rtrn > tmpwd then
		tmpwd = rtrn - tmpwd
	else
		tmpwd = tmpwd - rtrn
	endif
	if tmpwd > TEMP_DIFFERENCE_THRESHOLD then goto get_temperature

	; rtrn contains the temperature and both readings were close.
	; sertxd("Temp raw: ",#rtrn)
	tmpwd = rtrn & $8000 ; Is the most significant bit 1, indicating a negative?
	if tmpwd != 0 then
		; Negative, sign extend as needed.
		rtrn = rtrn * 5 / 8
		rtrn = rtrn | $E000
	else
		rtrn = rtrn * 5 / 8
	endif
	; sertxd(" Calc: ",#rtrn,cr,lf)
	return
#ENDIF

add_word:
	; Adds a word to @bptr in little endian format.
	; rtrn contains the word to add (it is a word)
	@bptrinc = rtrn & 0xff
	tmpwd = rtrn / 0xff
	@bptrinc = tmpwd
	return

; Libraries that will not be run first thing.
#INCLUDE "include/LoRa.basinc"
#INCLUDE "include/PJON.basinc"