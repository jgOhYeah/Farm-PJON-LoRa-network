#!/usr/bin/python3
""" ThingsboardLoRa.py
A gateway to receive PJON formatted LoRa packets from the farm network and send
them to Thingsboard. Designed to run from a raspberry pi.

Note that PyLora needs to be from this fork and branch as the original does not
work with python 3: https://github.com/hnlichong/PyLora/tree/py35
"""
from struct import pack
import PyLora
import traceback # For logging exceptions
import paho.mqtt.client as mqtt
import time
from datetime import datetime # To print generated date
import pjon
import RPi.GPIO as GPIO
from queue import Queue
import json
import threading

GPIO.setmode(GPIO.BCM)

status_led = 8
GPIO.setup(status_led, GPIO.OUT)
GPIO.output(status_led, GPIO.HIGH)

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
        "type": int, # Data type the end result will be
        "multiplier": 1 # To get 1 for on, 0 for off. Multiplier to turn back into a float (in case 125 is acutally 12.5V)
    },
    "F": {
        "name": "Fence Enabled", # Attribute to send to thingsboard
        "length": 1, # Number of bytes this field takes
        "type": int, # Data type the end result will be
        "multiplier": 1 # To get 1 for on, 0 for off. Multiplier to turn back into a float (in case 125 is acutally 12.5V)
    },
    "s": { # Don't actually expect to get this, but include it anyway
        "name": "Request status", # Attribute to send to thingsboard
        "length": 0, # Number of bytes this field takes
        "type": int, # Data type the end result will be
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

lock = threading.Lock()
request_counter = 0

class FencePacket():
    global lock
    def __init__(self):
        self.parameters = {
            "I": {
                "value": None,
                "tx_required": False
            },
            "F": {
                "value": None,
                "tx_required": False
            },
            "r": {
                "value": None,
                "tx_required": False
            }
        }
    
    def add_telemetry(self, payload):
        """ When given a received packet payload from the fence, checks off
        what still needs to be sent. """
        lock.acquire()
        i = 0
        while i < len(payload):
            field = chr(payload[i])
            length = fields[field]["length"]
            value = fields[field]["type"](self.bytes_to_number(payload, i + 1, length))

            if field in self.parameters:
                if value == self.parameters[field]["value"]:
                    # Already at the setting. No need to resend
                    self.parameters[field]["tx_required"] = False
            
            # Setup for next
            i += length + 1
        lock.release()
    
    def tx_required(self):
        """ Returns True if there is data still to send. """
        lock.acquire()
        for i in self.parameters:
            if self.parameters[i]["tx_required"]:
                lock.release()
                return True
        
        lock.release()
        return False
    
    def generate_payload(self):
        """ Generates the payload of the packet to send """
        lock.acquire()
        payload = []
        for i in self.parameters:
            if self.parameters[i]["tx_required"]:
                payload.append(ord(i) | 0x80)
                payload.append(self.parameters[i]["value"]) # NOTE: Currently only supports length 1
            
        lock.release()
        return bytes(payload)

    def set_fence(self, state):
        """ Turns the fence on or off. """
        log("Setting fence to: {}".format(state))
        lock.acquire()
        self.parameters["F"]["value"] = state
        self.parameters["F"]["tx_required"] = True
        lock.release()

    def bytes_to_number(self, lst, start, size):
        """ Converts bytes in a list into a number """
        number = 0
        for i in range(start + size - 1, start - 1, -1):
            number <<= 8
            number += lst[i]

        return number
        
fence_tx = FencePacket()
transmitting = False

def log(msg):
    with open("/home/pi/LoRa/ThingsboardLoRa.log", "a") as log_file:
        msg = "{}:\t{}".format(datetime.now(), msg)
        print(msg)
        log_file.write("{}\n".format(msg))

def dummy_packet():
    sim_delay = random.random() * 30
    log("Dummy packet will \"arrive\" in: {}s".format(sim_delay))
    time.sleep(sim_delay)
    data = ExampleData.data[random.randrange(len(ExampleData.data))]
    log("\"Received\" fake packet: {}".format(list(data)))
    try:
        received = decoder.parse(data)
    except pjon.PJONPacketError:
        log("Packet is not valid or addressed to us")
    else:
        # Successfully got a packet. Return it
        log("Got a valid packet")
        return received

def pjon_wait_packet():
    """ Blocks until a valid pjon packet is received. """
    while True:
        log("Waiting for packet")
        PyLora.receive()   # put into receive mode
        while transmitting or not PyLora.packet_available():
            # wait for a package
            time.sleep(0.1)
        received = PyLora.receive_packet()
        print(received)
        if len(received) <= 3 or received[2] == 0:
            # Short test if valid or not to quickly skip to the next
            log("X")
        else:
            log("Got a packet. Will try to process it")
            try:
                received = decoder.parse(received)
            except pjon.PJONPacketError as e:
                log("Packet is not valid or addressed to us.\nMessage: {}\nPacket: {}\n".format(e.message, list(e.packet)))
            else:
                # Successfully got a packet. Return it
                log("Got a valid packet\n")
                return received

def tx_thread():
    """ Checks if a packet needs to be sent and does so once every 10 seconds
    if needed """
    while True:
        if fence_tx.tx_required():
            payload = fence_tx.generate_payload()
            packet = decoder.generate(0x4A, payload)
            log("Need to send packet: {}".format(packet))
            transmitting = True # NOTE: Is this thread safe?
            PyLora.send_packet(packet)
            transmitting = False
            PyLora.receive()   # Put into receive mode

        time.sleep(10)

def generate_payload(received):
    """ Converts the payload of a pjon packet into a json mqqt format """
    out = ""
    i = 0
    while i < len(received):
        field = chr(received[i])
        length = fields[field]["length"]
        value = fence_tx.bytes_to_number(received, i + 1, length)
        value = fields[field]["type"](value)

        # Format
        # Format bools as expected by json
        if isinstance(value, bool):
            if value:
                value = "true"
            else:
                value = "false"
        else:
            value = round(value * fields[field]["multiplier"], 1)

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
        log("Adding device {}".format(devices[i]["name"]))
        mqtt.publish(topic, payload=out, qos=0, retain=False)

def send_tx_status(device, request_id):
    status = fence_tx.tx_required()
    topic = "v1/gateway/rpc"
    payload = "{{\"device\": \"{}\", \"id\": {}, \"data\": {{\"isOutgoing\": {}}}}}".format(device, int(request_id), status)
    mqtt.publish(topic, payload=payload, qos=0, retain=False)

def send_tx_status_attribute():
    status = fence_tx.tx_required()
    topic = "v1/gateway/attributes"
    payload = "{{\"{}\": {{\"isOutgoing\": {}}}}}".format(devices[0x4A]["name"], status)
    mqtt.publish(topic, payload=payload, qos=0, retain=False)

def on_connect(client, userdata, flags, rc):
    log("MQTT connected")
    upload_device_list()

    # Setup RPC
    topic = "v1/gateway/rpc"
    mqtt.subscribe(topic, qos = 0)

def on_message(client, userdata, message):
    global request_counter
    log("Got MQTT message")
    log("Topic: {}, Payload: {}".format(message.topic, message.payload))
    payload = json.loads(message.payload.decode("utf-8"))
    request_counter = payload["data"]["id"] + 1
    if payload["data"]["method"] == "isOutgoing":
        log("Request for queue status")
        send_tx_status(payload["device"], payload["data"]["id"])
    if payload["data"]["method"] == "setFenceStatus" and payload["device"] == "Solar Electric Fence":
        log("Request to turn fence on or off")
        fence_tx.set_fence(payload["data"]["params"])
        send_tx_status_attribute()

if __name__ == "__main__":
    mqtt = mqtt.Client()
    try:
        # Start LoRa
        log("Starting LoRa")
        PyLora.set_pins(cs_pin=24, rst_pin=25)
        log("Init: {}".format(PyLora.init()))
        log("Is connected: {}".format(PyLora.is_connected()))
        PyLora.set_frequency(lora_freq)
        PyLora.set_spreading_factor(lora_sf)
        PyLora.set_tx_power(17)

        # Start transmission thread
        tx = threading.Thread(target=tx_thread)
        tx.start()

        # Start MQTT
        mqtt.on_connect = on_connect
        mqtt.on_message = on_message
        mqtt.username_pw_set(mqtt_access_token)

        # Try to get mqtt running - might take a while when starting from boot
        while True:
            try:
                mqtt.connect(mqtt_address)
            except:
                log("MQTT could not be stated. Trying again in a few seconds.")
                mqtt.loop_stop()
                mqtt.disconnect()
                time.sleep(10)
            else:
                log("MQTT connected successfully")
                break

        mqtt.loop_start()

        log("Started")
        while True:
            # Wait for a packet to arrive
            received = pjon_wait_packet()
            # received = dummy_packet()
            if received:
                GPIO.output(status_led, GPIO.LOW) # Flash LED off to say got something. Doesn't go off for long enough
                payload, sender = received

                # Process the packet
                print ('Packet received: {}'.format(payload))
                to_send = "{{{}, \"SNR\": {}, \"RSSI\": {}}}".format(generate_payload(payload), PyLora.packet_snr(), PyLora.packet_rssi())


                # Send the packet over mqtt
                topic = "v1/gateway/telemetry"
                mqtt_payload = "{{\"{}\":[{}]}}".format(devices[sender]["name"], to_send) # TODO: Make not crash when unkown id
                log("Data: {}".format(mqtt_payload))
                mqtt.publish(topic, payload=mqtt_payload, qos=0, retain=False)
                GPIO.output(status_led, GPIO.HIGH)

                # Cross reference with packet to send
                if sender == 0x4A:
                    fence_tx.add_telemetry(payload)
                    if not fence_tx.tx_required():
                        send_tx_status_attribute()
            else:
                log("Ignoring packet")
            # Stop the loop for testing
            log("Done")

    except KeyboardInterrupt:
        log("Keyboard interrupt stopping.\n\n")

    except Exception as e:
        tb_str = traceback.format_exception(etype=type(e), value=e, tb=e.__traceback__) # https://stackoverflow.com/a/54083435
        log("""Stopping because of exception\n{}\n{}{}{}\n\n\n""".format(type(e), tb_str[0], tb_str[1], tb_str[2]))

    GPIO.output(status_led, GPIO.LOW)
    GPIO.cleanup()
    mqtt.loop_stop()
    mqtt.disconnect()
