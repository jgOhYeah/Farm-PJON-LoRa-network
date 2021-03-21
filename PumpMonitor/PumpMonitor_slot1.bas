; Pump duty cycle monitor
; Designed to detect if the pump is running excessively because of a leak or lost prime.
; Written by Jotham Gates
; Created 27/12/2020
; Modified 15/03/2021
#PICAXE 18M2
#SLOT 1
#NO_DATA
#DEFINE VERSION = "v2.0"

#INCLUDE "include/PumpMonitorCommon.basinc"
#INCLUDE "include/symbols.basinc"

init:
    ;#sertxd("Pump Monitor MAIN", VERSION, cr,lf, "Jotham Gates, Compiled ", ppp_date_uk, cr, lf)
    ; Assuming that the program in slot 0 has initialised the eeprom circular buffer for us.
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

main:



#INCLUDE "include/CircularBuffer.basinc"
#INCLUDE "include/LoRa.basinc"
#INCLUDE "include/PJON.basinc"

interrupt:
    ; Start and stop pump timing