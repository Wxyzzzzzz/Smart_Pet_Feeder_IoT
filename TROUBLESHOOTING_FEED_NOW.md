# Troubleshooting: Feed Now Button Not Working

## Expected Flow
1. **Phone App** → Sets `manual_feed: true` in Firestore (`feeders/feeder_001`)
2. **Backend (Python)** → Detects change, sends MQTT "FEED" command
3. **ESP32 Hardware** → Receives MQTT command, activates servo motor

## Checklist

### ✅ Step 1: Verify Backend is Running
```powershell
# Check if backend.py is running
Get-Process python -ErrorAction SilentlyContinue
```

**If NOT running:**
```powershell
cd c:\Users\User\Downloads\smart_pet_feeder\cloud
python backend.py
```

**You should see:**
```
[SYSTEM] Firebase Connected. Project ID: your-project-id
[SYSTEM] Listening for Manual Control on 'feeders/feeder_001'...
[SYSTEM] Connecting to MQTT Broker at localhost...
[SYSTEM] MQTT Connected Successfully.
```

---

### ✅ Step 2: Test Firestore Connection
Open Firestore in Firebase Console and manually:
1. Go to `feeders/feeder_001` document
2. Set `manual_feed` to `true`
3. Watch backend terminal - you should see:
   ```
   [DEBUG] Document feeder_001 STATE CHANGE: manual_feed = True
   [MANUAL] Trigger received for feeder_001!
   [COMMAND] Sent 'FEED' to feeder/feeder_001/command
   ```

---

### ✅ Step 3: Verify MQTT Broker is Running
```powershell
# Check if Mosquitto broker is running
Get-Service mosquitto -ErrorAction SilentlyContinue

# Or check process
Get-Process mosquitto -ErrorAction SilentlyContinue
```

**If NOT running:**
```powershell
# Start Mosquitto service
net start mosquitto

# Or run manually
mosquitto -v
```

---

### ✅ Step 4: Test MQTT Connection
```powershell
# Subscribe to command topic (in new terminal)
mosquitto_sub -h localhost -p 1883 -u esp32_user -P 1234 -t "feeder/feeder_001/command" -v

# Publish test command (in another terminal)
mosquitto_pub -h localhost -p 1883 -u esp32_user -P 1234 -t "feeder/feeder_001/command" -m "FEED"
```

You should see "FEED" appear in the subscriber terminal.

---

### ✅ Step 5: Verify ESP32 is Connected
Check Serial Monitor output from Arduino IDE. You should see:
```
WiFi connected
IP address: 192.168.x.x
Attempting MQTT connection...connected
```

**If connection fails:**
- Check `secret.h` has correct WiFi credentials
- Verify MQTT broker IP/hostname in `secret.h`
- Check if ESP32 is powered on

---

### ✅ Step 6: Test Complete Flow
1. **Backend running** ✅
2. **Mosquitto running** ✅
3. **ESP32 connected** ✅
4. **Phone app** → Press "FEED NOW"

**Watch all terminals:**
- **App**: Should show "Sending command to device..."
- **Backend**: Should print `[MANUAL] Trigger received...` and `[COMMAND] Sent 'FEED'...`
- **ESP32 Serial Monitor**: Should print `Message arrived [feeder/feeder_001/command]: FEED`
- **Hardware**: Servo should activate

---

## Common Issues

### Issue 1: Backend Not Detecting Firestore Changes
**Symptom:** No output in backend terminal when clicking Feed Now

**Fix:**
- Check Firebase credentials in `serviceAccountKey.json`
- Verify Firestore rules allow read/write
- Check if document path is exactly `feeders/feeder_001`

### Issue 2: MQTT Command Not Reaching ESP32
**Symptom:** Backend sends command, but ESP32 doesn't receive it

**Fix:**
- Verify broker IP in ESP32 `secret.h` matches backend `BROKER` setting
- Check credentials match (`esp32_user` / `1234`)
- Ensure topic format is `feeder/feeder_001/command` (no extra slashes)

### Issue 3: ESP32 Not Responding to MQTT Messages
**Symptom:** ESP32 receives message but servo doesn't move

**Fix:**
- Check servo power supply (needs 5V, not 3.3V)
- Verify servo is connected to correct pin (GPIO 13)
- Add debug prints in callback function
- Test servo manually with simple Arduino code

### Issue 4: Firestore Permission Denied
**Symptom:** Error updating `manual_feed` field

**Fix:** Update Firestore Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /feeders/{feederId} {
      allow read, write: if request.auth != null;
      
      match /feeding_commands/{commandId} {
        allow read, write: if request.auth != null;
      }
      
      match /feeding_logs/{logId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

---

## Enhanced Debugging Code

### Add to backend.py (for more verbose logging):
```python
def on_snapshot(doc_snapshot, changes, read_time):
    print(f"[DEBUG] Snapshot received at {read_time}")
    print(f"[DEBUG] Number of docs: {len(doc_snapshot)}")
    
    for doc in doc_snapshot:
        print(f"[DEBUG] Processing document: {doc.id}, exists: {doc.exists}")
        
        if not doc.exists:
            continue
            
        data = doc.to_dict()
        print(f"[DEBUG] Full document data: {data}")
        # ... rest of function
```

### Add to ESP32 main.ino callback:
```cpp
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.println("=== MQTT MESSAGE RECEIVED ===");
  Serial.print("Topic: ");
  Serial.println(topic);
  Serial.print("Payload length: ");
  Serial.println(length);
  
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.print("Message: ");
  Serial.println(message);
  Serial.println("=============================");
  
  // ... rest of callback
}
```

---

## Quick Test Script

Save as `test_feed_command.py`:
```python
import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("serviceAccountKey.json")
app = firebase_admin.initialize_app(cred)
db = firestore.client()

# Trigger manual feed
db.collection("feeders").document("feeder_001").update({"manual_feed": True})
print("✅ Manual feed triggered! Check backend and ESP32.")
```

Run: `python test_feed_command.py`

---

## Status Indicators

| Component | Check | Expected |
|-----------|-------|----------|
| Backend | `ps aux | grep backend.py` | Process running |
| MQTT Broker | `sudo service mosquitto status` | Active (running) |
| ESP32 | Serial Monitor | "connected" message |
| Firestore | Firebase Console | `manual_feed: false` (auto-resets) |

---

## Next Steps

1. **Run backend.py in one terminal**
2. **Open ESP32 Serial Monitor in Arduino IDE**
3. **Click Feed Now button in app**
4. **Watch both terminals for error messages**
5. **Report back with any error messages you see**
