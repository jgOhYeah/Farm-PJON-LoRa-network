import PyLora
import time
from datetime import datetime # To print generated date

print(PyLora.init())
PyLora.set_frequency(433000000)
PyLora.set_spreading_factor(9)
print("Started")
while True:
    PyLora.receive()   # put into receive mode
    while not PyLora.packet_available():
        # wait for a package
        time.sleep(0.1)
    rec = PyLora.receive_packet()
    print ('Packet received: {}'.format(rec))
    with open("records.csv", "a") as file:
        file.write("{},{},{},{}\n".format(datetime.today().strftime("%Y-%m-%d %H:%M:%S"), rec, PyLora.packet_rssi(), PyLora.packet_snr()))
