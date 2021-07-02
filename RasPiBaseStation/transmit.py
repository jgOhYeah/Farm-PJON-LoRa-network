import PyLora
import time
print(PyLora.init())
PyLora.set_frequency(433000000)
PyLora.enable_crc()
while True:
    PyLora.send_packet(b'Hello')
    print('Packet sent...')
    time.sleep(2)