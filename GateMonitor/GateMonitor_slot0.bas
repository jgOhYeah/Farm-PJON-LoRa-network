; GateMonitor_slot0.bas
; A remote LoRa farm gate monitor and movement detector.
; (Bootloader).
; Written by Jotham Gates
; Created 31/12/2024 (based on the battery voltage monitor).
; Modified 31/12/2024
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

#INCLUDE "include/GateMonitorCommon.basinc"
#INCLUDE "include/symbols.basinc"
#INCLUDE "include/generated.basinc"
; #DEFINE ENABLE_LORA_RECEIVE
; #DEFINE ENABLE_PJON_RECEIVE
; #DEFINE ENABLE_LORA_TRANSMIT
; #DEFINE ENABLE_PJON_TRANSMIT

#TERMINAL 38400

; Default settings on upload
eeprom EEPROM_LIGHT_ENABLED, (DEFAULT_light_enableD)
eeprom EEPROM_TX_ENABLED, (DEFAULT_TX_ENABLED)
eeprom EEPROM_TX_INTERVALS, (DEFAULT_TX_INTERVALS)

init:
    ; Initial setup
	setfreq m32
	high LED_PIN
    ;#sertxd(NAME, " ", VERSION , " BOOTLOADER", cr,lf, "Jotham Gates, Compiled ", ppp_date_uk, cr, lf, "Seeing as I have lots of space in the bootloader section, here is a URL to look at:", cr, lf, URL, cr, lf)

	; Load settings from EEPROM
	read EEPROM_LIGHT_ENABLED, light_enable
	read EEPROM_TX_ENABLED,  transmit_enable
	read EEPROM_TX_INTERVALS, tx_intervals
	if light_enable = 1 then
		high LIGHT_PIN
	else
		low LIGHT_PIN
	endif

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

	;#sertxd("Starting slot 1...", cr, lf, cr, lf)
	low LED_PIN

    run 1

failed:
	tmpwd_l = 0
failed_loop:
	; Flashes the LED on and off to give an indication it isn't happy.
	toggle LED_PIN
	pause 4000
	if tmpwd_l > FAILED_RESET_ITERATIONS_COUNT then
		;#sertxd("Resetting...", cr, lf, cr, lf)
		reset
	endif
	inc tmpwd_l
	goto failed_loop

; Libraries that will not be run first thing.
#INCLUDE "include/LoRa.basinc"