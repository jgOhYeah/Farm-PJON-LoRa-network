'-----PREPROCESSED BY picaxepreprocess.py-----
'----UPDATED AT 06:27PM, December 31, 2024----
'----SAVING AS compiled_slot0.bas ----

'---BEGIN PumpMonitor_slot0.bas ---
; Pump duty cycle monitor bootloader
; Designed to detect if the pump is running excessively because of a leak or lost prime.
; This program runs in slot 0 and initialises the eeprom circular buffer and proivdes debugging
; tools if needed, then starts the main program in slot 1
; Written by Jotham Gates
; Created 27/12/2020
; Modified 31/12/2024
#PICAXE 18M2      'CHIP VERSION PARSED
#SLOT 0
#NO_DATA

; #COM /dev/ttyUSB0
; #DEFINE INCLUDE_BUFFER_INIT
; #DEFINE INCLUDE_BUFFER_UPLOAD
'---BEGIN include/PumpMonitorCommon.basinc ---
; Pump duty cycle monitor common code
; Defines and symbols shared between each slot
; Written by Jotham Gates
; Created 15/03/2021
; Modified 31/12/2024

; #DEFINE VERSION "v2.2.2"

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

; To save and restore the time at the start of the interval so that hopefully the time between calls is always 30 minutes no matter how long the call is.
; #DEFINE INTERVAL_START_BACKUP_LOC_L 121
; #DEFINE INTERVAL_START_BACKUP_LOC_H 122

; To save and restore the words used by the buffer
; #DEFINE BUFFER_START_BACKUP_LOC_L 123
; #DEFINE BUFFER_START_BACKUP_LOC_H 124
; #DEFINE BUFFER_LENGTH_BACKUP_LOC_L 125
; #DEFINE BUFFER_LENGTH_BACKUP_LOC_H 126
; #DEFINE TABLE_SERTXD_BACKUP_LOC 127 ; 5 bytes from here, defined above.

; #DEFINE MAX_TIME_LOC_L 132
; #DEFINE MAX_TIME_LOC_H 133
; #DEFINE MIN_TIME_LOC_L 134
; #DEFINE MIN_TIME_LOC_H 135
; #DEFINE SWITCH_ON_COUNT_LOC_L 132
; #DEFINE SWITCH_ON_COUNT_LOC_H 133
; #DEFINE STD_TIME_LOC_L 138 ; TODO see https://math.stackexchange.com/a/1769248 for a possible implementations
; #DEFINE STD_TIME_LOC_H 139
; #DEFINE BLOCK_ON_TIME 140
; #DEFINE BLOCK_ON_TIME 141
; #DEFINE STORE_INTERVAL_COUNT_LOC 134 ; Used to count the number of sub intervals that have elapsed.

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
	setfreq m32
    high B.6
    high B.3

;#sertxd("Pump Monitor ", "v2.2.2" , " BOOTLOADER", cr, lf, "Jotham Gates, Compiled ", "31-12-2024", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 0
rtrn = 66
gosub print_table_sertxd
    gosub buffer_index
    gosub buffer_backup

    pause 4000 ; Wait for a while to give the programmer a chance if need be.

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

start_slot_1:
    ; Go to 
    ; Initialise the temperature sensor
    '--START OF MACRO: TEMP_HUM_I2C
    hi2csetup i2cmaster, AHT20_DEF_I2C_ADDR, i2cslow_32, i2cbyte
'--END OF MACRO: TEMP_HUM_I2C()
    '--START OF MACRO: TEMP_HUM_INIT
    hi2cout (CMD_INIT, CMD_INIT_PARAMS_1ST, CMD_INIT_PARAMS_2ND)
    pause CMD_INIT_TIME
'--END OF MACRO: TEMP_HUM_INIT()
    '--START OF MACRO: TEMP_HUM_GET_STATUS
    hi2cout (CMD_STATUS)
    hi2cin (rtrnl)
'--END OF MACRO: TEMP_HUM_GET_STATUS(rtrnl)
    '--START OF MACRO: TEMP_HUM_BUSY
    rtrnl = rtrnl & 0x80
'--END OF MACRO: TEMP_HUM_BUSY(rtrnl)
    if rtrnl != 0 then
;#sertxd("AHT20 busy or NC.", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 116
rtrn = 134
gosub print_table_sertxd
    endif

    ; Lora radio setup
    gosub begin_lora
	if rtrn = 0 then
;#sertxd("LoRa Failed to connect. Will reset to try again in 15s.",cr,lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 135
rtrn = 191
gosub print_table_sertxd
        high B.3
        lora_fail = 1
        pause 60000
        sertxd("Resetting",cr, lf, "-----", cr, lf)
        reset
	else
		sertxd("LoRa Connected",cr,lf)
        lora_fail = 0
	endif
    ; Set the spreading factor
	gosub set_spreading_factor

    ; Used in slot 2
    '--START OF MACRO: RESET_STATS
	; Reset all of the above
    ; poke MAX_TIME_LOC_L, 0
    ; poke MAX_TIME_LOC_H, 0
    ; poke MIN_TIME_LOC_L, 255
    ; poke MIN_TIME_LOC_H, 255
    poke 132, 0
    poke 133, 0
'--END OF MACRO: RESET_STATS()
    ; Fall throught to start slot 1 if the received char wasn't "t".
;#sertxd("Starting slot 1", cr, lf, "------", cr, lf, cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 192
rtrn = 218
gosub print_table_sertxd
    low B.6
    run 1

eeprom_main:
    ; Debugging interface
    ; Variables modified: param1, rtrn, tmpwd0, tmpwd1, tmpwd2, tmpwd3, tmpwd4
    high B.6
    low B.3
    serrxd tmpwd4l
    sertxd(cr, lf)
    select case tmpwd4l
        case "a"
            sertxd("Printing all", cr, lf)
            for tmpwd3 = 0 to 2047 step 8
                param1 = tmpwd3
                gosub print_block
            next tmpwd3
		case "b"
			sertxd("Printing 1st 255B", cr, lf)
            for tmpwd3 = 0 to 255 step 8
                param1 = tmpwd3
                gosub print_block
            next tmpwd3
		case "u"
			sertxd("From 1st to last:", cr, lf)
			gosub buffer_upload
        case "w"
            sertxd("Enter ADDRESS: ")
            serrxd #tmpwd0
            '--START OF MACRO: EEPROM_SETUP
	; ADDR is a word
	; TMPVAR is a byte
	; I2C address
	 tmpwd4l = tmpwd0 / 128 & %00001110
	 tmpwd4l =  tmpwd4l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster,  tmpwd4l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
'--END OF MACRO: EEPROM_SETUP(tmpwd0, tmpwd4l)
            sertxd(#tmpwd0, cr, lf, "VALUE: ")
            serrxd #tmpwd4l
            hi2cout tmpwd0l, (tmpwd4l)
            sertxd(#tmpwd4l, cr, lf)
		case "z"
			sertxd("Enter VALUE: ")
            serrxd #param1
			gosub buffer_write
			sertxd(#param1, cr, lf)
		case "i"
			sertxd("# records to ave: ")
            serrxd #param1
			sertxd(#param1, cr, lf)
			gosub buffer_average
			sertxd("Ave. of ", #rtrn, " in last ", #param1, " records", cr, lf, "Total length: ", #buffer_length, " Start: ", #buffer_start, cr, lf) ; More efficient to use this than to use ;@sertxd in this case with vairables
        case "e"
            sertxd("Resetting to 255", cr, lf)
            gosub erase
        case "p"
;#sertxd("Programming mode. Anything sent will reset.", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 219
rtrn = 263
gosub print_table_sertxd
            reconnect
            stop
		case "q"
			sertxd("Resetting",cr, lf)
			reset
        case "h", " ", cr, lf
            ; Ignore
        else
;#sertxd(cr, lf, "Unknown. Please retry.", cr, lf) 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 264
rtrn = 289
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
	 tmpwd4l =  tmpwd4l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster,  tmpwd4l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
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
;#sertxd(cr, lf, "EEPROM Tools", cr, lf, "Commands:", cr, lf, " a Read all", cr, lf, " b Read 1st block", cr, lf, " u Read buffer old to new", cr, lf, " z Add value to buffer", cr, lf, " w Write at address", cr, lf, " i Buffer info", cr, lf, " e Erase all", cr, lf, " p Enter programming mode", cr, lf, " q Reset", cr, lf, " h Show this help", cr, lf, ">>> ") 'Evaluated below
gosub backup_table_sertxd ; Save the values currently in the variables
param1 = 290
rtrn = 510
gosub print_table_sertxd
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
	 param1l =  param1l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster,  param1l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
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
	 tmpwd3l =  tmpwd3l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster,  tmpwd3l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
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
	 tmpwd3l =  tmpwd3l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster,  tmpwd3l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
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
'---BEGIN include/CircularBuffer.basinc ---
; Pump duty cycle monitor circular buffer
; Handles reading and writing to and from a circular buffer in eeprom
; Written by Jotham Gates
; Created 15/03/2021
; Modified 27/01/2024
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

; #IFDEF INCLUDE_BUFFER_UPLOAD
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
; #ENDIF

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
	 tmpwd2l =  tmpwd2l | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster,  tmpwd2l, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
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

table 0, ("Pump Monitor ","v2.2.2"," BOOTLOADER",cr,lf,"Jotham Gates, Compiled ","31-12-2024",cr,lf) ;#sertxd
table 67, ("Press 't' for EEPROM tools or '`' for computers",cr,lf) ;#sertxd
table 116, ("AHT20 busy or NC.",cr,lf) ;#sertxd
table 135, ("LoRa Failed to connect. Will reset to try again in 15s.",cr,lf) ;#sertxd
table 192, ("Starting slot 1",cr,lf,"------",cr,lf,cr,lf) ;#sertxd
table 219, ("Programming mode. Anything sent will reset.",cr,lf) ;#sertxd
table 264, (cr,lf,"Unknown. Please retry.",cr,lf) ;#sertxd
table 290, (cr,lf,"EEPROM Tools",cr,lf,"Commands:",cr,lf," a Read all",cr,lf," b Read 1st block",cr,lf," u Read buffer old to new",cr,lf," z Add value to buffer",cr,lf," w Write at address",cr,lf," i Buffer info",cr,lf," e Erase all",cr,lf," p Enter programming mode",cr,lf," q Reset",cr,lf," h Show this help",cr,lf,">>> ") ;#sertxd
