# Farm-PJON-LoRa-network
Code relating to a small LoRa network for remote monitoring and control.
This is a work in progress.

## Base station
Currently an Arduino Nano and 40x2 Alphanumeric LCD, thinking of swapping the nano with a raspberry pi to allow better data logging and display over an ip network.
This is still a work in progress.
Needs the lcd graph library I have written to draw graphs on alpha numeric lcds. It is also a work in progress. This can be found [here](https://github.com/jgOhYeah/LCDGraph).

## Battery Voltage Monitor and Electric Fence control
This is code currently in use in a device that is monitoring battery charge in a remote solar powered electric fence. It sends a packet with the battery voltage once every few minutes and listens for an incoming packet for a set time after each tansmission. The incoming packet can tell the device to turn the fence on or off or control other aspects of the radio link such as disabling tranmissions until another incoming packet enables them or requesting the current status be resent.

### Stripboard Plans
I used KiCad to plan a layout on veroboard so that I knew there was room for everything and I didn't end up cutting the wrong tracks. The yellow circles and lines in layer `Eco2.User` are where tracks should be cut. The KiCad files can be found [here](BatteryVoltageMonitor/BatteryMonitorVeroboardLayout).
![Battery Voltage Monitor Schematic](Pictures/BatteryMonitorSchematic.png)
![Planned layout on stripboard](Pictures/BatteryMonitorVeroboardLayout.svg)

### Photos
This is a work in progess and as such it is only temperarily mounted in the shed, although you know what they say about temporary things :).
![Circuit on stripboard in a plastic box](Pictures/BatteryMonitor.jpg)

Battery voltage monitor before the mosfet was added for controlling the fence and an external antenna to improve range.

![Inside of a shed with fence energiser, battery and monitor](Pictures/ShedInside.jpg)

The shed and setup of the battery monitor.
