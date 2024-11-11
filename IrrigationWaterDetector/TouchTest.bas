; Pins
symbol PIN_WATER = B.1
symbol PIN_LED = B.4
symbol DEFAULT_TOUCH_CONF = %00001001
; symbol TOUCH_CONF = %000

init:
    sertxd("Touch test", cr, lf)
main:
    toggle PIN_LED
    touch16 PIN_WATER, w0
    sertxd(#w0, cr, lf)
    pause 500
    goto main