# Firebase Test Data Setup

## 🔧 Adding Test Data to Your Firebase

To see your dashboard and history working, you need to add sample data to Firebase.

### Option 1: Using Firebase Console (Easiest)

#### Add Sensor Data

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Firestore Database**
4. Navigate to: `feeders/feeder_001/sensor_history`
5. Click **"Add document"**
6. Use **"Auto-ID"** for document ID
7. Add these fields:

```
Field Name       | Type      | Value
-----------------|-----------|-------
detected         | boolean   | false
device_id        | string    | feeder_001
food_level       | number    | 75
humidity         | number    | 55
last_seen        | timestamp | (click "SET TO CURRENT TIME")
temp             | number    | 26
timestamp        | timestamp | (click "SET TO CURRENT TIME")
```

8. Click **Save**

#### Add Feeding Log

1. Navigate to: `feeders/feeder_001/feeding_logs`
2. Click **"Add document"**
3. Use **"Auto-ID"**
4. Add these fields:

```
Field Name       | Type      | Value
-----------------|-----------|-------
device_id        | string    | feeder_001
food_remaining   | number    | 70
last_seen        | timestamp | (click "SET TO CURRENT TIME")
source           | string    | manually
timestamp        | timestamp | (click "SET TO CURRENT TIME")
```

5. Click **Save**

### Option 2: Using Firebase Console - Quick Multiple Entries

Add multiple sensor readings (for analytics):

**Sensor History Entry 1:**
```json
{
  "detected": false,
  "device_id": "feeder_001",
  "food_level": 80,
  "humidity": 52,
  "last_seen": [CURRENT_TIMESTAMP],
  "temp": 25,
  "timestamp": [CURRENT_TIMESTAMP]
}
```

**Sensor History Entry 2:**
```json
{
  "detected": true,
  "device_id": "feeder_001",
  "food_level": 75,
  "humidity": 54,
  "last_seen": [CURRENT_TIMESTAMP],
  "temp": 26,
  "timestamp": [CURRENT_TIMESTAMP]
}
```

**Sensor History Entry 3:**
```json
{
  "detected": false,
  "device_id": "feeder_001",
  "food_level": 70,
  "humidity": 56,
  "last_seen": [CURRENT_TIMESTAMP],
  "temp": 27,
  "timestamp": [CURRENT_TIMESTAMP]
}
```

**Feeding Log Entry 1:**
```json
{
  "device_id": "feeder_001",
  "food_remaining": 75,
  "last_seen": [CURRENT_TIMESTAMP],
  "source": "scheduled",
  "timestamp": [CURRENT_TIMESTAMP]
}
```

**Feeding Log Entry 2:**
```json
{
  "device_id": "feeder_001",
  "food_remaining": 70,
  "last_seen": [CURRENT_TIMESTAMP],
  "source": "manually",
  "timestamp": [CURRENT_TIMESTAMP]
}
```

### Option 3: Import JSON (Advanced)

If you want to batch import, create a file `test_data.json`:

```json
{
  "feeders": {
    "feeder_001": {
      "sensor_history": {
        "sensor_001": {
          "detected": false,
          "device_id": "feeder_001",
          "food_level": 80,
          "humidity": 52,
          "last_seen": "2026-01-15T10:00:00Z",
          "temp": 25,
          "timestamp": "2026-01-15T10:00:00Z"
        },
        "sensor_002": {
          "detected": true,
          "device_id": "feeder_001",
          "food_level": 75,
          "humidity": 54,
          "last_seen": "2026-01-15T11:00:00Z",
          "temp": 26,
          "timestamp": "2026-01-15T11:00:00Z"
        },
        "sensor_003": {
          "detected": false,
          "device_id": "feeder_001",
          "food_level": 70,
          "humidity": 56,
          "last_seen": "2026-01-15T12:00:00Z",
          "temp": 27,
          "timestamp": "2026-01-15T12:00:00Z"
        }
      },
      "feeding_logs": {
        "log_001": {
          "device_id": "feeder_001",
          "food_remaining": 75,
          "last_seen": "2026-01-15T11:00:00Z",
          "source": "scheduled",
          "timestamp": "2026-01-15T11:00:00Z"
        },
        "log_002": {
          "device_id": "feeder_001",
          "food_remaining": 70,
          "last_seen": "2026-01-15T12:00:00Z",
          "source": "manually",
          "timestamp": "2026-01-15T12:00:00Z"
        }
      }
    }
  }
}
```

Then use Firebase CLI:
```bash
firebase firestore:import test_data.json
```

## 🧪 Verify Data is Added

### Check in Firebase Console
1. Go to Firestore Database
2. You should see:
   - `feeders` → `feeder_001` → `sensor_history` → (multiple documents)
   - `feeders` → `feeder_001` → `feeding_logs` → (multiple documents)

### Check in Your App
1. Run: `flutter run`
2. Login to the app
3. **Dashboard should show:**
   - Food level percentage
   - Temperature (e.g., 26°C)
   - Humidity (e.g., 55%)
   - Device status: "Online"
   - Pet detection status

4. **History screen should show:**
   - List of feeding logs
   - Statistics (Total, Scheduled, Manual counts)
   - Timestamps for each feeding

## 🔍 Troubleshooting

### Dashboard shows "No sensor data available"
**Problem:** No documents in `sensor_history` collection
**Solution:** Add at least one sensor data document (see above)

### History shows "No feeding logs yet"
**Problem:** No documents in `feeding_logs` collection
**Solution:** Add at least one feeding log document (see above)

### Error: "NoSuchMethodError: toDate"
**Status:** ✅ FIXED in the latest code
**Cause:** Timestamp fields were null or in wrong format
**Fix Applied:** Models now handle null timestamps and different formats

### Dashboard doesn't update
**Problem:** StreamBuilder not receiving data
**Checks:**
1. Verify Firebase config in `firebase_config.dart`
2. Check Firestore security rules allow read access
3. Ensure documents exist in correct path: `feeders/feeder_001/sensor_history`
4. Check browser console for Firebase errors

### Data exists but app shows nothing
**Problem:** Device ID mismatch
**Solution:** Ensure all documents have `device_id: "feeder_001"`

## 📊 Expected Results After Adding Data

### Dashboard
```
Control Room 📱
┌──────────────────────┐
│ Device Online        │
│ Device: feeder_001   │
└──────────────────────┘

     ┌─────┐
     │ 75% │  ← Food Level
     │     │
     └─────┘
   Food Level: 75
   Est. Empty in: 3 Days

┌──────────┬──────────┬──────────┐
│   26°C   │   55%    │   Pet    │
│   Temp   │ Humidity │  Absent  │
└──────────┴──────────┴──────────┘

Portion Size: 20g
[===|=====] 5g - 50g

[  FEED NOW (20g)  ]
```

### History
```
Feeding History 📜
┌────────────────────────┐
│ System Reliability     │
├────────────────────────┤
│ Total: 2               │
│ Scheduled: 1           │
│ Manual: 1              │
└────────────────────────┘

┌────────────────────────┐
│ 🍖 Manual Feeding      │
│ Jan 15, 2026 12:00 PM  │
│ Device: feeder_001     │
│ Food Left: 70          │
└────────────────────────┘

┌────────────────────────┐
│ ⏰ Scheduled Feeding   │
│ Jan 15, 2026 11:00 AM  │
│ Device: feeder_001     │
│ Food Left: 75          │
└────────────────────────┘
```

## 🎯 Quick Start (Minimum Data)

To get started quickly, add just these two documents:

**1. One Sensor Data:**
- Path: `feeders/feeder_001/sensor_history/[AUTO-ID]`
- Fields: detected=false, device_id="feeder_001", food_level=75, humidity=55, temp=26
- Timestamps: Set both last_seen and timestamp to current time

**2. One Feeding Log:**
- Path: `feeders/feeder_001/feeding_logs/[AUTO-ID]`
- Fields: device_id="feeder_001", food_remaining=70, source="manually"
- Timestamps: Set both last_seen and timestamp to current time

That's it! Your dashboard and history should now display data.

## 🔄 Hot Reload

After adding data to Firebase:
1. App should auto-update (StreamBuilder listens for changes)
2. If not, press `r` in the terminal to hot reload
3. Or restart the app

---

**Next:** After verifying the app shows data correctly, you can connect your IoT device to automatically add sensor data and respond to feeding commands!
