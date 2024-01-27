/**
 * conversions.ino
 * General functions for converting to and from char arrays.
 */

/**
 * Converts a long (4 bytes) to a char array in little endian format.
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

/**
 * Converts a char array to a long (4 bytes) in little endian format.
 * @param charBuffer The char array to use. Must be at least 4 chars + startPos long.
 * @param startPos [Optional, default 0] The position in the char array to read the given long from.
 */
uint32_t charArrayToULong(char *charBuffer, uint8_t startPos) {
    // For each byte, generate a char from it.
    uint32_t integer = 0;
    for(int8_t i = startPos + 3; i >= startPos; i--) {
        integer = integer << 8;
        integer += (uint8_t)charBuffer[i];
    }
    return integer;
}

/**
 * Converts an unsigned int (2 bytes) to a char array in little endian format.
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

/**
 * Converts a char array to an unsigned int (2 bytes) in little endian format.
 * @param charBuffer The char array to use. Must be at least 4 chars + startPos long.
 * @param startPos [Optional, default 0] The position in the char array to read the given long from.
 */
uint16_t charArrayToUInt(char *charBuffer, uint8_t startPos) {
    uint16_t integer = (uint8_t)charBuffer[startPos] | (((uint8_t)charBuffer[startPos+1]) << 8);
    Serial.print(F("Int: "));
    Serial.print(integer);
    Serial.print(F("\tChar array: "));
    Serial.print((uint8_t)charBuffer[startPos]);
    Serial.print(F(", "));
    Serial.println((uint8_t)charBuffer[startPos+1]);
    return integer;
}
