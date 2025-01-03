; Pump duty cycle monitor bootloader
; Designed to detect if the pump is running excessively because of a leak or lost prime.
; This program runs in slot 0 and initialises the eeprom circular buffer and proivdes debugging
; tools if needed, then starts the main program in slot 1
; Written by Jotham Gates
; Created 27/12/2020
; Modified 31/12/2024
#PICAXE 18M2
#SLOT 0
#NO_DATA

; #COM /dev/ttyUSB0
#DEFINE INCLUDE_BUFFER_INIT
#DEFINE INCLUDE_BUFFER_UPLOAD
#INCLUDE "include/PumpMonitorCommon.basinc"
#INCLUDE "include/symbols.basinc"
#INCLUDE "include/aht20.basinc"

init:
    disconnect
	setfreq m32
    high PIN_LED_ON
    high PIN_LED_ALARM

	;#sertxd("Pump Monitor ", VERSION , " BOOTLOADER", cr, lf, "Jotham Gates, Compiled ", ppp_date_uk, cr, lf)
    gosub buffer_index
    gosub buffer_backup

    pause 4000 ; Wait for a while to give the programmer a chance if need be.

    ;#sertxd("Press 't' for EEPROM tools or '`' for computers", cr, lf)
    low PIN_LED_ALARM
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
    TEMP_HUM_I2C()
    TEMP_HUM_INIT()
    TEMP_HUM_GET_STATUS(rtrnl)
    TEMP_HUM_BUSY(rtrnl)
    if rtrnl != 0 then
        ;#sertxd("AHT20 busy or NC.", cr, lf)
    endif

    ; Lora radio setup
    gosub begin_lora
	if rtrn = 0 then
		;#sertxd("LoRa Failed to connect. Will reset to try again in 15s.",cr,lf)
        high PIN_LED_ALARM
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
    RESET_STATS()
    ; Fall throught to start slot 1 if the received char wasn't "t".
	;#sertxd("Starting slot 1", cr, lf, "------", cr, lf, cr, lf)
    low PIN_LED_ON
    run 1

eeprom_main:
    ; Debugging interface
    ; Variables modified: param1, rtrn, tmpwd0, tmpwd1, tmpwd2, tmpwd3, tmpwd4
    high PIN_LED_ON
    low PIN_LED_ALARM
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
            EEPROM_SETUP(tmpwd0, tmpwd4l)
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
            ;#sertxd("Programming mode. Anything sent will reset.", cr, lf)
            reconnect
            stop
		case "q"
			sertxd("Resetting",cr, lf)
			reset
        case "h", " ", cr, lf
            ; Ignore
        else
            ;#sertxd(cr, lf, "Unknown. Please retry.", cr, lf)
    end select
	gosub print_help
    goto eeprom_main

erase:
    ; Wipes the eeprom chip
    ; Variables modified: tmpwd1, tmpwd4l
    for tmpwd1 = 0 to 2047
        toggle PIN_LED_ALARM
        EEPROM_SETUP(tmpwd1, tmpwd4l)
        hi2cout tmpwd1l, (0xFF)
        pause 80
    next tmpwd1
    return

print_help:
    ; Prints a help message with a list of available options
    ; Variables modified: none

    ; Don't have enough table memory to store all strings in there, so some still have to be part
    ; of the program.
    ;#sertxd(cr, lf, "EEPROM Tools", cr, lf, "Commands:", cr, lf, " a Read all", cr, lf, " b Read 1st block", cr, lf, " u Read buffer old to new", cr, lf, " z Add value to buffer", cr, lf, " w Write at address", cr, lf, " i Buffer info", cr, lf, " e Erase all", cr, lf, " p Enter programming mode", cr, lf, " q Reset", cr, lf, " h Show this help", cr, lf, ">>> ")
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
        EEPROM_SETUP(tmpwd2, param1l)
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
    low PIN_LED_ON
    high PIN_LED_ALARM

computer_mode_loop:
    serrxd tmpwd0l
    select case tmpwd0l
        case "r" ; Read bytes
            low PIN_LED_ALARM
            serrxd tmpwd1l, tmpwd1h, tmpwd2l, tmpwd2h ; Start and end address (inclusive) in little endian
            ; Upload everything
            high PIN_LED_ALARM
            high PIN_LED_ON
            for tmpwd0 = tmpwd1 to tmpwd2
                EEPROM_SETUP(tmpwd0, tmpwd3l)
                hi2cin tmpwd0l, (tmpwd3l)
                sertxd(tmpwd3l)
            next tmpwd0
            low PIN_LED_ON
        case "w" ; Write bytes
            low PIN_LED_ALARM
            serrxd tmpwd1l, tmpwd1h, tmpwd2l, tmpwd2h ; Start and end address (inclusive) in little endian
            ; Read everything
            high PIN_LED_ALARM
            high PIN_LED_ON
            for tmpwd0 = tmpwd1 to tmpwd2
                sertxd(1) ; Acknowledge
                EEPROM_SETUP(tmpwd0, tmpwd3l)
                serrxd tmpwd3l
                hi2cout tmpwd0l, (tmpwd3l)
                toggle PIN_LED_ON
                pause 80
            next tmpwd0
            low PIN_LED_ON
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

#INCLUDE "include/generated.basinc"
#INCLUDE "include/LoRa.basinc"
#INCLUDE "include/CircularBuffer.basinc"