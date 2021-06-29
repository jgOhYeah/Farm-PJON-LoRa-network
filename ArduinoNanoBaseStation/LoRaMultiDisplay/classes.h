enum Status {
    unknown = 0,
    error = 1,
    good = 2
};

/** Core fields common to every device */
class Device {
    public:
        float snr;
        int rssi;
        uint32_t received;
        Status status = unknown;

        Device(uint8_t devId, uint8_t reg) : _graph(4, 1, reg) {
            id = devId;
        }

        virtual void begin(LiquidCrystal *lcd, PJONThroughLora *bus) {
            // LCD
            _graph.begin(lcd);
            _graph.filled = false;
            _lcd = lcd;

            // PJON
            _bus = bus;
        }

        void end() {
            _graph.end();
        }

        /** Prints the status to a 40 by 2 lcd on the given line.
         * The layout should be something like a line from this:
         *   0123456789012345678901234567890123456789
         * --------------------------------------------
         * | ! Fence: 12.9V  |-_- hh:mm:ss R-123 S-12 |
         * | ? Pump:  28.7m  |--_ hh:mm:ss R-123 S-12 |
         * --------------------------------------------
         */
        void display(uint8_t line) {
            // Status symbol
            _lcd->setCursor(0, line);
            displayStatus();
            _lcd->write(' ');

            // Device name
            displayName();

            // Main number
            _lcd->setCursor(8, line);
            displayPad(displayMainNumber(), 6);

            // Graph
            rescaleGraph();
            _graph.setRegisters();
            _graph.display(14, line);

            // Secondary Number
            _lcd->write(' ');
            displayPad(displaySecondaryNumber(), 5);

            // Time
            updateClock(line);
            
            // RSSI
            _lcd->setCursor(30, line);
            _lcd->write('R');
            displayPad(_lcd->print(rssi), 5);

            // SNR
            _lcd->write('S');
            displayPad(_lcd->print(snr, 0), 3);
        }

        /** Prints the time since data was recieved on the LCD */
        void updateClock(uint8_t line) {
            uint32_t timeDiff = (millis() - received) / 1000;

            // Seconds
            uint8_t time = timeDiff % 60;
            _lcd->setCursor(27, line);
            if(time < 10) {
                _lcd->write('0');
            }
            _lcd->print(time);

            // Minutes
            timeDiff /= 60;
            _lcd->setCursor(23, line);
            if(timeDiff < 100) {
                _lcd->write(' ');
                if(timeDiff < 10) {
                    _lcd->write('0');
                }
                _lcd->print(timeDiff);
            } else {
                _lcd->print(F(">99"));
            }
            _lcd->write(':');
        }

        /** Enables or disables radio transmissions */
        void setRadio(bool enabled) {
            char msg[2];
            msg[0] = 'r' | 0x80;
            msg[1] = enabled;
            _bus->send(id, msg, 2);
        }

        /** Requests status */
        void getStatus() {
            uint8_t msg = 's' | 0x80;
            _bus->send(id, &msg, 1); // TODO: Not sending correct data
        }

        /** Checks and updates the state based off the last time a packet was received 
         * @returns true if the state has changed, false otherwise.
         */
        bool updateState() {
            Status old = status;
            if(status != error) {
                // Do not change from error until manually reset
                // TODO: A better way or go away if been ok for a certain time.
                if(millis() - received > LATE_TIME) {
                    // Have not received for a while
                    status = unknown;
                } else {
                    status = good;
                }
            }
            return status != old;
        }

    protected:
        LCDGraph<int16_t> _graph;
        LiquidCrystal *_lcd;
        PJON<ThroughLora> *_bus;
        uint8_t id;

        /** Prints an error message to say the packet does not have a valid length for the contents */
        void errorPacketLength() {
            // The length is not long enough for the data type
            Serial.println(F("Invalid packet length"));
        }

        /** Converts a long (4 bytes) to a char array in little endian format.
         * @param integer The integer to convert to a char array.
         * @param charBuffer The char array to put the number in. Must be at least 4 chars + startPos long.
         * @param startPos [Optional, default 0] The position in the char array to put the given long in.
         */
        void uLongToCharArray(uint32_t integer, char *charBuffer, uint8_t startPos) {
            // For each byte, generate a char from it.
            for(uint8_t i = startPos; i < startPos + 4; i++) {
                charBuffer[i] = integer & 0xFF;
                integer = integer >> 8;
            }
        }

        /** Converts a char array to a long (4 bytes) in little endian format.
         * @param charBuffer The char array to use. Must be at least 4 chars + startPos long.
         * @param startPos [Optional, default 0] The position in the char array to read the given long from.
         */
        uint32_t charArrayToULong(char *charBuffer, uint8_t startPos) {
            // For each byte, generate a char from it.
            uint32_t integer = 0;
            for(uint8_t i = startPos + 3; i >= startPos; i--) {
                integer = integer << 8;
                integer += (uint8_t)charBuffer[i];
            }
            return integer;
        }

        /** Converts an unsigned int (2 bytes) to a char array in little endian format.
         * @param integer The integer to convert to a char array.
         * @param charBuffer The char array to put the number in. Must be at least 4 chars + startPos long.
         * @param startPos [Optional, default 0] The position in the char array to put the given long in.
         */
        void uIntToCharArray(uint16_t integer, char *charBuffer, uint8_t startPos) {
            charBuffer[startPos] = integer & 0xFF;
            charBuffer[startPos+1] = (integer >> 8);
            Serial.print(F("Int: "));
            Serial.print(integer);
            Serial.print(F("\tChar array: "));
            Serial.print((uint8_t)charBuffer[startPos]);
            Serial.print(F(", "));
            Serial.println((uint8_t)charBuffer[startPos+1]);
        }

        /** Converts a char array to an unsigned int (2 bytes) in little endian format.
         * @param charBuffer The char array to use. Must be at least 4 chars + startPos long.
         * @param startPos [Optional, default 0] The position in the char array to read the given long from.
         */
        uint16_t charArrayToUInt(char *charBuffer, uint8_t startPos) {
            uint16_t integer = (uint8_t)charBuffer[startPos] | (((uint8_t)charBuffer[startPos+1]) << 8);
            return integer;
        }

    private:
        virtual void displayName() {}
        virtual uint8_t displayMainNumber() {}
        virtual uint8_t displaySecondaryNumber() {}
        virtual void rescaleGraph() {}

        /** Writes a symbol representing the current status to the display */
        void displayStatus() {
            switch(status) {
                case unknown:
                    _lcd->write('?');
                    break;
                case error:
                    _lcd->write('!');
                    break;
                default:
                    _lcd->write(' ');
            }
        }

        /** Pads out any numbers to clear anything previously on now unused chars */
        void displayPad(uint8_t written, uint8_t desired) {
            if(written < desired) {
                written = desired - written; // Fill up space after so that anything residual is gone
                for(; written != 0; written--) {
                    _lcd->write(' ');
                }
            }
        }

};

template<typename DataFormat>
struct DataField {
    bool present;
    DataFormat data; // For now, assume everything is stored as an unsigned long.
};

/** Class for the pump */
class Pump : public Device {
    public:
        DataField<uint16_t> average;
        DataField<uint16_t> onTime; // In 0.5s
        DataField<bool> transmitEnable;
        Pump(uint8_t devId, uint8_t reg = 0) : Device(devId, reg) {}

        /**
         * Initialises the graph and lcd pointers
         */
        void begin(LiquidCrystal *lcd, PJONThroughLora *bus) {
            Device::begin(lcd, bus);
            _graph.yMin = 0;
            _graph.yMax = 3600;
        }

        /** Parses a PJON packet and extracts data on the current status */
        void parsePacket(uint8_t * payload, uint8_t length) {
            // Reset all fields present
            average.present = false;
            onTime.present = false;
            transmitEnable.present = false;

            // Get the signal information.
            snr = _bus->strategy.packetSnr();
            rssi = _bus->strategy.packetRssi();
            received = millis();

            // Process the payload.
            uint8_t i = 0;
            while(i < length) {
                char field = payload[i];
                i++;
                switch(field) {
                    case 'P': // Pump run time since the last transmission
                        if(i + 1 > length) {
                            // The length is not long enough for the data type
                            errorPacketLength();
                            return;
                        }
                        onTime.present = true;
                        onTime.data = charArrayToUInt((char*)payload, i);
                        _graph.add(onTime.data);
                        i += 2;
                        break;
                    case 'a': // Average run time
                        if(i + 1 > length) {
                            // The length is not long enough for the data type
                            errorPacketLength();
                            return;
                        }
                        average.present = true;
                        average.data = charArrayToUInt((char*)payload, i);
                        i += 2;
                        break;
                    case 'r': // Enable / disable radio transmissions.
                        if(i > length) {
                            // The length is not long enough for the data type
                            errorPacketLength();
                            return;
                        }
                        transmitEnable.present = true;
                        transmitEnable.data = payload[i];
                        i += 1;
                        break;
                    //default: // Something not implemented yet.
                }
            }
        }

        /** Checks and updates the state based off the last time a packet was received and battery voltage
         * @returns true if the state has changed, false otherwise.
         */
        //bool updateState() {
            // TODO: Detecting errors from graph records?
            //return Device::updateState(); // Check time since last heard from
        //}

    protected:
        /** Prints the name of the device to the lcd */
        void displayName() {
            _lcd->print(F("Pump"));
        }

        /** Prints the voltage on the display */
        uint8_t displayMainNumber() {
            uint8_t length;
            if(onTime.present) {
                length = _lcd->print(onTime.data / 120);
                _lcd->write('.');
                length += _lcd->print((onTime.data % 120) >> 1);
                _lcd->write('m');
                length += 2; // For '.' and 'm'
            } else {
                length = _lcd->print(F("--.-m"));
            }
            return length;
        }
        
        /** Prints the average time */
        uint8_t displaySecondaryNumber() {
            uint8_t length;
            if(onTime.present) {
                length = _lcd->print(average.data / 120);
                _lcd->write('.');
                length++;
                length += _lcd->print((average.data % 120) >> 1);
                if(length < 4) { // We don't have as much space, so drop the unit if
                    _lcd->write('m');
                    length++;
                }
            } else {
                length = _lcd->print(F("-.-m"));
            }
            return length;
        }
};

/** Class for managing remote fences */
class Fence : public Device {
    public:
        DataField<uint16_t> voltage;
        DataField<uint32_t> uptime;
        DataField<uint16_t> temperature;
        DataField<bool> transmitEnable;
        DataField<bool> fenceEnable;

        Fence(uint8_t devId, uint8_t reg = 0) : Device(devId, reg) {}

        /**
         * Initialises the graph and lcd pointers
         */
        /*void begin(LiquidCrystal *lcd, PJONThroughLora *bus) {
            Device::begin(lcd, bus);
        }*/

        /** Parses a PJON packet and extracts data on the current status */
        void parsePacket(uint8_t * payload, uint8_t length) {
            // Reset all fields present
            voltage.present = false;
            uptime.present = false;
            temperature.present = false;
            fenceEnable.present = false;
            transmitEnable.present = false;

            // Get the signal information.
            snr = _bus->strategy.packetSnr();
            rssi = _bus->strategy.packetRssi();
            received = millis();

            // Process the payload.
            uint8_t i = 0;
            while(i < length) {
                char field = payload[i];
                i++;
                switch(field) {
                    case 'V': // Battery Voltage
                        if(i + 1 > length) {
                            // The length is not long enough for the data type
                            errorPacketLength();
                            return;
                        }
                        voltage.present = true;
                        voltage.data = charArrayToUInt((char*)payload, i);
                        _graph.add(voltage.data);
                        i += 2;
                        break;
                    case 't': // Uptime
                        if(i + 3 > length) {
                            // The length is not long enough for the data type
                            errorPacketLength();
                            return;
                        }
                        uptime.present = true;
                        uptime.data = charArrayToULong((char*)payload, i);
                        i += 4;
                        break;
                    case 'T': // Temperature
                        if(i + 1 > length) {
                            // The length is not long enough for the data type
                            errorPacketLength();
                            return;
                        }
                        temperature.present = true;
                        temperature.data = charArrayToUInt((char*)payload, i);
                        i += 2;
                        break;
                    case 'r': // Enable / disable radio transmissions.
                        if(i > length) {
                            // The length is not long enough for the data type
                            errorPacketLength();
                            return;
                        }
                        transmitEnable.present = true;
                        transmitEnable.data = payload[i];
                        i += 1;
                        break;
                    case 'F': // Enable / disable radio transmissions.
                        if(i > length) {
                            // The length is not long enough for the data type
                            errorPacketLength();
                            return;
                        }
                        fenceEnable.present = true;
                        fenceEnable.data = payload[i];
                        i += 1;
                        break;
                    
                    //default: // Something not implemented yet.
                }
            }
        }

        /** Sends a PJON packet telling the fence to turn on or off and setting the radio */
        void sendCommand(bool fenceEnable, bool radioEnable) {
            // TODO: Send repeatedly once every so often until there is a response and timeout errors
            char msg[4];
            msg[0] = 'r' | 0x80;
            msg[1] = radioEnable;
            msg[2] = 'F' | 0x80;
            msg[3] = fenceEnable;
            _bus->send(id, msg, 4); // TODO: Make the bus address part of the class instance
        }

        /** Enables or disables the fence */
        void setFence(bool enabled) {
            char msg[2];
            msg[0] = 'F' | 0x80;
            msg[1] = enabled;
            _bus->send(id, msg, 2);
        }

        /** Sets the transmit interval
         * @param interval is the number of ~3 minute blocks.
        */
        void setTXInterval(uint8_t interval) {
            char msg[2];
            msg[0] = 'I' | 0x80;
            msg[1] = interval;
            _bus->send(id, msg, 2);
        }

        /** Checks and updates the state based off the last time a packet was received and battery voltage
         * @returns true if the state has changed, false otherwise.
         */
        bool updateState() {
            if(voltage.present) {
                if(voltage.data > BATTERY_OVERCHARGED || voltage.data < BATTERY_FLAT) {
                    if(status != error) {
                        status = error;
                        return true;
                    } else {
                        return false;
                    }
                }
            }
            return Device::updateState(); // Check time since last heard from
        }

    protected:
        /** Prints the name of the device to the lcd */
        void displayName() {
            _lcd->print(F("Fence"));
        }

        /** Prints the voltage on the display */
        uint8_t displayMainNumber() {
            uint8_t length;
            if(voltage.present) {
                length = _lcd->print(voltage.data / 10);
                _lcd->write('.');
                length += _lcd->print(voltage.data % 10);
                _lcd->write('V');
                length += 2; // For '.' and 'V'
            } else {
                length = _lcd->print(F("--.-V"));
            }
            return length;
        }

        /** Prints whether the fence is on or off */
        uint8_t displaySecondaryNumber() {
            uint8_t length;
            if(fenceEnable.present) {
                if(fenceEnable.data) {
                    length = _lcd->print(F("On"));
                } else {
                    length = _lcd->print(F("Off"));
                }
            } else {
                length = _lcd->print(F("--"));
            }
            return length;
        }

        /** Calls _graph.autoRescale to update the scaling */
        void rescaleGraph() override {
            _graph.autoRescale(false);
        }
};