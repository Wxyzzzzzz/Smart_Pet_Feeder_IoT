"""
Quick Test Script - Trigger Manual Feed from Python
This bypasses the Flutter app to test backend → MQTT → ESP32 flow
"""

import firebase_admin
from firebase_admin import credentials, firestore
import time

print("=== Smart Pet Feeder - Manual Feed Test ===\n")

# Initialize Firebase
KEY_PATH = "serviceAccountKey.json"
print(f"1. Loading Firebase credentials from {KEY_PATH}...")

try:
    cred = credentials.Certificate(KEY_PATH)
    app = firebase_admin.initialize_app(cred)
    print(f"   ✅ Connected to Firebase Project: {cred.project_id}\n")
except ValueError:
    # Already initialized
    app = firebase_admin.get_app()
    print("   ✅ Firebase already initialized\n")

db = firestore.client()

# Get feeder document
device_id = "feeder_001"
feeder_ref = db.collection("feeders").document(device_id)

print(f"2. Checking current state of {device_id}...")
doc = feeder_ref.get()

if doc.exists:
    data = doc.to_dict()
    print(f"   ✅ Document exists")
    print(f"   - manual_feed: {data.get('manual_feed')}")
    print(f"   - food_level: {data.get('food_level')}")
    print(f"   - last_seen: {data.get('last_seen')}\n")
else:
    print(f"   ❌ Document does not exist! Creating it...\n")
    feeder_ref.set({
        "device_id": device_id,
        "manual_feed": False,
        "food_level": 50,
        "temp": 25,
        "humidity": 60,
        "detected": False
    })

print("3. Triggering manual feed...")
print("   Setting manual_feed = True...")

# Trigger the feed
feeder_ref.update({"manual_feed": True})

print("   ✅ Command sent to Firestore!\n")

print("4. What should happen next:")
print("   a. Backend (backend.py) should detect the change")
print("   b. Backend sends MQTT 'FEED' command")
print("   c. ESP32 receives command and activates servo")
print("   d. Backend resets manual_feed to False\n")

print("5. Checking if backend reset the flag...")
time.sleep(2)  # Give backend time to process

doc = feeder_ref.get()
current_state = doc.to_dict().get('manual_feed')

if current_state == False:
    print(f"   ✅ Backend processed command! (manual_feed = {current_state})")
    print("   This means backend is working correctly.")
else:
    print(f"   ❌ manual_feed is still {current_state}")
    print("   Backend might not be running or not detecting changes.")

print("\n=== Test Complete ===")
print("\nNext steps:")
print("1. Check backend.py terminal for debug messages")
print("2. Check ESP32 Serial Monitor for MQTT messages")
print("3. Verify servo motor activated")
