'-----PREPROCESSED BY picaxepreprocess.py-----
'----UPDATED AT 07:35PM, April 05, 2021----
'----SAVING AS compiled_slot0.bas ----

'---BEGIN PumpMonitor_slot0.bas ---
; Pump duty cycle monitor bootloader
; Designed to detect if the pump is running excessively because of a leak or lost prime.
; This program runs in slot 0 and initialises the eeprom circular buffer and proivdes debugging
; tools if needed, then starts the main program in slot 1
; Written by Jotham Gates
; Created 27/12/2020
; Modified 21/03/2021
#PICAXE 18M2      'CHIP VERSION PARSED
#SLOT 0
#NO_DATA

; #COM /dev/ttyUSB0
; #DEFINE INCLUDE_BUFFER_INIT
'---BEGIN include/PumpMonitorCommon.basinc ---
; Pump duty cycle monitor common code
; Defines and symbols shared between each slot
; Written by Jotham Gates
; Created 15/03/2021
; Modified 21/03/2021

; #DEFINE VERSION "v2.0.3"

; #DEFINE TABLE_SERTXD_BACKUP_VARS
; #DEFINE TABLE_SERTXD_BACKUP_LOC 127 ; 5 bytes from here
; #DEFINE TABLE_SERTXD_ADDRESS_VAR param1
; #DEFINE TABLE_SERTXD_ADDRESS_VAR_L param1l
; #DEFINE TABLE_SERTXD_ADDRESS_VAR_H param1h
; #DEFINE TABLE_SERTXD_ADDRESS_END_VAR rtrn
; #DEFINE TABLE_SERTXD_ADDRESS_END_VAR_L rtrnl
; #DEFINE TABLE_SERTXD_ADDRESS_END_VAR_H rtrnh
; #DEFINE TABLE_SERTXD_TMP_BYTE param2

; #DEFINE ENABLE_LORA_RECEIVE
; #DEFINE ENABLE_PJON_RECEIVE
; #DEFINE ENABLE_LORA_TRANSMIT
; #DEFINE ENABLE_PJON_TRANSMIT

; #DEFINE PIN_PUMP pinC.2 ; Must be interrupt capable and PIN_PUMP_BIN must be updated to match
; #DEFINE PIN_PUMP_BIN %00000100
; #DEFINE PIN_LED_ALARM B.3 ; Swapped with PIN_PUMP for V2 due to interrupt requirements
; #DEFINE PIN_LED_ON B.6
; #DEFINE LED_ON_STATE pinB.6 ; Used to keep track of pump status
; #DEFINE PIN_BUTTON B.7
; #DEFINE PIN_I2C_SDA B.1
; #DEFINE PIN_I2C_SCL B.4
; #DEFINE PIN_RX pinC.4
; #DEFINE PIN_TX C.3

; LoRa module
symbol SS = C.6
symbol SCK = C.0
symbol MOSI = C.7
symbol MISO = pinB.0
symbol RST = C.1
symbol DIO0 = pinC.5 ; High when a packet has been received

; 2*30*60 = 3600 - time increments once every half seconds
; #DEFINE STORE_INTERVAL 3600 ; Once every 10s.

; #DEFINE BUFFER_BLANK_CHAR 0xFFFF
; #DEFINE BUFFER_BLANK_CHAR_HALF 0xFF
; 2 KiB EEPROM and always have at least one space free for the start / end marker.
; #DEFINE BUFFER_MAXLENGTH 2047
; #DEFINE BUFFER_SIZE 2048

symbol alarm = bit0
symbol lora_fail = bit1
symbol buffer_start = w1
symbol buffer_startl = b2
symbol buffer_starth = b3
symbol buffer_length = w2
symbol buffer_lengthl = b4
symbol buffer_lengthh = b5
symbol tmpwd0 = w3
symbol tmpwd0l = b6
symbol tmpwd0h = b7
symbol tmpwd1 = w4
symbol tmpwd1l = b8
symbol tmpwd1h = b9
symbol tmpwd2 = w5
symbol tmpwd2l = b10
symbol tmpwd2h = b11
symbol tmpwd3 = w6
symbol tmpwd3l = b12
symbol tmpwd3h = b13
symbol tmpwd4 = w7
symbol tmpwd4l = b14
symbol tmpwd4h = b15
symbol interval_start_time = w8
symbol interval_start_timel = b16
symbol interval_start_timeh = b17
symbol pump_start_time = w9 ; Used by interrupts. Use only for timing when the pump was switched on.
symbol pump_start_timel = b18
symbol pump_start_timeh = b19
symbol block_on_time = w10 ; Used by interrupts. Use only for counting the number of seconds the pump is on in each block.
symbol block_on_timel = b20
symbol block_on_timeh = b21
symbol param1 = w11
symbol param1l = b22
symbol param1h = b23
symbol param2 = b24
symbol tmpbt0 = b25
symbol rtrn = w13
symbol rtrnl = b26
symbol rtrnh = b27

; To save and restore the words used by the buffer
; #DEFINE BUFFER_START_BACKUP_LOC_L 123
; #DEFINE BUFFER_START_BACKUP_LOC_H 124
; #DEFINE BUFFER_LENGTH_BACKUP_LOC_L 125
; #DEFINE BUFFER_LENGTH_BACKUP_LOC_H 126

; To save and restore the time at the start of the interval so that hopefully the time between calls is always 30 minutes no matter how long the call is.
; #DEFINE INTERVAL_START_BACKUP_LOC_L 121
; #DEFINE INTERVAL_START_BACKUP_LOC_H 122

; #DEFINE EEPROM_ALARM_CONSECUTIVE_BLOCKS 0
; #DEFINE EEPROM_ALARM_MULT_NUM 1 ; Multiplier for the average (numerator)
; #DEFINE EEPROM_ALARM_MULT_DEN 2 ; Multiplier for the average (denominator)
; A block is counted as > baseline if (on_time > (average * multiplier) / deniminator)
; If consecutive block count is over, raise alarm.

'PARSED MACRO EEPROM_SETUP
'---END include/PumpMonitorCommon.basinc---
'---BEGIN include/symbols.basinc ---
; symbols.basinc
; Definitions to be used in other files
; Jotham Gates
; 22/11/2020

; Pins
; Serial
; RX = C.5
; TX = B.0

; Constants that can be set by the user
symbol LISTEN_TIME = 120 ; Listen for 60s (0.5s each) after each transmission
symbol SLEEP_TIME = 5 ; Roughly 5 mins at 26*2.3s each ; TODO: Save in eeprom and adjust OTA?
symbol RECEIVE_FLASH_INT = 1 ; Every half second

; Temperature and battery voltage calibration
symbol CAL_BATT_NUMERATOR = 58
symbol CAL_BATT_DENOMINATOR = 85
; ; #IFDEF ENABLE_TEMP [#IF CODE REMOVED]
; symbol CAL_TEMP_NUMERATOR = 52 [#IF CODE REMOVED]
; symbol CAL_TEMP_DENOMINATOR = 17 [#IF CODE REMOVED]
; #ENDIF

; #DEFINE LORA_FREQ 433000000
symbol LORA_FREQ_MSB = 0x6C ; Python script can be used to calculate these 3 bytes
symbol LORA_FREQ_MID = 0x40
symbol LORA_FREQ_LSB = 0x00
; symbol LORA_BANDWIDTH = 125000 ; Not implemented, uses default 125000
symbol LORA_LDO_ON = 0 ; Need to use the python script to calculate this for the spreading factor. Changes with spreading factor
; #DEFINE LORA_SPREADING_FACTOR 9
symbol LORA_TIMEOUT = 2 ; Number of seconds after which it is presumed the module has dropped out and should be reset.


; #DEFINE LORA_RECEIVED DIO0 = 1
symbol LORA_RECEIVED_CRC_ERROR = 65535 ; Says there is a CRC error if returned by
symbol PJON_INVALID_PACKET = 65534 ; Says the packet is invalid, not a PJON packet, or not addressed to us

symbol UPSTREAM_ADDRESS = 255 ; Address to send things to

; symbol transmit_enable = bit1
symbol mask = tmpwd0l
symbol level = tmpwd0h
symbol counter = tmpwd1l
symbol counter2 = tmpwd1h
symbol total_length = tmpwd2l
symbol s_transfer_storage = tmpwd2h ; Saves param1 duing LoRa spiing
symbol crc0 = tmpwd3l ; crcs can be used whenever a crc calculation is not required
symbol crc1 = tmpwd3h
symbol crc2 = tmpwd4l
symbol crc3 = tmpwd4h
symbol counter3 = tmpbt0
; b11, b12, b13, b1, b15, b16, b17, b18, b19 are free
symbol start_time = interval_start_time
symbol start_time_h = interval_start_timeh
symbol start_time_l = interval_start_timel
symbol tmpwd = buffer_length
; symbol param1 = b24
; symbol param2 = b25
; symbol rtrn = w13
'---END include/symbols.basinc---

init:
    disconnect
	setfreq m32
    high B.6
    high B.3

;#sertxd("Pump Monitor ", "v2.0.3" , " BOOTLOADER",cr,lf, "Jotham Gates, Compiled ", "05-04-2021", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 0
rtrn = 66
gosub print_table_sertxd
    gosub buffer_index
    gosub buffer_backup

;#sertxd("Press 't' for EEPROM tools or '`' for computers", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 67
rtrn = 115
gosub print_table_sertxd
    low B.3
	serrxd[16000, start_slot_1], tmpwd0l
	if tmpwd0l = "t" then
        gosub print_help
		goto eeprom_main
    else
        goto computer_mode
	endif
    ; Fall throught to start slot 1 if the received char wasn't "t".

start_slot_1:
    ; Go to 
;#sertxd("Starting slot 1", cr, lf, "------", cr, lf, cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 116
rtrn = 142
gosub print_table_sertxd
    low B.6
    run 1

eeprom_main:
    ; Debugging interface
    ; Variables modified: param1, rtrn, tmpwd0, tmpwd1, tmpwd2, tmpwd3, tmpwd4
    high B.6
    low B.3
    serrxd tmpwd4l
    select case tmpwd4l
        case "a"
;#sertxd(cr, lf, "Printing all", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 143
rtrn = 158
gosub print_table_sertxd
            for tmpwd3 = 0 to 2047 step 8
                param1 = tmpwd3
                gosub print_block
            next tmpwd3
		case "b"
;#sertxd(cr, lf, "Printing 1st 255B", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 159
rtrn = 179
gosub print_table_sertxd
            for tmpwd3 = 0 to 255 step 8
                param1 = tmpwd3
                gosub print_block
            next tmpwd3
		case "u"
;#sertxd("From 1st to last:", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 180
rtrn = 198
gosub print_table_sertxd
			gosub buffer_upload
        case "w"
;#sertxd("ADDRESS: ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 199
rtrn = 207
gosub print_table_sertxd
            serrxd #tmpwd0
            '--START OF MACRO: EEPROM_SETUP
	; ADDR is a word
	; TMPVAR is a byte
	; I2C address
	tmpwd4l = tmpwd0 / 128 & %00001110
	tmpwd4l = tmpwd4l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster, tmpwd4l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
'--END OF MACRO: EEPROM_SETUP(tmpwd0, tmpwd4l)
            sertxd(#tmpwd0)
;#sertxd(cr, lf, "VALUE: ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 208
rtrn = 216
gosub print_table_sertxd
            serrxd #tmpwd4l
            hi2cout tmpwd0l, (tmpwd4l)
            sertxd(#tmpwd4l, cr, lf)
		case "z"
;#sertxd("VAL: ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 217
rtrn = 221
gosub print_table_sertxd
            serrxd #param1
			gosub buffer_write
			sertxd(#param1, cr, lf)
		case "i"
;#sertxd("# records to ave: ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 222
rtrn = 239
gosub print_table_sertxd
            serrxd #param1
			sertxd(#param1, cr, lf)
			gosub buffer_average
;#sertxd("Ave. of ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 240
rtrn = 247
gosub print_table_sertxd
            sertxd(#rtrn)
;#sertxd(" in last ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 248
rtrn = 256
gosub print_table_sertxd
            sertxd(#param1)
;#sertxd(" records", cr, lf, "Total length: ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 257
rtrn = 280
gosub print_table_sertxd
            sertxd(#buffer_length)
;#sertxd(" Start: ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 281
rtrn = 288
gosub print_table_sertxd
            sertxd(#buffer_start)
gosub print_newline_sertxd
        case "e"
;#sertxd("Resetting to 255", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 289
rtrn = 306
gosub print_table_sertxd
            gosub erase
        case "p"
;#sertxd("Programming mode. Anything sent will reset.", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 307
rtrn = 351
gosub print_table_sertxd
            reconnect
            stop
		case "q"
;#sertxd("Resetting",cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 352
rtrn = 362
gosub print_table_sertxd
			reset
        case "h", " ", cr, lf
            ; Ignore
        else
;#sertxd(cr, lf, "Unknown. Please retry.", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 363
rtrn = 388
gosub print_table_sertxd
    end select
	gosub print_help
    goto eeprom_main

erase:
    ; Wipes the eeprom chip
    ; Variables modified: tmpwd1, tmpwd4l
    for tmpwd1 = 0 to 2047
        toggle B.3
        '--START OF MACRO: EEPROM_SETUP
	; ADDR is a word
	; TMPVAR is a byte
	; I2C address
	tmpwd4l = tmpwd1 / 128 & %00001110
	tmpwd4l = tmpwd4l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster, tmpwd4l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
'--END OF MACRO: EEPROM_SETUP(tmpwd1, tmpwd4l)
        hi2cout tmpwd1l, (0xFF)
        pause 80
    next tmpwd1
    return

print_help:
    ; Prints a help message with a list of available options
    ; Variables modified: none

    ; Don't have enough table memory to store all strings in there, so some still have to be part
    ; of the program.
;#sertxd(cr, lf, "EEPROM Tools", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 389
rtrn = 404
gosub print_table_sertxd
;#sertxd("Commands:", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 405
rtrn = 415
gosub print_table_sertxd
;#sertxd(" a Read all", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 416
rtrn = 428
gosub print_table_sertxd
;#sertxd(" b Read 1st block", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 429
rtrn = 447
gosub print_table_sertxd
;#sertxd(" u Read buffer old to new", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 448
rtrn = 474
gosub print_table_sertxd
;#sertxd(" z Add value to buffer", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 475
rtrn = 498
gosub print_table_sertxd
    sertxd(" w Write at address", cr, lf)
	sertxd(" i Buffer info", cr, lf)
    sertxd(" e Erase all", cr, lf)
    sertxd(" p Enter programming mode", cr, lf)
	sertxd(" q Reset", cr, lf)
    sertxd(" h Show this help", cr, lf)
    sertxd("Waiting for input: ")
    return
    

print_block:
    ; Read the 8 bytes and display them as hex
    ;
    ; Variables modified: tmpwd0, param1, tmpwd1, tmpwd2
    tmpwd0 = param1
    param1 = param1h
    gosub print_byte
    param1 = tmpwd0l
    gosub print_byte
    param1 = tmpwd0
    sertxd(": ")
    tmpwd0 = param1 + 7
    tmpwd1 = param1
    for tmpwd2 = tmpwd1 to tmpwd0
        '--START OF MACRO: EEPROM_SETUP
	; ADDR is a word
	; TMPVAR is a byte
	; I2C address
	param1l = tmpwd2 / 128 & %00001110
	param1l = param1l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster, param1l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
'--END OF MACRO: EEPROM_SETUP(tmpwd2, param1l)
        hi2cin tmpwd2l, (param1)
        gosub print_byte
        sertxd(" ")
    next tmpwd2
    sertxd(cr, lf)
    return

print_byte:
    ; Prints a byte formatted as hex stored in param1
    ;
    ; Variables modified: tmpwd4l
    tmpwd4l = param1l
    param1 = param1l / 0x10
    gosub print_digit
    param1 = tmpwd4l & 0x0F
    gosub print_digit
    param1 = tmpwd4l ; Reset param1 back to what it was
    return

print_digit:
    ; Prints a 4 bit hex digit stored in param1
    ;
    ; Variables modified: param1
    ; sertxd("(",#param1,")")
    if param1 < 0x0A then
        param1 = param1 + 0x30
    else
        param1 = param1 + 0x37
    endif
    sertxd(param1)
    return

computer_mode:
    ; Mode for interacting with a program on a computer that is not nice to look at
    ; TODO
    ; NOTE: Possibly use firmata if appropriate???
    sertxd(1)
    low B.6
    high B.3

computer_mode_loop:
    serrxd tmpwd0l
    select case tmpwd0l
        case "r" ; Read bytes
            low B.3
            serrxd tmpwd1l, tmpwd1h, tmpwd2l, tmpwd2h ; Start and end address (inclusive) in little endian
            ; Upload everything
            high B.3
            high B.6
            for tmpwd0 = tmpwd1 to tmpwd2
                '--START OF MACRO: EEPROM_SETUP
	; ADDR is a word
	; TMPVAR is a byte
	; I2C address
	tmpwd3l = tmpwd0 / 128 & %00001110
	tmpwd3l = tmpwd3l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster, tmpwd3l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
'--END OF MACRO: EEPROM_SETUP(tmpwd0, tmpwd3l)
                hi2cin tmpwd0l, (tmpwd3l)
                sertxd(tmpwd3l)
            next tmpwd0
            low B.6
        case "w" ; Write bytes
            low B.3
            serrxd tmpwd1l, tmpwd1h, tmpwd2l, tmpwd2h ; Start and end address (inclusive) in little endian
            ; Read everything
            high B.3
            high B.6
            for tmpwd0 = tmpwd1 to tmpwd2
                sertxd(1) ; Acknowledge
                '--START OF MACRO: EEPROM_SETUP
	; ADDR is a word
	; TMPVAR is a byte
	; I2C address
	tmpwd3l = tmpwd0 / 128 & %00001110
	tmpwd3l = tmpwd3l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster, tmpwd3l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
'--END OF MACRO: EEPROM_SETUP(tmpwd0, tmpwd3l)
                serrxd tmpwd3l
                hi2cout tmpwd0l, (tmpwd3l)
                toggle B.6
                pause 80
            next tmpwd0
            low B.6
            ; Done
        ; TODO: Other cases
        case "q" ; Reset
            reset
        case "p" ; Programming mode
            reconnect
            stop
        case "?" ; Query if this program is running correctly
            sertxd(1)
    end select
    goto computer_mode_loop

'---BEGIN include/CircularBuffer.basinc ---
; Pump duty cycle monitor circular buffer
; Handles reading and writing to and from a circular buffer in eeprom
; Written by Jotham Gates
; Created 15/03/2021
; Modified 15/03/2021
buffer_backup:
	; Saves buffer_start and buffer_length to storage ram so it can be used for something else
	poke 125, buffer_lengthl
	poke 126, buffer_lengthh
	poke 123, buffer_startl
	poke 124, buffer_starth
	return

buffer_restore:
	; Restores buffer_start and buffer_length from storage ram
	peek 125, buffer_lengthl
	peek 126, buffer_lengthh
	peek 123, buffer_startl
	peek 124, buffer_starth
	return

buffer_upload:
	; Prints all stored data in the buffer to the serial console as csv in the form
	; position, data
	;
	; Variables modified: tmpwd0, tmpwd1, tmpwd2
	; Variables read: buffer_start, buffer_length
	tmpwd1 = buffer_start
	for tmpwd0 = 1 to buffer_length
		'--START OF MACRO: EEPROM_SETUP
	; ADDR is a word
	; TMPVAR is a byte
	; I2C address
	tmpwd2l = tmpwd1 / 128 & %00001110
	tmpwd2l = tmpwd2l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster, tmpwd2l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
'--END OF MACRO: EEPROM_SETUP(tmpwd1, tmpwd2l)
		hi2cin tmpwd1l, (tmpwd2h, tmpwd2l)
		sertxd(#tmpwd0, ",", #tmpwd2, cr, lf)
		tmpwd1 = tmpwd1 + 2 % 2048
	next tmpwd0
	return

buffer_average: ; TODO: Exclude everthing above base
	; Returns the average of the contents of the buffer
    ; Based off https://www.quora.com/How-can-I-compute-the-average-of-a-large-array-of-integers-without-running-into-overflow
	; Param1 is the last number of records to average. If there are less records than this, the average of those present is returned.
    ;
    ; Variables modified: rtrn, tmpwd0, tmpwd1, tmpwd2, tmpwd3, tmpwd4, param1
	; Variables read: buffer_start, buffer_length
	
	; Limit the amount read out if there is not much stored
	if param1 > buffer_length then
		param1 = buffer_length
	endif
	; Calculate the starting location
	tmpwd4 = 2 * buffer_length ; Start location
	tmpwd3 = 2 * param1 ; Attempt to get bodmas to work
	tmpwd4 = tmpwd4 - tmpwd3 + buffer_start % 2048 ; Adding BUFFER_SIZE so hopefully no overflow

	; Setup for finding the average
    rtrn = 0
    tmpwd0 = 0 ; Numerator
    for tmpwd1 = 1 to param1
        '--START OF MACRO: EEPROM_SETUP
	; ADDR is a word
	; TMPVAR is a byte
	; I2C address
	tmpwd2l = tmpwd4 / 128 & %00001110
	tmpwd2l = tmpwd2l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster, tmpwd2l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
'--END OF MACRO: EEPROM_SETUP(tmpwd4, tmpwd2l)
        hi2cin tmpwd4l, (tmpwd2h, tmpwd2l)
        ; sertxd("ADDR: ", #tmpwd4, "Reading: ", #tmpwd2, " ave: ", #rtrn, " rem: ", #tmpwd0, cr, lf)
        rtrn = tmpwd2 / param1 + rtrn
        tmpwd2 = tmpwd2 % param1
        tmpwd3 = param1 - tmpwd2
        if tmpwd0 >= tmpwd3 then
            inc rtrn
            tmpwd0 = tmpwd0 - tmpwd3
        else
            tmpwd0 = tmpwd0 + tmpwd2
        endif
		tmpwd4 = tmpwd4 + 2 % 2048
    next tmpwd1
    return
	
buffer_write:
	; Appends param1 to the circular buffer. If full, deletes the earliest.
	;
	; Variables modified: tmpwd0, tmpwd1
	; Variables read: param1, buffer_start, buffer_length

	; Write the value to save
	; sertxd("buffer_start: ", #buffer_start, "  buffer_length: ", #buffer_length, "  BUFFER_SIZE: ", #BUFFER_SIZE, cr, lf)
	tmpwd0 = 2 * buffer_length + buffer_start % 2048 ; Where to write the data.
	; sertxd("Location is: ", #tmpwd0, cr, lf)
	'--START OF MACRO: EEPROM_SETUP
	; ADDR is a word
	; TMPVAR is a byte
	; I2C address
	tmpwd1h = tmpwd0 / 128 & %00001110
	tmpwd1h = tmpwd1h | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster, tmpwd1h, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
'--END OF MACRO: EEPROM_SETUP(tmpwd0, tmpwd1h)
	hi2cout tmpwd0l, (param1h, param1l)
    pause 80 ; Wait for writing to be done
	; Wipe the byte after if needed so that indexing will work next time
	tmpwd0 = tmpwd0 + 2 % 2048
	; sertxd("After address is: ", #tmpwd0, cr, lf)
	'--START OF MACRO: EEPROM_SETUP
	; ADDR is a word
	; TMPVAR is a byte
	; I2C address
	tmpwd1h = tmpwd0 / 128 & %00001110
	tmpwd1h = tmpwd1h | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster, tmpwd1h, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
'--END OF MACRO: EEPROM_SETUP(tmpwd0, tmpwd1h)
	hi2cin tmpwd0l, (tmpwd1h, tmpwd1l)
	; sertxd("Byte after is: ", #tmpwd1)
	if tmpwd1 != 0xFFFF then
		hi2cout tmpwd0l, (0xFF, 0xFF)
		buffer_start = buffer_start + 2 % 2048
		pause 80 ; Wait for writing to be done
	else
		inc buffer_length
	endif
	sertxd("Start: ", #buffer_start, ", Length: ", #buffer_length, cr, lf)
	return

; ; #IFDEF INCLUDE_BUFFER_ALARM_CHECK [#IF CODE REMOVED]
; buffer_alarm_check: [#IF CODE REMOVED]
; 	; Checks if the previous x elements are above the allowed threshold. If so, alarm = 1, else alarm = 0 [#IF CODE REMOVED]
;     ; rtrn is the average from buffer_average [#IF CODE REMOVED]
;     ; Variables modified: rtrn, tmpwd0, tmpwd1, tmpwd2, tmpwd3, tmpwd4 [#IF CODE REMOVED]
; 	; Variables read: buffer_start, buffer_length [#IF CODE REMOVED]
; 	; TODO: Update variables [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Read the number of blocks to check [#IF CODE REMOVED]
; 	read 0, tmpwd0 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Calculate the starting location [#IF CODE REMOVED]
; 	tmpwd4 = 2 * buffer_length ; Start location [#IF CODE REMOVED]
; 	tmpwd3 = 2 * param1 ; Attempt to get bodmas to work [#IF CODE REMOVED]
; 	tmpwd4 = tmpwd4 - tmpwd3 + buffer_start % 2048 ; Adding BUFFER_SIZE so hopefully no overflow [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Get the multiplier for being above the threshold [#IF CODE REMOVED]
; 	read 1, tmpwd3l [#IF CODE REMOVED]
; 	read 2, tmpwd3h [#IF CODE REMOVED]
; 	rtrn = rtrn * tmpwd3l / tmpwd3h ; Multiply to get the threshold [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Iterate over the last X blocks [#IF CODE REMOVED]
;     for tmpwd1 = 1 to tmpwd0 [#IF CODE REMOVED]
;         '--START OF MACRO: EEPROM_SETUP
	; ADDR is a word
	; TMPVAR is a byte
	; I2C address
	tmpwd2l = tmpwd4 / 128 & %00001110
	tmpwd2l = tmpwd2l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster, tmpwd2l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
'--END OF MACRO: EEPROM_SETUP(tmpwd4, tmpwd2l) [#IF CODE REMOVED]
;         hi2cin tmpwd4l, (tmpwd2h, tmpwd2l) [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 		; If tmpwd2 is not out of bounds, there is no alarm, return [#IF CODE REMOVED]
; 		if tmpwd2 <= rtrn then [#IF CODE REMOVED]
; 			; A least one of the last X blocks was below the threshold. Therefore no alarm. [#IF CODE REMOVED]
; 			alarm = 0 [#IF CODE REMOVED]
; 			return [#IF CODE REMOVED]
; 		endif [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 		tmpwd4 = tmpwd4 + 2 % 2048 [#IF CODE REMOVED]
;     next tmpwd1 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; If we got to this point, all of the last X blocks were over the threshold, so raise the alarm [#IF CODE REMOVED]
; 	alarm = 1 [#IF CODE REMOVED]
;     return [#IF CODE REMOVED]
; #ENDIF

; Thinking about having a bootloader that does initialisation so indexing does not have to be done later.
; #IFDEF INCLUDE_BUFFER_INIT
buffer_index:
	; Calculates and sets buffer_length and buffer_start.
	;
	; Modifies variables: tmpwd0, tmpwd1, tmpwd2, buffer_length, buffer_start
	; Setup
	tmpwd1 = 0xFFFF ; Setup previous
	buffer_length = 0

	; Iterate through all values to count those that are not blank and find the start
	for tmpwd0 = 0 to 2047 step 2
		; Read the value at this address
		'--START OF MACRO: EEPROM_SETUP
	; ADDR is a word
	; TMPVAR is a byte
	; I2C address
	tmpwd2l = tmpwd0 / 128 & %00001110
	tmpwd2l = tmpwd2l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster, tmpwd2l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
'--END OF MACRO: EEPROM_SETUP(tmpwd0, tmpwd2l)
		hi2cin tmpwd0l, (tmpwd2h, tmpwd2l) ; Get the current
		; Process
		if tmpwd2 != 0xFFFF then
			; Non empty character.
			inc buffer_length
			if tmpwd1 = 0xFFFF then
				; The previous char was blank so this must be the start.
				buffer_start = tmpwd0
			endif
		endif
		tmpwd1 = tmpwd2 ; previous = current
    next tmpwd0
	return

; #ENDIF
'---END include/CircularBuffer.basinc---

'---END PumpMonitor_slot0.bas---


'---Extras added by the preprocessor---
backup_table_sertxd:
    poke 127, param2
    poke 128, param1l
    poke 129, param1h
    poke 130, rtrnl
    poke 131, rtrnh
    return

print_table_sertxd:
    for param1 = param1 to rtrn
    readtable param1, param2
    sertxd(param2)
next param1

    peek 127, param2
    peek 128, param1l
    peek 129, param1h
    peek 130, rtrnl
    peek 131, rtrnh
    return

table 0, ("Pump Monitor ","v2.0.3"," BOOTLOADER",cr,lf,"Jotham Gates, Compiled ","05-04-2021",cr,lf) ;#sertxd
table 67, ("Press 't' for EEPROM tools or '`' for computers",cr,lf) ;#sertxd
table 116, ("Starting slot 1",cr,lf,"------",cr,lf,cr,lf) ;#sertxd
table 143, (cr,lf,"Printing all",cr,lf) ;#sertxd
table 159, (cr,lf,"Printing 1st 255B",cr,lf) ;#sertxd
table 180, ("From 1st to last:",cr,lf) ;#sertxd
table 199, ("ADDRESS: ") ;#sertxd
table 208, (cr,lf,"VALUE: ") ;#sertxd
table 217, ("VAL: ") ;#sertxd
table 222, ("# records to ave: ") ;#sertxd
table 240, ("Ave. of ") ;#sertxd
table 248, (" in last ") ;#sertxd
table 257, (" records",cr,lf,"Total length: ") ;#sertxd
table 281, (" Start: ") ;#sertxd
table 289, ("Resetting to 255",cr,lf) ;#sertxd
table 307, ("Programming mode. Anything sent will reset.",cr,lf) ;#sertxd
table 352, ("Resetting",cr,lf) ;#sertxd
table 363, (cr,lf,"Unknown. Please retry.",cr,lf) ;#sertxd
table 389, (cr,lf,"EEPROM Tools",cr,lf) ;#sertxd
table 405, ("Commands:",cr,lf) ;#sertxd
table 416, (" a Read all",cr,lf) ;#sertxd
table 429, (" b Read 1st block",cr,lf) ;#sertxd
table 448, (" u Read buffer old to new",cr,lf) ;#sertxd
table 475, (" z Add value to buffer",cr,lf) ;#sertxd
print_newline_sertxd:
    sertxd(cr, lf)
    return
