# Fields in the packets
Each field is represented by a byte followed by *x* more bytes, where *x* is the number of bytes taken up the the datatype of the field.

Set the most significant bit of the field to 1 to set that field on the device it is addressed to. If this bit is a 0, it is assumed that the device sending the packet is reporting its own status.

| Field |  Datatype  | Description                                                                       |
| :---: | :--------: | :-------------------------------------------------------------------------------- |
| `'V'` | `uint16_t` | Battery voltage in tenths of a volt (multiply by 0.1 for volts)                   |
| `'t'` | `uint32_t` | Uptime in ms                                                                      |
| `'T'` | `uint16_t` | Temperature in 0.1C                                                               |
| `'r'` | `uint8_t`  | Enable (`1`) / Disable (`0`) radio transmissions                                  |
| `'F'` | `uint8_t`  | Enable (`1`) / Disable (`0`) the electric fence / switched output                 |
| `'s'` |    none    | Request the status                                                                |
| `'I'` | `uint8_t`  | Interval between transmissions (in 3 minute steps for the electric fence monitor) |
| `'P'` | `uint16_t` | Pump run time in last block in 0.5s                                               |
| `'a'` | `uint16_t` | Average pump run time in 0.5s                                                     |
| `'w'` | `uint16_t` | Water detected (PICAXE `touch16` value) - subject to change                       |
| `'m'` | `uint16_t` | Maximum pump run time in block                                                    |
| `'n'` | `uint16_t` | Minimum pump run time in block                                                    |
| `'c'` | `uint16_t` | Count of pump starts in block                                                     |
