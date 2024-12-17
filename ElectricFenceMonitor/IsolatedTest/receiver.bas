; Receives ADC and prints to serial.
#picaxe 08m2
#no_data
#define PIN_IR C.1
#define in w0
#define in_l b0
#define in_h b1
#define out w1
#define out_l b2
#define out_h b3
#define collected b4
#define letter b5

init:
    sertxd("Isolated test - receiver", cr, lf)
    letter = "a"

main:
    ; Get the lower 6 bits
    do
        irin PIN_IR, in_l
        collected = in_l / 64 ; Check bit 6. 0 means lower collected, 1 means upper.
    loop while collected != 0

    ; Get the upper 4 bits
    irin PIN_IR, in_h
    collected = in_h / 64 ; Should be 1.
    if collected != 1 then main ; Haven't gotten the high byte, restart.

    ; Reconstruct value and print.
    out_l = in_l & 0x3f
    in_h = in_h & 0x0f
    in = in_h * 64
    out = out_l + in
    sertxd(letter, " ", #out, cr, lf)
    inc letter
    if letter > "z" then
        letter = "a"
    endif
    goto main