/**
 * LoRaVoltsReceive40by2.ino
 * Recieves PJON encoded data over LoRa and displays it on a 40 by 2
 * alphanumeric LCD. Designed as a remote monitor for an electric fence.
 * Written by Jotham Gates.
 * Created 11/11/2020
 */
#include "defines.h"
#include "classes.h"

// Class instances
LiquidCrystal lcd(4, 5, 6, 7, 8, A5);
Fence fence(ADDR_FENCE, 0);
Pump pump(ADDR_PUMP, 4);

// Disabled busses for PICAXE
PJONThroughLora bus(255);
    
void setup() {
    // Setup Serial
    Serial.begin(38400);
    Serial.println(F("Electric Fence Monitor"));

    // Setup the lcd
    lcd.begin(40, 2);
    lcd.print(F("Electric Fence Monitor"));

    // Setup the LED
    pinMode(PIN_LED, OUTPUT);
    digitalWrite(PIN_LED, HIGH);
    
    // Setup LoRa and PJON
    bus.set_receiver(PJONReceive);
	bus.strategy.setFrequency(433E6);
    bus.strategy.setSpreadingFactor(9);
    LoRa.setSPIFrequency(4E6);
	bus.begin();
    // TODO: Check the module initialised properly

    // Setup the pump and fence objects
    fence.begin(&lcd, &bus);
    pump.begin(&lcd, &bus);
    lcd.clear();
    fence.display(LCD_LINE_FENCE);
    pump.display(LCD_LINE_PUMP);
}

void loop() {
    fence.updateClock(LCD_LINE_FENCE);
    pump.updateClock(LCD_LINE_PUMP);
    if(fence.updateState()) {
        fence.display(LCD_LINE_FENCE);
    }
    if(pump.updateState()) {
        pump.display(LCD_LINE_PUMP);
    }
    // Set the LED
    if(fence.status == error || pump.status == error) {
        digitalWrite(3, HIGH);
    } else {
        digitalWrite(3, LOW);
    }
    bus.update();
    bus.receive(1000); // 1 second delay

    if(Serial.available()) {
        bool send = true;
        // TODO: Proper UI
        switch(Serial.read()) {
            case 'y':
                fence.setFence(true);
                Serial.println("Setting fence on");
                break;
            case 'n':
                fence.setFence(false);
                Serial.println(F("Setting fence off"));
                break;
            case 'r':
                fence.setRadio(false);
                Serial.println(F("Setting transmit to off"));
                break;
            case 'R':
                Serial.println(F("Setting transmit to on"));
                fence.setRadio(true);
                break;
            case 's':
                Serial.println("Requesting status with extra byte");
                fence.getStatus();
                break;
        }
        while(Serial.available()) Serial.read();
    }
}

/**
 * Called when a packet addressed to this device is recieved.
 * Updates the display and resets the time since updated.
 */
void PJONReceive(uint8_t * payload, uint16_t length, const PJON_Packet_Info & packet_info) {
    Serial.print(F("Received packet from 0x"));
    Serial.println(packet_info.tx.id, 16); // TODO: Update to latest PJON library
    Serial.print(F("  - RSSI: "));
    Serial.print(bus.strategy.packetRssi());
    Serial.print(F("dBi\r\n  - SNR: "));
    Serial.print(bus.strategy.packetSnr(), 1);
    Serial.println(F("dBi"));
    switch(packet_info.tx.id) { // TODO: Update to latest PJON library
        case ADDR_FENCE:
            fence.parsePacket(payload, length);
            fence.display(LCD_LINE_FENCE);
            Serial.print(F("  - Voltage: ")); // TODO: Checking if voltage is actually included
            Serial.print(fence.voltage.data /10);
            Serial.write('.');
            Serial.print(fence.voltage.data % 10);
            Serial.println('V');
            Serial.println();
            break;

        case ADDR_PUMP:
            pump.parsePacket(payload, length);
            pump.display(LCD_LINE_PUMP);
            Serial.print(F("  - On Time: ")); // TODO: Checking if voltage is actually included
            Serial.print(pump.onTime.data >> 1);
            Serial.println('s');
            Serial.print(F("  - Average: "));
            Serial.print(pump.average.data >> 1);
            Serial.println('s');
            break;
    }
}

/** Displays a message on the screen and enters an infinite loop if the LoRa module is disconnected. */
void checkConnected() {
    if(!LoRa.isConnected()) {
        lcd.clear();
        lcd.print(F("LoRa Module Disconnected"));
        lcd.setCursor(0, 1);
        lcd.print(F("Please reconnect it & reset"));
        Serial.println(F("Disconnected"));
        while(true) {
            digitalWrite(PIN_LED, HIGH);
            delay(1000);
            digitalWrite(PIN_LED, LOW);
            delay(1000);
        }
    }
}