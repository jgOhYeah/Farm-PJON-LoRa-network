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

#INCLUDE "include/BatteryVoltsMonitorCommon.basinc"
#INCLUDE "include/symbols.basinc"
#INCLUDE "include/generated.basinc"
; #DEFINE ENABLE_LORA_RECEIVE
; #DEFINE ENABLE_PJON_RECEIVE
; #DEFINE ENABLE_LORA_TRANSMIT
; #DEFINE ENABLE_PJON_TRANSMIT
#PICAXE 14M2
#TERMINAL 38400

; Default settings on upload
eeprom EEPROM_FENCE_ENABLED, (DEFAULT_FENCE_ENABLED)
eeprom EEPROM_TX_ENABLED, (DEFAULT_TX_ENABLED)
eeprom EEPROM_TX_INTERVALS, (DEFAULT_TX_INTERVALS)

init:
    ; Initial setup
	setfreq m32
    ;#sertxd(NAME, VERSION , " BOOTLOADER", cr,lf, "Jotham Gates, Compiled ", ppp_date_uk, cr, lf)
	high LED_PIN

	; Load settings from EEPROM
	read EEPROM_FENCE_ENABLED, fence_enable
	read EEPROM_TX_ENABLED,  transmit_enable
	read EEPROM_TX_INTERVALS, tx_intervals
	if fence_enable = 1 then
		high FENCE_PIN
	else
		low FENCE_PIN
	endif

	iterations_count = 0

	;#sertxd("Electric Fence Controller", cr, lf, "Jotham Gates, Compiled ", ppp_date_uk, cr, lf)
	; Attempt to start the module
	gosub begin_lora
	if rtrn = 0 then
		;#sertxd("LoRa Failed",cr,lf)
		goto failed
	else
		;#sertxd("LoRa Started",cr,lf)
	endif

	; Set the spreading factor
	gosub set_spreading_factor

	; gosub idle_lora ; 4.95mA
	; gosub sleep_lora ; 3.16mA
	; gosub setup_lora_receive ; 14mA
	; Everything in sleep ; 0.18 to 0.25mA
	; Finish setup
	low LED_PIN

    run 1

failed:
	; Flashes the LED on and off to give an indication it isn't happy.
	high LED_PIN
	pause 4000
	low LED_PIN
	pause 4000
	if time > FAILED_RESET_ITERATIONS_COUNT then goto init
	goto failed

; Libraries that will not be run first thing.
#INCLUDE "include/LoRa.basinc"
#INCLUDE "include/PJON.basinc"