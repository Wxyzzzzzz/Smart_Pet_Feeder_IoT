import paho.mqtt.client as mqtt
import json
import time
import os
import pytz
import threading
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, firestore, messaging

# --- CONFIGURATION ---
# Since this script runs on the SAME VM as the Mosquitto Broker,
# we can use "localhost" for lower latency and security.
BROKER = "localhost" 
PORT = 1883
USERNAME = "esp32_user"
PASSWORD = "1234" 

# Topics
TOPIC_EVENTS    = "feeder/+/events"
TOPIC_TELEMETRY = "feeder/+/telemetry"
TOPIC_COMMAND_ALL = "feeder/+/command" # Subscribe to this to verify our own messages
TOPIC_CMD_PREFIX = "feeder/"

# Paths
KEY_PATH = "serviceAccountKey.json"
EVENT_FILE  = "../output/feeding_history.json"
SENSOR_FILE = "../output/sensor_log.json"

# --- FIREBASE SETUP ---
cred = credentials.Certificate(KEY_PATH)
try:
    app = firebase_admin.initialize_app(cred)
    print(f"[SYSTEM] Firebase Connected. Project ID: {cred.project_id}")
except ValueError:
    # App already initialized
    app = firebase_admin.get_app()
    print(f"[SYSTEM] Firebase Re-Connected. Project ID: {cred.project_id}")

db = firestore.client()

# --- GLOBAL VARIABLES ---
mqtt_client = None  # We need this accessible globally to send commands
is_mqtt_connected = False
last_scheduled_feed_time = {}  # Track when scheduled feeds happen

# --- HELPER FUNCTIONS ---

def send_mqtt_command(device_id, command_text):
    """Sends a command (like 'FEED') to the ESP32"""
    # FIX: Topic must match firmware (feeder/feeder_001/command)
    topic = f"{TOPIC_CMD_PREFIX}{device_id}/command"
    
    print(f"[DEBUG] Attempting to send MQTT command...")
    print(f"[DEBUG] - Device ID: {device_id}")
    print(f"[DEBUG] - Command: {command_text}")
    print(f"[DEBUG] - Topic: {topic}")
    print(f"[DEBUG] - MQTT Client exists: {mqtt_client is not None}")
    print(f"[DEBUG] - MQTT Connected: {is_mqtt_connected}")
    
    if mqtt_client and is_mqtt_connected:
        info = mqtt_client.publish(topic, command_text)
        info.wait_for_publish() # Block until message is actually sent to broker
        print(f"[COMMAND] ✅ Sent '{command_text}' to {topic} (Message ID: {info.mid})")
        
        # Additional confirmation
        if info.rc == 0:
            print(f"[SUCCESS] Message published successfully!")
        else:
            print(f"[ERROR] Publish failed with return code: {info.rc}")
    else:
        print(f"[ERROR] ❌ Cannot send command: MQTT not connected!")
        print(f"[ERROR] - Client: {mqtt_client}")
        print(f"[ERROR] - Connected: {is_mqtt_connected}")

def update_live_status(device_id, data):
    doc_ref = db.collection("feeders").document(device_id)
    data["last_seen"] = firestore.SERVER_TIMESTAMP
    doc_ref.set(data, merge=True)

    print(f"[FIREBASE] Updated Live Status for {device_id}")

def save_history(device_id, collection_name, data):
    data["timestamp"] = firestore.SERVER_TIMESTAMP
    db.collection("feeders").document(device_id).collection(collection_name).add(data)

    print(f"[FIREBASE] History Saved to '{collection_name}' for {device_id}")
    
# --- 1. MANUAL CONTROL LISTENER (REAL-TIME) ---
def on_snapshot(doc_snapshot, changes, read_time):
    """
    Listens for changes on the specific feeder document.
    """
    print(f"[DEBUG] Firestore snapshot received at {read_time}")
    print(f"[DEBUG] Number of documents in snapshot: {len(doc_snapshot)}")
    
    # doc_snapshot is a list of documents if tracking collection, 
    # but for a single document watch, let's treat it carefully.
    
    for doc in doc_snapshot:
        print(f"[DEBUG] Processing document: {doc.id}, exists: {doc.exists}")
        
        if not doc.exists:
            print(f"[WARNING] Document {doc.id} does not exist!")
            continue
            
        data = doc.to_dict()
        doc_id = doc.id
        manual_feed_val = data.get('manual_feed')
        
        # [DEBUG] Always print manual_feed state for debugging
        print(f"[DEBUG] Document {doc_id} - manual_feed = {manual_feed_val} (type: {type(manual_feed_val)})")
        
        # Only print if it's potentially interesting (true) to avoid log spam from sensor updates
        if manual_feed_val is True:
             print(f"[DEBUG] Document {doc_id} STATE CHANGE: manual_feed = {manual_feed_val}")

        if manual_feed_val == True:
            print(f"[MANUAL] Trigger received for {doc_id}!")
            
            # 1. Send Command to Robot
            send_mqtt_command(doc_id, "FEED")
            
            # 2. Reset the switch IMMEDIATELY
            doc.reference.update({'manual_feed': False})

            # 3. Update pending commands
            try:
                # Note: 'feeding_commands' is a subcollection
                pending_cmds = doc.reference.collection('feeding_commands').where('status', '==', 'pending').stream()
                count = 0
                for cmd in pending_cmds:
                    cmd.reference.update({
                        'status': 'completed', 
                        'executed_at': firestore.SERVER_TIMESTAMP
                    })
                    count += 1
                if count > 0:
                    print(f"[FIREBASE] Marked {count} command(s) as completed for {doc_id}")
            except Exception as e:
                print(f"[ERROR] updating commands: {e}")

# Start listening to the SPECIFIC feeder document
# This is much more reliable than collection watch for a single device
print(f"[SYSTEM] Listening for Manual Control on 'feeders/feeder_001'...")
feeder_watch = db.collection("feeders").document("feeder_001").on_snapshot(on_snapshot)

# --- 2. SCHEDULER LOGIC ---
def check_schedules():
    """Checks if any routine matches the current time"""
    
    # Use UTC timezone (matches VM system time)
    try:
        utc_tz = pytz.UTC
        now = datetime.now(utc_tz)
        
        current_time_str = now.strftime("%H:%M") # e.g. "14:30"
        current_day_int = now.weekday()          # 0=Mon, 6=Sun
        
        # Debug: Print current time being checked (only print once per minute to avoid spam)
        if now.second < 10:  # Only print in first 10 seconds of each minute
            print(f"[SCHEDULER] Current UTC time: {current_time_str}, Day: {current_day_int} ({['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][current_day_int]})")
        
        # Only print this once in a while to avoid spamming logs
        # print(f"[SCHEDULER] Checking {current_time_str} on day {current_day_int}...")

        # Get all feeders
        docs = db.collection('feeders').stream()

        for doc in docs:
            data = doc.to_dict()
            device_id = doc.id
            routines = data.get('routines', [])
            
            if not isinstance(routines, list):
                print(f"[SCHEDULER ERROR] routines is not a list for {device_id}, got: {type(routines)}")
                continue
            
            for index, routine in enumerate(routines):
                # Skip if routine is not a dictionary
                if not isinstance(routine, dict):
                    print(f"[SCHEDULER ERROR] Routine {index} is not a dict for {device_id}, got type: {type(routine)}, value: {routine}")
                    print(f"[SCHEDULER ERROR] Please delete this invalid entry from Firebase!")
                    continue
                
                # Logic: Enabled? + Time Match? + Day Match?
                try:
                    if (routine.get('enabled') == True and 
                        routine.get('time') == current_time_str and 
                        current_day_int in routine.get('days', [])):
                        
                        print(f"[SCHEDULE] Match found for {device_id} at {current_time_str}!")
                        
                        # Mark this as a scheduled feed (will be used when event comes back)
                        last_scheduled_feed_time[device_id] = datetime.now(utc_tz)
                        
                        # Send feed command
                        send_mqtt_command(device_id, "FEED")
                        
                        # Also create a feeding log entry with scheduled source
                        portion_size = routine.get('portion_size', 20)  # Get portion from routine
                        try:
                            # Add feeding log to Firestore with "scheduled" source
                            db.collection("feeders").document(device_id).collection("feeding_logs").add({
                                'device_id': device_id,
                                'source': 'scheduled',
                                'timestamp': firestore.SERVER_TIMESTAMP,
                                'last_seen': firestore.SERVER_TIMESTAMP,
                                'portion_size': portion_size,
                                'food_remaining': 0,  # Will be updated when device responds
                                'scheduled_time': current_time_str,
                            })
                            print(f"[SCHEDULE] Added feeding log for scheduled feed: {portion_size}g")
                        except Exception as log_error:
                            print(f"[SCHEDULE ERROR] Failed to log scheduled feed: {log_error}")
                        
                except Exception as routine_error:
                    print(f"[SCHEDULER ERROR] Failed processing routine {index}: {routine_error}")
                    print(f"[SCHEDULER ERROR] Routine data: {routine}")
                    
                    # IMPORTANT: Sleep briefly to avoid double-triggering in the same second
                    # But since we run this loop every 60s, it should be fine.
    except Exception as e:
        print(f"[SCHEDULER ERROR] {e}")

# --- MQTT CALLBACKS ---
def on_connect(client, userdata, flags, rc, properties=None):
    global is_mqtt_connected
    if rc == 0:
        print(f"[SYSTEM] MQTT Connected Successfully.")
        is_mqtt_connected = True
        # Subscribe to Command topic too, to verify we are sending correctly (Loopback check)
        client.subscribe([(TOPIC_EVENTS, 0), (TOPIC_TELEMETRY, 0), (TOPIC_COMMAND_ALL, 0)])
    else:
        print(f"[SYSTEM] MQTT Connection FAILED with code {rc}")

def on_disconnect(client, userdata, flags, rc, properties=None):
    global is_mqtt_connected
    print(f"[SYSTEM] MQTT Disconnected! (rc={rc})")
    is_mqtt_connected = False

def on_message(client, userdata, msg):
    try:
        payload = msg.payload.decode()
        
        # [DEBUG] Loopback check: Did we see our own command?
        if "command" in msg.topic:
            print(f"[DEBUG] VERIFIED: Broker received command '{payload}' on '{msg.topic}'")
            return

        data = json.loads(payload)
        device_id = data.get("device_id", "feeder_001")
        
        if "events" in msg.topic:
            print(f"[EVENT] Feeding Complete!")
            
            # Check if this was a scheduled feed (within last 2 minutes)
            if device_id in last_scheduled_feed_time:
                time_diff = (datetime.now(pytz.UTC) - last_scheduled_feed_time[device_id]).total_seconds()
                if time_diff < 120:  # Within 2 minutes
                    # This is a scheduled feed - ensure source is "scheduled"
                    data['source'] = 'scheduled'
                    print(f"[EVENT] Marking as SCHEDULED feed (triggered {time_diff:.0f}s ago)")
                    # Clear the tracking
                    del last_scheduled_feed_time[device_id]
                else:
                    # Old scheduled feed tracking, clear it
                    del last_scheduled_feed_time[device_id]
            
            # If no source is set, default to "manually"
            if 'source' not in data:
                data['source'] = 'manually'
            
            save_history(device_id, "feeding_logs", data)
            update_live_status(device_id, data)
            
        elif "telemetry" in msg.topic:
            # print(f"[TELEMETRY] Update from {device_id}") # Optional: Uncomment to see logs
            update_live_status(device_id, data)

    except Exception as e:
        print(f"[ERROR] {e}")

# --- MAIN SETUP ---
mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
mqtt_client.username_pw_set(USERNAME, PASSWORD)
mqtt_client.on_connect = on_connect
mqtt_client.on_disconnect = on_disconnect
mqtt_client.on_message = on_message

print("[SYSTEM] Starting Background Services...")

# 1. Connect MQTT
try:
    print(f"[SYSTEM] Connecting to MQTT Broker at {BROKER}...")
    mqtt_client.connect(BROKER, PORT, 60)
    mqtt_client.loop_start() # <--- Runs in background thread!
except Exception as e:
    print(f"[CRITICAL] MQTT Failed: {e}")

# 2. Main Loop (Handles Scheduler)
last_checked_minute = -1


while True:
    try:
        # Get current minute
        current_minute = datetime.now().minute
        
        # Only run scheduler ONCE per minute
        if current_minute != last_checked_minute:
            check_schedules()
            last_checked_minute = current_minute
        
        # Sleep to save CPU (check every 5 seconds)
        time.sleep(5)
        
    except KeyboardInterrupt:
        print("\n[SYSTEM] Stopping...")
        mqtt_client.loop_stop()
        break
    except Exception as e:
        print(f"[ERROR] Main Loop: {e}")
        time.sleep(5)