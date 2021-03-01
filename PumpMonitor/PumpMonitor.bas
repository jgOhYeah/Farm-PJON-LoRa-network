; Pump duty cycle monitor
; Designed to detect if the pump is running excessively because of a leak or lost prime.
; Written by Jotham Gates
; Created 27/12/2020
; Modified 01/03/2021
#PICAXE 18M2
#NO_DATA
; #COM /dev/ttyUSB0
#DEFINE TABLE_SERTXD_BACKUP_VARS
#DEFINE TABLE_SERTXD_BACKUP_LOC 121 ; 5 bytes from here
#DEFINE TABLE_SERTXD_ADDRESS_VAR param1
#DEFINE TABLE_SERTXD_ADDRESS_VAR_L param1l
#DEFINE TABLE_SERTXD_ADDRESS_VAR_H param1h
#DEFINE TABLE_SERTXD_ADDRESS_END_VAR rtrn
#DEFINE TABLE_SERTXD_ADDRESS_END_VAR_L rtrnl
#DEFINE TABLE_SERTXD_ADDRESS_END_VAR_H rtrnh
#DEFINE TABLE_SERTXD_TMP_BYTE param2

#DEFINE ENABLE_LORA_RECEIVE
#DEFINE ENABLE_PJON_RECEIVE
#DEFINE ENABLE_LORA_TRANSMIT
#DEFINE ENABLE_PJON_TRANSMIT

#DEFINE PIN_PUMP pinB.3
#DEFINE PIN_LED_STATUS C.2
#DEFINE PIN_LED_ON B.6
#DEFINE PIN_BUTTON B.7
; #DEFINE PIN_ALARM B.2
#DEFINE PIN_I2C_SDA B.1
#DEFINE PIN_I2C_SCL B.4
#DEFINE PIN_RX pinC.4
#DEFINE PIN_TX C.3

; LoRa module
symbol SS = C.6
symbol SCK = C.0
symbol MOSI = C.7
symbol MISO = pinB.0
symbol RST = C.1
symbol DIO0 = pinC.5 ; High when a packet has been received

; 2*30*60 = 3600 - time increments once every half seconds
#DEFINE STORE_INTERVAL 3600 ; Once every 10s.
#DEFINE STATIC_THRESHOLD 3590 ; Detect if the pump is running all the time.
; (THRESHOLD * 5.555555)% over the average is the threshold for the alarm being raised
#DEFINE THRESHOLD 1
#DEFINE REENABLE_THRESHOLD 1
#DEFINE PERCENT_MULTIPLIER 18 ; Max count times this must be less than 65535. Percentage steps is 100 / PERCENT_MULTIPLIER
; For a 1 hour interval, maximum would be 3600, so 0xFFFF is way higher than what would be possible, even for longer intervals
#DEFINE BUFFER_BLANK_CHAR 0xFFFF
#DEFINE BUFFER_BLANK_CHAR_HALF 0xFF
; 2 KiB EEPROM and always have at least one space free for the start / end marker.
#DEFINE BUFFER_MAXLENGTH 2047
#DEFINE BUFFER_SIZE 2048
#DEFINE BUFFER_INVALID_ADDRESS 65535
#DEFINE DISABLE_TIME_LOC 28 ; bptr 28 and 29 to free up named registers
#DEFINE STORE_START_TIME_SECONDARY_LOCH 126 ; Spot to store stuff long term
#DEFINE STORE_START_TIME_SECONDARY_LOCL 127 ; Spot to store stuff long term
#DEFINE MINIMUM_LENGTH 12 ; Minimum length

#DEFINE DISABLE_TIME_MIN 7200
symbol disabled = bit0
symbol buffer_start = w1
symbol buffer_startl = b2
symbol buffer_starth = b3
symbol buffer_length = w2
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
symbol store_start_time = w8
symbol store_start_timel = b16
symbol store_start_timeh = b17
symbol update_start_time = w9
symbol update_start_timel = b18
symbol update_start_timeh = b19
symbol total_time = w10
symbol total_timel = b20
symbol total_timeh = b21
symbol param1 = w11
symbol param1l = b22
symbol param1h = b23
symbol param2 = b24
symbol tmpbt0 = b25
symbol rtrn = w13
symbol rtrnl = b26
symbol rtrnh = b27
#INCLUDE "include/symbols.basinc"
#MACRO EEPROM_SETUP(ADDR, TMPVAR)
	; I2C address
	TMPVAR = ADDR / 128 & %00001110
	TMPVAR = TMPVAR | %10100000
    ; sertxd(" (", #ADDR, ", ", #TMPVAR, ")")
	hi2csetup i2cmaster, TMPVAR, i2cslow_32, i2cbyte ; Reduce clock speeds when running at 3.3v
#ENDMACRO

; NOTE: Need to collect more data on what these should be
; #DEFINE NUM_THRESHOLDS 5
; #DEFINE NUM_THRESHOLDS_MIN_1 4
;   Number of hours:      1   2   6  12  24
; eeprom 0,              (2,  4, 12, 24, 48) ; Number of most recent records to average
; eeprom NUM_THRESHOLDS, (9,  7,  5,  3,  2) ; * 5.555% difference from the average of all records

init:
	setfreq m32

	;#sertxd("Pump Monitor v1.0",cr,lf, "Jotham Gates, Compiled ", ppp_date_uk, cr, lf)
    gosub buffer_index
    gosub begin_lora
	if rtrn = 0 then
		;#sertxd("LoRa Failed to connect",cr,lf)
        high PIN_LED_STATUS
	else
		;#sertxd("LoRa Connected",cr,lf)
	endif
    ; Set the spreading factor
	gosub set_spreading_factor
	store_start_time = time
	update_start_time = time
#IFDEF ENABLE_EEPROM_TOOLS
    ;#sertxd("Press 't' for EEPROM tools.")
    
	serrxd[16000, serrxd_timeout], tmpwd0l
	if tmpwd0l = "t" then
		gosub print_help
		goto eeprom_main
	endif

serrxd_timeout:
#ENDIF
	;#sertxd("Started monitoring", cr, lf)
#IFDEF ENABLE_EEPROM_TOOLS
	reconnect ; Go back into programming mode
#ENDIF
    disconnect

main:
	; Increment the time once per half second if the pump is running
	tmpwd0 = time - update_start_time
    tmpwd1 = time - store_start_time
	if tmpwd0 >= 1 then
        update_start_time = time
		if PIN_PUMP = 0 then  ; Increment total_time once per half second if the pump is on
			inc total_time
            high PIN_LED_ON
        else
            low PIN_LED_ON
		endif
        ;#sertxd("Time Elapsed (0.5s): ")
        sertxd(#tmpwd1)
        ;#sertxdnl
	endif

	; Store the total time for the block in EEPROM and check if is significantly higher.
	if tmpwd1 >= STORE_INTERVAL then
        ; store_start_time = time
        ; Treat as bytes due to bug in 18m2 compiler
        tmpwd1 = time
        poke STORE_START_TIME_SECONDARY_LOCH, tmpwd1h ; free up store_start_time
        poke STORE_START_TIME_SECONDARY_LOCL, tmpwd1l ; free up store_start_time
		param1 = total_time
        gosub buffer_write
        param1 = 1023
        gosub buffer_average ; Get the baseline to compare it to
        gosub send_status
        ; Treat as bytes due to bug in 18m2 compiler
        peek STORE_START_TIME_SECONDARY_LOCH, store_start_timeh ; Load the time alarms were disabled as we don't have enough named ram.
        peek STORE_START_TIME_SECONDARY_LOCL, store_start_timel ; Load the time alarms were disabled as we don't have enough named ram.
        update_start_time = store_start_timel ; Allows us to use update_start_Time
        total_time = 0
	endif

    if PIN_RX = 1 then ; Crude way of seeing if something sent
        gosub buffer_upload
         ; NOTE: Currently an issue with apostraphes in strings and another issue with comments on the same line
        ;#sertxd("Type ", 39, "p", 39, " to program & ", 39, "s", 39, " to send a LoRa packet", cr, lf)
        tmpwd0l = 0
        serrxd[16000], tmpwd0l
        if tmpwd0l = "p" then
            ;#sertxd("Entering programming mode.", cr, lf, "Anything sent now will cause a reset.", cr, lf)
            reconnect
            stop ; Will not respond with end
        elseif tmpwd0l = "s" then
            param1 = 1023
            gosub buffer_average
            gosub send_status ; Will send time on in last block, not actual
        endif
    endif

	goto main

#rem
alarm:
    sertxd("Alarm", cr, lf)
    high PIN_ALARM
    goto alarm_done
#endrem
buffer_upload:
	; Prints all stored data in the buffer to the serial console
	;
	; Variables modified: tmpwd0, tmpwd1, tmpwd2
	tmpwd1 = buffer_start
	for tmpwd0 = 1 to buffer_length
		EEPROM_SETUP(tmpwd1, tmpwd2l)
		hi2cin tmpwd1l, (tmpwd2h, tmpwd2l)
		sertxd(#tmpwd0, ",", #tmpwd2, cr, lf)
		tmpwd1 = tmpwd1 + 2 % BUFFER_SIZE
	next tmpwd0
	return
    

buffer_average: ; TODO: Exclude everthing above base
	; Returns the average of the contents of the buffer
    ; Based off https://www.quora.com/How-can-I-compute-the-average-of-a-large-array-of-integers-without-running-into-overflow
	; Param1 is the last number of records to average. If there are less records than this, the average of those present is returned.
    ;
    ; Variables modified: rtrn, tmpwd0, tmpwd1, tmpwd2, tmpwd3, tmpwd4, param1
	; Limit the amount read out if there is not much stored
	if param1 > buffer_length then
		param1 = buffer_length
	endif
	; Calculate the starting location
	tmpwd4 = 2 * buffer_length ; Start location
	tmpwd3 = 2 * param1 ; Attempt to get bodmas to work
	tmpwd4 = tmpwd4 - tmpwd3 + buffer_start % BUFFER_SIZE ; Adding BUFFER_SIZE so hopefully no overflow

	; Setup for finding the average
    rtrn = 0
    tmpwd0 = 0 ; Numerator
    for tmpwd1 = 1 to param1
        EEPROM_SETUP(tmpwd4, tmpwd2l)
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
		tmpwd4 = tmpwd4 + 2 % BUFFER_SIZE
    next tmpwd1
    return
	
buffer_write:
	; Appends param1 to the circular buffer. If full, deletes the earliest.
	;
	; Variables modified: tmpwd0, tmpwd1
	; Write the value to save
	; sertxd("buffer_start: ", #buffer_start, "  buffer_length: ", #buffer_length, "  BUFFER_SIZE: ", #BUFFER_SIZE, cr, lf)
	tmpwd0 = 2 * buffer_length + buffer_start % BUFFER_SIZE ; Where to write the data.
	; sertxd("Location is: ", #tmpwd0, cr, lf)
	EEPROM_SETUP(tmpwd0, tmpwd1h)
	hi2cout tmpwd0l, (param1h, param1l)
    pause 80 ; Wait for writing to be done
	; Wipe the byte after if needed so that indexing will work next time
	tmpwd0 = tmpwd0 + 2 % BUFFER_SIZE
	; sertxd("After address is: ", #tmpwd0, cr, lf)
	EEPROM_SETUP(tmpwd0, tmpwd1h)
	hi2cin tmpwd0l, (tmpwd1h, tmpwd1l)
	; sertxd("Byte after is: ", #tmpwd1)
	if tmpwd1 != BUFFER_BLANK_CHAR then
		hi2cout tmpwd0l, (BUFFER_BLANK_CHAR_HALF, BUFFER_BLANK_CHAR_HALF)
		buffer_start = buffer_start + 2 % BUFFER_SIZE
		pause 80 ; Wait for writing to be done
	else
		inc buffer_length
	endif
	return
	
buffer_index:
	; Calculates and sets buffer_length and buffer_start.
	;
	; Modifies variables: tmpwd0, tmpwd1, tmpwd2, buffer_length, buffer_start
	; Setup
	tmpwd1 = BUFFER_BLANK_CHAR ; Setup previous
	buffer_length = 0

	; Iterate through all values to count those that are not blank and find the start
	for tmpwd0 = 0 to BUFFER_MAXLENGTH step 2
		; Read the value at this address
		EEPROM_SETUP(tmpwd0, tmpwd2l)
		hi2cin tmpwd0l, (tmpwd2h, tmpwd2l) ; Get the current
		; Process
		if tmpwd2 != BUFFER_BLANK_CHAR then
			; Non empty character.
			inc buffer_length
			if tmpwd1 = BUFFER_BLANK_CHAR then
				; The previous char was blank so this must be the start.
				buffer_start = tmpwd0
			endif
		endif
		tmpwd1 = tmpwd2 ; previous = current
    next tmpwd0
	return

send_status:
    ; Variables modified: rtrn, tmpwd0, tmpwd1, tmpwd2, tmpwd3, tmpwd4, param1
	gosub begin_pjon_packet

    ; Pump on time
	@bptrinc = "P"
    EEPROM_SETUP(tmpwd1, tmpwd2l)
    param1 = rtrn
    ;#sertxd("Pump on time: ")
    sertxd(#total_time)
    rtrn = total_time
    ;#sertxdnl
    gosub add_word

    ; Average Pump on time
	@bptrinc = "a"
    rtrn = param1
    ;#sertxd("Average on time: ")
    sertxd(#rtrn)
    ;#sertxdnl
    gosub add_word

    ; Finish up
    param1 = UPSTREAM_ADDRESS
    gosub end_pjon_packet
	if rtrn = 0 then ; Something went wrong. Attempt to reinitialise the radio module.
		;#sertxd("LoRa failed to send. Will try to restart module.", cr, lf)
        pause 1000
		gosub begin_lora
        gosub set_spreading_factor
        high PIN_LED_STATUS
    endif
    ;#sertxd("Done")
	low PIN_LED_ON
	return
add_word:
	; Adds a word to @bptr in little endian format.
	; rtrn contains the word to add (it is a word)
	@bptrinc = rtrn & 0xff
	tmpwd0 = rtrn / 0xff
	@bptrinc = tmpwd0
	return


#IFDEF ENABLE_EEPROM_TOOLS
eeprom_main:
    serrxd tmpwd4l
    select case tmpwd4l
        case "a"
            sertxd(cr, lf, "Printing all", cr, lf)
            for tmpwd3 = 0 to 2047 step 8
                param1 = tmpwd3
                gosub print_block
            next tmpwd3
		case "b"
			sertxd(cr, lf, "Printing 1st 255B", cr, lf)
            for tmpwd3 = 0 to 255 step 8
                param1 = tmpwd3
                gosub print_block
            next tmpwd3
		case "u"
			sertxd("From 1st to last:", cr, lf)
			gosub buffer_upload
        case "w"
            sertxd("ADDR: ")
            serrxd #tmpwd0
            EEPROM_SETUP(tmpwd0, tmpwd4l)
            sertxd(#tmpwd0, cr, lf, "VAL: ")
            serrxd #tmpwd4l
            hi2cout tmpwd0l, (tmpwd4l)
            sertxd(#tmpwd4l, cr, lf)
		case "z"
			sertxd("VAL: ")
            serrxd #param1
			gosub buffer_write
			sertxd(#param1, cr, lf)
		case "i"
			sertxd("# records to ave: ")
            serrxd #param1
			sertxd(#param1, cr, lf)
			gosub buffer_average
			sertxd("Ave. of ", #rtrn, " in last ", #param1, " records", cr, lf)
			sertxd("Total length: ", #buffer_length, " Start: ", #buffer_start, cr, lf)
        case "e"
            sertxd("Resetting to 255", cr, lf)
            gosub erase
        case "p"
            sertxd("Programming mode. Anything sent will reset.", cr, lf)
            reconnect
            stop
		case "q"
			sertxd("Resetting",cr, lf)
			reset
        case "h", " ", cr, lf
            ; Ignore
        else
            sertxd(cr, lf, "Unknown. Pls retry.", cr, lf)
    end select
	gosub print_help
    goto eeprom_main

erase:
    for tmpwd1 = 0 to 2047
        EEPROM_SETUP(tmpwd1, tmpwd4l)
        hi2cout tmpwd1l, (0xFF)
        pause 80
    next tmpwd1
    return

print_help:
    sertxd(cr, lf, "EEPROM Tools", cr, lf)
    sertxd("Commands:", cr, lf)
    sertxd(" a Read all", cr, lf)
	sertxd(" b Read 1st block", cr, lf)
	sertxd(" u Read buffer old to new", cr, lf)
	sertxd(" z Add value to buffer", cr, lf)
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
    ; Variables modified: tmpwd0, param1, tmpwd1, tmpwd2, 
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
        EEPROM_SETUP(tmpwd2, param1)
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

#ENDIF

#INCLUDE "include/LoRa.basinc"
#INCLUDE "include/PJON.basinc"