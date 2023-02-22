'-----PREPROCESSED BY picaxepreprocess.py-----
'----UPDATED AT 08:43PM, February 22, 2023----
'----SAVING AS compiled_slot1.bas ----

'---BEGIN BatteryVoltsMonitor_slot1.bas ---
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
#SLOT 1
#NO_DATA ; EEPROM settings set when uploading slot 0

'---BEGIN include/BatteryVoltsMonitorCommon.basinc ---
; Battery voltage monitor monitor common code
; Defines and symbols shared between each slot
; Written by Jotham Gates
; Created 22/02/2023
; Modified 22/03/2023

; #DEFINE VERSION "v2.0.0"
; #DEFINE NAME "Battery voltage monitor and fence control"
; #DEFINE URL "https://github.com/jgOhYeah/Farm-PJON-LoRa-network"

#PICAXE 14M2      'CHIP VERSION PARSED
#TERMINAL 38400
; #COM /dev/ttyUSB0

; Sensors
; #DEFINE ENABLE_TEMP
; #DEFINE ENABLE_FVR

; Sensors and control
symbol BATTERY_PIN = B.2
; #IFDEF ENABLE_TEMP
symbol TEMPERATURE_PIN = B.1
; #ENDIF
symbol FENCE_PIN = B.4

; Status LED
symbol LED_PIN = B.3

; Variables unique to this - see symbols.basinc for the rest
symbol fence_enable = bit0
symbol transmit_enable = bit1
symbol long_listen_time = bit2
symbol tx_intervals = b18
symbol tx_interval_count = b19

; TableSertxd extension settings
; Before conversion to tablesertxd: 2005
; After conversion to tablesertxd: 1765
; #DEFINE TABLE_SERTXD_ADDRESS_VAR w6 ; b12, b13
; #DEFINE TABLE_SERTXD_ADDRESS_END_VAR w7 ; b14, b15
; #DEFINE TABLE_SERTXD_TMP_BYTE b16

; Constants
symbol LISTEN_TIME_NORMAL = 30 ; Listen for 15s (number of 0.5s counts) after each transmission and every so often.
; 15s should be 2 transmission attempts with the current base station setup.
symbol LISTEN_TIME_AWAKE = 600 ; Listedn for a longer time continuously in case someone wants to send more commands in quick succession.
symbol SLEEP_TIME = 33 ; Roughly 75s
; #DEFINE RESET_PERIODICALLY ; Reset every so often in case something like the radio stops talking properly.
symbol RESET_ITERATIONS_COUNT = 960 ; Roughly 24 hours with 90s periods
symbol FAILED_RESET_ITERATIONS_COUNT = 60 ; 1 minute of 1s period flashes
symbol RECEIVE_FLASH_INT = 1 ; Every half second
symbol RESET_CODE = 101 ; Needs to be present as the payload of the reset command in order to reset.
symbol TEMP_DIFFERENCE_THRESHOLD = 63

; Temperature and battery voltage calibration
symbol CAL_BATT_NUMERATOR = 58
symbol CAL_BATT_DENOMINATOR = 85

'PARSED MACRO UPDATE_EEPROM
symbol EEPROM_FENCE_ENABLED = 0
symbol EEPROM_TX_ENABLED = 1
symbol EEPROM_TX_INTERVALS = 2

; Values to be loaded into EEPROM on slot 0 upload
symbol DEFAULT_FENCE_ENABLED = 1
symbol DEFAULT_TX_ENABLED = 1
symbol DEFAULT_TX_INTERVALS = 10

symbol RAM_ITERATIONS_COUNT_L = 256 ; bptr can't mess around up here
symbol RAM_ITERATIONS_COUNT_H = 257 ; bptr can't mess around up here
'---END include/BatteryVoltsMonitorCommon.basinc---
'---BEGIN include/symbols.basinc ---
; symbols.basinc
; Definitions to be used in other files
; Jotham Gates
; Created 22/11/2020
; Modified 25/01/2020
; https://github.com/jgOhYeah/PICAXE-Libraries-Extras

; Pins
; Serial
; RX = C.5
; TX = B.0
; LoRa module
symbol SS = C.0 ; Current (keep the B register free for other stuff, which seems to have more features in terms of adc)
symbol SCK = C.1
symbol MOSI = C.2
symbol MISO = pinC.3
symbol RST = C.4
symbol DIO0 = pinB.5 ; High when a packet has been received

; Variables
symbol mask = b1
symbol level = b2
symbol counter = b3
symbol counter2 = b4
symbol total_length = b5
symbol s_transfer_storage = b6 ; Saves param1 duing LoRa spiing
symbol crc0 = b7 ; crcs can be used whenever a crc calculation is not required
symbol crc1 = b8
symbol crc2 = b9
symbol crc3 = b10
symbol counter3 = b11
; b12, b13, b14, b15, b16, b17, b18, b19 are free for the main program
symbol start_time = w10
symbol start_time_h = b21
symbol start_time_l = b20
symbol tmpwd = w11
symbol tmpwd_l = b22
symbol tmpwd_h = b23
symbol paramwd = w12
symbol param1 = b24
symbol param2 = b25
symbol rtrn = w13

symbol LORA_TIMEOUT = 2 ; Number of seconds after which it is presumed the module has dropped out
                        ; due to a dodgy connection or breadboard and should be reset.

; Macro to simplify checking if a packet has been received.
; #DEFINE LORA_RECEIVED DIO0 = 1

symbol LORA_RECEIVED_CRC_ERROR = 65535 ; Says there is a CRC error if returned by setup_lora_read
symbol PJON_INVALID_PACKET = 65534 ; Says the packet is invalid, not a PJON packet, or not addressed to us

symbol MY_ID = 0x4A ; PJON id of this device
symbol UPRSTEAM_ADDRESS = 255 ; Address to send things to using PJON

; #DEFINE FILE_SYMBOLS_INCLUDED ; Prove this file is included properly

'---END include/symbols.basinc---
'---BEGIN include/generated.basinc ---
; Autogenerated by calculations.py at 2023-02-22 20:42:18
; For a FREQUENCY of 433.0MHz, a SPREAD FACTOR of 9 and a bandwidth of 125000kHz:
; #DEFINE LORA_FREQ 433000000
; #DEFINE LORA_FREQ_MSB 0x6C
; #DEFINE LORA_FREQ_MID 0x40
; #DEFINE LORA_FREQ_LSB 0x00
; #DEFINE LORA_SPREADING_FACTOR 9
; #DEFINE LORA_LDO_ON 0

; #DEFINE FILE_GENERATED_INCLUDED ; Prove this file is included properly

'---END include/generated.basinc---
; #DEFINE ENABLE_LORA_RECEIVE
; #DEFINE ENABLE_PJON_RECEIVE
; #DEFINE ENABLE_LORA_TRANSMIT
; #DEFINE ENABLE_PJON_TRANSMIT
; #DEFINE DISABLE_LORA_SETUP

init:
	; Initial setup (need to have run slot 0 for radio init)
	setfreq m32
;#sertxd("Battery voltage monitor and fence control", " ",    "v2.0.0" , " MAIN", cr,lf, "Jotham Gates, Compiled ", "22-02-2023", cr, lf) 'Evaluated below
w6 = 0
w7 = 89
gosub print_table_sertxd
	
main:
	; Create and send a packet with the temperature and measured battery voltage
	if transmit_enable = 1 then
		gosub send_status
	endif
;#sertxd("Sent packet", cr, lf) 'Evaluated below
w6 = 90
w7 = 102
gosub print_table_sertxd

	; Alternate between sleeping and receiving for a while
	for tx_interval_count = 1 to tx_intervals
		gosub receive_mode ; Listen for 30s ; Stack is now at 8 for this branch. Cannot add any more levels to this branch.
		gosub sleep_mode ; Sleep for 2.5m

		; Reset the unit on a timed basis.
		peek RAM_ITERATIONS_COUNT_L, tmpwd_l, tmpwd_h
		inc tmpwd
		poke RAM_ITERATIONS_COUNT_L, tmpwd_l, tmpwd_h
		sertxd(#tmpwd)
;#sertxd(" iterations of ") 'Evaluated below
w6 = 103
w7 = 117
gosub print_table_sertxd
		sertxd(#RESET_ITERATIONS_COUNT, cr, lf)
		if tmpwd = RESET_ITERATIONS_COUNT then
;#sertxd("Timed reset", cr, lf) 'Evaluated below
w6 = 118
w7 = 130
gosub print_table_sertxd
			reset
		endif
	next tx_interval_count
	goto main

receive_mode:
	; Go into listen mode
	; Listens for the designated time and handles incoming packets
	; Maximum stack depth used: 7

	pulsout LED_PIN, 10000
;#sertxd("Entering receive mode", cr, lf) 'Evaluated below
w6 = 131
w7 = 153
gosub print_table_sertxd
	long_listen_time = 0 ; By default, listen for only a short while.
	gosub setup_lora_receive ; Stack depth 4
	start_time = time
	rtrn = time ; Start time for led flashing
	do
		; Handle packets arriving
		if DIO0 = 1 then
			gosub read_pjon_packet ; Stack depth 4
			if rtrn != PJON_INVALID_PACKET then
;#sertxd("Valid packet received", cr, lf) 'Evaluated below
w6 = 154
w7 = 176
gosub print_table_sertxd
				; Valid packet
				high LED_PIN
				; Processing and actions
				level = 0 ; Whether to send the status back and stay listening for a while after.
				do while rtrn > 0 ; rtrn is the length left
					mask = @bptrinc ; Field is stored in mask
					dec rtrn
					select mask
						case 0xC6 ; "F" | 0x80 ; Fence on and off
							; 1 byte, 0 for off, anything else for on.
;#sertxd("Fence ") 'Evaluated below
w6 = 177
w7 = 182
gosub print_table_sertxd
							if rtrn > 0 then
								if @bptrinc = 0 then
;#sertxd("Off", cr, lf) 'Evaluated below
w6 = 183
w7 = 187
gosub print_table_sertxd
									fence_enable = 0
									low FENCE_PIN
								else
;#sertxd("On", cr, lf) 'Evaluated below
w6 = 188
w7 = 191
gosub print_table_sertxd
									fence_enable = 1
									high FENCE_PIN
								endif
								'--START OF MACRO: UPDATE_EEPROM
	read EEPROM_FENCE_ENABLED,  tmpwd_l
	if  tmpwd_l !=  fence_enable then
		write EEPROM_FENCE_ENABLED,  fence_enable
	endif
'--END OF MACRO: UPDATE_EEPROM(EEPROM_FENCE_ENABLED, fence_enable, tmpwd_l)
								dec rtrn
							endif
							level = 1
						case 0xF2 ; "r" | 0x80 ; Radio transmissions on and off
							; 1 byte, 0 for off, anything else for on.
;#sertxd("Transmit ") 'Evaluated below
w6 = 192
w7 = 200
gosub print_table_sertxd
							if rtrn > 0 then
								if @bptrinc = 0 then
;#sertxd("Off", cr, lf) 'Evaluated below
w6 = 201
w7 = 205
gosub print_table_sertxd
									transmit_enable = 0
								else
;#sertxd("On", cr, lf) 'Evaluated below
w6 = 206
w7 = 209
gosub print_table_sertxd
									transmit_enable = 1
								endif
								'--START OF MACRO: UPDATE_EEPROM
	read EEPROM_TX_ENABLED,  tmpwd_l
	if  tmpwd_l !=  transmit_enable then
		write EEPROM_TX_ENABLED,  transmit_enable
	endif
'--END OF MACRO: UPDATE_EEPROM(EEPROM_TX_ENABLED, transmit_enable, tmpwd_l)
								dec rtrn
							endif
							level = 1
						case 201 ; "I" | 0x80 ; Interval between transmissions
							; 1 byte, number of blocks to skip between transmissions.
;#sertxd("Transmit interval is ") 'Evaluated below
w6 = 210
w7 = 230
gosub print_table_sertxd
							if rtrn > 0 then
								if @bptr != 0 then
									tx_intervals = @bptrinc
									sertxd(#tx_intervals)
;#sertxd(" *1.5 minutes", cr, lf) 'Evaluated below
w6 = 231
w7 = 245
gosub print_table_sertxd
									'--START OF MACRO: UPDATE_EEPROM
	read EEPROM_TX_INTERVALS,  tmpwd_l
	if  tmpwd_l !=  tx_intervals then
		write EEPROM_TX_INTERVALS,  tx_intervals
	endif
'--END OF MACRO: UPDATE_EEPROM(EEPROM_TX_INTERVALS, tx_intervals, tmpwd_l)
								else
									inc bptr
;#sertxd("invalid. Ignoring", cr, lf) 'Evaluated below
w6 = 246
w7 = 264
gosub print_table_sertxd
								endif
								dec rtrn
							endif
							level = 1
						case 0xF3 ; "s" | 0x80 ; Request status, msb is high as it is an instruction
							; No payload.
;#sertxd("Status", cr, lf) 'Evaluated below
w6 = 265
w7 = 272
gosub print_table_sertxd
							level = 1
						case 0xD8 ; "X" | 0x80 ; Reset
							if rtrn > 0 then
								if @bptrinc = RESET_CODE then
;#sertxd("Resetting", cr, lf) 'Evaluated below
w6 = 273
w7 = 283
gosub print_table_sertxd
									reset
								else
;#sertxd("Bad code", cr, lf) 'Evaluated below
w6 = 284
w7 = 293
gosub print_table_sertxd
								endif
								dec rtrn
							endif
							level = 1
						else
							; Something not recognised or implemented
							; NOTE: Should the rest of the packet be discarded to ensure any possible data of unkown length is not treated as a field?
;#sertxd("Field ") 'Evaluated below
w6 = 294
w7 = 299
gosub print_table_sertxd
							sertxd(#mask)
;#sertxd(" unkown", cr, lf) 'Evaluated below
w6 = 300
w7 = 308
gosub print_table_sertxd
					endselect
				loop

				; Send a message back if needed.
				if level = 1 then
;#sertxd("Replying", cr, lf) 'Evaluated below
w6 = 309
w7 = 318
gosub print_table_sertxd
					nap 5 ; Wait for things to settle (576ms)
					gosub send_status ; Reply with the current settings if needed
					gosub setup_lora_receive ; Go back to listening
					; Am going to be in long receive mode, so due for a status message when we leave.
					tx_interval_count = tx_intervals
					long_listen_time = 1 ; Stay in receive mode for a longer time to make it easier to send subsequent commands.

				endif

				low LED_PIN
				start_time = time ; Reset the time. ; NOTE Possible security risk of being able to keep the box in high power state?
				rtrn = time
			else
;#sertxd("Invalid packet recieved. Ignoring", cr, lf) 'Evaluated below
w6 = 319
w7 = 353
gosub print_table_sertxd
			endif
		endif

		; Flash the LED every half second
		tmpwd = time - rtrn
		if tmpwd >= RECEIVE_FLASH_INT then
			if long_listen_time = 1 then
				high LED_PIN
;#sertxd("Long listen time", cr, lf) 'Evaluated below
w6 = 354
w7 = 371
gosub print_table_sertxd
				low LED_PIN
			else
				pulsout LED_PIN, 10000
			endif
			rtrn = time
		endif
		; nap 2 ; Save some power hopefully

		; How long do we stay in listening mode?
		tmpwd = time - start_time
		if long_listen_time = 1 then
			paramwd = LISTEN_TIME_AWAKE
		else
			paramwd	= LISTEN_TIME_NORMAL
		endif
	loop while tmpwd < paramwd
	return

sleep_mode:
	; Go into power saving mode
;#sertxd("Entering sleep mode", cr, lf) 'Evaluated below
w6 = 372
w7 = 392
gosub print_table_sertxd
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
;#sertxd("Sending state", cr, lf) 'Evaluated below
w6 = 393
w7 = 407
gosub print_table_sertxd
	gosub begin_pjon_packet

	; Battery voltage
	@bptrinc = "V"
	gosub get_voltage
	sertxd(#rtrn)
;#sertxd(" (*0.1) V", cr, lf) 'Evaluated below
w6 = 408
w7 = 418
gosub print_table_sertxd
	gosub add_word

	; Temperature
; #IFDEF ENABLE_TEMP
	@bptrinc = "T"
	gosub get_temperature
	gosub add_word
	sertxd(#rtrn)
;#sertxd("*0.1 C", cr, lf) 'Evaluated below
w6 = 419
w7 = 426
gosub print_table_sertxd
; #ENDIF

	; Fence enable
;#sertxd("Fence: ") 'Evaluated below
w6 = 427
w7 = 433
gosub print_table_sertxd
	sertxd(#fence_enable, cr, lf)
	@bptrinc = "F"
	@bptrinc = fence_enable

	; Transmit enable
;#sertxd("Transmit: ") 'Evaluated below
w6 = 434
w7 = 443
gosub print_table_sertxd
	sertxd(#transmit_enable, cr, lf)
	@bptrinc = "r"
	@bptrinc = transmit_enable

	; TX interval
;#sertxd("TX Interval: ") 'Evaluated below
w6 = 444
w7 = 456
gosub print_table_sertxd
	sertxd(#tx_intervals, cr, lf)
	@bptrinc = "I"
	@bptrinc = tx_intervals

	param1 = UPRSTEAM_ADDRESS
	gosub end_pjon_packet ; Stack is 6
	if rtrn = 0 then ; Something went wrong. Attempt to reinitialise the radio module.
;#sertxd("LoRa dropped out.") 'Evaluated below
w6 = 457
w7 = 473
gosub print_table_sertxd
		for tmpwd = 0 to 15
			toggle LED_PIN
			pause 4000
		next tmpwd

;#sertxd("Will reset and have another go.", cr, lf, cr, lf) 'Evaluated below
w6 = 474
w7 = 508
gosub print_table_sertxd
		reset
	endif
	low LED_PIN
	return

get_voltage:
	; Calculates the supply voltage in 0.1V steps (255 = 25.5V)
	; fvrsetup FVR2048 ; set FVR as 2.048V
	; adcconfig %011 ; set FVR as ADC Vref+, 0V Vref-
	; readadc10 BATTERY_PIN, rtrn
; ; #IFDEF ENABLE_FVR [#IF CODE REMOVED]
; 	fvrsetup FVR2048 ; set FVR as 2.048V [#IF CODE REMOVED]
; 	adcconfig %011 ; set FVR as ADC Vref+, 0V Vref- [#IF CODE REMOVED]
; #ENDIF
	readadc10 BATTERY_PIN, rtrn ; Do it twice to try and avoid croos talk from the first reading
	rtrn = rtrn * CAL_BATT_NUMERATOR / CAL_BATT_DENOMINATOR
	return

; #IFDEF ENABLE_TEMP
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
; #ENDIF

add_word:
	; Adds a word to @bptr in little endian format.
	; rtrn contains the word to add (it is a word)
	@bptrinc = rtrn & 0xff
	tmpwd = rtrn / 0xff
	@bptrinc = tmpwd
	return

; Libraries that will not be run first thing.
'---BEGIN include/LoRa.basinc ---
; LoRa.basinc
; Attempt at talking to an SX1278 LoRa radio module using picaxe M2 parts.
; Heavily based on the Arduino LoRa library found here: https://github.com/sandeepmistry/arduino-LoRa
; Jotham Gates
; Created 22/11/2020
; Modified 22/02/2023
; https://github.com/jgOhYeah/PICAXE-Libraries-Extras

; Symbols only used for LoRa
; Registers
symbol REG_FIFO = 0x00
symbol REG_OP_MODE = 0x01
symbol REG_FRF_MSB = 0x06
symbol REG_FRF_MID = 0x07
symbol REG_FRF_LSB = 0x08
symbol REG_PA_CONFIG = 0x09
symbol REG_OCP = 0x0b
symbol REG_LNA = 0x0c
symbol REG_FIFO_ADDR_PTR = 0x0d
symbol REG_FIFO_TX_BASE_ADDR = 0x0e
symbol REG_FIFO_RX_BASE_ADDR = 0x0f
symbol REG_FIFO_RX_CURRENT_ADDR = 0x10
symbol REG_IRQ_FLAGS = 0x12
symbol REG_RX_NB_BYTES = 0x13
symbol REG_PKT_SNR_VALUE = 0x19
symbol REG_PKT_RSSI_VALUE = 0x1a
symbol REG_MODEM_CONFIG_1 = 0x1d
symbol REG_MODEM_CONFIG_2 = 0x1e
symbol REG_PREAMBLE_MSB = 0x20
symbol REG_PREAMBLE_LSB = 0x21
symbol REG_PAYLOAD_LENGTH = 0x22
symbol REG_MODEM_CONFIG_3 = 0x26
symbol REG_FREQ_ERROR_MSB = 0x28
symbol REG_FREQ_ERROR_MID = 0x29
symbol REG_FREQ_ERROR_LSB = 0x2a
symbol REG_RSSI_WIDEBAND = 0x2c
symbol REG_DETECTION_OPTIMIZE = 0x31
symbol REG_INVERTIQ = 0x33
symbol REG_DETECTION_THRESHOLD = 0x37
symbol REG_SYNC_WORD = 0x39
symbol REG_INVERTIQ2 = 0x3b
symbol REG_DIO_MAPPING_1 = 0x40
symbol REG_VERSION = 0x42
symbol REG_PA_DAC = 0x4d

; Modes
symbol MODE_LONG_RANGE_MODE = 0x80
symbol MODE_SLEEP = 0x00
symbol MODE_STDBY = 0x01
symbol MODE_TX = 0x03
symbol MODE_RX_CONTINUOUS = 0x05
symbol MODE_RX_SINGLE = 0x06

; PA Config
symbol PA_BOOST = 0x80

; IRQ masks
symbol IRQ_TX_DONE_MASK = 0x08
symbol IRQ_PAYLOAD_CRC_ERROR_MASK = 0x20
symbol IRQ_RX_DONE_MASK = 0x40

; Other
symbol MAX_PKT_LENGTH = 255

; Check the correct files have been included to reduce cryptic error messages.
; ; #IFNDEF FILE_SYMBOLS_INCLUDED [#IF CODE REMOVED]
; 	#ERROR "'symbols.basinc' is not included. Please make sure it included above 'LoRa.basinc'." [#IF CODE REMOVED]
; #ENDIF
; ; #IFNDEF FILE_GENERATED_INCLUDED [#IF CODE REMOVED]
; 	#ERROR "'generated.basinc' is not included. Please make sure it included above 'LoRa.basinc'." [#IF CODE REMOVED]
; #ENDIF

; ; #IFNDEF DISABLE_LORA_SETUP [#IF CODE REMOVED]
; begin_lora: [#IF CODE REMOVED]
; 	; Sets the module up. [#IF CODE REMOVED]
; 	; Initialises the LoRa module (begin) [#IF CODE REMOVED]
; 	; Usage: [#IF CODE REMOVED]
; 	;	gosub begin_lora [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Variables read: none [#IF CODE REMOVED]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2, level [#IF CODE REMOVED]
; 	; Maximum stack depth used: 5 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	high SS [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Reset the module [#IF CODE REMOVED]
; 	low RST [#IF CODE REMOVED]
; 	pause 10 [#IF CODE REMOVED]
; 	high RST [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Begin spi [#IF CODE REMOVED]
; 	; Check version [#IF CODE REMOVED]
; 	; uint8_t version = readRegister(REG_VERSION); [#IF CODE REMOVED]
;   	; if (version != 0x12) { [#IF CODE REMOVED]
;       ;     return 0; [#IF CODE REMOVED]
; 	; } [#IF CODE REMOVED]
; 	param1 = REG_VERSION [#IF CODE REMOVED]
; 	gosub read_register [#IF CODE REMOVED]
; 	if rtrn != 0x12 then [#IF CODE REMOVED]
; 		; sertxd("Got: ",#rtrn," ") [#IF CODE REMOVED]
; 		rtrn = 0 [#IF CODE REMOVED]
; 		return [#IF CODE REMOVED]
; 	endif [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; put in sleep mode [#IF CODE REMOVED]
; 	gosub sleep_lora [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; set frequency [#IF CODE REMOVED]
; 	; setFrequency(frequency); [#IF CODE REMOVED]
; 	gosub set_frequency [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; set base addresses [#IF CODE REMOVED]
; 	; writeRegister(REG_FIFO_TX_BASE_ADDR, 0); [#IF CODE REMOVED]
; 	param1 = REG_FIFO_TX_BASE_ADDR [#IF CODE REMOVED]
; 	param2 = 0 [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; writeRegister(REG_FIFO_RX_BASE_ADDR, 0); [#IF CODE REMOVED]
; 	param1 = REG_FIFO_RX_BASE_ADDR [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; set LNA boost [#IF CODE REMOVED]
; 	; writeRegister(REG_LNA, readRegister(REG_LNA) | 0x03); [#IF CODE REMOVED]
; 	param1 = REG_LNA [#IF CODE REMOVED]
; 	gosub read_register ; Should not change param1 [#IF CODE REMOVED]
; 	param2 = rtrn | 0x03 [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; set auto AGC [#IF CODE REMOVED]
; 	; writeRegister(REG_MODEM_CONFIG_3, 0x04); [#IF CODE REMOVED]
; 	param1 = REG_MODEM_CONFIG_3 [#IF CODE REMOVED]
; 	param2 = 0x04 [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; set output power to 17 dBm [#IF CODE REMOVED]
; 	; setTxPower(17); [#IF CODE REMOVED]
; 	param1 = 17 [#IF CODE REMOVED]
; 	gosub set_tx_power [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; put in standby mode [#IF CODE REMOVED]
; 	gosub idle_lora [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Success. Return [#IF CODE REMOVED]
; 	rtrn = 1 [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; #ENDIF

; #IFDEF ENABLE_LORA_TRANSMIT
begin_lora_packet:
	; Call this to set the module up to send a packet.
	; Only supports explicit header mode for now.
	; Usage:
	;	gosub begin_packet
	;
	; Variables read: none
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2
	; Maximum stack depth used: 4

	; Check if the radio is busy and return 0 if so.
	; As we are always waiting until the packet has been transmitted, we can not do this and save
	; program memory.
	; gosub is_transmitting
	; if rtrn = 1 then
	; 	rtrn = 0
	; 	return
	; endif

	; Put into standby mode
	gosub idle_lora
	
	; Explicit header mode
	; writeRegister(REG_MODEM_CONFIG_1, readRegister(REG_MODEM_CONFIG_1) & 0xfe);
	param1 = REG_MODEM_CONFIG_1
	gosub read_register
	param2 = rtrn & 0xfe
	gosub write_register
	
	; reset FIFO address and paload length
  	; writeRegister(REG_FIFO_ADDR_PTR, 0);
	param1 = REG_FIFO_ADDR_PTR
	param2 = 0
	gosub write_register
	
	; writeRegister(REG_PAYLOAD_LENGTH, 0);
	param1 = REG_PAYLOAD_LENGTH
	gosub write_register
	
	rtrn = 1
	return
	
end_lora_packet:
	; Finalises the packet and instructs the module to send it.
	; Waits until transmission is finished (async is treated as false).
	; Usage:
	;	gosub end_packet
	;
	; Variables read: none
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2,
	;                     start_time,
	; Maximum stack depth used: 3

	; put in TX mode
	; writeRegister(REG_OP_MODE, MODE_LONG_RANGE_MODE | MODE_TX);
	param1 = REG_OP_MODE
	param2 = MODE_LONG_RANGE_MODE | MODE_TX
	gosub write_register
	
	; Wait for TX done
	; while ((readRegister(REG_IRQ_FLAGS) & IRQ_TX_DONE_MASK) == 0) { yield(); }
	start_time = time
end_packet_wait:
	tmpwd = time - start_time
	if tmpwd > LORA_TIMEOUT then ; On a breadboard, occasionally the spi seems to drop out and the chip gets stuck here.
		rtrn = 0
		return
	endif
	param1 = REG_IRQ_FLAGS
	gosub read_register
	tmpwd = rtrn & IRQ_TX_DONE_MASK
	if tmpwd = 0 then end_packet_wait
	
	; clear IRQ's
	; writeRegister(REG_IRQ_FLAGS, IRQ_TX_DONE_MASK);
	param1 = REG_IRQ_FLAGS
	param2 = IRQ_TX_DONE_MASK
	gosub write_register
	
	rtrn = 1
	return

write_lora:
	; Writes a string starting at bptr that is param1 chars long
	; Usage:
	;     bptr = 28 ; First character in string / char array is at the byte after b27 (treating
	;               ; general purpose memory as a char array).
	;     param1 = 5 ; 5 bytes to add to send.
	;     gosub write_lora
	;
	; Variables read: param1, bptr
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2, bptr,
	;                     level, total_length, counter2
	
	level = param1
	
	param1 = REG_PAYLOAD_LENGTH
	gosub read_register
	
	; Check size
	total_length = rtrn + level
	if total_length > MAX_PKT_LENGTH then
		level = MAX_PKT_LENGTH - rtrn
	endif
	
	; Write data
	for counter2 = 1 to level
		param1 = REG_FIFO
		param2 = @bptrinc
		; sertxd("W: ", #param2,cr, lf)
		gosub write_register
	next counter2
	; sertxd(cr,lf)
	
	; Update length
	param1 = REG_PAYLOAD_LENGTH
	param2 = total_length
	gosub write_register
	
	rtrn = level
	return

; #rem [Commented out]
; is_transmitting: [Commented out]
; 	; Returns 1 if the transmitter is transmitting and 0 otherwise. [Commented out]
; 	; Note: Is this required seeing as we always wait for transmissions to be done? [Commented out]
; 	; return (readRegister(REG_OP_MODE) & MODE_TX) == MODE_TX) [Commented out]
; 	; Does not preserve param1 or param2 [Commented out]
; 	; [Commented out]
; 	; Variables read: none [Commented out]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2 [Commented out]
; 	param1 = REG_OP_MODE [Commented out]
; 	gosub read_register [Commented out]
; 	rtrn = rtrn & MODE_TX [Commented out]
; 	if rtrn = MODE_TX then [Commented out]
; 		rtrn = 1 [Commented out]
; 		return [Commented out]
; 	endif [Commented out]
;  [Commented out]
; 	; IRQ Stuff [Commented out]
; 	; if (readRegister(REG_IRQ_FLAGS) & IRQ_TX_DONE_MASK) { [Commented out]
; 	;	clear IRQ's [Commented out]
; 	;	writeRegister(REG_IRQ_FLAGS, IRQ_TX_DONE_MASK); [Commented out]
; 	; } [Commented out]
; 	param1 = REG_IRQ_FLAGS [Commented out]
; 	gosub read_register [Commented out]
; 	rtrn = rtrn & IRQ_TX_DONE_MASK [Commented out]
; 	if rtrn != 0 then [Commented out]
; 		param2 = IRQ_TX_DONE_MASK [Commented out]
; 		gosub write_register [Commented out]
; 	endif [Commented out]
;  [Commented out]
; 	rtrn = 0 [Commented out]
; 	return [Commented out]
; #endrem [Commented out]
; #ENDIF

; #IFDEF ENABLE_LORA_RECEIVE
setup_lora_receive:
	; Puts the LoRa module in receiving (higher power draw) mode.
	; Based off void LoRaClass::receive(int size), but no params as always using DI0 pin.
	;
	; Variables read: none
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2
	; Maximum stack depth used: 3

	; writeRegister(REG_DIO_MAPPING_1, 0x00); // DIO0 => RXDONE
	param1 = REG_DIO_MAPPING_1
	param2 = 0x00
	gosub write_register
	
	; Note: As the size is assumed to always be 0 as the DIO0 pin is used, explicit mode only is implemented
	; if (size > 0) {
	;	implicitHeaderMode();
	;	writeRegister(REG_PAYLOAD_LENGTH, size & 0xff);
	; } else {
	;	explicitHeaderMode();
	; }

	; Explicit header mode function:
	; writeRegister(REG_MODEM_CONFIG_1, readRegister(REG_MODEM_CONFIG_1) & 0xfe);
	param1 = REG_MODEM_CONFIG_1
	gosub read_register
	param2 = rtrn & 0xFE
	gosub write_register

	; writeRegister(REG_OP_MODE, MODE_LONG_RANGE_MODE | MODE_RX_CONTINUOUS);
	param1 = REG_OP_MODE
	param2 = MODE_LONG_RANGE_MODE | MODE_RX_CONTINUOUS
	gosub write_register
	return

setup_lora_read:
	; Call this when the dio0 pin on the module is high.
	; Based off handleDio0Rise()
	; Returns the packet length is valid or LORA_RECEIVED_CRC_ERROR
	;
	; Variables read: none
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2, level
	; Maximum stack depth used: 3

	; int irqFlags = readRegister(REG_IRQ_FLAGS);
	; writeRegister(REG_IRQ_FLAGS, irqFlags); // clear IRQ's
	param1 = REG_IRQ_FLAGS
	gosub read_register
	param2 = rtrn
	gosub write_register ; rtrn will be overwritten, so use param2 afterwards as needed
	
	; if ((irqFlags & IRQ_PAYLOAD_CRC_ERROR_MASK) == 0) {
	tmpwd = param2 & IRQ_PAYLOAD_CRC_ERROR_MASK
	if tmpwd = 0 then
		; Asyncronous tx not implemented, so no checking if it is not because of the rx done flag.
		; We have received a packet.
		; Implicit header mode is not implemented. Will need to change registers here if it is.
		; int packetLength = _implicitHeaderMode ? readRegister(REG_PAYLOAD_LENGTH) : readRegister(REG_RX_NB_BYTES); Read packet length
		param1 = REG_RX_NB_BYTES
		gosub read_register
		level = rtrn
		
		; Set FIFO address to current RX address
      	; writeRegister(REG_FIFO_ADDR_PTR, readRegister(REG_FIFO_RX_CURRENT_ADDR));
		param1 = REG_FIFO_RX_CURRENT_ADDR
		gosub read_register
		param1 = REG_FIFO_ADDR_PTR
		param2 = rtrn
		gosub write_register
		;counter3 = rtrn
		rtrn = level ; Return the length of the packet
	else
		rtrn = LORA_RECEIVED_CRC_ERROR

	endif
	return

read_lora:
	; Reads the next byte from the receiver.
	; Currently does not do any checking if too many bytes have been read.
	; TODO: Checking if too many bytes have been read.
	;
	; Variables read: none
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2
	; Maximum stack depth used: 3

	param1 = REG_FIFO
	gosub read_register
	; sertxd("Reading: ", #rtrn, cr, lf)
	return

packet_rssi:
	; Returns the RSSI in 2's complement
	;
	; Variables read: none
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2
	; return (readRegister(REG_PKT_RSSI_VALUE) - (_frequency < 868E6 ? 164 : 157));
	param1 = REG_PKT_RSSI_VALUE
	gosub read_register
	
; 	#IF 433000000 < 868000000
	rtrn = rtrn - 164
; ; 	#ELSE [#IF CODE REMOVED]
; 	rtrn = rtrn - 157 [#IF CODE REMOVED]
; 	#ENDIF
	return
	
packet_snr:
	; Returns the SNR in 2's complement * 4
	;
	; Variables read: none
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1
	param1 = REG_PKT_SNR_VALUE
	gosub read_register
	return
	
; #ENDIF

; ; #IFNDEF DISABLE_LORA_SETUP [#IF CODE REMOVED]
; set_spreading_factor: [#IF CODE REMOVED]
; 	; Sets the spreading factor. If not called, defaults to 7. [#IF CODE REMOVED]
; 	; Spread factor 6 is not supported as implicit header mode is not enabled. [#IF CODE REMOVED]
; 	; Spread factor and LDO flag are hardcoded in symbols.basinc as symbols LORA_SPREADING_FACTOR and LORA_LDO_ON [#IF CODE REMOVED]
; 	; Usage: [#IF CODE REMOVED]
; 	;	gosub set_spreading_factor [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Variables read: none [#IF CODE REMOVED]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2 [#IF CODE REMOVED]
; 	; Maximum stack depth used: 4 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; ; #IF 9 < 7 [#IF CODE REMOVED]
; 	#ERROR "Spread factors less than 7 are not currently supported" [#IF CODE REMOVED]
; #ELSEIF 9 > 12 [#IF CODE REMOVED]
; 	#ERROR "Spread factors greater than 12 are not currently supported" [#IF CODE REMOVED]
; ; #ENDIF [#IF CODE REMOVED]
; 	; TODO: Spread factor 6 implementation [#IF CODE REMOVED]
; 	; if param1 = 6 then [#IF CODE REMOVED]
; 	; Spread factor 6 (not implemented): [#IF CODE REMOVED]
; 	; writeRegister(REG_DETECTION_OPTIMIZE, 0xc5); [#IF CODE REMOVED]
; 	; writeRegister(REG_DETECTION_THRESHOLD, 0x0c); [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; All other spread factors [#IF CODE REMOVED]
; 	; writeRegister(REG_DETECTION_OPTIMIZE, 0xc3); [#IF CODE REMOVED]
; 	param1 = REG_DETECTION_OPTIMIZE [#IF CODE REMOVED]
; 	param2 = 0xc3 [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; writeRegister(REG_DETECTION_THRESHOLD, 0x0a); [#IF CODE REMOVED]
; 	param1 = REG_DETECTION_THRESHOLD [#IF CODE REMOVED]
; 	param2 = 0x0a [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; writeRegister(REG_MODEM_CONFIG_2, (readRegister(REG_MODEM_CONFIG_2) & 0x0f) | ((sf << 4) & 0xf0)); [#IF CODE REMOVED]
; 	param1 = REG_MODEM_CONFIG_2 [#IF CODE REMOVED]
; 	gosub read_register [#IF CODE REMOVED]
; 	param2 = rtrn & 0x0f [#IF CODE REMOVED]
; 	tmpwd = 9 * 16 & 0xf0 [#IF CODE REMOVED]
; 	param2 = param2 | tmpwd [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; setLdoFlag(); [#IF CODE REMOVED]
; 	gosub set_ldo_flag [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; set_ldo_flag: [#IF CODE REMOVED]
; 	; param1 contains the spreading factor [#IF CODE REMOVED]
; 	; Uses the LORA_LDO_ON symbol for now. Use the included python file to calculate if this should [#IF CODE REMOVED]
; 	; be 0 (false) or 1 (true). [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Variables read: none [#IF CODE REMOVED]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2 [#IF CODE REMOVED]
; 	; Maximum stack depth used: 3 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	param1 = REG_MODEM_CONFIG_3 [#IF CODE REMOVED]
; 	gosub read_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	param2 = rtrn & %11110111 ; Clear the ldo bit in case it needs to be cleared [#IF CODE REMOVED]
; 	;tmpwd = LORA_LDO_ON [#IF CODE REMOVED]
; ; #IF 0 = 1 [#IF CODE REMOVED]
; 	; if tmpwd = 1 then [#IF CODE REMOVED]
; 	param2 = param2 | %1000 ; Set the bit [#IF CODE REMOVED]
; 	; endif [#IF CODE REMOVED]
; ; #ENDIF [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; set_tx_power: [#IF CODE REMOVED]
; 	; PA Boost only implemented to save memory (not RFO) [#IF CODE REMOVED]
; 	; Does NOT preserve param1! [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Variables read: param1 [#IF CODE REMOVED]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2, level [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	level = param1 ; Need to save param 1 for later [#IF CODE REMOVED]
; 	if level > 17 then [#IF CODE REMOVED]
; 		if level > 20 then [#IF CODE REMOVED]
; 			level = 20 [#IF CODE REMOVED]
; 		endif [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 		level = level - 3 ; Map 18 - 20 to 15 - 17 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 		; High Power +20 dBm Operation (Semtech SX1276/77/78/79 5.4.3.) [#IF CODE REMOVED]
;       	; writeRegister(REG_PA_DAC, 0x87); [#IF CODE REMOVED]
; 		param1 = REG_PA_DAC [#IF CODE REMOVED]
; 		param2 = 0x87 [#IF CODE REMOVED]
; 		gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
;       	; setOCP(140); [#IF CODE REMOVED]
; 		param1 = 140 [#IF CODE REMOVED]
; 		gosub set_OCP [#IF CODE REMOVED]
; 	else [#IF CODE REMOVED]
; 		if level < 2 then [#IF CODE REMOVED]
; 			level = 2 [#IF CODE REMOVED]
; 		endif [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 		; Default value PA_HF/LF or +17dBm [#IF CODE REMOVED]
;       	; writeRegister(REG_PA_DAC, 0x84); [#IF CODE REMOVED]
; 		param1 = REG_PA_DAC [#IF CODE REMOVED]
; 		param2 = 0x84 [#IF CODE REMOVED]
; 		gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
;       	; setOCP(100); [#IF CODE REMOVED]
; 		param1 = 100 [#IF CODE REMOVED]
; 		gosub set_OCP [#IF CODE REMOVED]
; 	endif [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; writeRegister(REG_PA_CONFIG, PA_BOOST | (level - 2)); [#IF CODE REMOVED]
; 	param1 = REG_PA_CONFIG [#IF CODE REMOVED]
; 	param2 = level - 2 [#IF CODE REMOVED]
; 	param2 = PA_BOOST | param2 [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; set_OCP: [#IF CODE REMOVED]
; 	; Sets the overcurrent protection [#IF CODE REMOVED]
; 	; param1: mA [#IF CODE REMOVED]
; 	; Does not preserve param1 [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Variables read: param1 [#IF CODE REMOVED]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2 [#IF CODE REMOVED]
; 	tmpwd = 27 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	if param1 <= 120 then [#IF CODE REMOVED]
; 		tmpwd = param1 - 45 [#IF CODE REMOVED]
; 		tmpwd = tmpwd / 5 [#IF CODE REMOVED]
; 	elseif param1 <= 240 then [#IF CODE REMOVED]
; 		tmpwd = param1 + 30 [#IF CODE REMOVED]
; 		tmpwd = tmpwd / 10 [#IF CODE REMOVED]
; 	endif [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	param1 = REG_OCP [#IF CODE REMOVED]
; 	param2 = 0x1f & tmpwd [#IF CODE REMOVED]
; 	param2 = 0x20 | param2 [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; set_frequency: [#IF CODE REMOVED]
; 	; Sets the frequency using the LORA_FREQ_MSB, LORA_FREQ_MID and LORA_FREQ_LSB symbols. [#IF CODE REMOVED]
; 	; There should be a python script to calculate these. [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Variables read: none [#IF CODE REMOVED]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2 [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; uint64_t frf = ((uint64_t)frequency << 19) / 32000000; [#IF CODE REMOVED]
; 	; writeRegister(REG_FRF_MSB, (uint8_t)(frf >> 16)); [#IF CODE REMOVED]
; 	param1 = REG_FRF_MSB [#IF CODE REMOVED]
; 	param2 = 0x6C [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; writeRegister(REG_FRF_MID, (uint8_t)(frf >> 8)); [#IF CODE REMOVED]
; 	param1 = REG_FRF_MID [#IF CODE REMOVED]
; 	param2 = 0x40 [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; writeRegister(REG_FRF_LSB, (uint8_t)(frf >> 0)); [#IF CODE REMOVED]
; 	param1 = REG_FRF_LSB [#IF CODE REMOVED]
; 	param2 = 0x00 [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; #ENDIF

sleep_lora:
	; Puts the LoRa module into sleep (low power) mode.
	;
	; Variables read: none
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2
	;
	; writeRegister(REG_OP_MODE, MODE_LONG_RANGE_MODE | MODE_SLEEP);
	param1 = REG_OP_MODE
	param2 = MODE_LONG_RANGE_MODE | MODE_SLEEP
	gosub write_register
	return

idle_lora:
	; Puts the LoRa module into idle (default power level) mode.
	;
	; Variables read: none
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2
	; Maximum stack depth used: 3

	; writeRegister(REG_OP_MODE, MODE_LONG_RANGE_MODE | MODE_STDBY);
	param1 = REG_OP_MODE
	param2 = MODE_LONG_RANGE_MODE | MODE_STDBY
	gosub write_register
	return
	
read_register:
	; Reads a LoRa register
	;
	; Variables read: param1
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2
	; Maximum stack depth used: 2

	param1 = param1 & 0x7f
	param2 = 0
	gosub single_transfer
	; single_transfer will have set rtrn
	return

write_register:
	; Writes to a register in the transceiver
	;
	; Variables read: param1, param2
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1
	; Maximum stack depth used: 2

	; singleTransfer(address | 0x80, value);
	param1 = param1 | 0x80
	; param2 = value is already set
	gosub single_transfer
	return

single_transfer:
	; Performs a single transfer operation to and from the LoRa module
	; param1 is the first byte
	; param2 is the second byte
	; rtrn is the second byte returned
	;
	; Variables read: param1, param2
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage
	; Maximum stack depth used: 1
	low SS
	; param1 is already set
	s_transfer_storage = param1 ; so param1can be restored later
	gosub spi_byte
	param1 = param2
	gosub spi_byte
	; rtrn is already set
	param1 = s_transfer_storage
	high SS
	return
	
spi_byte:
	; Sends and receives a byte over spi. Based off the examples in the manual, except full duplex.
	; The clock frequency is very roughly 1.58kHz at 32MHz clock.
	; Usage:
	;     param1 = byte to send
	;     gosub spi_byte
	;     rtrn = received byte
	;
	; Variables read: param1
	; Variables modified: rtrn, tmpwd, counter, mask
	rtrn = 0
	tmpwd = param1
	for counter = 1 to 8 ; number of bits
		mask = tmpwd & 128 ; mask MSB
		; Send data
		if mask = 0 then ; Set MOSI
			low MOSI
		else
			high MOSI
		endif
		
		; Receive data
		rtrn = rtrn * 2 ; shift left as MSB first
		if MISO != 0 then
			inc rtrn
		endif
		
		; pulsout SCK,80 ; pulse clock for 800us (80). Slow down to allow the arduino to detect it
		pulsout SCK, 1 ; Faster version for normal use.
		
		tmpwd = tmpwd * 2 ; shift variable left for MSB
		next counter
	return

; #DEFINE FILE_LORA_INCLUDED ; Prove this file has been included correctly

'---END include/LoRa.basinc---
'---BEGIN include/PJON.basinc ---
; PJON.basinc
; Basic BASIC implementation of the PJON Protocol for use with LoRa.
; The official C++ library can be found here: https://www.pjon.org/
; Jotham Gates
; Created: 24/11/2020
; Modified: 22/02/2023
; https://github.com/jgOhYeah/PICAXE-Libraries-Extras
; TODO: Allow bus ids and more flexibility in packet types
; TODO: Allow it to work with other strategies

; symbol PACKET_HEADER = %00000010 ; Local mode, no bus id, tx sender info
symbol PACKET_HEADER = %00100110 ; CRC32, ACK, TX info
symbol PACKET_HEAD_LENGTH = 5 ; Local mode, no bus id, tx sender info
; symbol BUS_ID_0 = 0 ; Not implemented yet
; symbol BUS_ID_1 = 0
; symbol BUS_ID_2 = 0
; symbol BUS_ID_3 = 0
symbol PACKET_TX_START = 28 ; The address of the first byte in memory to use when transmitting.
symbol PACKET_RX_START = 63 ; The address of the first byte in memory to use when receiving.
							; RX is separate to TX so that a packet could theoretically be built
							; while another is received.
symbol PACKET_RX_HEADER = 64
symbol PACKET_RX_LENGTH = 65 ; Needs to be the byte after PACKET_RX_HEADER. Defined here as the
							 ; compiler doesn't seem to have any optimisations or evaluation of
							 ; expressions with only constants.

; PJON header byte bits
symbol HEADER_PKT_ID = %10000000
symbol HEADER_EXT_LENGTH = %01000000
symbol HEADER_CRC = %00100000
symbol HEADER_PORT = %00010000
symbol HEADER_ACK_MODE = %00001000
symbol HEADER_ACK = %0000100
symbol HEADER_TX_INFO = %0000010
symbol HEADER_MODE = %00000001

; #DEFINE DEBUG_PJON_RECEIVE ; At this stage, cannot include code for transmitting and debug as not enough memory

; Check the correct files have been included to reduce cryptic error messages.
; ; #IFNDEF FILE_SYMBOLS_INCLUDED [#IF CODE REMOVED]
; 	#ERROR "'symbols.basinc' is not included. Please make sure it included above 'PJON.basinc'." [#IF CODE REMOVED]
; #ENDIF
; ; #IFNDEF FILE_GENERATED_INCLUDED [#IF CODE REMOVED]
; 	#ERROR "'generated.basinc' is not included. Please make sure it included above 'PJON.basinc'." [#IF CODE REMOVED]
; #ENDIF
; ; #IFNDEF FILE_LORA_INCLUDED [#IF CODE REMOVED]
; 	#ERROR "'LoRa.basinc' is not included. Please make sure it is included above 'PJON.basinc'." [#IF CODE REMOVED]
; #ENDIF
; #IFDEF ENABLE_PJON_RECEIVE
; ; 	#IFNDEF ENABLE_LORA_RECEIVE [#IF CODE REMOVED]
; 		#ERROR "'ENABLE_LORA_RECEIVE' must be defined to use PJON receive." [#IF CODE REMOVED]
; 	#ENDIF
; #ENDIF
; #IFDEF ENABLE_PJON_TRANSMIT
; ; 	#IFNDEF ENABLE_LORA_TRANSMIT [#IF CODE REMOVED]
; 		#ERROR "'ENABLE_LORA_TRANSMIT' must be defined to use PJON transmit." [#IF CODE REMOVED]
; 	#ENDIF
; #ENDIF

; #IFDEF ENABLE_PJON_TRANSMIT
begin_pjon_packet:
	; Sets bptr to the correct location to start writing data
	; Maximum stack depth used: 0

	bptr = PACKET_TX_START + PACKET_HEAD_LENGTH
	return

end_pjon_packet:
	; Finalises the packet, writes the header and sends it using LoRa radio
	; param1 contains the id
	; Maximum stack depth used: 5
	
	level = bptr
	param2 = bptr - PACKET_TX_START + 4 ; Length of packet with the crc bytes
	gosub write_pjon_header
	
	param1 = level - PACKET_TX_START; Length of the packet without the final crc bytes
	bptr = PACKET_TX_START
	gosub crc32_compute
	; Add the final crc
	@bptrinc = crc3
	@bptrinc = crc2
	@bptrinc = crc1
	@bptrinc = crc0
	
	; Send the packet
	gosub begin_lora_packet ; Stack is 5
	param1 = bptr - PACKET_TX_START
	bptr = PACKET_TX_START
	gosub write_lora
	gosub end_lora_packet
	return

write_pjon_header:
	; param1 contains the id
	; param2 contains the length
	; Afterwards, bptr is at the correct location to begin writing the packet contents.
	; Maximum stack depth used: 2

	bptr = PACKET_TX_START
	@bptrinc = param1
	@bptrinc = PACKET_HEADER
	@bptrinc = param2
	; CRC of everything up to now
	bptr = PACKET_TX_START
	param1 = 3
	gosub crc8_compute
	@bptrinc = rtrn
	; PJON local only implemented at this stage
	@bptrinc = MY_ID ; Add sender id
	return

; #ENDIF

; #IFDEF ENABLE_PJON_RECEIVE
read_pjon_packet:
	; Reads the packet and if the header is valid, copy to bptr (we need to be able to calculate the
	; checksum at the end, so storage on the chip is required).
	; If there is not packet, it is not addressed to us or it is invalid / fails the checksum, rtrn
	; will be PJON_INVALID_PACKET. If the packet is valid and addressed to us, rtrn will be the
	; payload length and bptr will point to the first byte of the payload.
	; param1 contains the sender id or 0 if there is none.
	;
	; Variables read: none
	; Variables modified: crc0, crc1, crc2, crc3, counter, param1, param2, counter2, tmpwd, mask,
	;                     level, rtrn, s_transfer_Storage, bptr, total_length, start_time,
	;                     start_time_h, start_time_l, counter3 (in other words, everything defined
	;                     as of when this was written)
	; Maximum stack depth used: 3
	gosub setup_lora_read
	if rtrn != LORA_RECEIVED_CRC_ERROR then
		total_length = rtrn
		; counter3 = 0
		bptr = PACKET_RX_START
		; Read the packet header into ram.
		if total_length >= 4 then ; There needs to be at least 4 bytes for the header
			; Address
			gosub read_lora ; rtrn contains the packet id
			; inc counter3
			if rtrn = MY_ID or rtrn = 0 then
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 				sertxd("PKT is to us", cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
				; This is a valid id we should respond to
				@bptrinc = rtrn

				; Packet header byte
				gosub read_lora ; rtrn contains the header
				; inc counter3
				@bptrinc = rtrn
				; TODO: Proper full implementation of all header options
				; Ignores Packet_ID
				; Ignores EXT_LENGTH (LoRa is limited in length anyway)
				; CRC is processed later
				; PORT is ignored
				; ACK mode is ignored
				; ACK is ignored
				; TX Info is processed later
				; Mode is ignored (assumes local)
					
				; Packet length
				gosub read_lora
				; inc counter3
				@bptrinc = rtrn

				; Get the checksum of the header.
				gosub read_lora
				; inc counter3
				@bptrinc = rtrn
				param2 = rtrn ; crc8_compute does not use param2... hopefully

				; Check crc of the received header and compare it to what it should be.
				bptr = PACKET_RX_START
				param1 = 3 ; Address, Header, Length
				gosub crc8_compute
				if param2 = rtrn then
					; Checksums match. All good.
					; Calculate the required length and check that the LoRa packet is at least that.
					start_time = 0 ; Total length calculations. Mose well reset start_time_h and start_time_l at the same time
					; Read the sender id if needed
					bptr = PACKET_RX_HEADER
					tmpwd = @bptr & HEADER_TX_INFO
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 					sertxd("Header is: ", #@bptr, cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
					if tmpwd != 0 then
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 						sertxd("Sender info is included", cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
						start_time_l = 1
					endif

					; Set the length of the checksum
					; bptr = PACKET_RX_HEADER ; Hopefully should still be there
					tmpwd = @bptrinc & HEADER_CRC
					if tmpwd != 0 then
						; 32 bit checksum at the end
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 						sertxd("32 bit checksum", cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
						crc1 = 4
					else
						; 8 bit checksum at the end
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 						sertxd("8 bit checksum", cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
						crc1 = 1
					endif

					; Read the packet length - should be there now after header
					; bptr = PACKET_RX_LENGTH
					start_time_h = @bptr - 4 - start_time_l - crc1 ; start_time_h is the payload length
					; NOTE: Above is a possible failure point
					; Check if the required length will fit inside the packet
					if @bptrdec <= total_length then ; Should be at packet length
						; Length is correct. Can safely read until the end of the packet
						; Copy the sender id if included
						tmpwd = @bptr & HEADER_TX_INFO
						bptr = PACKET_RX_START + 4 + start_time_l ; Hopefully back where we were before we went off on that verification rubbish :)
						; NOTE: Above is a possible failure point
						if tmpwd != 0 then
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 							sertxd("Sender info is still included", cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
							gosub read_lora
							; inc counter3
							dec bptr
							@bptrinc = rtrn ; Copy sender id
						endif

						; Load the payload
						for crc0 = 1 to start_time_h
							gosub read_lora
							; inc counter3
							@bptrinc = rtrn
						next crc0

						; Calculate the checksum, load and compare it with the one in the packet
						param1 = bptr - PACKET_RX_START ; Total length of everything up to now/
						bptr = PACKET_RX_HEADER ; Check checksum type
						tmpwd = @bptr & HEADER_CRC
						bptr = PACKET_RX_START ; Setup for crc calc
						if tmpwd != 0 then
							; 32 bit checksum at the end
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 							sertxd("32 bit checksum calcs", cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
							gosub crc32_compute
							gosub read_lora
							; inc counter3
							@bptrinc = rtrn
							if crc3 = rtrn then
								; First part matches
								gosub read_lora
								; inc counter3
								@bptrinc = rtrn
								if crc2 = rtrn then
									; Second part matches
									gosub read_lora
									; inc counter3
									@bptrinc = rtrn
									if crc1 = rtrn then
										; Third part matches
										gosub read_lora
										; inc counter3
										@bptrinc = rtrn
										if crc0 = rtrn then
											; Entire checksum matches
											; All good. Packet can be returned
											goto correct_pjon_packet_rtrn ; Shared with crc8
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 										else [#IF CODE REMOVED]
; 											sertxd("CRC0 failed", cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
										endif
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 									else [#IF CODE REMOVED]
; 										sertxd("CRC1 failed", cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
									endif
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 								else [#IF CODE REMOVED]
; 									sertxd("CRC2 failed", cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
								endif
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 							else [#IF CODE REMOVED]
; 								sertxd("CRC3 failed", cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
							endif
						else
							; 8 bit checksum at the end
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 							sertxd("8 bit checksum calcs", cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
							; TODO: crc8 check
							gosub crc8_compute
							crc0 = rtrn
							gosub read_lora
							; inc counter3
							@bptrinc = rtrn
							if crc0 = rtrn then
								; Checksum matches. All good
								; All good. Packet can be returned
								goto correct_pjon_packet_rtrn ; Shared with crc32
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 							else [#IF CODE REMOVED]
; 								sertxd("CRC Failed", cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
							endif
						endif
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 					else [#IF CODE REMOVED]
; 						sertxd("PKT incorrect total length", cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
					endif
						
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 				else [#IF CODE REMOVED]
; 					; Checksums do not match. Invalid packet. [#IF CODE REMOVED]
; 					sertxd("PKT invalid header chksum: ", cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
				endif
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 			else [#IF CODE REMOVED]
; 				; Packet is not addressed to us. [#IF CODE REMOVED]
; 				sertxd("PKT invalid addr: ", #rtrn, cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
			endif
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 		else [#IF CODE REMOVED]
; 			; Packet is too short to contain a header. [#IF CODE REMOVED]
; 			sertxd("PKT no head: ", #total_length, cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
		endif
	endif
	rtrn = PJON_INVALID_PACKET
	return
; #ENDIF

correct_pjon_packet_rtrn:
	; Handles correct packet return from read_pjon_packet.
	; Do not call from anywhere else.
	rtrn = start_time_h ; Payload length
	bptr = PACKET_RX_START + 4

	; Load the sender id and move bptr to the correct start pos if sender id present
	param1 = 0
	if start_time_l != 0 then
		param1 = @bptrinc
	endif
; ; 	#IFDEF DEBUG_PJON_RECEIVE [#IF CODE REMOVED]
; 	sertxd("Received packet successfully",cr, lf) [#IF CODE REMOVED]
; 	#ENDIF
	return

; CRC8 implementation from the Arduino PJON library
crc8_compute:
	; Computes the crc8 of a given set of bytes.
	; bptr points to the first byte.
	; param1 is the length
	; rtrn is the crc
	; bptr points to the byte after.
	; Variables read: none
	; Variables modified: counter2, tmpwd, rtrn, param1, mask, counter, bptr
	; Maximum stack depth used: 1

	rtrn = 0
	mask = param1
	for counter = 1 to mask
		param1 = @bptrinc
		gosub crc8_roll
	next counter
	
	return
	
crc8_roll:
	; Performs a roll.
	; param1 is the input byte
	; rtrn is the current crc
	;
	; Variables read: none
	; Variables modified: counter2, tmpwd, rtrn, param1
	; Maximum stack depth used: 0

	for counter2 = 8 to 1 step -1
		tmpwd = rtrn ^ param1
		tmpwd = tmpwd & 0x01
		rtrn = rtrn / 2
		if tmpwd != 0 then
			rtrn = rtrn ^ 0x97
		endif
		param1 = param1 / 2
	next counter2
	return

crc32_compute:
	; Computes the crc32 of the given bytes
	; bptr points to the first byte.
	; param1 is the length
	; the crc is contained in crc3, crc2, crc1, crc0 after
	; bptr points to the byte after.
	;
	; Variables read: none
	; Variables modified: crc0, crc1, crc2, crc3, counter, param1, counter2, tmpwd, mask, level,
	;                     bptr
	; Maximum stack depth used: 0

	crc0 = 0xFF ; Lowest byte
	crc1 = 0xFF
	crc2 = 0xFF
	crc3 = 0xFF ; Highest byte

	for counter = param1 to 1 step -1
		crc0 = crc0 ^ @bptrinc
		for counter2 = 0 to 7
			; Right bitshift everything by 1
			; crc >>= 1
			tmpwd = crc3 & 1
				crc3 = crc3 / 2

			mask = crc2 & 1
        		crc2 = crc2 / 2
        		if tmpwd != 0 then
            		crc2 = crc2 + 0x80
			endif
		
			tmpwd = crc1 & 1
			crc1 = crc1 / 2
        		if mask != 0 then
            		crc1 = crc1 + 0x80
			endif

			level = crc0 & 1
        		crc0 = crc0 / 2
        		if tmpwd != 0 then
            		crc0 = crc0 + 0x80
			endif

			; XOR the crc if needed
			if level != 0 then
				; crc = (crc >> 1) ^ 0xEDB88320
				crc3 = crc3 ^ 0xED
				crc2 = crc2 ^ 0xB8
				crc1 = crc1 ^ 0x83
				crc0 = crc0 ^ 0x20
			endif
		next counter2
	next counter
	
	; Invert everything and we are done
	crc3 = crc3 ^ 0xFF ; ~ is not supported on M2 parts
	crc2 = crc2 ^ 0xFF
	crc1 = crc1 ^ 0xFF
	crc0 = crc0 ^ 0xFF
	return
'---END include/PJON.basinc---

'---END BatteryVoltsMonitor_slot1.bas---


'---Extras added by the preprocessor---
print_table_sertxd:
    for w6 = w6 to w7
    readtable w6, b16
    sertxd(b16)
next w6

    return

table 0, ("Battery voltage monitor and fence control"," ","v2.0.0"," MAIN",cr,lf,"Jotham Gates, Compiled ","22-02-2023",cr,lf) ;#sertxd
table 90, ("Sent packet",cr,lf) ;#sertxd
table 103, (" iterations of ") ;#sertxd
table 118, ("Timed reset",cr,lf) ;#sertxd
table 131, ("Entering receive mode",cr,lf) ;#sertxd
table 154, ("Valid packet received",cr,lf) ;#sertxd
table 177, ("Fence ") ;#sertxd
table 183, ("Off",cr,lf) ;#sertxd
table 188, ("On",cr,lf) ;#sertxd
table 192, ("Transmit ") ;#sertxd
table 201, ("Off",cr,lf) ;#sertxd
table 206, ("On",cr,lf) ;#sertxd
table 210, ("Transmit interval is ") ;#sertxd
table 231, (" *1.5 minutes",cr,lf) ;#sertxd
table 246, ("invalid. Ignoring",cr,lf) ;#sertxd
table 265, ("Status",cr,lf) ;#sertxd
table 273, ("Resetting",cr,lf) ;#sertxd
table 284, ("Bad code",cr,lf) ;#sertxd
table 294, ("Field ") ;#sertxd
table 300, (" unkown",cr,lf) ;#sertxd
table 309, ("Replying",cr,lf) ;#sertxd
table 319, ("Invalid packet recieved. Ignoring",cr,lf) ;#sertxd
table 354, ("Long listen time",cr,lf) ;#sertxd
table 372, ("Entering sleep mode",cr,lf) ;#sertxd
table 393, ("Sending state",cr,lf) ;#sertxd
table 408, (" (*0.1) V",cr,lf) ;#sertxd
table 419, ("*0.1 C",cr,lf) ;#sertxd
table 427, ("Fence: ") ;#sertxd
table 434, ("Transmit: ") ;#sertxd
table 444, ("TX Interval: ") ;#sertxd
table 457, ("LoRa dropped out.") ;#sertxd
table 474, ("Will reset and have another go.",cr,lf,cr,lf) ;#sertxd
