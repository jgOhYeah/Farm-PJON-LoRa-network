; Tests if the current transformer and amplifier is behaving as well as code
#picaxe 18m2
#include "include/PumpMonitorCommon.basinc"

init:
    setfreq m32 ; Keep serial bauds consistant.
    sertxd("Test program", cr, lf)
    low PIN_LED_ON
    low PIN_LED_ALARM

main:
    if PIN_PUMP = 1 then
        high PIN_LED_ON
        sertxd("Pump on. Led on state: ", #LED_ON_STATE, cr, lf)
    else
        low PIN_LED_ON
        sertxd("Pump off. Led on state: ", #LED_ON_STATE, cr, lf)
    endif
    pause 1000
    goto main