# IoT Bidirectional Communication Setup

## 📡 Overview

Your Smart Pet Feeder app now supports **bidirectional communication** with the IoT device:
- **Upload (Device → Firebase)**: Device sends sensor data and feeding logs
- **Download (Firebase → Device)**: App sends feeding commands that device executes

## 🏗️ Firestore Database Structure

```
feeders/
  feeder_001/
    feeding_logs/ (collection)
      {log_id}/
        - device_id: "feeder_001"
        - food_remaining: 75
        - last_seen: timestamp
        - source: "manually" | "scheduled"
        - timestamp: timestamp
    
    sensor_history/ (collection)
      {sensor_id}/
        - detected: false
        - device_id: "feeder_001"
        - food_level: 80
        - humidity: 55
        - last_seen: timestamp
        - temp: 26
        - timestamp: timestamp
    
    feeding_commands/ (collection) ⭐ NEW
      {command_id}/
        - device_id: "feeder_001"
        - portion_size: 20
        - status: "pending" | "processing" | "completed" | "failed"
        - created_at: timestamp
        - executed_at: timestamp (nullable)
        - error_message: string (nullable)
```

## 🔄 Command Flow

### 1. User Action → Command Creation
```
User clicks "FEED NOW (20g)" button
         ↓
App creates command document in feeding_commands/
         ↓
Status: "pending"
```

### 2. IoT Device Listens for Commands
```
Device monitors: feeders/feeder_001/feeding_commands
         ↓
Finds commands where status == "pending"
         ↓
Updates status to "processing"
```

### 3. Device Executes Command
```
Device activates servo motor
         ↓
Dispenses food (e.g., 20g)
         ↓
Updates command status to "completed"
         ↓
Sets executed_at timestamp
```

### 4. App Receives Confirmation
```
App watches command status
         ↓
Receives "completed" status
         ↓
Shows success notification: "✅ Fed successfully!"
```

## 🛠️ IoT Device Implementation

### ESP32/Arduino Example (C++)

```cpp
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <ESP32Servo.h>

// Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Servo motor
Servo feederServo;
const int SERVO_PIN = 13;

// Device configuration
const String DEVICE_ID = "feeder_001";
const String COMMANDS_PATH = "feeders/feeder_001/feeding_commands";

void setup() {
  Serial.begin(115200);
  
  // Initialize servo
  feederServo.attach(SERVO_PIN);
  feederServo.write(0); // Initial position
  
  // Connect to WiFi
  WiFi.begin("YOUR_WIFI_SSID", "YOUR_WIFI_PASSWORD");
  while (WiFi.status() != WL_CONNECTED) {
    delay(300);
    Serial.print(".");
  }
  Serial.println("\nConnected to WiFi");
  
  // Configure Firebase
  config.api_key = "YOUR_FIREBASE_API_KEY";
  config.database_url = "YOUR_FIREBASE_PROJECT.firebaseio.com";
  
  // Sign in to Firebase
  auth.user.email = "device@yourapp.com";
  auth.user.password = "your_device_password";
  
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  // Start listening for commands
  setupCommandListener();
}

void loop() {
  // Check for pending commands every 2 seconds
  static unsigned long lastCheck = 0;
  if (millis() - lastCheck > 2000) {
    checkPendingCommands();
    lastCheck = millis();
  }
  
  // Your other sensor reading code here
  // readSensors();
  // uploadSensorData();
}

void setupCommandListener() {
  // Listen for changes in feeding_commands collection
  if (Firebase.Firestore.beginStream(&fbdo, COMMANDS_PATH)) {
    Serial.println("Listening for commands...");
  }
}

void checkPendingCommands() {
  FirebaseJson query;
  FirebaseJson queryContent;
  
  // Query for pending commands
  queryContent.set("from/collectionId", "feeding_commands");
  queryContent.set("where/fieldFilter/field/fieldPath", "status");
  queryContent.set("where/fieldFilter/op", "EQUAL");
  queryContent.set("where/fieldFilter/value/stringValue", "pending");
  queryContent.set("orderBy/field/fieldPath", "created_at");
  queryContent.set("orderBy/direction", "ASCENDING");
  
  String documentPath = "projects/YOUR_PROJECT_ID/databases/(default)/documents/feeders/feeder_001";
  
  if (Firebase.Firestore.runQuery(&fbdo, documentPath, &query)) {
    // Parse results
    FirebaseJsonArray &arr = fbdo.jsonArray();
    
    for (size_t i = 0; i < arr.size(); i++) {
      FirebaseJsonData result;
      arr.get(result, i);
      
      // Extract command details
      String commandId = extractCommandId(result);
      int portionSize = extractPortionSize(result);
      
      // Execute the command
      executeCommand(commandId, portionSize);
    }
  }
}

void executeCommand(String commandId, int portionSize) {
  Serial.printf("Executing command %s: dispense %dg\n", commandId.c_str(), portionSize);
  
  // Update status to "processing"
  updateCommandStatus(commandId, "processing", "");
  
  // Activate servo motor
  bool success = dispenseFoodServo(portionSize);
  
  if (success) {
    // Update status to "completed"
    updateCommandStatus(commandId, "completed", "");
    Serial.println("Command completed successfully");
  } else {
    // Update status to "failed"
    updateCommandStatus(commandId, "failed", "Servo motor error");
    Serial.println("Command failed");
  }
}

bool dispenseFoodServo(int portionSize) {
  try {
    // Calculate servo angle based on portion size
    // Example: 5g = 30°, 50g = 180°
    int angle = map(portionSize, 5, 50, 30, 180);
    
    // Rotate servo to open dispenser
    feederServo.write(angle);
    delay(2000); // Keep open for 2 seconds
    
    // Return to closed position
    feederServo.write(0);
    delay(500);
    
    return true;
  } catch (...) {
    return false;
  }
}

void updateCommandStatus(String commandId, String status, String errorMsg) {
  String docPath = "feeders/feeder_001/feeding_commands/" + commandId;
  
  FirebaseJson content;
  content.set("fields/status/stringValue", status);
  content.set("fields/executed_at/timestampValue", getCurrentTimestamp());
  
  if (errorMsg.length() > 0) {
    content.set("fields/error_message/stringValue", errorMsg);
  }
  
  Firebase.Firestore.patchDocument(&fbdo, "YOUR_PROJECT_ID", "(default)", 
                                   docPath.c_str(), content.raw(), "status,executed_at,error_message");
}

String getCurrentTimestamp() {
  // Return current time in ISO 8601 format
  time_t now = time(nullptr);
  char buffer[30];
  strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%SZ", gmtime(&now));
  return String(buffer);
}
```

### Python Example (Raspberry Pi)

```python
import firebase_admin
from firebase_admin import credentials, firestore
from gpiozero import Servo
from time import sleep
import threading

# Initialize Firebase
cred = credentials.Certificate("path/to/serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Initialize servo motor
servo = Servo(17)  # GPIO pin 17
DEVICE_ID = "feeder_001"

def listen_for_commands():
    """Listen for new pending commands"""
    commands_ref = db.collection('feeders').document(DEVICE_ID).collection('feeding_commands')
    
    # Watch for changes
    def on_snapshot(col_snapshot, changes, read_time):
        for change in changes:
            if change.type.name == 'ADDED' or change.type.name == 'MODIFIED':
                doc = change.document
                data = doc.to_dict()
                
                if data['status'] == 'pending':
                    print(f"New command received: {doc.id}")
                    execute_command(doc.id, data['portion_size'])
    
    # Start watching
    col_watch = commands_ref.where('status', '==', 'pending').on_snapshot(on_snapshot)
    
    return col_watch

def execute_command(command_id, portion_size):
    """Execute feeding command"""
    try:
        # Update status to processing
        update_command_status(command_id, 'processing')
        
        # Dispense food using servo
        success = dispense_food(portion_size)
        
        if success:
            update_command_status(command_id, 'completed')
            print(f"Successfully dispensed {portion_size}g")
        else:
            update_command_status(command_id, 'failed', 'Servo error')
            print("Failed to dispense food")
            
    except Exception as e:
        update_command_status(command_id, 'failed', str(e))
        print(f"Error: {e}")

def dispense_food(portion_size):
    """Control servo motor to dispense food"""
    try:
        # Map portion size to servo angle
        # 5g = -1 (min), 50g = 1 (max)
        angle = ((portion_size - 5) / 45) * 2 - 1
        
        # Rotate servo to open
        servo.value = angle
        sleep(2)  # Keep open for 2 seconds
        
        # Return to closed position
        servo.value = -1
        sleep(0.5)
        
        return True
    except Exception as e:
        print(f"Servo error: {e}")
        return False

def update_command_status(command_id, status, error_msg=None):
    """Update command status in Firestore"""
    command_ref = db.collection('feeders').document(DEVICE_ID).collection('feeding_commands').document(command_id)
    
    update_data = {
        'status': status,
        'executed_at': firestore.SERVER_TIMESTAMP
    }
    
    if error_msg:
        update_data['error_message'] = error_msg
    
    command_ref.update(update_data)

if __name__ == '__main__':
    print("Starting IoT feeder device...")
    
    # Start listening for commands
    watch = listen_for_commands()
    
    print("Listening for feeding commands...")
    
    try:
        # Keep running
        while True:
            sleep(1)
    except KeyboardInterrupt:
        print("\nStopping...")
        watch.unsubscribe()
```

## 📱 App-Side Implementation

### Dashboard Feed Now Button

The button now:
1. ✅ Sends command to Firestore
2. ✅ Shows "Sending command..." notification
3. ✅ Listens for command status updates
4. ✅ Shows real-time feedback:
   - 🔵 "Sending command to device..."
   - 🟠 "Device is dispensing food..."
   - 🟢 "Fed successfully! Dispensed 20g"
   - 🔴 "Feeding failed: [error message]"

### Code Flow (Flutter)

```dart
// 1. User clicks button
onPressed: () => _handleManualFeed(currentFoodLevel)

// 2. Send command to Firestore
final commandId = await _firestoreService.sendFeedingCommand(portionSize);

// 3. Listen for status updates
_firestoreService.watchCommandStatus(commandId).listen((command) {
  if (command.status == 'completed') {
    // Show success message
  }
});
```

## 🔐 Security Rules

Update your Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /feeders/{feederId} {
      // Allow authenticated users to read
      allow read: if request.auth != null;
      
      // Feeding commands - users can create, devices can update
      match /feeding_commands/{commandId} {
        allow create: if request.auth != null;
        allow read: if request.auth != null;
        allow update: if request.auth != null; // Device updates status
      }
      
      // Other collections...
      match /feeding_logs/{logId} {
        allow read, write: if request.auth != null;
      }
      
      match /sensor_history/{sensorId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

## 🧪 Testing Without IoT Device

You can manually test the command flow:

### 1. Click "FEED NOW" in the app
### 2. Check Firebase Console
   - Navigate to `feeders/feeder_001/feeding_commands`
   - You should see a new document with `status: "pending"`

### 3. Manually update the command status
   - Click on the document
   - Change `status` to `"completed"`
   - Add `executed_at` with current timestamp
   - Save

### 4. Check the app
   - You should see "✅ Fed successfully!" notification

## 📊 Command Status States

| Status | Description | Updated By |
|--------|-------------|------------|
| `pending` | Command created, waiting for device | App |
| `processing` | Device is executing the command | IoT Device |
| `completed` | Command executed successfully | IoT Device |
| `failed` | Command execution failed | IoT Device |

## ⚙️ Configuration

### Device Authentication

For production, create a dedicated device user:

1. Go to Firebase Console → Authentication
2. Add new user: `device@yourapp.com`
3. Use these credentials in your IoT device code

### Firestore Indexes

If you get index errors, create these indexes:

```
Collection: feeding_commands
Fields: status (Ascending), created_at (Ascending)
```

## 🐛 Troubleshooting

### Command stuck in "pending"
- Check if IoT device is online
- Verify device Firebase credentials
- Check device console logs

### "Failed to send command"
- Verify Firebase configuration
- Check internet connection
- Review Firestore security rules

### Servo motor not moving
- Check servo power supply (5V)
- Verify GPIO pin connection
- Test servo with simple code first

## 🚀 Next Steps

1. **Deploy IoT Code**: Upload code to your ESP32/Raspberry Pi
2. **Test Connection**: Verify device can read from Firestore
3. **Test Command**: Click "FEED NOW" and watch the servo move
4. **Add Scheduling**: Extend this system to support scheduled feeding
5. **Add Camera**: Integrate ESP32-CAM for visual confirmation

## 📝 Command History

View recent commands in Firebase Console or add a debug screen in your app:

```dart
StreamBuilder<List<FeedingCommand>>(
  stream: _firestoreService.getRecentCommands(limit: 10),
  builder: (context, snapshot) {
    // Display command history
  },
)
```

---

**Status:** ✅ Bidirectional Communication Implemented
**Last Updated:** January 15, 2026
