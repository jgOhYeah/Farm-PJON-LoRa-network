'-----PREPROCESSED BY picaxepreprocess.py-----
'----UPDATED AT 08:46PM, January 01, 2025----
'----SAVING AS compiled_slot0.bas ----

'---BEGIN BatteryVoltsMonitor_slot0.bas ---
; BatteryVoltsMonitor_slot0.bas
; A remote LoRa battery monitor and electric fence energiser switch
; (Bootloader).
; Written by Jotham Gates
; Created 22/02/2023
; Modified 22/02/2023
;
; https://github.com/jgOhYeah/Farm-PJON-LoRa-network
;
; FLASH MODES:
; Sleeping: One flash ~once per minute
; Actively listening: One flash every half second
; Cannot connect to LoRa module on start: Constant long flashes (on half second, off half second).
;
#SLOT 0
; We do want eeprom data for defaults.

'---BEGIN include/BatteryVoltsMonitorCommon.basinc ---
; Battery voltage monitor monitor common code
; Defines and symbols shared between each slot
; Written by Jotham Gates
; Created 22/02/2023
; Modified 31/12/2024

; #DEFINE VERSION "v2.0.3"
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
symbol CAL_BATT_DENOMINATOR_2 = 42 ; CAL_BATT_DENOMINATOR / 2 so that rounding works as expected.

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
symbol rtrn_l = b26
symbol rtrn_h = b27

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
; Autogenerated by calculations.py at 2025-01-01 20:46:18
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
#PICAXE 14M2      'CHIP VERSION PARSED
#TERMINAL 38400

; Default settings on upload
eeprom EEPROM_FENCE_ENABLED, (DEFAULT_FENCE_ENABLED)
eeprom EEPROM_TX_ENABLED, (DEFAULT_TX_ENABLED)
eeprom EEPROM_TX_INTERVALS, (DEFAULT_TX_INTERVALS)

init:
    ; Initial setup
	setfreq m32
	high LED_PIN
;#sertxd("Battery voltage monitor and fence control", " ", "v2.0.3" , " BOOTLOADER", cr,lf, "Jotham Gates, Compiled ", "01-01-2025", cr, lf, "Seeing as I have lots of space in the bootloader section, here is a URL to look at:", cr, lf, "https://github.com/jgOhYeah/Farm-PJON-LoRa-network", cr, lf) 'Evaluated below
w6 = 0
w7 = 232
gosub print_table_sertxd

	; Load settings from EEPROM
	read EEPROM_FENCE_ENABLED, fence_enable
	read EEPROM_TX_ENABLED,  transmit_enable
	read EEPROM_TX_INTERVALS, tx_intervals
	if fence_enable = 1 then
		high FENCE_PIN
	else
		low FENCE_PIN
	endif

	poke RAM_ITERATIONS_COUNT_L, 0, 0 ; Set iterations count to 0

	; Attempt to start the module
	gosub begin_lora
	if rtrn = 0 then
;#sertxd("LoRa Failed",cr,lf) 'Evaluated below
w6 = 233
w7 = 245
gosub print_table_sertxd
		goto failed
	else
;#sertxd("LoRa Started",cr,lf) 'Evaluated below
w6 = 246
w7 = 259
gosub print_table_sertxd
	endif

	; Set the spreading factor
	gosub set_spreading_factor

	; gosub idle_lora ; 4.95mA
	; gosub sleep_lora ; 3.16mA
	; gosub setup_lora_receive ; 14mA
	; Everything in sleep ; 0.18 to 0.25mA
	; Finish setup

;#sertxd("Starting slot 1...", cr, lf, cr, lf) 'Evaluated below
w6 = 260
w7 = 281
gosub print_table_sertxd
	low LED_PIN

    run 1

failed:
	tmpwd_l = 0
failed_loop:
	; Flashes the LED on and off to give an indication it isn't happy.
	toggle LED_PIN
	pause 4000
	if tmpwd_l > FAILED_RESET_ITERATIONS_COUNT then
;#sertxd("Resetting...", cr, lf, cr, lf) 'Evaluated below
w6 = 282
w7 = 297
gosub print_table_sertxd
		reset
	endif
	inc tmpwd_l
	goto failed_loop

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

; #IFNDEF DISABLE_LORA_SETUP
begin_lora:
	; Sets the module up.
	; Initialises the LoRa module (begin)
	; Usage:
	;	gosub begin_lora
	;
	; Variables read: none
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2, level
	; Maximum stack depth used: 5

	high SS
	
	; Reset the module
	low RST
	pause 10
	high RST
	
	; Begin spi
	; Check version
	; uint8_t version = readRegister(REG_VERSION);
  	; if (version != 0x12) {
      ;     return 0;
	; }
	param1 = REG_VERSION
	gosub read_register
	if rtrn != 0x12 then
		; sertxd("Got: ",#rtrn," ")
		rtrn = 0
		return
	endif
	
	; put in sleep mode
	gosub sleep_lora
	
	; set frequency
	; setFrequency(frequency);
	gosub set_frequency

	; set base addresses
	; writeRegister(REG_FIFO_TX_BASE_ADDR, 0);
	param1 = REG_FIFO_TX_BASE_ADDR
	param2 = 0
	gosub write_register
	
	; writeRegister(REG_FIFO_RX_BASE_ADDR, 0);
	param1 = REG_FIFO_RX_BASE_ADDR
	gosub write_register

	; set LNA boost
	; writeRegister(REG_LNA, readRegister(REG_LNA) | 0x03);
	param1 = REG_LNA
	gosub read_register ; Should not change param1
	param2 = rtrn | 0x03
	gosub write_register
	
	; set auto AGC
	; writeRegister(REG_MODEM_CONFIG_3, 0x04);
	param1 = REG_MODEM_CONFIG_3
	param2 = 0x04
	gosub write_register

	; set output power to 17 dBm
	; setTxPower(17);
	param1 = 17
	gosub set_tx_power

	; put in standby mode
	gosub idle_lora

	; Success. Return
	rtrn = 1
	return

; #ENDIF

; ; #IFDEF ENABLE_LORA_TRANSMIT [#IF CODE REMOVED]
; begin_lora_packet: [#IF CODE REMOVED]
; 	; Call this to set the module up to send a packet. [#IF CODE REMOVED]
; 	; Only supports explicit header mode for now. [#IF CODE REMOVED]
; 	; Usage: [#IF CODE REMOVED]
; 	;	gosub begin_packet [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Variables read: none [#IF CODE REMOVED]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2 [#IF CODE REMOVED]
; 	; Maximum stack depth used: 4 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Check if the radio is busy and return 0 if so. [#IF CODE REMOVED]
; 	; As we are always waiting until the packet has been transmitted, we can not do this and save [#IF CODE REMOVED]
; 	; program memory. [#IF CODE REMOVED]
; 	; gosub is_transmitting [#IF CODE REMOVED]
; 	; if rtrn = 1 then [#IF CODE REMOVED]
; 	; 	rtrn = 0 [#IF CODE REMOVED]
; 	; 	return [#IF CODE REMOVED]
; 	; endif [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Put into standby mode [#IF CODE REMOVED]
; 	gosub idle_lora [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Explicit header mode [#IF CODE REMOVED]
; 	; writeRegister(REG_MODEM_CONFIG_1, readRegister(REG_MODEM_CONFIG_1) & 0xfe); [#IF CODE REMOVED]
; 	param1 = REG_MODEM_CONFIG_1 [#IF CODE REMOVED]
; 	gosub read_register [#IF CODE REMOVED]
; 	param2 = rtrn & 0xfe [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; reset FIFO address and paload length [#IF CODE REMOVED]
;   	; writeRegister(REG_FIFO_ADDR_PTR, 0); [#IF CODE REMOVED]
; 	param1 = REG_FIFO_ADDR_PTR [#IF CODE REMOVED]
; 	param2 = 0 [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; writeRegister(REG_PAYLOAD_LENGTH, 0); [#IF CODE REMOVED]
; 	param1 = REG_PAYLOAD_LENGTH [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	rtrn = 1 [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; end_lora_packet: [#IF CODE REMOVED]
; 	; Finalises the packet and instructs the module to send it. [#IF CODE REMOVED]
; 	; Waits until transmission is finished (async is treated as false). [#IF CODE REMOVED]
; 	; Usage: [#IF CODE REMOVED]
; 	;	gosub end_packet [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Variables read: none [#IF CODE REMOVED]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2, [#IF CODE REMOVED]
; 	;                     start_time, [#IF CODE REMOVED]
; 	; Maximum stack depth used: 3 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; put in TX mode [#IF CODE REMOVED]
; 	; writeRegister(REG_OP_MODE, MODE_LONG_RANGE_MODE | MODE_TX); [#IF CODE REMOVED]
; 	param1 = REG_OP_MODE [#IF CODE REMOVED]
; 	param2 = MODE_LONG_RANGE_MODE | MODE_TX [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Wait for TX done [#IF CODE REMOVED]
; 	; while ((readRegister(REG_IRQ_FLAGS) & IRQ_TX_DONE_MASK) == 0) { yield(); } [#IF CODE REMOVED]
; 	start_time = time [#IF CODE REMOVED]
; end_packet_wait: [#IF CODE REMOVED]
; 	tmpwd = time - start_time [#IF CODE REMOVED]
; 	if tmpwd > LORA_TIMEOUT then ; On a breadboard, occasionally the spi seems to drop out and the chip gets stuck here. [#IF CODE REMOVED]
; 		rtrn = 0 [#IF CODE REMOVED]
; 		return [#IF CODE REMOVED]
; 	endif [#IF CODE REMOVED]
; 	param1 = REG_IRQ_FLAGS [#IF CODE REMOVED]
; 	gosub read_register [#IF CODE REMOVED]
; 	tmpwd = rtrn & IRQ_TX_DONE_MASK [#IF CODE REMOVED]
; 	if tmpwd = 0 then end_packet_wait [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; clear IRQ's [#IF CODE REMOVED]
; 	; writeRegister(REG_IRQ_FLAGS, IRQ_TX_DONE_MASK); [#IF CODE REMOVED]
; 	param1 = REG_IRQ_FLAGS [#IF CODE REMOVED]
; 	param2 = IRQ_TX_DONE_MASK [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	rtrn = 1 [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; write_lora: [#IF CODE REMOVED]
; 	; Writes a string starting at bptr that is param1 chars long [#IF CODE REMOVED]
; 	; Usage: [#IF CODE REMOVED]
; 	;     bptr = 28 ; First character in string / char array is at the byte after b27 (treating [#IF CODE REMOVED]
; 	;               ; general purpose memory as a char array). [#IF CODE REMOVED]
; 	;     param1 = 5 ; 5 bytes to add to send. [#IF CODE REMOVED]
; 	;     gosub write_lora [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Variables read: param1, bptr [#IF CODE REMOVED]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2, bptr, [#IF CODE REMOVED]
; 	;                     level, total_length, counter2 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	level = param1 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	param1 = REG_PAYLOAD_LENGTH [#IF CODE REMOVED]
; 	gosub read_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Check size [#IF CODE REMOVED]
; 	total_length = rtrn + level [#IF CODE REMOVED]
; 	if total_length > MAX_PKT_LENGTH then [#IF CODE REMOVED]
; 		level = MAX_PKT_LENGTH - rtrn [#IF CODE REMOVED]
; 	endif [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Write data [#IF CODE REMOVED]
; 	for counter2 = 1 to level [#IF CODE REMOVED]
; 		param1 = REG_FIFO [#IF CODE REMOVED]
; 		param2 = @bptrinc [#IF CODE REMOVED]
; 		; sertxd("W: ", #param2,cr, lf) [#IF CODE REMOVED]
; 		gosub write_register [#IF CODE REMOVED]
; 	next counter2 [#IF CODE REMOVED]
; 	; sertxd(cr,lf) [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Update length [#IF CODE REMOVED]
; 	param1 = REG_PAYLOAD_LENGTH [#IF CODE REMOVED]
; 	param2 = total_length [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	rtrn = level [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
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

; ; #IFDEF ENABLE_LORA_RECEIVE [#IF CODE REMOVED]
; setup_lora_receive: [#IF CODE REMOVED]
; 	; Puts the LoRa module in receiving (higher power draw) mode. [#IF CODE REMOVED]
; 	; Based off void LoRaClass::receive(int size), but no params as always using DI0 pin. [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Variables read: none [#IF CODE REMOVED]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2 [#IF CODE REMOVED]
; 	; Maximum stack depth used: 3 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; writeRegister(REG_DIO_MAPPING_1, 0x00); // DIO0 => RXDONE [#IF CODE REMOVED]
; 	param1 = REG_DIO_MAPPING_1 [#IF CODE REMOVED]
; 	param2 = 0x00 [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Note: As the size is assumed to always be 0 as the DIO0 pin is used, explicit mode only is implemented [#IF CODE REMOVED]
; 	; if (size > 0) { [#IF CODE REMOVED]
; 	;	implicitHeaderMode(); [#IF CODE REMOVED]
; 	;	writeRegister(REG_PAYLOAD_LENGTH, size & 0xff); [#IF CODE REMOVED]
; 	; } else { [#IF CODE REMOVED]
; 	;	explicitHeaderMode(); [#IF CODE REMOVED]
; 	; } [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Explicit header mode function: [#IF CODE REMOVED]
; 	; writeRegister(REG_MODEM_CONFIG_1, readRegister(REG_MODEM_CONFIG_1) & 0xfe); [#IF CODE REMOVED]
; 	param1 = REG_MODEM_CONFIG_1 [#IF CODE REMOVED]
; 	gosub read_register [#IF CODE REMOVED]
; 	param2 = rtrn & 0xFE [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; writeRegister(REG_OP_MODE, MODE_LONG_RANGE_MODE | MODE_RX_CONTINUOUS); [#IF CODE REMOVED]
; 	param1 = REG_OP_MODE [#IF CODE REMOVED]
; 	param2 = MODE_LONG_RANGE_MODE | MODE_RX_CONTINUOUS [#IF CODE REMOVED]
; 	gosub write_register [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; setup_lora_read: [#IF CODE REMOVED]
; 	; Call this when the dio0 pin on the module is high. [#IF CODE REMOVED]
; 	; Based off handleDio0Rise() [#IF CODE REMOVED]
; 	; Returns the packet length is valid or LORA_RECEIVED_CRC_ERROR [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Variables read: none [#IF CODE REMOVED]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2, level [#IF CODE REMOVED]
; 	; Maximum stack depth used: 3 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; int irqFlags = readRegister(REG_IRQ_FLAGS); [#IF CODE REMOVED]
; 	; writeRegister(REG_IRQ_FLAGS, irqFlags); // clear IRQ's [#IF CODE REMOVED]
; 	param1 = REG_IRQ_FLAGS [#IF CODE REMOVED]
; 	gosub read_register [#IF CODE REMOVED]
; 	param2 = rtrn [#IF CODE REMOVED]
; 	gosub write_register ; rtrn will be overwritten, so use param2 afterwards as needed [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; if ((irqFlags & IRQ_PAYLOAD_CRC_ERROR_MASK) == 0) { [#IF CODE REMOVED]
; 	tmpwd = param2 & IRQ_PAYLOAD_CRC_ERROR_MASK [#IF CODE REMOVED]
; 	if tmpwd = 0 then [#IF CODE REMOVED]
; 		; Asyncronous tx not implemented, so no checking if it is not because of the rx done flag. [#IF CODE REMOVED]
; 		; We have received a packet. [#IF CODE REMOVED]
; 		; Implicit header mode is not implemented. Will need to change registers here if it is. [#IF CODE REMOVED]
; 		; int packetLength = _implicitHeaderMode ? readRegister(REG_PAYLOAD_LENGTH) : readRegister(REG_RX_NB_BYTES); Read packet length [#IF CODE REMOVED]
; 		param1 = REG_RX_NB_BYTES [#IF CODE REMOVED]
; 		gosub read_register [#IF CODE REMOVED]
; 		level = rtrn [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 		; Set FIFO address to current RX address [#IF CODE REMOVED]
;       	; writeRegister(REG_FIFO_ADDR_PTR, readRegister(REG_FIFO_RX_CURRENT_ADDR)); [#IF CODE REMOVED]
; 		param1 = REG_FIFO_RX_CURRENT_ADDR [#IF CODE REMOVED]
; 		gosub read_register [#IF CODE REMOVED]
; 		param1 = REG_FIFO_ADDR_PTR [#IF CODE REMOVED]
; 		param2 = rtrn [#IF CODE REMOVED]
; 		gosub write_register [#IF CODE REMOVED]
; 		;counter3 = rtrn [#IF CODE REMOVED]
; 		rtrn = level ; Return the length of the packet [#IF CODE REMOVED]
; 	else [#IF CODE REMOVED]
; 		rtrn = LORA_RECEIVED_CRC_ERROR [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	endif [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; read_lora: [#IF CODE REMOVED]
; 	; Reads the next byte from the receiver. [#IF CODE REMOVED]
; 	; Currently does not do any checking if too many bytes have been read. [#IF CODE REMOVED]
; 	; TODO: Checking if too many bytes have been read. [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Variables read: none [#IF CODE REMOVED]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2 [#IF CODE REMOVED]
; 	; Maximum stack depth used: 3 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	param1 = REG_FIFO [#IF CODE REMOVED]
; 	gosub read_register [#IF CODE REMOVED]
; 	; sertxd("Reading: ", #rtrn, cr, lf) [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; packet_rssi: [#IF CODE REMOVED]
; 	; Returns the RSSI in 2's complement [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Variables read: none [#IF CODE REMOVED]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2 [#IF CODE REMOVED]
; 	; return (readRegister(REG_PKT_RSSI_VALUE) - (_frequency < 868E6 ? 164 : 157)); [#IF CODE REMOVED]
; 	param1 = REG_PKT_RSSI_VALUE [#IF CODE REMOVED]
; 	gosub read_register [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	#IF 433000000 < 868000000
	rtrn = rtrn - 164
; ; 	#ELSE [#IF CODE REMOVED]
; 	rtrn = rtrn - 157 [#IF CODE REMOVED]
; ; 	#ENDIF [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; packet_snr: [#IF CODE REMOVED]
; 	; Returns the SNR in 2's complement * 4 [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Variables read: none [#IF CODE REMOVED]
; 	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1 [#IF CODE REMOVED]
; 	param1 = REG_PKT_SNR_VALUE [#IF CODE REMOVED]
; 	gosub read_register [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; #ENDIF

; #IFNDEF DISABLE_LORA_SETUP
set_spreading_factor:
	; Sets the spreading factor. If not called, defaults to 7.
	; Spread factor 6 is not supported as implicit header mode is not enabled.
	; Spread factor and LDO flag are hardcoded in symbols.basinc as symbols LORA_SPREADING_FACTOR and LORA_LDO_ON
	; Usage:
	;	gosub set_spreading_factor
	;
	; Variables read: none
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2
	; Maximum stack depth used: 4

; ; #IF 9 < 7 [#IF CODE REMOVED]
; 	#ERROR "Spread factors less than 7 are not currently supported" [#IF CODE REMOVED]
; #ELSEIF 9 > 12 [#IF CODE REMOVED]
; 	#ERROR "Spread factors greater than 12 are not currently supported" [#IF CODE REMOVED]
; #ENDIF
	; TODO: Spread factor 6 implementation
	; if param1 = 6 then
	; Spread factor 6 (not implemented):
	; writeRegister(REG_DETECTION_OPTIMIZE, 0xc5);
	; writeRegister(REG_DETECTION_THRESHOLD, 0x0c);
	
	; All other spread factors
	; writeRegister(REG_DETECTION_OPTIMIZE, 0xc3);
	param1 = REG_DETECTION_OPTIMIZE
	param2 = 0xc3
	gosub write_register
	
	; writeRegister(REG_DETECTION_THRESHOLD, 0x0a);
	param1 = REG_DETECTION_THRESHOLD
	param2 = 0x0a
	gosub write_register
	
	; writeRegister(REG_MODEM_CONFIG_2, (readRegister(REG_MODEM_CONFIG_2) & 0x0f) | ((sf << 4) & 0xf0));
	param1 = REG_MODEM_CONFIG_2
	gosub read_register
	param2 = rtrn & 0x0f
	tmpwd = 9 * 16 & 0xf0
	param2 = param2 | tmpwd
	gosub write_register
	
	; setLdoFlag();
	gosub set_ldo_flag
	
	return

set_ldo_flag:
	; param1 contains the spreading factor
	; Uses the LORA_LDO_ON symbol for now. Use the included python file to calculate if this should
	; be 0 (false) or 1 (true).
	;
	; Variables read: none
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2
	; Maximum stack depth used: 3

	param1 = REG_MODEM_CONFIG_3
	gosub read_register
	
	param2 = rtrn & %11110111 ; Clear the ldo bit in case it needs to be cleared
	;tmpwd = LORA_LDO_ON
; ; #IF 0 = 1 [#IF CODE REMOVED]
; 	; if tmpwd = 1 then [#IF CODE REMOVED]
; 	param2 = param2 | %1000 ; Set the bit [#IF CODE REMOVED]
; 	; endif [#IF CODE REMOVED]
; #ENDIF
	gosub write_register
	
	return

set_tx_power:
	; PA Boost only implemented to save memory (not RFO)
	; Does NOT preserve param1!
	;
	; Variables read: param1
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2, level

	level = param1 ; Need to save param 1 for later
	if level > 17 then
		if level > 20 then
			level = 20
		endif
		
		level = level - 3 ; Map 18 - 20 to 15 - 17
		
		; High Power +20 dBm Operation (Semtech SX1276/77/78/79 5.4.3.)
      	; writeRegister(REG_PA_DAC, 0x87);
		param1 = REG_PA_DAC
		param2 = 0x87
		gosub write_register
		
      	; setOCP(140);
		param1 = 140
		gosub set_OCP
	else
		if level < 2 then
			level = 2
		endif
		
		; Default value PA_HF/LF or +17dBm
      	; writeRegister(REG_PA_DAC, 0x84);
		param1 = REG_PA_DAC
		param2 = 0x84
		gosub write_register
		
      	; setOCP(100);
		param1 = 100
		gosub set_OCP
	endif
	
	; writeRegister(REG_PA_CONFIG, PA_BOOST | (level - 2));
	param1 = REG_PA_CONFIG
	param2 = level - 2
	param2 = PA_BOOST | param2
	gosub write_register

	return

set_OCP:
	; Sets the overcurrent protection
	; param1: mA
	; Does not preserve param1
	;
	; Variables read: param1
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2
	tmpwd = 27
	
	if param1 <= 120 then
		tmpwd = param1 - 45
		tmpwd = tmpwd / 5
	elseif param1 <= 240 then
		tmpwd = param1 + 30
		tmpwd = tmpwd / 10
	endif
	
	param1 = REG_OCP
	param2 = 0x1f & tmpwd
	param2 = 0x20 | param2
	gosub write_register
	return


set_frequency:
	; Sets the frequency using the LORA_FREQ_MSB, LORA_FREQ_MID and LORA_FREQ_LSB symbols.
	; There should be a python script to calculate these.
	;
	; Variables read: none
	; Variables modified: rtrn, tmpwd, counter, mask, s_transfer_storage, param1, param2
	;
	; uint64_t frf = ((uint64_t)frequency << 19) / 32000000;
	; writeRegister(REG_FRF_MSB, (uint8_t)(frf >> 16));
	param1 = REG_FRF_MSB
	param2 = 0x6C
	gosub write_register
	
	; writeRegister(REG_FRF_MID, (uint8_t)(frf >> 8));
	param1 = REG_FRF_MID
	param2 = 0x40
	gosub write_register
	
	; writeRegister(REG_FRF_LSB, (uint8_t)(frf >> 0));
	param1 = REG_FRF_LSB
	param2 = 0x00
	gosub write_register
	return

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

'---END BatteryVoltsMonitor_slot0.bas---


'---Extras added by the preprocessor---
print_table_sertxd:
    for w6 = w6 to w7
        readtable w6, b16
        sertxd(b16)
    next w6

    return

table 0, ("Battery voltage monitor and fence control"," ","v2.0.3"," BOOTLOADER",cr,lf,"Jotham Gates, Compiled ","01-01-2025",cr,lf,"Seeing as I have lots of space in the bootloader section, here is a URL to look at:",cr,lf,"https://github.com/jgOhYeah/Farm-PJON-LoRa-network",cr,lf) ;#sertxd
table 233, ("LoRa Failed",cr,lf) ;#sertxd
table 246, ("LoRa Started",cr,lf) ;#sertxd
table 260, ("Starting slot 1...",cr,lf,cr,lf) ;#sertxd
table 282, ("Resetting...",cr,lf,cr,lf) ;#sertxd
