# ESP32 Hardware Setup Guide

## 🎯 Overview

Your ESP32 now supports **bidirectional communication** with Firebase:
- ✅ Sends sensor data to Firebase (telemetry)
- ✅ Receives feeding commands from the Flutter app
- ✅ Updates command status in real-time

## 📦 Required Libraries

Install these libraries in Arduino IDE:

1. **Firebase ESP32 Client** by Mobizt
   - Arduino IDE: Sketch → Include Library → Manage Libraries
   - Search: "Firebase ESP32 Client"
   - Install the latest version

2. **PubSubClient** by Nick O'Leary (MQTT)
3. **ESP32Servo** by Kevin Harrington
4. **DHT sensor library** by Adafruit
5. **ArduinoJson** by Benoit Blanchon

## ⚙️ Configuration Steps

### 1. Create secret.h File

Copy `secret.h.template` to `secret.h`:

```bash
cd hardware/main
cp secret.h.template secret.h
```

### 2. Update WiFi Credentials

Open `secret.h` and update:

```cpp
#define WIFI_SSID "YourWiFiName"
#define WIFI_PASS "YourWiFiPassword"
```

### 3. Configure Firebase

#### Get Firebase API Key:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click ⚙️ → **Project Settings**
4. Copy **Web API Key**

#### Get Project ID:
- Same page, under "Project ID"

#### Update secret.h:
```cpp
#define FIREBASE_API_KEY "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
#define FIREBASE_PROJECT_ID "your-project-id"
#define FIREBASE_DATABASE_URL "https://your-project-id.firebaseio.com"
```

### 4. Create Device User in Firebase Auth

Your ESP32 needs authentication to access Firebase:

1. Go to Firebase Console → **Authentication**
2. Click **Users** tab
3. Click **Add User**
4. Enter:
   - Email: `device@yourproject.com` (or any email)
   - Password: Create a strong password
5. Click **Add User**

#### Update secret.h:
```cpp
#define FIREBASE_USER_EMAIL "device@yourproject.com"
#define FIREBASE_USER_PASSWORD "YourStrongPassword123"
```

## 🔌 Hardware Connections

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
- GND → All component grounds (common ground)
```

### Component Wiring Diagram:

```
Servo Motor (SG90):
├─ Brown  → GND
├─ Red    → 5V (external power recommended for multiple servos)
└─ Orange → GPIO 13

Ultrasonic Sensor (HC-SR04):
├─ VCC  → 5V
├─ TRIG → GPIO 27
├─ ECHO → GPIO 26
└─ GND  → GND

DHT11 Temperature/Humidity:
├─ VCC  → 3.3V
├─ DATA → GPIO 18
└─ GND  → GND

IR Obstacle Sensor:
├─ VCC → 3.3V
├─ OUT → GPIO 4
└─ GND → GND

Manual Feed Button:
├─ One side → GPIO 14
└─ Other side → GND

LED Indicator:
├─ Long leg (Anode) → GPIO 15 (through 220Ω resistor)
└─ Short leg (Cathode) → GND
```

## 📤 Upload to ESP32

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

## 🧪 Testing

### Expected Serial Output:

```
Connecting to YourWiFi....
WiFi connected
IP address: 192.168.1.100
Attempting MQTT connection...connected
Initializing Firebase...
Firebase initialized
--------------------------------
STATUS: Feeding MANUAL - Portion: 20g
SUCCESS: Info updated to MQTT
--------------------------------
Sent Telemetry: {"device_id":"feeder_001","food_level":75,"temp":26.5,"humidity":55,"detected":false}
Processing Firebase command: 20g
Updated command status to: processing
--------------------------------
STATUS: Feeding APP - Portion: 20g
SUCCESS: Info updated to MQTT
--------------------------------
Updated command status to: completed
Command completed successfully
```

## 🔄 How It Works

### 1. On Startup:
- Connects to WiFi
- Connects to MQTT broker (Google Cloud)
- Initializes Firebase
- Starts checking for commands

### 2. Every 10 Seconds:
- Reads sensors (ultrasonic, DHT11, IR)
- Publishes telemetry to MQTT
- Updates Firebase with current state

### 3. Every 2 Seconds:
- Queries Firebase for pending commands
- Checks `feeders/feeder_001/feeding_commands` collection
- Processes any commands with `status: "pending"`

### 4. When Command Found:
1. Updates command status to `"processing"`
2. Activates servo motor (angle based on portion size)
3. Dispenses food for 3 seconds
4. Updates command status to `"completed"`
5. Publishes feeding event to MQTT

### 5. Manual Button Press:
- Immediately dispenses 20g
- Publishes to both MQTT and Firebase

## 🎛️ Servo Motor Portion Mapping

The servo angle is automatically calculated based on portion size:

| Portion Size | Servo Angle | Duration |
|--------------|-------------|----------|
| 5g           | 30°         | 3 seconds |
| 20g          | 90°         | 3 seconds |
| 35g          | 150°        | 3 seconds |
| 50g          | 180°        | 3 seconds |

Formula: `angle = map(portionSize, 5, 50, 30, 180)`

## 🐛 Troubleshooting

### "Firebase not ready"
**Solution:**
- Check Firebase credentials in secret.h
- Verify device user exists in Firebase Auth
- Check internet connection

### "Failed to list documents"
**Solution:**
- Verify Firestore security rules allow device to read/write
- Check Firebase Project ID is correct
- Ensure `feeding_commands` collection path is correct

### Servo doesn't move
**Solution:**
- Check servo power (5V)
- Verify GPIO 13 connection
- Test servo with simple sketch first
- May need external 5V power supply for servo

### "MQTT connection failed"
**Solution:**
- This is normal if you haven't set up Google Cloud IoT yet
- Firebase commands will still work
- MQTT is optional for this setup

### Command executed but app doesn't show status
**Solution:**
- Check serial monitor for "Updated command status" messages
- Verify timestamp format is correct (ISO 8601)
- Check Firestore console to see if status was updated

## 📊 Data Flow Diagram

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│ Flutter App │         │   Firebase   │         │   ESP32     │
│  (Mobile)   │         │  Firestore   │         │  Hardware   │
└─────────────┘         └──────────────┘         └─────────────┘
       │                       │                        │
       │ 1. User clicks       │                        │
       │    "FEED NOW 20g"    │                        │
       │─────────────────────>│                        │
       │ Create command       │                        │
       │ status: "pending"    │                        │
       │                      │                        │
       │                      │  2. ESP32 queries      │
       │                      │     every 2 seconds    │
       │                      │<───────────────────────│
       │                      │  Get pending commands  │
       │                      │                        │
       │                      │  3. Command found!     │
       │                      │───────────────────────>│
       │                      │                        │
       │                      │  4. Update status      │
       │                      │<───────────────────────│
       │                      │  status: "processing"  │
       │                      │                        │
       │                      │                        │  5. Servo ON
       │                      │                        │     Dispense
       │                      │                        │     food ⚙️
       │                      │                        │
       │                      │  6. Update status      │
       │                      │<───────────────────────│
       │                      │  status: "completed"   │
       │                      │                        │
       │ 7. App receives      │                        │
       │    status update     │                        │
       │<─────────────────────│                        │
       │ Show: "✅ Fed        │                        │
       │       successfully!" │                        │
```

## 🚀 Next Steps

1. **Upload the code** to your ESP32
2. **Test manual button** - Should dispense food immediately
3. **Test from app** - Click "FEED NOW" in Flutter app
4. **Monitor serial output** - Watch for command processing
5. **Check Firebase Console** - Verify command status updates

## 🔐 Security Notes

- Never commit `secret.h` to version control
- Use strong passwords for Firebase device user
- Update Firestore security rules to restrict device access
- Consider using Firebase service account for production

---

**Your ESP32 is now fully integrated with Firebase for bidirectional control!** 🎉
