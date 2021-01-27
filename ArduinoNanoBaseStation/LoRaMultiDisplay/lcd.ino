/**
 * lcd.ino
 * Code for writing to the 40 by 2 lcd.
 * Jotham Gates, 11/11/2020
 */

/**
 * Sets up the placeholders for the display
 * 
 * Display layout:
 * --------------------------------------------
 * | Battery:  -.-V   SNR: --.-   RSSI: ----  |
 * | Temperature:  -.-C  Updated: --h --m --s |
 * --------------------------------------------
 * 
 * --------------------------------------------
 * | Battery: 25.5V  RSSI: ****  SNR: ***.*   |
 * | Temp: 25.5C |--__-_-  Received: hh:mm:ss |
 * --------------------------------------------

 *//*
void initDisplay() {
    lcd.clear();
    // Top row
    lcd.print(F("Battery: --.-V  RSSI: -     SNR: -.- "));
    // Bottom row
    lcd.setCursor(0,1);
    lcd.print(F("Temp: --.-C           Received: --:--:--"));

    // Setup the graph
    //graph.filled = false;
    graph.setRegisters();
    graph.display(12,1); // We can update the custom character registers and they will also update on the display.
}*/

/**
 * Displays the correct data in the correct positions if present.
 *//*
void displayData(RecievedData & data) {
    // Voltage
    if(data.voltage.present) {
        lcd.setCursor(9, 0);
        if(data.voltage.data < 100) { //Less than 10 after d.p.
            lcd.write(' ');
        }
        lcd.print(data.voltage.data / 10);
        lcd.setCursor(12, 0);
        lcd.print(data.voltage.data % 10);
        graph.add(data.voltage.data); // NOTE: Graph is now Voltage
        graph.autoRescale(false);
        graph.setRegisters();
    } else {
        lcd.setCursor(9, 0);
        lcd.print(F(" -.-"));
    }

    // Temperature
    if(data.temperature.present) {
        lcd.setCursor(6, 1);
        if(data.temperature.data < 100) {
            lcd.write(' ');
        }
        lcd.print(data.temperature.data / 10);
        lcd.setCursor(9, 1);
        lcd.print(data.temperature.data % 10);

        // Temperature graph
        // graph.add(data.temperature.data);
        // graph.autoRescale(false);
        // graph.setRegisters();
    } else {
        lcd.setCursor(6, 1);
        lcd.print(F(" -.-"));
    }

    // SNR
    lcd.setCursor(35, 0);
    uint8_t length = 5 - lcd.print(data.snr, 1);
    while(length > 0) { // Write as many blank spaces as needed to completely fill it up
        length--;
        lcd.write(' ');
    }
    

    // RSSI
    lcd.setCursor(24, 0);
    length = 4 - lcd.print(data.rssi);
    while(length > 0) { // Write as many blank spaces as needed to completely fill it up
        length--;
        lcd.write(' ');
    }
    //graph.add(data.rssi); // NOTE: Graph is now RSSI
    // graph.autoRescale(false);
    //graph.setRegisters();
}*/