; Pins
symbol PIN_WATER = B.1
symbol PIN_LED = B.4

init:
    sertxd("Touch test", cr, lf)
main:
    toggle PIN_LED
    touch16 PIN_WATER, w0
    sertxd(#w0, cr, lf)
    pause 500
    goto main