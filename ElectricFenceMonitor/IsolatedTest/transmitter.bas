; Reads the ADC at high speed, then sends it over infrared
#picaxe 18m2
#no_data
#define PIN_IR B.4
#define PIN_ADC C.1
#define result w0
#define result_l b0
#define result_h b1
#define read_count w2
#define out w3
#define out_l b6
#define out_h b7

init:
    out = 0
    sertxd("Isolated test - transmitter", cr, lf)

main:
    ; Read lots of samples from the ADC and take the maximum
    setfreq m32
    out = 0
    for read_count = 1 to 3500
        readadc10 PIN_ADC, result
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
    sertxd(#out, cr, lf)
    goto main