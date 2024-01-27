'-----PREPROCESSED BY picaxepreprocess.py-----
'----UPDATED AT 02:06PM, January 27, 2024----
'----SAVING AS compiled_slot1.bas ----

'---BEGIN PumpMonitor_slot1.bas ---
; Pump duty cycle monitor
; Designed to detect if the pump is running excessively because of a leak or lost prime.
; Written by Jotham Gates
; Created 27/12/2020
; Modified 27/04/2024
; NOTE: Need to swap pins C.2 and B.3 from V1 as the current shunt needs to be connected to an interrupt
; capable pin (schematic should be updated to match)
; TODO: Make smaller
; TODO: Alarm reset button
#PICAXE 18M2      'CHIP VERSION PARSED
#SLOT 1
#NO_DATA

; #DEFINE DISABLE_LORA_SETUP ; Save a bit of space
; #DEFINE ENABLE_LORA_RECEIVE
; #DEFINE ENABLE_PJON_RECEIVE
; #DEFINE ENABLE_LORA_TRANSMIT
; #DEFINE ENABLE_PJON_TRANSMIT


; #DEFINE INCLUDE_BUFFER_ALARM_CHECK
'---BEGIN include/PumpMonitorCommon.basinc ---
; Pump duty cycle monitor common code
; Defines and symbols shared between each slot
; Written by Jotham Gates
; Created 15/03/2021
; Modified 27/01/2024

; #DEFINE VERSION "v2.2.0"

; #DEFINE TABLE_SERTXD_BACKUP_VARS
; #DEFINE TABLE_SERTXD_BACKUP_LOC 127 ; 5 bytes from here
; #DEFINE TABLE_SERTXD_ADDRESS_VAR param1
; #DEFINE TABLE_SERTXD_ADDRESS_VAR_L param1l
; #DEFINE TABLE_SERTXD_ADDRESS_VAR_H param1h
; #DEFINE TABLE_SERTXD_ADDRESS_END_VAR rtrn
; #DEFINE TABLE_SERTXD_ADDRESS_END_VAR_L rtrnl
; #DEFINE TABLE_SERTXD_ADDRESS_END_VAR_H rtrnh
; #DEFINE TABLE_SERTXD_TMP_BYTE param2

; #DEFINE PIN_PUMP pinC.2 ; Must be interrupt capable and PIN_PUMP_BIN must be updated to match
; #DEFINE PIN_PUMP_BIN %00000100
; #DEFINE PIN_LED_ALARM B.3 ; Swapped with PIN_PUMP for V2 due to interrupt requirements
; #DEFINE PIN_LED_ON B.6
; #DEFINE LED_ON_STATE outpinB.6 ; Used to keep track of pump status
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

; 2*30*60 = 3600 - time increments once every half second
; STORE_INTERVAL = STORE_SUB_INTERVAL * STORE_SUBS
; #DEFINE STORE_SUB_INTERVAL 600 ; Once every 5 minutes, store once per half hour.
; #DEFINE STORE_SUBS 6

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

; #DEFINE MAX_TIME_LOC_L 132
; #DEFINE MAX_TIME_LOC_H 133
; #DEFINE MIN_TIME_LOC_L 134
; #DEFINE MIN_TIME_LOC_H 135
; #DEFINE SWITCH_ON_COUNT_LOC_L 136
; #DEFINE SWITCH_ON_COUNT_LOC_H 137
; #DEFINE STD_TIME_LOC_L 138 ; TODO see https://math.stackexchange.com/a/1769248 for a possible implementations
; #DEFINE STD_TIME_LOC_H 139
; #DEFINE BLOCK_ON_TIME 140
; #DEFINE BLOCK_ON_TIME 141
; #DEFINE STORE_INTERVAL_COUNT_LOC 140 ; Used to count the number of sub intervals that have elapsed.

; #DEFINE EEPROM_ALARM_CONSECUTIVE_BLOCKS 0
; #DEFINE EEPROM_ALARM_MULT_NUM 1 ; Multiplier for the average (numerator)
; #DEFINE EEPROM_ALARM_MULT_DEN 2 ; Multiplier for the average (denominator)
; A block is counted as > baseline if (on_time > (average * multiplier) / deniminator)
; If consecutive block count is over, raise alarm.

'PARSED MACRO EEPROM_SETUP
'PARSED MACRO BACKUP_PARAMS
'PARSED MACRO RESTORE_PARAMS
'PARSED MACRO BACKUP_TMPWDS
'PARSED MACRO RESTORE_TMPWDS
'PARSED MACRO RESTORE_INTERRUPTS
'PARSED MACRO RESET_STATS
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

symbol MY_ID = 0x5A ; PJON id of this device

; Temperature and battery voltage calibration
symbol CAL_BATT_NUMERATOR = 58
symbol CAL_BATT_DENOMINATOR = 85
; ; #IFDEF ENABLE_TEMP [#IF CODE REMOVED]
; symbol CAL_TEMP_NUMERATOR = 52 [#IF CODE REMOVED]
; symbol CAL_TEMP_DENOMINATOR = 17 [#IF CODE REMOVED]
; #ENDIF

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

; #DEFINE FILE_SYMBOLS_INCLUDED ; Prove this file is included properly

'---END include/symbols.basinc---
'---BEGIN include/aht20.basinc ---
; Macros and constants for talking to an AHT20 temperature and humidity sensor
; Written by Jotham Gates
; Created 26/01/2024
; Modified 27/01/2024

symbol AHT20_DEF_I2C_ADDR = 0x70 ;0x38 ;Default I2C address of AHT20 sensor 
symbol CMD_INIT = 0xBE ;Init command
symbol CMD_INIT_PARAMS_1ST = 0x08 ;The first parameter of init command: 0x08
symbol CMD_INIT_PARAMS_2ND = 0x00 ;The second parameter of init command: 0x00
symbol CMD_INIT_TIME = 80; 10 ;Waiting time for init completion: 10ms
symbol CMD_MEASUREMENT = 0xAC ;Trigger measurement command
symbol CMD_MEASUREMENT_PARAMS_1ST = 0x33 ;The first parameter of trigger measurement command: 0x33
symbol CMD_MEASUREMENT_PARAMS_2ND = 0x00 ;The second parameter of trigger measurement command: 0x00
symbol CMD_MEASUREMENT_TIME = 640 ; 80 ;Measurement command completion time: 80ms
symbol CMD_MEASUREMENT_DATA_LEN = 6 ;Return length when the measurement command is without CRC check.
symbol CMD_MEASUREMENT_DATA_CRC_LEN = 7 ;Return data length when the measurement command is with CRC check.
symbol CMD_SOFT_RESET = 0xBA ;Soft reset command
symbol CMD_SOFT_RESET_TIME = 160 ; 20 ;Soft reset time: 20ms
symbol CMD_STATUS = 0x71 ;Get status word command

'PARSED MACRO TEMP_HUM_I2C
'PARSED MACRO TEMP_HUM_INIT
'PARSED MACRO TEMP_HUM_GET_STATUS
'PARSED MACRO TEMP_HUM_BUSY
'---END include/aht20.basinc---

init:
    disconnect
    setfreq m32 ; Seems to reset the frequency
;#sertxd("Pump Monitor ", "v2.2.0" , " MAIN", cr,lf, "Jotham Gates, Compiled ", "27-01-2024", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 0
rtrn = 60
gosub print_table_sertxd
    ; Assuming that the program in slot 0 has initialised the eeprom circular buffer for us.
    

    ; Setup monitoring
	interval_start_time = time ; Counter for when to end each 30 minute block
    block_on_time = 0
    pump_start_time = time
    ; Setup the pump and led for the current state
    if pinC.2 = 0 then
        high B.6
    else
        low B.6
    endif
    setint 0, %00000100 ; Interrupt when the pump turns on
    ; TODO: Put receiver into receiving mode and listen for incoming signals

main:
    ; Check if 30 min has passed
    tmpwd0 = time - interval_start_time
    if tmpwd0 >= 600 then
        ; Backup the current time so this point counts as t0 in the c ountdown for the next iteration
        tmpwd0 = time ; To freeze time and get lower and higher bytes
        poke 121, tmpwd0l
        poke 122, tmpwd0h

        ; Check if this is a sub interval or the main deal.
        peek 140, tmpwd0l
        inc tmpwd0l ; Poking this back in each side of the if statement so that tmpwd0l doesn't get modified accidentally.
        if tmpwd0l > 6 then
            ; Main store / analyse pump occured.
            tmpwd0l = 0
            poke 140, tmpwd0l

            ; Get the pump on time, save it to eeprom, calculate the average and send it off on radio
            gosub get_and_reset_time ; param1 is the time on in the last half hour

            ; Save to the eeprom buffer
            gosub buffer_restore
            gosub buffer_write
            gosub buffer_backup ; buffer_write changes the values
; ; #IFDEF INCLUDE_BUFFER_ALARM_CHECK [#IF CODE REMOVED]
;             gosub buffer_alarm_check ; TODO: Sort out modifying or not of rtrn and calling buffer_average before this. Also actually make this cause an alarm. [#IF CODE REMOVED]
; #ENDIF
            gosub send_status
        
        else
            ; Smaller interval. Just take the temperature and humidity readings.
            poke 140, tmpwd0l
            gosub send_short_status
        endif

        ; Restore interval_start_time to reset it after it was used for other things.
        peek 121, interval_start_timel
        peek 122, interval_start_timeh
    endif
    if pinC.4 = 1 then gosub user_interface ; Crude way to tell if something is being sent. Not enough space for a full interface.
    ; TODO: Check if a packet was received
    goto main

get_and_reset_time:
    ; Sets param1 to be the time the pump was on in the last block, safely resets the counter for
    ; the time the pump was last on and if the pump is on, makes it appear as though the pump just
    ; turned on.
    ; To reset timing
    setint off ; Stop an interrupt getting in the way

    ; If the pump is currently on, add the time from when it started to now.
    if outpinB.6 = 1 then
        block_on_time = time - pump_start_time + block_on_time ; Add to current time
    endif

    ; Copy block_on_time to somewhere else so that the time can be reset and interrupts restarted
    param1 = block_on_time

    pump_start_time = time
    block_on_time = 0

    '--START OF MACRO: RESTORE_INTERRUPTS
	; Restore interrupts
    if outpinB.6 = 1 then
        ; Pump is currently on. Resume with interrupt for when off
        setint %00000100, %00000100
    else
        ; Pump is currently off. Resume with interrupt for when on
        setint 0, %00000100
    endif
'--END OF MACRO: RESTORE_INTERRUPTS()
    return

send_status:
    ; Sends the status in a PJON Packet over LoRa
    ; param1 is the pump on time
    ; buffer_average is called from here
    ; Variables modified: rtrn, tmpwd0, tmpwd1, tmpwd2, tmpwd3, tmpwd4, param1
;#sertxd("Long status", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 61
rtrn = 73
gosub print_table_sertxd
	gosub begin_pjon_packet

    ; Pump on time
	@bptrinc = "P"
;#sertxd("Pump on time: ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 74
rtrn = 87
gosub print_table_sertxd
    sertxd(#param1)
gosub print_newline_sertxd
    rtrn = param1
    gosub add_word

    ; Average Pump on time
	@bptrinc = "a"
    param1 = 1023 ; Number of records to average
    gosub buffer_restore
    gosub buffer_average
;#sertxd("Average on time: ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 88
rtrn = 104
gosub print_table_sertxd
    sertxd(#rtrn, cr, lf)
    gosub add_word

    ; Max run time
    ; @bptrinc = "m"
    setint off
    ; NOTE: Fatal flaw with min and max is that the time should be since the pump started, not necessarily since the start of the block if the pump has been running quite a while.
    ; Thus I have disabled sending this for now
    ; peek MAX_TIME_LOC_L, rtrnl
    ; peek MAX_TIME_LOC_H, rtrnh
    ; sertxd("Max time is ", #rtrnl, cr, lf)
    ; gosub add_word

    ; ; Min run time
    ; @bptrinc = "n"
    ; peek MIN_TIME_LOC_L, rtrnl
    ; peek MIN_TIME_LOC_H, rtrnh
    ; sertxd("Min time is ", #rtrnl, cr, lf)
    ; gosub add_word

    ; Start counts
    @bptrinc = "c"
    peek 136, rtrnl
    peek 137, rtrnh
    sertxd("Switched on ", #rtrnl, " times", cr, lf)
    gosub add_word

    ; Reset all of the above
    '--START OF MACRO: RESET_STATS
	; Reset all of the above
    poke 132, 0
    poke 133, 0
    poke 134, 255
    poke 135, 255
    poke 136, 0
    poke 137, 0
'--END OF MACRO: RESET_STATS()
    '--START OF MACRO: RESTORE_INTERRUPTS
	; Restore interrupts
    if outpinB.6 = 1 then
        ; Pump is currently on. Resume with interrupt for when off
        setint %00000100, %00000100
    else
        ; Pump is currently off. Resume with interrupt for when on
        setint 0, %00000100
    endif
'--END OF MACRO: RESTORE_INTERRUPTS()
    ; Falls through.
finish_status:
    ; Add temperature and humidity
    gosub add_temp_hum

    ; Finish up
    param1 = UPSTREAM_ADDRESS
    gosub end_pjon_packet
	if rtrn = 0 then ; Something went wrong. Attempt to reinitialise the radio module.
;#sertxd("LoRa failed. Will reset in a minute to see if that helps", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 105
rtrn = 162
gosub print_table_sertxd
        lora_fail = 1
		; gosub begin_lora
        ; gosub set_spreading_factor
        high B.3
        pause 60000
;#sertxd("Resetting because LoRa failed.", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 163
rtrn = 194
gosub print_table_sertxd
        reconnect
        reset ; TODO: Jump back to slot 0 and return rather than reset - not urgent though as I haven't had a failure after using veroboard.

    endif
;#sertxd("Done sending", cr, lf, cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 195
rtrn = 210
gosub print_table_sertxd
	return

send_short_status:
    ; Sends the minimum sized status.
;#sertxd("Short status", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 211
rtrn = 224
gosub print_table_sertxd
    gosub begin_pjon_packet
    goto finish_status

add_word:
	; Adds a word to @bptr in little endian format.
	; rtrn contains the word to add (it is a word)
	@bptrinc = rtrn & 0xff
	@bptrinc = rtrn / 0xff
	return


user_interface:
    ; Print help and ask for input
;#sertxd("Uptime: ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 225
rtrn = 232
gosub print_table_sertxd
    sertxd(#time)
;#sertxd(cr, lf, "Block time: ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 233
rtrn = 246
gosub print_table_sertxd
    tmpwd0 = time - interval_start_time
    sertxd(#tmpwd0)
;#sertxd(cr, lf, "On Time (not including current start): ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 247
rtrn = 287
gosub print_table_sertxd
    sertxd(#block_on_time)
;#sertxd(cr, lf, "Options:", cr, lf, " u Upload data in buffer as csv", cr, lf, " p Programming mode", cr, lf, ">>> ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 288
rtrn = 357
gosub print_table_sertxd
    serrxd [32000, user_interface_end], tmpwd0
    sertxd(tmpwd0, cr, lf) ; Print what the user just wrote in case using a terminal that does not show it.

    ; Check what the input actually was
    select case tmpwd0
        case "u"
;#sertxd("Record,On Time", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 358
rtrn = 373
gosub print_table_sertxd
            gosub buffer_restore
            gosub buffer_upload
        case "p"
;#sertxd("Programming mode. NOT MONITORING! Anything sent resets", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 374
rtrn = 429
gosub print_table_sertxd
            high B.3
            reconnect
            stop ; Keep the clocks running so the chip will listen for a new download
        else
;#sertxd("Unknown command", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 430
rtrn = 446
gosub print_table_sertxd
    end select

user_interface_end:
;#sertxd(cr, lf, "Returning to monitoring", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 447
rtrn = 473
gosub print_table_sertxd
    return

add_temp_hum:
    ; Reads the temperature and humidity from the sensor and adds it to a packet.
    ; Modifies tmpwd0, tmpwd1, rtrn
    '--START OF MACRO: TEMP_HUM_I2C
    hi2csetup i2cmaster, AHT20_DEF_I2C_ADDR, i2cslow_32, i2cbyte
'--END OF MACRO: TEMP_HUM_I2C()
    hi2cout (CMD_MEASUREMENT, CMD_MEASUREMENT_PARAMS_1ST, CMD_MEASUREMENT_PARAMS_2ND)
    pause CMD_MEASUREMENT_TIME
    
    ; Big endian
    ; status, hum, hum, hum / temp, temp, temp, crc if requested.
    hi2cin (tmpwd0l, rtrnh, rtrnl, tmpwd0h, tmpwd1l, tmpwd1h)

    ; Unpack humidity (chucking away the bottom 4 bits as insignificant)
    rtrn = rtrn ** 100
    sertxd("Humidity: ", #rtrn, " %", cr, lf)
    @bptrinc = "H"
    gosub add_word

    ; Unpack temperature.
    ; Extract the 16MSB
    rtrnl = tmpwd1l & 0xf0 / 0x10 ; Bottom nibble of top byte.
    rtrnh = tmpwd0h & 0x0f * 0x10 + rtrnl; Top 4 bits + bottom.
    tmpwd0h = tmpwd1h & 0xf0 / 0x10 ; Bottom nibble of bottom byte.
    rtrnl = tmpwd1l & 0x0f * 0x10 + tmpwd0h; Bottom byte
    
    ; Magic conversions. Ends up as 2's complement if negative.
    rtrn = rtrn ** 2000 - 500; Already chucked out the bottom 16 bits in the low word.
    
    sertxd("Temperature: ", #rtrn, " *0.1C", cr, lf)
    @bptrinc = "T"
    gosub add_word

    return

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
	 tmpwd2l =  tmpwd2l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster,  tmpwd2l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
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
	 tmpwd2l =  tmpwd2l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster,  tmpwd2l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
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
	 tmpwd1h =  tmpwd1h | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster,  tmpwd1h, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
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
	 tmpwd1h =  tmpwd1h | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster,  tmpwd1h, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
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
	sertxd("EEPROM Buffer Start: ", #buffer_start, ", Length: ", #buffer_length, cr, lf)
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
; 	; ADDR is a word
; 	; TMPVAR is a byte
; 	; I2C address
; 	TMPVAR = ADDR / 128 & %00001110
; 	TMPVAR = TMPVAR | %10100000
;     ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
; 	hi2csetup i2cmaster, TMPVAR, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
; '--END OF MACRO: EEPROM_SETUP(tmpwd4, tmpwd2l)
; [#IF CODE REMOVED]
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
; ; #IFDEF INCLUDE_BUFFER_INIT [#IF CODE REMOVED]
; buffer_index: [#IF CODE REMOVED]
; 	; Calculates and sets buffer_length and buffer_start. [#IF CODE REMOVED]
; 	; [#IF CODE REMOVED]
; 	; Modifies variables: tmpwd0, tmpwd1, tmpwd2, buffer_length, buffer_start [#IF CODE REMOVED]
; 	; Setup [#IF CODE REMOVED]
; 	tmpwd1 = 0xFFFF ; Setup previous [#IF CODE REMOVED]
; 	buffer_length = 0 [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; 	; Iterate through all values to count those that are not blank and find the start [#IF CODE REMOVED]
; 	for tmpwd0 = 0 to 2047 step 2 [#IF CODE REMOVED]
; 		; Read the value at this address [#IF CODE REMOVED]
; 		'--START OF MACRO: EEPROM_SETUP
; 	; ADDR is a word
; 	; TMPVAR is a byte
; 	; I2C address
; 	TMPVAR = ADDR / 128 & %00001110
; 	TMPVAR = TMPVAR | %10100000
;     ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
; 	hi2csetup i2cmaster, TMPVAR, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
; '--END OF MACRO: EEPROM_SETUP(tmpwd0, tmpwd2l)
; [#IF CODE REMOVED]
; 		hi2cin tmpwd0l, (tmpwd2h, tmpwd2l) ; Get the current [#IF CODE REMOVED]
; 		; Process [#IF CODE REMOVED]
; 		if tmpwd2 != 0xFFFF then [#IF CODE REMOVED]
; 			; Non empty character. [#IF CODE REMOVED]
; 			inc buffer_length [#IF CODE REMOVED]
; 			if tmpwd1 = 0xFFFF then [#IF CODE REMOVED]
; 				; The previous char was blank so this must be the start. [#IF CODE REMOVED]
; 				buffer_start = tmpwd0 [#IF CODE REMOVED]
; 			endif [#IF CODE REMOVED]
; 		endif [#IF CODE REMOVED]
; 		tmpwd1 = tmpwd2 ; previous = current [#IF CODE REMOVED]
;     next tmpwd0 [#IF CODE REMOVED]
; 	return [#IF CODE REMOVED]
;  [#IF CODE REMOVED]
; #ENDIF
'---END include/CircularBuffer.basinc---
'---BEGIN include/generated.basinc ---
; Autogenerated by calculations.py at 2023-06-20 22:06:12
; For a FREQUENCY of 433.0MHz, a SPREAD FACTOR of 9 and a bandwidth of 125000kHz:
; #DEFINE LORA_FREQ 433000000
; #DEFINE LORA_FREQ_MSB 0x6C
; #DEFINE LORA_FREQ_MID 0x40
; #DEFINE LORA_FREQ_LSB 0x00
; #DEFINE LORA_SPREADING_FACTOR 9
; #DEFINE LORA_LDO_ON 0

; #DEFINE FILE_GENERATED_INCLUDED ; Prove this file is included properly

'---END include/generated.basinc---
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

interrupt:
    ; Start and stop pump timing. Uses the pump on led and pin as memory to tell if the pump is currently on or not.
    ; Needs to be the very last subroutine in the file
    '--START OF MACRO: BACKUP_PARAMS
	poke 140, param1l
	poke 141, param1h
	poke 142, param2
	poke 143, rtrnl
	poke 144, rtrnh
'--END OF MACRO: BACKUP_PARAMS()
    if outpinB.6 = 0 then ; NOTE: Might be an issue with variables on first line
        ; Pump just turned on.
        pump_start_time = time

        ; Increment the switch on count
        peek 136, param1l
        peek 137, param1h
        inc param1
        poke 136, param1l
        poke 137, param1h
        
        high B.6 ; Turn on the on LED and remember the pump is on
        setint %00000100, %00000100 ; Interrupt for when the pump turns off
    else
        ; Pump just turned off. Save the time to total time
        param1 = time - pump_start_time
        block_on_time = param1 + block_on_time ; Add to current time

        ; TODO
        ; ; Check maximums
        ; peek MAX_TIME_LOC_L, rtrnl
        ; peek MAX_TIME_LOC_H, rtrnh
        ; if param1 > rtrn then
        ;     poke MAX_TIME_LOC_L, param1l
        ;     poke MAX_TIME_LOC_H, param1h
        ; endif

        ; ; Check maximums
        ; peek MIN_TIME_LOC_L, rtrnl
        ; peek MIN_TIME_LOC_H, rtrnh
        ; if param1 < rtrn then
        ;     poke MIN_TIME_LOC_L, param1l
        ;     poke MIN_TIME_LOC_H, param1h
        ; endif

        ; ; TODO: Standard deviation

        low B.6 ; Turn off the LED and remember the pump is off
        setint 0, %00000100 ; Interrupt for when the pump turns on
    endif
    '--START OF MACRO: RESTORE_PARAMS
	peek 140, param1l
	peek 141, param1h
	peek 142, param2
	peek 143, rtrnl
	peek 144, rtrnh
'--END OF MACRO: RESTORE_PARAMS()
    return
'---END PumpMonitor_slot1.bas---


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

table 0, ("Pump Monitor ","v2.2.0"," MAIN",cr,lf,"Jotham Gates, Compiled ","27-01-2024",cr,lf) ;#sertxd
table 61, ("Long status",cr,lf) ;#sertxd
table 74, ("Pump on time: ") ;#sertxd
table 88, ("Average on time: ") ;#sertxd
table 105, ("LoRa failed. Will reset in a minute to see if that helps",cr,lf) ;#sertxd
table 163, ("Resetting because LoRa failed.",cr,lf) ;#sertxd
table 195, ("Done sending",cr,lf,cr,lf) ;#sertxd
table 211, ("Short status",cr,lf) ;#sertxd
table 225, ("Uptime: ") ;#sertxd
table 233, (cr,lf,"Block time: ") ;#sertxd
table 247, (cr,lf,"On Time (not including current start): ") ;#sertxd
table 288, (cr,lf,"Options:",cr,lf," u Upload data in buffer as csv",cr,lf," p Programming mode",cr,lf,">>> ") ;#sertxd
table 358, ("Record,On Time",cr,lf) ;#sertxd
table 374, ("Programming mode. NOT MONITORING! Anything sent resets",cr,lf) ;#sertxd
table 430, ("Unknown command",cr,lf) ;#sertxd
table 447, (cr,lf,"Returning to monitoring",cr,lf) ;#sertxd
print_newline_sertxd:
    sertxd(cr, lf)
    return
