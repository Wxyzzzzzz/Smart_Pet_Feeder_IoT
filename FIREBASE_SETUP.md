# Smart Pet Feeder - Firebase Integration Setup

This app is now integrated with Firebase Firestore to display real-time data from your smart pet feeder device.

## 📋 Prerequisites

- A Firebase project set up
- Firestore database created
- Your database structure matches:
  ```
  feeders/
    feeder_001/
      feeding_logs/ (collection)
        {document_id}/
          - device_id: string
          - food_remaining: number
          - last_seen: timestamp
          - source: string ("manually" or "scheduled")
          - timestamp: timestamp
      
      sensor_history/ (collection)
        {document_id}/
          - detected: boolean
          - device_id: string
          - food_level: number
          - humidity: number
          - last_seen: timestamp
          - temp: number
          - timestamp: timestamp
      
      feeding_commands/ (collection) ⭐ NEW - for IoT control
        {document_id}/
          - device_id: string
          - portion_size: number (grams)
          - status: string ("pending", "processing", "completed", "failed")
          - created_at: timestamp
          - executed_at: timestamp (nullable)
          - error_message: string (nullable)
  ```

## 🔧 Firebase Configuration Steps

### 1. Get Your Firebase Config

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the gear icon (⚙️) next to "Project Overview"
4. Select "Project settings"
5. Scroll down to "Your apps" section
6. If you haven't added a web app, click "Add app" and select Web (</>)
7. Copy the Firebase configuration values

### 2. Update Firebase Config File

Open `lib/config/firebase_config.dart` and replace the placeholder values:

```dart
class FirebaseConfig {
  static const String apiKey = "YOUR_ACTUAL_API_KEY";
  static const String authDomain = "YOUR_PROJECT.firebaseapp.com";
  static const String projectId = "YOUR_PROJECT_ID";
  static const String storageBucket = "YOUR_PROJECT.appspot.com";
  static const String messagingSenderId = "YOUR_SENDER_ID";
  static const String appId = "1:YOUR_APP_ID:web:xxxxx";
}
```

### 3. Configure Firestore Security Rules

In Firebase Console > Firestore Database > Rules, set up appropriate security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write to feeder documents
    match /feeders/{feederId} {
      allow read, write: if true; // Adjust based on your auth requirements
      
      match /feeding_logs/{logId} {
        allow read, write: if true;
      }
      
      match /sensor_history/{historyId} {
        allow read, write: if true;
      }
      
      match /feeding_commands/{commandId} {
        allow read, write: if true;
      }
    }
  }
}
```

**Note:** Update these rules to include proper authentication once you implement Firebase Auth.

## 📱 Features Connected to Firestore

### Dashboard Screen
- **Real-time sensor data**: Temperature, humidity, food level, pet detection
- **Food level gauge**: Shows current food percentage
- **Device status**: Online/offline indicator
- **Manual feed button**: Sends commands to IoT device via Firestore, tracks execution status

### History Screen  
- **Live feeding logs**: Streams all feeding history from database
- **Statistics**: Total feedings, scheduled vs manual counts
- **Audit trail**: Complete timeline with timestamps and device info

### Analytics Screen (Coming Soon)
- Will pull historical sensor data for charts and insights

## 🔄 How Data Flows

1. **IoT Device → Firestore**: Your ESP32/Arduino device writes sensor data and feeding logs
2. **Firestore → Flutter App**: App listens to real-time streams and updates UI automatically
3. **Flutter App → Firestore → IoT Device**: Manual feed button creates command, device executes and updates status ⭐ NEW

## 🧪 Testing

### Test with Mock Data

You can manually add test documents in Firebase Console:

1. Go to Firestore Database
2. Navigate to `feeders/feeder_001/sensor_history`
3. Add a document with:
   ```json
   {
     "detected": false,
     "device_id": "feeder_001",
     "food_level": 75,
     "humidity": 55,
     "last_seen": [current timestamp],
     "temp": 26,
     "timestamp": [current timestamp]
   }
   ```

4. Navigate to `feeders/feeder_001/feeding_logs`
5. Add a document with:
   ```json
   {
     "device_id": "feeder_001",
     "food_remaining": 70,
     "last_seen": [current timestamp],
     "source": "manually",
     "timestamp": [current timestamp]
   }
   ```

The app will automatically display this data!

## 🚀 Running the App

```bash
# Make sure you've configured firebase_config.dart first
flutter run
```

## ❓ Troubleshooting

### "Error loading data"
- Check your Firebase config values
- Verify Firestore security rules allow read access
- Check browser console for specific errors

### "No sensor data available"
- Make sure your database has at least one document in `sensor_history`
- Verify the device_id matches "feeder_001"
- Check that timestamps are valid Firestore timestamp objects

### "No feeding logs yet"
- Add test data to `feeding_logs` collection
- Verify the document structure matches the expected format

## 📚 Next Steps

- [ ] Implement Firebase Authentication
- [ ] Update analytics screen to use real Firestore data
- [ ] Add schedule synchronization with Firestore
- [ ] Implement push notifications for low food alerts

## 🔐 Security Notes

- **Never commit your actual Firebase config to public repositories**
- Add `lib/config/firebase_config.dart` to `.gitignore` if using real credentials
- Implement proper authentication before deploying to production
- Review and update Firestore security rules regularly
