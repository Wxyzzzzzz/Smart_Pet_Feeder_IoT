# ESP32 Hardware Setup Guide

## Overview

This repository contains the firmware for the SmartPet Feeder hardware code. It is implement with ESP32 platform and use MQTT for communication.

### Hardware Component Involved

1. **ESP32 Microcontroller**
2. **HC-SR04 Ultrasonic Sensor**
3. **SG90 Micro Servo**
4. **DHT11**
5. **Active IR Sensor**
6. **LED Light**
7. 3 **1kOhm Resistor**

## Required Libraries

Install these libraries in Arduino IDE:

1. **PubSubClient** by Nick O'Leary (MQTT)
2. **ESP32Servo** by Kevin Harrington
3. **DHT sensor library** by Adafruit
4. **ArduinoJson** by Benoit Blanchon

## Configuration Steps

### 1. Create secret.h File

Copy `secret.h.template` to `secret.h`:

```bash
cd hardware/main
cp secret.h.template secret.h
```

### 2. Update Credentials

Open `secret.h` and update all credentials.

### 3. Configure Firebase

## Hardware Connections

### ESP32 Pin Mapping:

```
LEFT SIDE (5V Components):
- GPIO 13 → Servo Motor Signal (PWM)
- GPIO 27 → Ultrasonic TRIG
- GPIO 26 → Ultrasonic ECHO

RIGHT SIDE (3.3V Components):
- GPIO 4  → IR Sensor (Obstacle Detection)
- GPIO 18 → DHT11 Data Pin
- GPIO 14 → Manual Feed Button
- GPIO 15 → LED Indicator

POWER:
- 5V  → Servo Motor VCC, Ultrasonic VCC
- 3.3V → DHT11 VCC, IR Sensor VCC
- GND → Common ground
```

## Upload to ESP32

### 1. Select Board:
- Arduino IDE → Tools → Board → **ESP32 Dev Module**

### 2. Select Port:
- Tools → Port → Select your ESP32's COM port

### 3. Upload:
- Click the **Upload** button (→)
- Wait for compilation and upload to complete

### 4. Open Serial Monitor:
- Tools → Serial Monitor
- Set baud rate to **9600**
