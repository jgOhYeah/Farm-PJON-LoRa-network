import csv
import serial
import time
ser = serial.Serial('/dev/ttyUSB1', 38400, timeout=1)  # open serial por
with open('output.csv') as csvfile:
    data = csv.reader(csvfile, delimiter=',', quotechar='|')
    for row in data:
        print(row)
        addrl = 2*int(row[0]) - 1
        addrh = 2*int(row[0]) - 2
        high = int(row[1]) >> 8
        low = int(row[1]) & 0xFF
        print("HIGH: {} <- {}\tLOW: {} <- {}".format(addrh, high, addrl, low))
        ser.write('w\r\n'.encode('UTF-8'))
        time.sleep(0.05)
        print(ser.readline())
        ser.write("{}\r\n".format(addrh).encode("UTF-8"))
        time.sleep(0.05)
        print(ser.readline())
        ser.write("{}\r\n".format(high).encode("UTF-8"))
        ret = ser.readline()
        while "input:" not in str(ret):
            print(ret)
            ret = ser.readline()
        time.sleep(0.05)
        ser.write('w\r\n'.encode('UTF-8'))
        time.sleep(0.05)
        ser.write("{}\r\n".format(addrl).encode("UTF-8"))
        time.sleep(0.05)
        print(ser.readline())
        ser.write("{}\r\n".format(low).encode("UTF-8"))
        ret = ser.readline()
        while "input:" not in str(ret):
            print(ret)
            ret = ser.readline()
        time.sleep(0.05)
        
        

ser.close()
