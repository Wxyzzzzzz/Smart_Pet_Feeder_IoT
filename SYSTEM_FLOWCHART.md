# Smart Pet Feeder - System Flow Diagram

## 🎯 Complete User Interaction Flow

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                    👤 PET OWNER USER                                    │
└──────────────────────────────┬──────────────────────────────────────────────────────────┘
                               │
                               ├─── ACTION 1: AUTHENTICATION
                               │    
                ┌──────────────▼──────────────┐
                │  📱 Login/Signup Screen     │
                │  ─────────────────────────  │
                │  • Email & Password         │
                │  • Create Account           │
                │  • Reset Password           │
                └──────────────┬──────────────┘
                               │
                               ▼
                ┌──────────────────────────────┐
                │  🔐 Firebase Authentication  │
                │  ──────────────────────────  │
                │  • Verify Credentials        │
                │  • Generate JWT Token        │
                │  • Create User Session       │
                └──────────────┬───────────────┘
                               │
                               ├─── ACTION 2: VIEW DASHBOARD (REAL-TIME MONITORING)
                               │    
                ┌──────────────▼──────────────┐
                │  📊 Dashboard Screen        │◄────────────┐
                │  ─────────────────────────  │             │
                │  • Food Level: 75%          │             │
                │  • Temperature: 26°C        │             │
                │  • Humidity: 55%            │             │
                │  • Obstacle: None           │             │
                │  • Last Fed: 2 hours ago    │             │
                └──────────────┬──────────────┘             │
                               │                            │
                               │ (Stream Live Data)         │
                               ▼                            │
                ┌────────────────────────────────┐          │
                │  ☁️  Firestore Database        │          │
                │  ─────────────────────────────│          │
                │  feeders/feeder_001/          │          │
                │  ├── food_level: 75           │          │
                │  ├── temperature: 26          │          │
                │  ├── humidity: 55             │          │
                │  ├── detected: false          │          │
                │  ├── manual_feed: false       │          │
                │  └── last_seen: timestamp     │          │
                └────────────────┬───────────────┘          │
                                 │                          │
                                 │ (Real-time Updates)      │
                                 └──────────────────────────┘
                                 ▲
                                 │
                                 │ (Store Telemetry)
                                 │
                ┌────────────────┴───────────────┐
                │  🖥️  Backend Service (Python)  │
                │  ────────────────────────────  │
                │  • backend.py                  │
                │  • MQTT Subscriber             │
                │  • Firestore Writer            │
                └────────────────┬───────────────┘
                                 │
                                 │ (Subscribe & Publish)
                                 ▼
                ┌────────────────────────────────┐
                │  📡 MQTT Broker (Mosquitto)    │
                │  ────────────────────────────  │
                │  Topics:                       │
                │  ├── feeder/+/command          │
                │  ├── feeder/+/events           │
                │  └── feeder/+/telemetry        │
                └────────────────┬───────────────┘
                                 │
                                 │ (WiFi Connection)
                                 ▼
                ┌────────────────────────────────┐
                │  🤖 ESP32 IoT Device           │
                │  ────────────────────────────  │
                │  • WiFi Module                 │
                │  • MQTT Client                 │
                │  • Control Logic               │
                └────────────────┬───────────────┘
                                 │
                      ┌──────────┴───────────┐
                      │                      │
        ┌─────────────▼──────────┐  ┌────────▼──────────┐
        │  📊 SENSORS            │  │  ⚙️  ACTUATORS     │
        │  ────────────────────  │  │  ───────────────  │
        │  ├── Ultrasonic        │  │  ├── Servo Motor  │
        │  │   (Food Level)      │  │  │   (Dispenser)  │
        │  ├── IR Sensor         │  │  ├── LED          │
        │  │   (Obstacle)        │  │  └── Button       │
        │  └── DHT11             │  └───────────────────┘
        │      (Temp/Humidity)   │
        └────────────────────────┘

                               │
                               │
                               ├─── ACTION 3: MANUAL FEED (User Triggered)
                               │    
                ┌──────────────▼──────────────┐
                │  User clicks "FEED NOW"     │
                │  Button (20g portion)       │
                └──────────────┬──────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  📱 App sends command          │
                │  ────────────────────────────  │
                │  Firestore.update({            │
                │    manual_feed: true           │
                │  })                            │
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  ☁️  Firestore updates         │
                │  ────────────────────────────  │
                │  manual_feed: false → true     │
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  🖥️  Backend Listener detects  │
                │  ────────────────────────────  │
                │  • on_snapshot() triggered     │
                │  • Detect manual_feed = true   │
                │  • Reset manual_feed = false   │
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  Backend publishes MQTT        │
                │  ────────────────────────────  │
                │  Topic: feeder/feeder_001/cmd  │
                │  Message: "FEED"               │
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  📡 MQTT routes to device      │
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  🤖 ESP32 receives command     │
                │  ────────────────────────────  │
                │  • Parse "FEED" command        │
                │  • Execute dispenseFood()      │
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  ⚙️  Servo Motor activates     │
                │  ────────────────────────────  │
                │  • Rotate 180° for 3 seconds   │
                │  • Food dispensed              │
                │  • Return to 0°                │
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  ESP32 sends event             │
                │  ────────────────────────────  │
                │  Topic: feeder/+/events        │
                │  Payload: {                    │
                │    device_id: "feeder_001",    │
                │    source: "manually",         │
                │    food_remaining: 70          │
                │  }                             │
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  Backend receives event        │
                │  ────────────────────────────  │
                │  • Store in feeding_logs/      │
                │  • Update live status          │
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  ☁️  Firestore updated         │
                │  ────────────────────────────  │
                │  New document in:              │
                │  feeding_logs/{log_id}         │
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  📱 App receives update        │
                │  ────────────────────────────  │
                │  • Real-time stream triggers   │
                │  • UI updates instantly        │
                │  • Show: "✅ Fed successfully!"│
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  👤 User sees confirmation     │
                └────────────────────────────────┘

                               │
                               │
                               ├─── ACTION 4: CREATE SCHEDULE (Automated Feeding)
                               │    
                ┌──────────────▼──────────────┐
                │  📅 Schedule Screen         │
                │  ─────────────────────────  │
                │  User creates routine:      │
                │  • Time: 08:00 AM           │
                │  • Days: Mon-Fri            │
                │  • Portion: 50g             │
                │  • Enabled: ✓               │
                └──────────────┬──────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  App saves to Firestore        │
                │  ────────────────────────────  │
                │  feeders/feeder_001/           │
                │  routines: [                   │
                │    {                           │
                │      enabled: true,            │
                │      time: "08:00",            │
                │      days: [0,1,2,3,4],        │
                │      portion_size: 50          │
                │    }                           │
                │  ]                             │
                └──────────────┬─────────────────┘
                               │
                      ┌────────┴────────┐
                      │                 │
                      │ (Every minute)  │
                      ▼                 │
                ┌────────────────────────────────┐
                │  🖥️  Scheduler Thread          │
                │  ────────────────────────────  │
                │  • Check current time & day    │
                │  • Query all routines          │
                │  • Match: 08:00 + Monday?      │
                │  • ✓ Match found!              │
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  Backend publishes "FEED"      │
                │  ────────────────────────────  │
                │  Topic: feeder/feeder_001/cmd  │
                └──────────────┬─────────────────┘
                               │
                               ▼
                    (Same flow as Manual Feed)
                    ESP32 → Servo → Event → Store
                               │
                               ▼
                ┌────────────────────────────────┐
                │  📱 Push Notification sent     │
                │  ────────────────────────────  │
                │  "🍽️ Scheduled feeding done!"  │
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  👤 User receives alert        │
                └────────────────────────────────┘

                               │
                               │
                               ├─── ACTION 5: VIEW HISTORY & ANALYTICS
                               │    
                ┌──────────────▼──────────────┐
                │  📜 History Screen          │
                │  ─────────────────────────  │
                │  User views feeding logs    │
                └──────────────┬──────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  Query Firestore subcollection │
                │  ────────────────────────────  │
                │  feeders/feeder_001/           │
                │  feeding_logs/                 │
                │  ├── {log1}                    │
                │  │   ├── timestamp: 8:00 AM    │
                │  │   ├── source: scheduled     │
                │  │   └── portion: 50g          │
                │  ├── {log2}                    │
                │  │   ├── timestamp: 12:30 PM   │
                │  │   ├── source: manual        │
                │  │   └── portion: 20g          │
                │  └── ...                       │
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌──────────────▼──────────────┐
                │  📊 Analytics Screen        │
                │  ─────────────────────────  │
                │  • Total feeds today: 5     │
                │  • Total grams: 150g        │
                │  • Avg food level: 68%      │
                │  • Temp range: 24-28°C      │
                │  • Charts & Graphs          │
                └──────────────┬──────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  👤 User views insights        │
                └────────────────────────────────┘

                               │
                               │
                               ├─── ACTION 6: MANAGE PET PROFILE
                               │    
                ┌──────────────▼──────────────┐
                │  🐾 Profile Screen          │
                │  ─────────────────────────  │
                │  User sets:                 │
                │  • Pet Name: "Fluffy"       │
                │  • Pet Type: Cat            │
                │  • Weight: 4.5 kg           │
                │  • Daily Portion: 200g      │
                │  • Portion/Meal: 50g        │
                └──────────────┬──────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  Saved to Firestore            │
                │  ────────────────────────────  │
                │  users/{user_id}/              │
                │  ├── pet_name: "Fluffy"        │
                │  ├── pet_type: "cat"           │
                │  ├── pet_weight: 4.5           │
                │  ├── daily_portion: 200        │
                │  └── portion_per_meal: 50      │
                └──────────────┬─────────────────┘
                               │
                               ▼
                ┌────────────────────────────────┐
                │  App uses for calculations     │
                │  ────────────────────────────  │
                │  • Daily feeding limits        │
                │  • Portion size validation     │
                │  • Health recommendations      │
                └────────────────────────────────┘

                               │
                               │
                               ├─── BACKGROUND PROCESS: SENSOR MONITORING (Every 10s)
                               │    
                ┌──────────────▼──────────────────────────────────┐
                │  🤖 ESP32 reads sensors automatically           │
                │  ──────────────────────────────────────────────│
                │  loop() {                                       │
                │    ├── Read Ultrasonic → Food Level: 75%       │
                │    ├── Read IR Sensor → Detected: false        │
                │    ├── Read DHT11 → Temp: 26°C, Humidity: 55%  │
                │    ├── Create JSON payload                     │
                │    └── Publish to MQTT telemetry topic         │
                │  }                                              │
                └────────────────┬────────────────────────────────┘
                                 │
                                 ▼
                ┌────────────────────────────────────────────────┐
                │  Backend stores in Firestore                   │
                │  ────────────────────────────────────────────  │
                │  • Update live status (main document)          │
                │  • Add to sensor_history/ subcollection        │
                └────────────────┬───────────────────────────────┘
                                 │
                                 ▼
                ┌────────────────────────────────────────────────┐
                │  📱 Dashboard auto-refreshes                   │
                │  (Real-time stream updates UI)                 │
                └────────────────────────────────────────────────┘

                               │
                               │
                               └─── BACKGROUND PROCESS: SMART NOTIFICATIONS (Every 30s)
                                    
                ┌──────────────────────────────────────────────────┐
                │  🖥️  notification_monitor.py                    │
                │  ────────────────────────────────────────────── │
                │  while True:                                     │
                │    ├── Check food_level                          │
                │    │   └── If < 20% → Alert "⚠️ Low Food"        │
                │    ├── Check temperature                         │
                │    │   └── If > 35°C → Alert "🌡️ High Temp"      │
                │    ├── Check obstacle detected                   │
                │    │   └── If true → Alert "🚨 Obstacle!"        │
                │    └── sleep(30)                                 │
                └────────────────┬─────────────────────────────────┘
                                 │
                                 ▼
                ┌────────────────────────────────┐
                │  Firebase Cloud Messaging      │
                │  ────────────────────────────  │
                │  • Send push notification      │
                │  • Target: User's device token │
                └────────────────┬───────────────┘
                                 │
                                 ▼
                ┌────────────────────────────────┐
                │  📱 App receives notification  │
                │  ────────────────────────────  │
                │  • Display alert banner        │
                │  • Play notification sound     │
                │  • Show on lock screen         │
                └────────────────┬───────────────┘
                                 │
                                 ▼
                ┌────────────────────────────────┐
                │  👤 User sees alert & takes    │
                │     appropriate action         │
                └────────────────────────────────┘

```

---

## 🗂️ Firestore Database Structure

```
Firestore Database
│
├── 📁 feeders/
│   │
│   └── 📄 feeder_001/
│       ├── device_id: "feeder_001"
│       ├── manual_feed: false (boolean switch)
│       ├── food_level: 75 (%)
│       ├── temperature: 26 (°C)
│       ├── humidity: 55 (%)
│       ├── detected: false
│       ├── last_seen: timestamp
│       │
│       ├── routines: [
│       │   {
│       │     enabled: true,
│       │     time: "08:00",
│       │     days: [0, 1, 2, 3, 4],
│       │     portion_size: 20
│       │   },
│       │   {
│       │     enabled: true,
│       │     time: "18:00",
│       │     days: [0, 1, 2, 3, 4, 5, 6],
│       │     portion_size: 50
│       │   }
│       │ ]
│       │
│       ├── 📁 feeding_logs/ (subcollection)
│       │   ├── 📄 {log_id_1}/
│       │   │   ├── device_id: "feeder_001"
│       │   │   ├── source: "manual"
│       │   │   ├── food_remaining: 70
│       │   │   ├── portion_size: 20
│       │   │   └── timestamp: 2026-01-17 08:30:00
│       │   │
│       │   ├── 📄 {log_id_2}/
│       │   │   ├── device_id: "feeder_001"
│       │   │   ├── source: "scheduled"
│       │   │   ├── food_remaining: 50
│       │   │   ├── portion_size: 50
│       │   │   └── timestamp: 2026-01-17 12:00:00
│       │   │
│       │   └── 📄 {log_id_3}/
│       │       ├── device_id: "feeder_001"
│       │       ├── source: "button"
│       │       ├── food_remaining: 30
│       │       ├── portion_size: 20
│       │       └── timestamp: 2026-01-17 18:00:00
│       │
│       └── 📁 sensor_history/ (subcollection)
│           ├── 📄 {sensor_id_1}/
│           │   ├── device_id: "feeder_001"
│           │   ├── food_level: 75
│           │   ├── temperature: 26
│           │   ├── humidity: 55
│           │   ├── detected: false
│           │   └── timestamp: 2026-01-17 14:20:10
│           │
│           ├── 📄 {sensor_id_2}/
│           │   ├── device_id: "feeder_001"
│           │   ├── food_level: 73
│           │   ├── temperature: 27
│           │   ├── humidity: 54
│           │   ├── detected: false
│           │   └── timestamp: 2026-01-17 14:20:20
│           │
│           └── 📄 {sensor_id_3}/
│               ├── device_id: "feeder_001"
│               ├── food_level: 72
│               ├── temperature: 27
│               ├── humidity: 53
│               ├── detected: true
│               └── timestamp: 2026-01-17 14:20:30
│
├── 📁 users/
│   │
│   └── 📄 {user_id}/
│       ├── email: "user@example.com"
│       ├── created_at: timestamp
│       ├── fcm_token: "device_token_for_push_notifications"
│       │
│       └── 📁 pets/ (subcollection)
│           │
│           └── 📄 {pet_id}/
│               ├── pet_name: "Fluffy"
│               ├── pet_type: "cat"
│               ├── pet_breed: "Persian"
│               ├── pet_weight: 4.5
│               ├── pet_age: 3
│               ├── daily_portion: 200
│               ├── portion_per_meal: 50
│               └── last_updated: timestamp
│
└── 📁 notifications_log/
    │
    ├── 📄 {notification_id_1}/
    │   ├── user_id: "user_123"
    │   ├── device_id: "feeder_001"
    │   ├── type: "low_food"
    │   ├── message: "⚠️ Food level low (15%)"
    │   ├── sent_at: timestamp
    │   └── read: false
    │
    ├── 📄 {notification_id_2}/
    │   ├── user_id: "user_123"
    │   ├── device_id: "feeder_001"
    │   ├── type: "high_temperature"
    │   ├── message: "🌡️ Temperature high (37°C)"
    │   ├── sent_at: timestamp
    │   └── read: true
    │
    └── 📄 {notification_id_3}/
        ├── user_id: "user_123"
        ├── device_id: "feeder_001"
        ├── type: "scheduled_feed_complete"
        ├── message: "🍽️ Scheduled feeding completed"
        ├── sent_at: timestamp
        └── read: false

```

---

## 📡 MQTT Topics Structure

```
MQTT Broker (Mosquitto) - localhost:1883
│
├── 📤 PUBLISH (ESP32 → Backend)
│   │
│   ├── Topic: feeder/feeder_001/events
│   │   └── Payload: {
│   │         "device_id": "feeder_001",
│   │         "source": "manually" | "scheduled" | "button",
│   │         "food_remaining": 70,
│   │         "portion_size": 20,
│   │         "timestamp": "2026-01-17T14:30:00Z"
│   │       }
│   │
│   └── Topic: feeder/feeder_001/telemetry
│       └── Payload: {
│             "device_id": "feeder_001",
│             "food_level": 75,
│             "temperature": 26,
│             "humidity": 55,
│             "detected": false,
│             "timestamp": "2026-01-17T14:30:15Z"
│           }
│
└── 📥 SUBSCRIBE (Backend → ESP32)
    │
    └── Topic: feeder/feeder_001/command
        └── Payload: "FEED"
                     "STATUS"
                     "RESET"
```

---

## 🔧 System Components & Technologies

```
┌───────────────────────────────────────────────────────────────────────┐
│                        TECHNOLOGY STACK                               │
├───────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  📱 FRONTEND (Mobile & Web)                                          │
│  ├── Framework: Flutter (Dart)                                       │
│  ├── Platforms: Android, iOS, Web                                    │
│  ├── UI Components: Material Design                                  │
│  ├── State Management: StreamBuilder (Real-time)                     │
│  └── Charts: fl_chart, percent_indicator                             │
│                                                                       │
│  ☁️  BACKEND SERVICES                                                │
│  ├── Language: Python 3.x                                            │
│  ├── MQTT Client: paho-mqtt                                          │
│  ├── Backend Service: backend.py (Main listener)                     │
│  ├── Scheduler: Threading (time-based triggers)                      │
│  ├── Notification Monitor: notification_monitor.py                   │
│  └── Deployment: VM/Cloud Server (Ubuntu)                            │
│                                                                       │
│  🗄️  DATABASE & AUTHENTICATION                                       │
│  ├── Database: Google Firestore (NoSQL)                              │
│  ├── Authentication: Firebase Authentication                         │
│  ├── Cloud Messaging: Firebase Cloud Messaging (FCM)                 │
│  └── Admin SDK: firebase-admin (Python)                              │
│                                                                       │
│  📡 MESSAGE BROKER                                                    │
│  ├── Broker: Eclipse Mosquitto MQTT                                  │
│  ├── Protocol: MQTT v3.1.1                                           │
│  ├── Port: 1883 (TCP)                                                │
│  ├── Authentication: Username/Password                               │
│  └── QoS Level: 0 (At most once)                                     │
│                                                                       │
│  🤖 IoT HARDWARE                                                      │
│  ├── Microcontroller: ESP32 DevKit v1                                │
│  ├── WiFi: Built-in ESP32 WiFi Module                                │
│  ├── Programming: Arduino IDE (C++)                                  │
│  └── Libraries:                                                       │
│      ├── PubSubClient (MQTT)                                         │
│      ├── ESP32Servo (Motor Control)                                  │
│      ├── DHT sensor library (Temperature)                            │
│      └── ArduinoJson (Data Serialization)                            │
│                                                                       │
│  📊 SENSORS                                                           │
│  ├── Ultrasonic: HC-SR04 (Food Level Detection)                      │
│  │   ├── Range: 2cm - 400cm                                          │
│  │   └── Pins: Trigger (GPIO 27), Echo (GPIO 26)                     │
│  │                                                                    │
│  ├── IR Sensor: Active Infrared (Obstacle Detection)                 │
│  │   ├── Type: Digital Output                                        │
│  │   └── Pin: GPIO 4                                                 │
│  │                                                                    │
│  └── Temperature/Humidity: DHT11                                      │
│      ├── Range: 0-50°C, 20-90% RH                                    │
│      └── Pin: GPIO 18                                                │
│                                                                       │
│  ⚙️  ACTUATORS & PERIPHERALS                                         │
│  ├── Servo Motor: SG90 (Food Dispenser)                              │
│  │   ├── Rotation: 180°                                              │
│  │   ├── Control: PWM Signal                                         │
│  │   └── Pin: GPIO 13                                                │
│  │                                                                    │
│  ├── LED Indicator: Status Light                                     │
│  │   └── Pin: GPIO 15                                                │
│  │                                                                    │
│  └── Push Button: Manual Feed Trigger                                │
│      └── Pin: GPIO 14                                                │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Security & Authentication

```
Security Layers:
│
├── 🔐 User Authentication
│   ├── Firebase Authentication (Email/Password)
│   ├── JWT Token-based Sessions
│   ├── Password Reset via Email
│   └── Account Creation Validation
│
├── 🔒 Database Security
│   ├── Firestore Security Rules
│   │   ├── Users can only access their own data
│   │   ├── Read/Write permissions based on user ID
│   │   └── Timestamp-based validation
│   │
│   └── Service Account Authentication
│       ├── serviceAccountKey.json (Backend)
│       └── Private key storage (Not in Git)
│
├── 📡 MQTT Security
│   ├── Username/Password Authentication
│   │   ├── Username: esp32_user
│   │   └── Password: (configured in secret.h)
│   │
│   ├── Local Network (localhost:1883)
│   └── Topic-based Access Control
│
└── 🔑 API Keys & Secrets
    ├── Firebase Config (firebase_config.dart)
    ├── ESP32 Secrets (secret.h - not in Git)
    └── Environment Variables (Backend)

```
feeders/
├── feeder_001/
│   ├── device_id: "feeder_001"
│   ├── manual_feed: false (boolean switch)
│   ├── food_level: 75 (%)
│   ├── temperature: 26 (°C)
│   ├── humidity: 55 (%)
│   ├── detected: false
│   ├── last_seen: timestamp
│   ├── routines: [
│   │   {
│   │     enabled: true,
│   │     time: "08:00",
│   │     days: [0, 1, 2, 3, 4],
│   │     portion_size: 20
│   │   }
│   │ ]
│   │
│   ├── feeding_logs/ (subcollection)
│   │   ├── {log_id}/
│   │   │   ├── device_id: "feeder_001"
│   │   │   ├── source: "manual" | "scheduled" | "button"
│   │   │   ├── food_remaining: 70
│   │   │   ├── portion_size: 20
│   │   │   └── timestamp: timestamp
│   │   
│   └── sensor_history/ (subcollection)
│       └── {sensor_id}/
│           ├── device_id: "feeder_001"
│           ├── food_level: 75
│           ├── temperature: 26
│           ├── humidity: 55
│           ├── detected: false
│           └── timestamp: timestamp
│
├── users/ (collection)
│   └── {user_id}/
│       ├── email: "user@example.com"
│       ├── pet_name: "Fluffy"
│       ├── pet_type: "cat"
│       ├── pet_weight: 4.5
│       ├── daily_portion: 200
│       └── portion_per_meal: 50
```

## 🔌 System Components Communication

### MQTT Topics Structure
- **feeder/feeder_001/command** - Commands from backend to ESP32
- **feeder/feeder_001/events** - Feeding events from ESP32 to backend
- **feeder/feeder_001/telemetry** - Sensor data from ESP32 to backend

## 🎯 Key Features Implemented

```
✅ CORE FEATURES:
│
├── 1. Real-time Dashboard
│   ├── Live sensor data streaming (every 10s)
│   ├── Food level percentage indicator
│   ├── Temperature & humidity display
│   ├── Obstacle detection status
│   └── Last feeding timestamp
│
├── 2. Manual Feed Control
│   ├── "FEED NOW" button (instant trigger)
│   ├── Portion size selection (20g, 50g, 100g)
│   ├── Daily feeding limit validation
│   └── Real-time confirmation feedback
│
├── 3. Automated Scheduling
│   ├── Time-based feeding routines
│   ├── Day selection (Mon-Sun)
│   ├── Multiple schedules support
│   ├── Enable/disable toggle
│   └── Portion size per schedule
│
├── 4. Bidirectional IoT Communication
│   ├── App → Device: Feed commands
│   ├── Device → App: Sensor telemetry
│   ├── Device → App: Feeding events
│   └── MQTT protocol for reliability
│
├── 5. Push Notifications
│   ├── Low food level alerts (<20%)
│   ├── High temperature warnings (>35°C)
│   ├── Obstacle detection alerts
│   ├── Scheduled feeding confirmations
│   └── Firebase Cloud Messaging (FCM)
│
├── 6. Historical Analytics
│   ├── Feeding logs timeline
│   ├── Source tracking (manual/scheduled/button)
│   ├── Sensor history graphs
│   ├── Daily statistics
│   └── Weekly/monthly trends
│
├── 7. Pet Profile Management
│   ├── Pet name, type, breed
│   ├── Weight tracking
│   ├── Daily portion recommendations
│   ├── Portion per meal customization
│   └── Health-based calculations
│
├── 8. Multi-sensor Monitoring
│   ├── Ultrasonic: Food level (0-100%)
│   ├── DHT11: Temperature & humidity
│   ├── IR Sensor: Obstacle detection
│   └── Real-time data updates
│
├── 9. Physical Button Override
│   ├── Manual feed trigger on device
│   ├── No internet required
│   ├── LED status indicator
│   └── Emergency feeding option
│
└── 10. Daily Feeding Limits
    ├── Recommended daily portion
    ├── Maximum threshold (120%)
    ├── Portion tracking per day
    ├── Overfeed prevention
    └── Health safety warnings
```

---

## 📊 Data Flow Summary

```
User Actions → App UI → Firebase → Backend → MQTT → ESP32 → Physical Action
                ↑                                              ↓
                └──────────────────────────────────────────────┘
                       (Real-time feedback & sensor updates)


CONTINUOUS LOOPS:

[Sensor Monitoring Loop - Every 10s]
ESP32 reads sensors → MQTT publish → Backend stores → Firestore updates → App displays

[Scheduler Loop - Every 1 minute]
Backend checks time → Match routine? → Send MQTT feed command → ESP32 executes

[Notification Loop - Every 30s]
Monitor checks conditions → Alert triggered? → FCM sends notification → User receives
```

---

## 🔧 Technology Stack Summary

**Frontend**: Flutter (Dart) - Mobile & Web  
**Backend**: Python 3.x + paho-mqtt  
**Database**: Google Firestore (NoSQL)  
**Message Broker**: Eclipse Mosquitto MQTT  
**Cloud Services**: Firebase (Auth, FCM, Firestore)  
**Hardware**: ESP32 + Sensors + Servo Motor  

---

## 🔐 Security Features

- Firebase Authentication (Email/Password)
- MQTT Username/Password Authentication
- Firestore Security Rules
- JWT Token-based App Sessions
- Service Account for Backend-Firebase Communication

---

**Generated**: January 17, 2026  
**System**: Smart Pet Feeder IoT Solution
