import paho.mqtt.client as mqtt
import json
import time
import os
import firebase_admin
from firebase_admin import credentials, firestore, messaging
from datetime import datetime

# --- CONFIGURATION ---
BROKER = "localhost"
PORT = 1883
USERNAME = "esp32_user"
PASSWORD = "1234"  # <--- Update if needed

# Topics
TOPIC_EVENTS    = "feeder/+/events"
TOPIC_TELEMETRY = "feeder/+/telemetry"

# Paths
KEY_PATH = "serviceAccountKey.json"
EVENT_FILE  = "../output/feeding_history.json"
SENSOR_FILE = "../output/sensor_log.json"

# --- FIREBASE SETUP ---
cred = credentials.Certificate(KEY_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()
print("[SYSTEM] Firebase Connected Successfully!")

# --- DATABASE FUNCTIONS ---
def update_live_status(device_id, data):
    """
    Overwrites the 'Main Document' with the latest data.
    Used for: Showing 'Current Status' on the App Dashboard.
    """
    doc_ref = db.collection("feeders").document(device_id)
    data["last_seen"] = firestore.SERVER_TIMESTAMP
    doc_ref.set(data, merge=True)
    # print(f"[FIREBASE] Updated Live Status for {device_id}")

def save_history(device_id, collection_name, data):
    """
    Adds a NEW document to a sub-collection.
    Used for: Creating History Logs and Graphs.
    """
    # Add timestamp for sorting
    data["timestamp"] = firestore.SERVER_TIMESTAMP
    
    # Path: feeders -> [ID] -> [collection_name] -> [Auto-ID]
    db.collection("feeders").document(device_id).collection(collection_name).add(data)
    print(f"[FIREBASE] History Saved to '{collection_name}' for {device_id}")

# --- MQTT CALLBACKS ---
def on_connect(client, userdata, flags, rc, properties=None):
    print(f"[SYSTEM] Connected to Local MQTT Broker.")
    client.subscribe([(TOPIC_EVENTS, 0), (TOPIC_TELEMETRY, 0)])

def on_message(client, userdata, msg):
    try:
        payload = msg.payload.decode()
        data = json.loads(payload)
        
        # Get Device ID (default to feeder_001)
        device_id = data.get("device_id", "feeder_001")
        
        # --- SCENARIO 1: FEEDING EVENT ---
        if "events" in msg.topic:
            print(f"[EVENT] Feeding Happened!")
            # 1. Update Live Status (e.g. "Last fed at...")
            update_live_status(device_id, data)
            # 2. Save to History (Permanent Record)
            save_history(device_id, "feeding_logs", data)
            
        # --- SCENARIO 2: SENSOR TELEMETRY ---
        elif "telemetry" in msg.topic:
            temp = data.get('temp')
            print(f"[TELEMETRY] Temp: {temp}C")
            
            # 1. Update Live Status (For the dashboard gauge)
            update_live_status(device_id, data)
            
            # 2. Save to History (For the graph)
            # NOTE: Doing this every 5 seconds creates A LOT of data.
            # Ideally, your ESP32 should send this less often, 
            # or we filter it here. For now, we save everything.
            save_history(device_id, "sensor_history", data)

            # 3. Check for Low Food Alert
            food_level = data.get('food_level', 100)
            print(f"[TELEMETRY] Food: {food_level}%")
            
            if int(food_level) < 10:
                send_low_food_alert(food_level)

    except Exception as e:
        print(f"[ERROR] Processing Message: {e}")

# --- ALERT SYSTEM ---
def send_low_food_alert(food_level):
    # This token comes from your Flutter App (We will fetch it dynamically later)
    # For now, we will just print what WOULD happen.
    
    print(f"[ALERT SYSTEM] ⚠️ Food is Critically Low: {food_level}%")
    
    try:
        # Construct the message
        message = messaging.Message(
            notification=messaging.Notification(
                title="Refill Required!",
                body=f"Your pet's food is running low ({food_level}% remaining).",
            ),
            topic="feeder_alerts" # <--- simpler than managing individual tokens
        )
        
        # Send it
        response = messaging.send(message)
        print(f"[ALERT SYSTEM] Notification sent successfully: {response}")
        
    except Exception as e:
        print(f"[ALERT SYSTEM] Failed to send notification: {e}")

# --- MAIN LOOP ---
client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
client.username_pw_set(USERNAME, PASSWORD)
client.on_connect = on_connect
client.on_message = on_message

while True:
    try:
        client.connect(BROKER, PORT, 60)
        client.loop_forever()
    except Exception as e:
        print(f"[CRITICAL] Connection lost: {e}. Retrying in 5s...")
        time.sleep(5)