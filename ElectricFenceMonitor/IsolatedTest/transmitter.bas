; Reads the ADC at high speed, then sends it over infrared
#picaxe 14m2
#no_data
symbol PIN_ADC_REF = B.1
symbol PIN_FENCE_SW = B.2
symbol PIN_FENCE_PEAK = B.3
symbol PIN_LED = B.4
symbol PIN_IR = PIN_LED
#define result w0
#define result_l b0
#define result_h b1
#define read_count w2
#define out w3
#define out_l b6
#define out_h b7
#define letter b8

init:
    setfreq m32
    out = 0
    letter = "a"
    sertxd("Isolated test - transmitter", cr, lf)
    high PIN_FENCE_SW
	adcconfig %010 ; Use the PIN_ADC_REF as the positive reference.

main:
    ; Read lots of samples from the ADC and take the maximum
    out = 0
    for read_count = 1 to 3500
        readadc10 PIN_FENCE_PEAK, result
        if result > out then
            out = result
        endif
    next read_count
    ; inc out
    ; pause 100
    
    ; Send
    result_l = out_l & 0x3f ; Lower 6 bits, bit 6 = 0
    result_h = out / 64 | 0x40 ; Upper 4 bits, bit 6 = 1
    irout PIN_IR, 1, result_l
    pause 48
    irout PIN_IR, 1, result_h

    ; Serial print
    sertxd(letter, " ", #out, cr, lf)
    inc letter
    if letter > "z" then
        letter = "a"
    endif
    goto main