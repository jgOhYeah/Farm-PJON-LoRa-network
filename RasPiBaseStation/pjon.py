#!/usr/bin/python3
import PyLora
# from baseutils import *
# Clone PyLoRa for Python 3 from https://github.com/hnlichong/PyLora/tree/py35

class PJONPacketError(Exception):
    def __init__(self, message):
        self.message = message

class CRC:
    def crc32(self, data, length):
        bits = None
        crc = 0xFFFFFFFF
        current = 0
        while length > 0:
            length -= 1
            crc ^= data[current]
            current += 1
            bits = 8
            while bits > 0:
                bits -= 1
                if crc & 1:
                    crc = ((crc  & 0xFFFFFFFF) >> 1) ^0xEDB88320
                else:
                    crc = (crc & 0xFFFFFFFF) >> 1

        return (~crc) & 0xFFFFFFFF

    def crc8_roll(self, input_byte, crc):
        i = 8
        while i:
            result = (crc ^ input_byte) & 0x01
            crc >>= 1
            if result:
                crc ^= 0x97
            
            i-= 1
            input_byte >>= 1

        return crc

    def crc8(self, input_byte, length):
        crc = 0
        for b in range(length):
            crc = self.crc8_roll(input_byte[b], crc)

        return crc

class PJON:
    def __init__(self, id = 255):
        self.id = id

    def parse(self, packet): # tODO: FIX CHECKSUM INVALID
        sender_id = None
        header = None
        length = None
        cumulative_length = 4
        is_crc32 = False
        payload = []
        crc = CRC()
        if len(packet) >= 4:
            if packet[0] == 0 or packet[0] == self.id:
                header = packet[1]
                length = packet[2]
                header_checksum = packet[3]
                calculated = crc.crc8(packet, 3)
                if header_checksum == calculated:
                    # Checksums match
                    if header & 0x02 and len(packet) >= 5:
                        # Sender info is included and the packet is long enough
                        sender_id = packet[4]
                        cumulative_length += 1
                        crc_length = 1
                        if header & 0x020:
                            # CRC32 checksum
                            is_crc32 = True
                            crc_length = 4

                        # Get the payload
                        for i in range(cumulative_length, len(packet) - crc_length): # Using len() instead of length to stop truncated packets causing errors
                            payload.append(packet[i])

                        # Check the final crc
                        if is_crc32:
                            calclength = min(length, len(packet))
                            calculated = crc.crc32(packet, calclength - 4)
                            crc = (packet[calclength - 4] << 24) | (packet[calclength - 3] << 16) | (packet[calclength - 2] << 8) | packet[calclength - 1]

                        else:
                            calculated = crc.crc8(packet, length - 1)
                            crc = packet[length - 1]
                        if calculated != crc:
                            raise PJONPacketError("Failed end checksum")
                        return (payload, sender_id)
                    else:
                        raise PJONPacketError("Too short for sender id")
                else:
                    raise PJONPacketError("Failed header checksum")
            else:
                raise PJONPacketError("Not to us")
        else:
            raise PJONPacketError("Too short to be a packet")

if __name__ == "__main__":
    pjon = PJON()
    data = bytearray(b'\xff&\x10_JV\x80\x00F\x01r\x01\x9a\xfb\xad\x95')
    print(list(data))
    print(pjon.parse(data))