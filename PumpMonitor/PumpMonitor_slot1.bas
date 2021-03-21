; Pump duty cycle monitor
; Designed to detect if the pump is running excessively because of a leak or lost prime.
; Written by Jotham Gates
; Created 27/12/2020
; Modified 21/03/2021
; NOTE: Need to swap pins C.2 and B.3 from V1 as the current shunt needs to be connected to an interrupt
; capable pin (schematic should be updated to match)

#PICAXE 18M2
#SLOT 1
#NO_DATA
#DEFINE VERSION "v2.0"

#INCLUDE "include/PumpMonitorCommon.basinc"
#INCLUDE "include/symbols.basinc"

init:
    ;#sertxd("Pump Monitor MAIN", VERSION, cr,lf, "Jotham Gates, Compiled ", ppp_date_uk, cr, lf)
    ; Assuming that the program in slot 0 has initialised the eeprom circular buffer for us.
    gosub begin_lora
	if rtrn = 0 then
		;#sertxd("LoRa Failed to connect",cr,lf)
        high PIN_LED_ALARM
	else
		;#sertxd("LoRa Connected",cr,lf)
	endif
    ; Set the spreading factor
	gosub set_spreading_factor

    ; Setup monitoring
	interval_start_time = time ; Counter for when to end each 30 minute block
    setint PIN_PUMP_BIN, PIN_PUMP_BIN ; Interrupt when the pump turns on


main:
    ; Check if 30 min has passed
    tmpwd0 = time - interval_start_time
    if tmpwd0 >= STORE_INTERVAL then
        ; Get the pump on time, save it to eeprom, calculate the average and send it off on radio
        gosub get_and_reset_time ; param1 is the time on in the last half hour

        ; Save to the eeprom buffer
        gosub buffer_restore
        gosub buffer_write
        gosub buffer_backup ; buffer_write changes the values
        gosub send_status

        ; TODO
    endif
    if PIN_RX = 1 then gosub user_interface ; Crude way to tell if something is being sent
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
        setint 0, PIN_PUMP_BIN
    else
        ; Pump is currently off. Resume with interrupt for when on
        setint PIN_PUMP_BIN, PIN_PUMP_BIN
    endif
    return

send_status:
    ; Sends the status in a PJON Packet over LoRa
    ; param1 is the pump on time
    ; rtrn is the pump average on time
    ; Variables modified: rtrn, tmpwd0, tmpwd1, tmpwd2, tmpwd3, tmpwd4, param1
	gosub begin_pjon_packet

    ; Pump on time
	@bptrinc = "P"
    EEPROM_SETUP(tmpwd1, tmpwd2l)
    tmpwd0 = rtrn
    ;#sertxd("Pump on time: ")
    sertxd(#param1)
    ;#sertxdnl
    rtrn = param1
    gosub add_word

    ; Average Pump on time
	@bptrinc = "a"
    rtrn = tmpwd0
    ;#sertxd("Average on time: ")
    sertxd(#rtrn)
    ;#sertxdnl
    gosub add_word

    ; Finish up
    param1 = UPSTREAM_ADDRESS
    gosub end_pjon_packet
	if rtrn = 0 then ; Something went wrong. Attempt to reinitialise the radio module.
		;#sertxd("LoRa failed. Will try to restart module.", cr, lf)
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
    tmpwd0 = time - start_time / 2
    sertxd(#tmpwd0)
    ;#sertxd("s since last transmission", cr, lf)
    ;#sertxd("Quick Commands:", cr, lf, " u Upload stored data as csv", cr, lf, " r Reset", cr, lf, " d Reset to debugging mode", cr, lf, " p Enter programming mode", cr, lf)
    pause 1000 ; Allow some time to settle and the user to stop spamming buttons to get into this menu and press the right one
    ;#sertxd("Waiting for input: ")
    serrxd [32000, user_interface_end], tmpwd0
    sertxd(tmpwd0) ; Print what the user just wrote in case using a terminal that does not show it.
    ;#sertxdnl

    ; Check what the input actually was
    select case tmpwd0
        case "u"
            ;#sertxd("Record,On Time", cr, lf)
            gosub buffer_restore
            gosub buffer_upload
        case "r"
            ;#sertxd("Resetting", cr, lf, cr, lf, cr, lf)
            debugging = 0
            reset
        case "d"
            ;#sertxd("Resetting to debugging mode", cr, lf, cr, lf, cr, lf)
            debugging = 1
            reset
        case "p"
            ;#sertxd("Entering programming mode. Anything sent now will reset", cr, lf)
            reconnect
            stop ; Keep the clocks running
        else
            ;#sertxd("Unknown command", cr, lf)
    end select

user_interface_end:
    ;#sertxd(cr, lf, "Resuming normal operation", cr, lf)
    return

#INCLUDE "include/CircularBuffer.basinc"
#INCLUDE "include/LoRa.basinc"
#INCLUDE "include/PJON.basinc"

interrupt:
    ; Start and stop pump timing. Uses the pump on led and pin as memory to tell if the pump is currently on or not.
    if LED_ON_STATE = 0 then
        ; Pump just turned on.
        pump_start_time = time
        high PIN_LED_ON ; Turn on the on LED and remember the pump is on
        setint 0, PIN_PUMP_BIN ; Interrupt for when the pump turns off
    else
        ; Pump just turned off. Save the time to total time
        block_on_time = time - pump_start_time + block_on_time ; Add to current time
        low PIN_LED_ON ; Turn off the LED and remember the pump is off
    endif
    return