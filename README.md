# 🐾 Smart Pet Feeder System

An IoT-enabled pet feeding system with automated scheduling, real-time monitoring, and mobile app control. Built with Flutter, Firebase, and ESP32.

## 📋 Overview

The Smart Pet Feeder is a comprehensive solution for automated pet feeding that allows pet owners to:
- Schedule automatic feeding times
- Monitor food levels in real-time
- Receive notifications when pets are detected or food is low
- Track feeding history and analytics
- Manually dispense food remotely via mobile app

## 🏗️ System Architecture

### Components
- **Mobile App** (Flutter): Cross-platform app for iOS, Android, and Web
- **Backend** (Firebase): Cloud Firestore, Authentication, and Realtime Database
- **Hardware** (ESP32): Microcontroller with sensors and servo motor
- **Cloud Services** (Python): Backend monitoring and notification services

### Hardware Components
- ESP32 microcontroller
- HC-SR04 ultrasonic sensor (food level detection)
- Active IR sensor (pet detection)
- DHT11 sensor (temperature/humidity monitoring)
- Servo motor (food dispenser)
- LED and button for manual control

## ✨ Features

- **Automated Scheduling**: Set multiple daily feeding times
- **Real-time Monitoring**: Live updates on food levels, temperature, and humidity
- **Pet Detection**: IR sensor detects when your pet approaches the feeder
- **Push Notifications**: Get alerts for low food, feeding events, and pet detection
- **Feeding History**: Track all feeding events with timestamps and analytics
- **Manual Feed**: Dispense food anytime via the app or physical button
- **Daily Feeding Limits**: Set maximum daily feeding portions
- **Analytics Dashboard**: Visualize feeding patterns and trends

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.1.5)
- Firebase account
- ESP32 development board
- Arduino IDE
- Python 3.8+ (for cloud services)

### Installation

#### 1. Mobile App Setup

```bash
# Clone the repository
git clone <repository-url>
cd smart_pet_feeder

# Install dependencies
flutter pub get

# Run the app
flutter run
```

#### 2. Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication (Email/Password)
3. Create a Cloud Firestore database
4. Set up Firebase Realtime Database
5. Configure Firebase Cloud Messaging for notifications
6. Update `lib/config/firebase_config.dart` with your credentials

#### 3. Hardware Setup

1. Install required Arduino libraries:
   - PubSubClient (Nick O'Leary)
   - ESP32Servo (Kevin Harrington)
   - DHT sensor library (Adafruit)
   - ArduinoJson (Benoit Blanchon)

2. Configure WiFi and MQTT credentials in `hardware/main/secret.h`
3. Upload `hardware/main/main.ino` to ESP32

## 📱 Mobile App Screens

- **Login/Signup**: User authentication
- **Dashboard**: Overview of feeder status, food level, and quick actions
- **Schedule**: Manage automated feeding schedules
- **History**: View feeding logs and events
- **Analytics**: Charts and statistics on feeding patterns
- **Profile**: User settings and pet information
