#!/usr/bin/python3
""" ThingsboardLoRa.py
A gateway to receive PJON formatted LoRa packets from the farm network and send
them to Thingsboard. Designed to run from a raspberry pi.

Note that PyLora needs to be from this fork and branch as the original does not
work with python 3: https://github.com/hnlichong/PyLora/tree/py35
"""
import PyLora
import paho.mqtt.client as mqtt
import time
from datetime import datetime # To print generated date
import pjon

# Required for testing only:
import ExampleData
import random

# LoRa and PJON settings
lora_freq = 433000000
lora_sf = 9
my_id = 255
decoder = pjon.PJON(my_id)

# MQTT Thingsboard settings
mqtt_address = "localhost"
mqtt_access_token = "rHsuaUlb73zJ7Rxxn7MR"

# LoRa devices to thingsboard
devices = {
    0x4A: { # Fence
        "name": "Solar Electric Fence"
    },
    0x5A: { # Pump
        "name": "Main Pressure Pump"
    }
}

fields = {
    "V": {
        "name": "Battery Voltage", # Attribute to send to thingsboard
        "length": 2, # Number of bytes this field takes
        "type": float, # Data type the end result will be
        "multiplier": 0.1 # To get mV. Multiplier to turn back into a float (in case 125 is acutally 12.5V)
    },
    "t": {
        "name": "Uptime", # Attribute to send to thingsboard
        "length": 4, # Number of bytes this field takes
        "type": int, # Data type the end result will be
        "multiplier": 1 # To get ms. Multiplier to turn back into a float (in case 125 is acutally 12.5V)
    },
    "T": {
        "name": "Temperature", # Attribute to send to thingsboard
        "length": 2, # Number of bytes this field takes
        "type": float, # Data type the end result will be
        "multiplier": 0.1 # To get degrees C.  Multiplier to turn back into a float (in case 125 is acutally 12.5V)
    },
    "r": {
        "name": "Transmit Enabled", # Attribute to send to thingsboard
        "length": 1, # Number of bytes this field takes
        "type": bool, # Data type the end result will be
        "multiplier": 1 # To get 1 for on, 0 for off. Multiplier to turn back into a float (in case 125 is acutally 12.5V)
    },
    "F": {
        "name": "Fence Enabled", # Attribute to send to thingsboard
        "length": 1, # Number of bytes this field takes
        "type": bool, # Data type the end result will be
        "multiplier": 1 # To get 1 for on, 0 for off. Multiplier to turn back into a float (in case 125 is acutally 12.5V)
    },
    "s": { # Don't actually expect to get this, but include it anyway
        "name": "Request status", # Attribute to send to thingsboard
        "length": 0, # Number of bytes this field takes
        "type": bool, # Data type the end result will be
        "multiplier": 1 # Multiplier to turn back into a float (in case 125 is acutally 12.5V)
    },
    "I": {
        "name": "Transmit Interval", # Attribute to send to thingsboard
        "length": 1, # Number of bytes this field takes
        "type": int, # Data type the end result will be
        "multiplier": 1 # To get minutes. Multiplier to turn back into a float (in case 125 is acutally 12.5V)
    },
    "P": {
        "name": "Pump on time", # Attribute to send to thingsboard
        "length": 2, # Number of bytes this field takes
        "type": float, # Data type the end result will be
        "multiplier": 0.5 # To get seconds per 30 min block. Multiplier to turn back into a float (in case 125 is acutally 12.5V)
    },
    "a": {
        "name": "Average pump on time", # Attribute to send to thingsboard
        "length": 2, # Number of bytes this field takes
        "type": float, # Data type the end result will be
        "multiplier": 0.5 # To get seconds per 30 min block. Multiplier to turn back into a float (in case 125 is acutally 12.5V)
    }
}

def dummy_packet():
    sim_delay = random.random() * 30
    print("Dummy packet will \"arrive\" in: {}s".format(sim_delay))
    time.sleep(sim_delay)
    data = ExampleData.data[random.randrange(len(ExampleData.data))]
    print("\"Received\" fake packet: {}".format(list(data)))
    try:
        received = decoder.parse(data)
    except pjon.PJONPacketError:
        print("Packet is not valid or addressed to us")
    else:
        # Successfully got a packet. Return it
        print("Got a valid packet")
        return received

def pjon_wait_packet():
    """ Blocks until a valid pjon packet is received. """
    while True:
        print("Waiting for packet")
        PyLora.receive()   # put into receive mode
        while not PyLora.packet_available():
            # wait for a package
            time.sleep(0.25)
        received = PyLora.receive_packet()
        print("Got a packet. Will try to process it")
        try:
            received = decoder.parse(received)
        except pjon.PJONPacketError:
            print("Packet is not valid or addressed to us")
        else:
            # Successfully got a packet. Return it
            print("Got a valid packet")
            return received

def bytes_to_number(lst, start, size):
    """ Converts bytes in a list into a number """
    number = 0
    for i in range(start + size - 1, start - 1, -1):
        number <<= 8
        number += lst[i]

    return number

def generate_payload(received):
    """ Converts the payload of a pjon packet into a json mqqt format """
    out = ""
    i = 0
    while i < len(received):
        field = chr(received[i])
        length = fields[field]["length"]
        value = fields[field]["type"](bytes_to_number(received, i + 1, length))

        # Format
        # Format bools as expected by json
        if isinstance(value, bool):
            if value:
                value = "true"
            else:
                value = "false"
        else:
            value = value * fields[field]["multiplier"]

        # Add a comma to deliminate
        if i != 0:
            out += ", "

        # Combine everything
        out += "\"{}\": {}".format(fields[field]["name"], value)

        # Setup for next
        i += length + 1

    return out

def upload_device_list():
    """ Sends a list of devices to Thingsboard """
    topic = "v1/gateway/connect"
    for i in devices:
        out = "{{\"device\": \"{}\"}}".format(devices[i]["name"])
        print("Adding device {}".format(devices[i]["name"]))
        mqtt.publish(topic, payload=out, qos=0, retain=False)

def on_connect(client, userdata, flags, rc):
    print("MQTT connected")
    upload_device_list()

    # Setup RPC
    topic = "v1/devices/me/rpc/request/+"
    mqtt.subscribe(topic, qos = 0)

def on_message(client, userdata, flags, rc):
    print("Got MQTT message")

if __name__ == "__main__":
    # Start LoRa
    print("Starting LoRa")
    PyLora.init()
    PyLora.set_frequency(lora_freq)
    PyLora.set_spreading_factor(lora_sf)

    # Start MQTT
    mqtt = mqtt.Client()
    mqtt.on_connect = on_connect
    mqtt.on_message = on_message
    mqtt.username_pw_set(mqtt_access_token)
    mqtt.connect(mqtt_address)
    mqtt.loop_start()

    print("Started")
    while True:
        # Wait for a packet to arrive
        # received = pjon_wait_packet()
        received = dummy_packet()
        if received:
            payload, sender = received

            # Process the packet
            print ('Packet received: {}'.format(payload))
            to_send = "{{{}, \"SNR\": {}, \"RSSI\": {}}}".format(generate_payload(payload), PyLora.packet_snr(), PyLora.packet_rssi())

            # Send the packet over mqtt
            # NOTE: Does not seem to update
            topic = "v1/gateway/telemetry"
            payload = "{{\"{}\":[{}]}}".format(devices[sender]["name"], to_send)
            print("Data: {}".format(payload))
            mqtt.publish(topic, payload=payload, qos=0, retain=False)
        else:
            print("Ignoring packet")
        # Stop the loop for testing
        print("Done")