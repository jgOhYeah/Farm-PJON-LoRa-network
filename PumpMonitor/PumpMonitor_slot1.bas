; Pump duty cycle monitor
; Designed to detect if the pump is running excessively because of a leak or lost prime.
; Written by Jotham Gates
; Created 27/12/2020
; Modified 21/03/2021
; NOTE: Need to swap pins C.2 and B.3 from V1 as the current shunt needs to be connected to an interrupt
; capable pin (schematic should be updated to match)
; TODO: Make smaller
#PICAXE 18M2
#SLOT 1
#NO_DATA

#DEFINE INCLUDE_BUFFER_ALARM_CHECK
#INCLUDE "include/PumpMonitorCommon.basinc"
#INCLUDE "include/symbols.basinc"

init:
    disconnect
    setfreq m32 ; Seems to reset the frequency
    ;#sertxd("Pump Monitor ", VERSION , " MAIN", cr,lf, "Jotham Gates, Compiled ", ppp_date_uk, cr, lf)
    sertxd(#buffer_length, ", ", #buffer_start, cr, lf)
    ; Assuming that the program in slot 0 has initialised the eeprom circular buffer for us.
    gosub begin_lora
	if rtrn = 0 then
		;#sertxd("LoRa Failed to connect",cr,lf)
        high PIN_LED_ALARM
        lora_fail = 1
	else
		;#sertxd("LoRa Connected",cr,lf)
        lora_fail = 0
	endif
    ; Set the spreading factor
	gosub set_spreading_factor

    ; Setup monitoring
	interval_start_time = time ; Counter for when to end each 30 minute block
    ; Setup the pump and led for the current state
    if PIN_PUMP = 1 then
        high PIN_LED_ON
    else
        low PIN_LED_ON
    endif
    setint 0, PIN_PUMP_BIN ; Interrupt when the pump turns on
    ; TODO: Put receiver into receiving mode and listen for incoming signals

main:
    ; Check if 30 min has passed
    tmpwd0 = time - interval_start_time
    if tmpwd0 >= STORE_INTERVAL then
        ; Backup the current time so this point counts as t0 in the c ountdown for the next iteration
        tmpwd0 = time ; To freeze time and get lower and higher bytes
        poke INTERVAL_START_BACKUP_LOC_L, tmpwd0l
        poke INTERVAL_START_BACKUP_LOC_H, tmpwd0h

        ; Get the pump on time, save it to eeprom, calculate the average and send it off on radio
        gosub get_and_reset_time ; param1 is the time on in the last half hour

        ; Save to the eeprom buffer
        gosub buffer_restore
        gosub buffer_write
        gosub buffer_backup ; buffer_write changes the values
        gosub buffer_alarm_check ; TODO: Sort out modifying or not of rtrn and calling buffer_average before this
        gosub send_status

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

    ; Restore interrupts
    if LED_ON_STATE = 1 then
        ; Pump is currently on. Resume with interrupt for when off
        setint PIN_PUMP_BIN, PIN_PUMP_BIN
    else
        ; Pump is currently off. Resume with interrupt for when on
        setint 0, PIN_PUMP_BIN
    endif
    return

send_status:
    ; Sends the status in a PJON Packet over LoRa
    ; param1 is the pump on time
    ; buffer_average is called from here
    ; Variables modified: rtrn, tmpwd0, tmpwd1, tmpwd2, tmpwd3, tmpwd4, param1
	gosub begin_pjon_packet

    ; Pump on time
	@bptrinc = "P"
    EEPROM_SETUP(tmpwd1, tmpwd2l)
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
    sertxd(#rtrn)
    ;#sertxdnl
    gosub add_word

    ; Finish up
    param1 = UPSTREAM_ADDRESS
    gosub end_pjon_packet
	if rtrn = 0 then ; Something went wrong. Attempt to reinitialise the radio module.
		;#sertxd("LoRa failed.", cr, lf)
        lora_fail = 1
        pause 1000
		gosub begin_lora
        gosub set_spreading_factor
        high PIN_LED_ALARM
    endif
    ;#sertxd("Done sending")
	return

add_word:
	; Adds a word to @bptr in little endian format.
	; rtrn contains the word to add (it is a word)
	@bptrinc = rtrn & 0xff
	@bptrinc = rtrn / 0xff
	return


user_interface:
    ; Print help and ask for input
    sertxd(#time)
    ;#sertxd(cr, lf, "u=Upload, p=Prog: ")
    serrxd [32000, user_interface_end], tmpwd0
    sertxd(tmpwd0, cr, lf) ; Print what the user just wrote in case using a terminal that does not show it.

    ; Check what the input actually was
    select case tmpwd0
        case "u"
            ;#sertxd("Record,On Time", cr, lf)
            gosub buffer_restore
            gosub buffer_upload
        case "p"
            ;#sertxd("Programming mode. Anything sent resets", cr, lf)
            reconnect
            stop ; Keep the clocks running
        else
            ;#sertxd("Unknown", cr, lf)
    end select

user_interface_end:
    ;#sertxd(cr, lf, "Returning", cr, lf)
    return


#INCLUDE "include/CircularBuffer.basinc"
#INCLUDE "include/LoRa.basinc"
#INCLUDE "include/PJON.basinc"

interrupt:
    ; Start and stop pump timing. Uses the pump on led and pin as memory to tell if the pump is currently on or not.
    if LED_ON_STATE = 0 then ; NOTE: Might be an issue with variables on first line
        ; Pump just turned on.
        pump_start_time = time
        high PIN_LED_ON ; Turn on the on LED and remember the pump is on
        setint PIN_PUMP_BIN, PIN_PUMP_BIN ; Interrupt for when the pump turns off
    else
        ; Pump just turned off. Save the time to total time
        block_on_time = time - pump_start_time + block_on_time ; Add to current time
        low PIN_LED_ON ; Turn off the LED and remember the pump is off
        setint 0, PIN_PUMP_BIN ; Interrupt for when the pump turns on
    endif
    return