'-----PREPROCESSED BY picaxepreprocess.py-----
'----UPDATED AT 08:35PM, November 26, 2021----
'----SAVING AS compiled.bas ----

'---BEGIN IrrigationWaterDetector.bas ---
; IrrigationWaterDetector.bas
; A remote LoRa water detector for use with flood irrigation
; Jotham Gates, November 2021
; https://github.com/jgOhYeah/PICAXE-Libraries-Extras

#picaxe 18M2      'CHIP VERSION PARSED
#terminal 38400
; #define VERSION "v0.1.0"
#NO_DATA

'---BEGIN include/symbols.basinc ---
; symbols.basinc
; Definitions to be used in other files
; Jotham Gates
; Created 22/11/2020
; Modified 25/01/2020
; https://github.com/jgOhYeah/PICAXE-Libraries-Extras

; Pins
; LoRa module
symbol SS = C.6
symbol SCK = C.0
symbol MOSI = C.7
symbol MISO = pinB.0
symbol RST = C.1
symbol DIO0 = pinC.5 ; High when a packet has been received

; Variables
symbol mask = b1
symbol level = b2
symbol counter = b3
symbol counter2 = b4
symbol total_length = b5
symbol s_transfer_storage = b6 ; Saves param1 duing LoRa spiing
symbol crc0 = b7 ; crcs can be used whenever a crc calculation is not required
symbol crc1 = b8
symbol crc2 = b9
symbol crc3 = b10
symbol counter3 = b11
; b12, b13, b1, b15, b16, b17, b18, b19 are free
symbol start_time = w10
symbol start_time_h = b21
symbol start_time_l = b20
symbol tmpwd = w11
symbol param1 = b24
symbol param2 = b25
symbol rtrn = w13

symbol LORA_TIMEOUT = 2 ; Number of seconds after which it is presumed the module has dropped out
                        ; due to a dodgy connection or breadboard and should be reset.

; Macro to simplify checking if a packet has been received.
; #DEFINE LORA_RECEIVED DIO0 = 1

symbol LORA_RECEIVED_CRC_ERROR = 65535 ; Says there is a CRC error if returned by setup_lora_read
symbol PJON_INVALID_PACKET = 65534 ; Says the packet is invalid, not a PJON packet, or not addressed to us

symbol MY_ID = 167 ; PJON id of this device (Number courtesy of Aunty)
symbol UPRSTEAM_ADDRESS = 255 ; Address to send things to using PJON

; #DEFINE FILE_SYMBOLS_INCLUDED ; Prove this file is included properly

'---END include/symbols.basinc---
'---BEGIN include/generated.basinc ---
; Autogenerated by calculations.py at 2021-01-25 23:03:30
; For a FREQUENCY of 433.0MHz, a SPREAD FACTOR of 9 and a bandwidth of 125000kHz:
; #DEFINE LORA_FREQ 433000000
; #DEFINE LORA_FREQ_MSB 0x6C
; #DEFINE LORA_FREQ_MID 0x40
; #DEFINE LORA_FREQ_LSB 0x00
; #DEFINE LORA_SPREADING_FACTOR 9
; #DEFINE LORA_LDO_ON 0

; #DEFINE FILE_GENERATED_INCLUDED ; Prove this file is included properly

'---END include/generated.basinc---

; #define ENABLE_LORA_RECEIVE
; #define ENABLE_PJON_RECEIVE
; #define ENABLE_LORA_TRANSMIT
; #define ENABLE_PJON_TRANSMIT

; #define TABLE_SERTXD_ADDRESS_VAR w6 ; b12, b13
; #define TABLE_SERTXD_ADDRESS_END_VAR w7 ; b14, b15
; #define TABLE_SERTXD_TMP_BYTE b16

; Pins
symbol PIN_WATER = B.2
symbol PIN_LED = B.1
symbol IN_PIN_RATE_SELECT = pinB.3
symbol MASK_RATE_SELECT = %00001000

init:
    ; Initial setup
    setfreq m32
    pullup MASK_RATE_SELECT
;#sertxd("Irrigation water detector ", "v0.1.0", cr, lf, "By Jotham Gates, Compiled ", "26-11-2021", cr, lf) 'Evaluated below
w6 = 0
w7 = 71
gosub print_table_sertxd
    ; Attempt to start the module
	gosub begin_lora
	if rtrn = 0 then
;#sertxd("Failed to start LoRa",cr,lf) 'Evaluated below
w6 = 72
w7 = 93
gosub print_table_sertxd
		goto failed
	else
;#sertxd("LoRa Started",cr,lf) 'Evaluated below
w6 = 94
w7 = 107
gosub print_table_sertxd
	endif

	; Set the spreading factor
	gosub set_spreading_factor

	; gosub idle_lora ; 4.95mA
	gosub sleep_lora ; 3.16mA

main:
    ; Measure the capacitance and send it
    high PIN_LED
;#sertxd("Sending packet", cr, lf) 'Evaluated below
w6 = 108
w7 = 123
gosub print_table_sertxd
    gosub begin_pjon_packet

    ; Water level
    @bptrinc = "w"
    setfreq m4 ; touch reading varies with clock speed
    touch16 PIN_WATER, rtrn
    setfreq m32
;#sertxd("touch16=") 'Evaluated below
w6 = 124
w7 = 131
gosub print_table_sertxd
    sertxd(#rtrn, cr, lf)
    gosub add_word

    ; Send the packet
    param1 = UPRSTEAM_ADDRESS
    gosub end_pjon_packet ; Stack is 6
	if rtrn = 0 then ; Something went wrong. Attempt to reinitialise the radio module.
;#sertxd("LoRa dropped out.") 'Evaluated below
w6 = 132
w7 = 148
gosub print_table_sertxd
		for tmpwd = 0 to 15
			toggle PIN_LED
			pause 4000
		next tmpwd

		gosub begin_lora ; Stack is 6
		if rtrn != 0 then ; Reconnected ok. Set up the spreading factor.
;#sertxd("Reconnected ok") 'Evaluated below
w6 = 149
w7 = 162
gosub print_table_sertxd
			param1 = 9
			gosub set_spreading_factor
		else
;#sertxd("Could not reconnect") 'Evaluated below
w6 = 163
w7 = 181
gosub print_table_sertxd
		endif
	endif
	low PIN_LED

;#sertxd("Packet sent. Entering sleep mode", cr, lf) 'Evaluated below
w6 = 182
w7 = 215
gosub print_table_sertxd
	gosub sleep_lora

    ; Sleep for a while
    setfreq m4
    if IN_PIN_RATE_SELECT = 0 then
;#sertxd("Fast mode enabled", cr, lf) 'Evaluated below
w6 = 216
w7 = 234
gosub print_table_sertxd
        pause 10000
    else
        pause 60000
        pause 60000
    endif
    setfreq m32
    goto main

add_word:
	; Adds a word to @bptr in little endian format.
	; rtrn contains the word to add (it is a word)
	@bptrinc = rtrn & 0xff
	tmpwd = rtrn / 0xff
	@bptrinc = tmpwd
	return

failed:
	; Flashes the LED on and off to give an indication it isn't happy.
	high PIN_LED
	pause 4000
	low PIN_LED
	pause 4000
	goto failed


; Libraries that will not be run first thing.
'---BEGIN include/LoRa.basinc ---
; LoRa.basinc
; Attempt at talking to an SX1278 LoRa radio module using picaxe M2 parts.
; Heavily based on the Arduino LoRa library found here: https://github.com/sandeepmistry/arduino-LoRa
; Jotham Gates
; Created 22/11/2020
; Modified 25/01/2021
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
; Modified: 25/01/2021
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

'---END IrrigationWaterDetector.bas---


'---Extras added by the preprocessor---
print_table_sertxd:
    for w6 = w6 to w7
    readtable w6, b16
    sertxd(b16)
next w6

    return

table 0, ("Irrigation water detector ","v0.1.0",cr,lf,"By Jotham Gates, Compiled ","26-11-2021",cr,lf) ;#sertxd
table 72, ("Failed to start LoRa",cr,lf) ;#sertxd
table 94, ("LoRa Started",cr,lf) ;#sertxd
table 108, ("Sending packet",cr,lf) ;#sertxd
table 124, ("touch16=") ;#sertxd
table 132, ("LoRa dropped out.") ;#sertxd
table 149, ("Reconnected ok") ;#sertxd
table 163, ("Could not reconnect") ;#sertxd
table 182, ("Packet sent. Entering sleep mode",cr,lf) ;#sertxd
table 216, ("Fast mode enabled",cr,lf) ;#sertxd
