/**
 * defines.h
 * Common commands, fields and header studd
 */
// Libraries
#define PJON_INCLUDE_TL
#include <PJONThroughLora.h>
#include <LiquidCrystal.h>
#include <LCDGraph.h>

// PJON Addresses
#define ADDR_FENCE 0x4A
#define ADDR_PUMP 0x5A

// Lines on the lcd
#define LCD_LINE_FENCE 0
#define LCD_LINE_PUMP 1

// Pins
#define PIN_LED 3

// Fields
#define FIELD_VOLTAGE 'V'
#define FIELD_UPTIME 't'
#define FIELD_TEMPERATURE 'T'
#define FIELD_TRANSMIT_ENABLE 'r'
#define FIELD_FENCE_ENABLE 'F'
#define FIELD_REPEAT_STATUS 's'
#define FIELD_TRANSMIT_INTERVAL 'I'
#define FIELD_PUMP_STATUS 'P'

// TODO: Make this an attribute
#define LATE_TIME 12*60000L
// #define PUMP_LATE_TIME 63*60000L

// Conditions to start worrying
#define BATTERY_FLAT 120
#define BATTERY_OVERCHARGED 144