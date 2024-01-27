; Pump duty cycle monitor
; Designed to detect if the pump is running excessively because of a leak or lost prime.
; Written by Jotham Gates
; Created 27/12/2020
; Modified 27/04/2024
; NOTE: Need to swap pins C.2 and B.3 from V1 as the current shunt needs to be connected to an interrupt
; capable pin (schematic should be updated to match)
; TODO: Make smaller
; TODO: Alarm reset button
#PICAXE 18M2
#SLOT 1
#NO_DATA

#DEFINE DISABLE_LORA_SETUP ; Save a bit of space
#DEFINE ENABLE_LORA_RECEIVE
#DEFINE ENABLE_PJON_RECEIVE
#DEFINE ENABLE_LORA_TRANSMIT
#DEFINE ENABLE_PJON_TRANSMIT


; #DEFINE INCLUDE_BUFFER_ALARM_CHECK
#INCLUDE "include/PumpMonitorCommon.basinc"
#INCLUDE "include/symbols.basinc"
#INCLUDE "include/aht20.basinc"

init:
    disconnect
    setfreq m32 ; Seems to reset the frequency
    ;#sertxd("Pump Monitor ", VERSION , " MAIN", cr,lf, "Jotham Gates, Compiled ", ppp_date_uk, cr, lf)
    ; Assuming that the program in slot 0 has initialised the eeprom circular buffer for us.
    

    ; Setup monitoring
	interval_start_time = time ; Counter for when to end each 30 minute block
    block_on_time = 0
    pump_start_time = time
    ; Setup the pump and led for the current state
    if PIN_PUMP = 0 then
        high PIN_LED_ON
    else
        low PIN_LED_ON
    endif
    setint 0, PIN_PUMP_BIN ; Interrupt when the pump turns on
    ; TODO: Put receiver into receiving mode and listen for incoming signals

main:
    ; Check if 30 min has passed
    tmpwd0 = time - interval_start_time
    if tmpwd0 >= STORE_SUB_INTERVAL then
        ; Backup the current time so this point counts as t0 in the c ountdown for the next iteration
        tmpwd0 = time ; To freeze time and get lower and higher bytes
        poke INTERVAL_START_BACKUP_LOC_L, tmpwd0l
        poke INTERVAL_START_BACKUP_LOC_H, tmpwd0h

        ; Check if this is a sub interval or the main deal.
        peek STORE_INTERVAL_COUNT_LOC, tmpwd0l
        inc tmpwd0l ; Poking this back in each side of the if statement so that tmpwd0l doesn't get modified accidentally.
        if tmpwd0l >= STORE_SUBS then
            ; Main store / analyse pump occured.
            tmpwd0l = 0
            poke STORE_INTERVAL_COUNT_LOC, tmpwd0l

            ; Get the pump on time, save it to eeprom, calculate the average and send it off on radio
            gosub get_and_reset_time ; param1 is the time on in the last half hour

            ; Save to the eeprom buffer
            gosub buffer_restore
            gosub buffer_write
            gosub buffer_backup ; buffer_write changes the values
#IFDEF INCLUDE_BUFFER_ALARM_CHECK
            gosub buffer_alarm_check ; TODO: Sort out modifying or not of rtrn and calling buffer_average before this. Also actually make this cause an alarm.
#ENDIF
            gosub send_status
        
        else
            ; Smaller interval. Just take the temperature and humidity readings.
            poke STORE_INTERVAL_COUNT_LOC, tmpwd0l

            ; Check if sensor is actually connected.
            TEMP_HUM_I2C()
            TEMP_HUM_GET_STATUS(tmpwd0l)
            TEMP_HUM_BUSY(tmpwd0l)
            if tmpwd0l = 0 then
                ; Not busy and communicating ok.
                gosub send_short_status
            else
                ;#sertxd("AHT20 busy", cr, lf)
                TEMP_HUM_INIT()
            endif
        endif

        ; Restore interval_start_time to reset it after it was used for other things.
        peek INTERVAL_START_BACKUP_LOC_L, interval_start_timel
        peek INTERVAL_START_BACKUP_LOC_H, interval_start_timeh
    endif
    if PIN_RX = 1 then gosub user_interface ; Crude way to tell if something is being sent. Not enough space for a full interface.
    ; TODO: Check if a packet was received
    goto main

get_and_reset_time:
    ; Sets param1 to be the time the pump was on in the last block, safely resets the counter for
    ; the time the pump was last on and if the pump is on, makes it appear as though the pump just
    ; turned on.
    ; To reset timing
    setint off ; Stop an interrupt getting in the way

    ; If the pump is currently on, add the time from when it started to now.
    if LED_ON_STATE = 1 then
        block_on_time = time - pump_start_time + block_on_time ; Add to current time
    endif

    ; Copy block_on_time to somewhere else so that the time can be reset and interrupts restarted
    param1 = block_on_time

    pump_start_time = time
    block_on_time = 0

    RESTORE_INTERRUPTS()
    return

send_status:
    ; Sends the status in a PJON Packet over LoRa
    ; param1 is the pump on time
    ; buffer_average is called from here
    ; Variables modified: rtrn, tmpwd0, tmpwd1, tmpwd2, tmpwd3, tmpwd4, param1
    ;#sertxd("Long status", cr, lf)
	gosub begin_pjon_packet

    ; Pump on time
	@bptrinc = "P"
    ;#sertxd("Pump on time: ")
    sertxd(#param1)
    ;#sertxdnl
    rtrn = param1
    gosub add_word

    ; Average Pump on time
	@bptrinc = "a"
    param1 = 1023 ; Number of records to average
    gosub buffer_restore
    gosub buffer_average
    ;#sertxd("Average on time: ")
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
    peek SWITCH_ON_COUNT_LOC_L, rtrnl
    peek SWITCH_ON_COUNT_LOC_H, rtrnh
    sertxd("Switched on ", #rtrnl, " times", cr, lf)
    gosub add_word

    ; Reset all of the above
    RESET_STATS()
    RESTORE_INTERRUPTS()
    ; Falls through.
finish_status:
    ; Add temperature and humidity
    gosub add_temp_hum

    ; Finish up
    param1 = UPSTREAM_ADDRESS
    gosub end_pjon_packet
	if rtrn = 0 then ; Something went wrong. Attempt to reinitialise the radio module.
		;#sertxd("LoRa failed. Will reset in a minute to see if that helps", cr, lf)
        lora_fail = 1
		; gosub begin_lora
        ; gosub set_spreading_factor
        high PIN_LED_ALARM
        pause 60000
        ;#sertxd("Resetting because LoRa failed.", cr, lf)
        reconnect
        reset ; TODO: Jump back to slot 0 and return rather than reset - not urgent though as I haven't had a failure after using veroboard.

    endif
    ;#sertxd("Done sending", cr, lf, cr, lf)
	return

send_short_status:
    ; Sends the minimum sized status.
    ;#sertxd("Short status", cr, lf)
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
    ;#sertxd("Uptime: ")
    sertxd(#time)
    ;#sertxd(cr, lf, "Block time: ")
    tmpwd0 = time - interval_start_time
    sertxd(#tmpwd0)
    ;#sertxd(cr, lf, "On Time (not including current start): ")
    sertxd(#block_on_time)
    ;#sertxd(cr, lf, "Options (more available in bootloader):", cr, lf, " p Programming mode", cr, lf, ">>> ")
    serrxd [32000, user_interface_end], tmpwd0
    sertxd(tmpwd0, cr, lf) ; Print what the user just wrote in case using a terminal that does not show it.

    ; Check what the input actually was
    select case tmpwd0
        case "p"
            ;#sertxd("Programming mode. NOT MONITORING! Anything sent resets", cr, lf)
            high PIN_LED_ALARM
            reconnect
            stop ; Keep the clocks running so the chip will listen for a new download
        else
            ;#sertxd("Unknown command", cr, lf)
    end select

user_interface_end:
    ;#sertxd(cr, lf, "Returning to monitoring", cr, lf)
    return

add_temp_hum:
    ; Reads the temperature and humidity from the sensor and adds it to a packet.
    ; Modifies tmpwd0, tmpwd1, tmpwd2, rtrn, tmpbt0
    TEMP_HUM_I2C()
    hi2cout (CMD_MEASUREMENT, CMD_MEASUREMENT_PARAMS_1ST, CMD_MEASUREMENT_PARAMS_2ND)
    pause CMD_MEASUREMENT_TIME
    
    ; Big endian
    ; status, hum, hum, hum / temp, temp, temp, crc.
    hi2cin (tmpwd0l, tmpwd2h, tmpwd2l, tmpwd0h, tmpwd1l, tmpwd1h, tmpbt0)

    ; Check the checksum. (fall through)
compute_aht20_crc8:
    ; Different from PJON. Computes the CRC8 for verifying temperatue and humidity readings.
    ; rtrnl contains the result. rtrnl and rtrnh are modified.
    rtrnl = 0xff ; CRC Value
    
    ; Using an unrolled loop so I don't need to use indexing.
    rtrnl = rtrnl ^ tmpwd0l
    gosub aht20_crc8_roll
    rtrnl = rtrnl ^ tmpwd2h
    gosub aht20_crc8_roll
    rtrnl = rtrnl ^ tmpwd2l
    gosub aht20_crc8_roll
    rtrnl = rtrnl ^ tmpwd0h
    gosub aht20_crc8_roll
    rtrnl = rtrnl ^ tmpwd1l
    gosub aht20_crc8_roll
    rtrnl = rtrnl ^ tmpwd1h
    gosub aht20_crc8_roll
    ; Finished calculations. Fall through to save memory.

compute_aht20_crc8_return:
    ; Check that the busy flag and calibrated bits are set correctly:
    tmpwd0l = tmpwd0l & 0x88
    if rtrnl = tmpbt0 and tmpwd0l = 0x08 then
        ; Matches
        ; Unpack humidity (chucking away the bottom 4 bits as insignificant)
        tmpwd2 = tmpwd2 ** 100
        @bptrinc = "H"
        @bptrinc = tmpwd2l ; Single byte only.

        ; Unpack temperature.
        ; Extract the 16MSB
        rtrnl = tmpwd1l & 0xf0 / 0x10 ; Bottom nibble of top byte.
        rtrnh = tmpwd0h & 0x0f * 0x10 + rtrnl; Top 4 bits + bottom.
        tmpwd0h = tmpwd1h & 0xf0 / 0x10 ; Bottom nibble of bottom byte.
        rtrnl = tmpwd1l & 0x0f * 0x10 + tmpwd0h; Bottom byte
        
        ; Magic conversions. Ends up as 2's complement if negative.
        rtrn = rtrn ** 2000 - 500; Already chucked out the bottom 16 bits in the low word.
        
        sertxd("Temp: ", #rtrn, " *0.1C", cr, lf, "Humid: ", #tmpwd2l, " %", cr, lf)
        @bptrinc = "T"
        gosub add_word
    else
        ; Checksum didn't match. Try to initialise for next time.
        ;#sertxd("AHT20 CRC fail, busy or not initialised.", cr, lf)
        TEMP_HUM_INIT()
    endif
    return

aht20_crc8_roll:
    ; rtrnl contains the current crc to be operated on.
    ; rtrnh is modified.
    for rtrnh = 1 to 8
        if rtrnl >= 0x80 then
            ; Same as if (rtrnl & 0x80)
            rtrnl = rtrnl * 2 ^ 0x31
        else
            rtrnl = rtrnl * 2
        endif
    next rtrnh
    return

#INCLUDE "include/CircularBuffer.basinc"
#INCLUDE "include/generated.basinc"
#INCLUDE "include/LoRa.basinc"
#INCLUDE "include/PJON.basinc"

interrupt:
    ; Start and stop pump timing. Uses the pump on led and pin as memory to tell if the pump is currently on or not.
    ; Needs to be the very last subroutine in the file
    BACKUP_PARAMS()
    if LED_ON_STATE = 0 then ; NOTE: Might be an issue with variables on first line
        ; Pump just turned on.
        pump_start_time = time

        ; Increment the switch on count
        peek SWITCH_ON_COUNT_LOC_L, param1l
        peek SWITCH_ON_COUNT_LOC_H, param1h
        inc param1
        poke SWITCH_ON_COUNT_LOC_L, param1l
        poke SWITCH_ON_COUNT_LOC_H, param1h
        
        high PIN_LED_ON ; Turn on the on LED and remember the pump is on
        setint PIN_PUMP_BIN, PIN_PUMP_BIN ; Interrupt for when the pump turns off
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

        low PIN_LED_ON ; Turn off the LED and remember the pump is off
        setint 0, PIN_PUMP_BIN ; Interrupt for when the pump turns on
    endif
    RESTORE_PARAMS()
    return