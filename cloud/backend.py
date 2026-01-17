import paho.mqtt.client as mqtt
import json
import time
import os
import pytz
import threading
from datetime import datetime
import ssl
import firebase_admin
from firebase_admin import credentials, firestore, messaging

# --- CONFIGURATION ---
# Since this script runs on the SAME VM as the Mosquitto Broker,
# we can use "localhost" for lower latency and security.
BROKER = "localhost" 
PORT = 8883
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

# --- HELPER FUNCTIONS ---

def send_mqtt_command(device_id, command_text):
    """Sends a command (like 'FEED') to the ESP32"""
    # FIX: Topic must match firmware (feeder/feeder_001/command)
    topic = f"{TOPIC_CMD_PREFIX}{device_id}/command"
    
    if mqtt_client and is_mqtt_connected:
        info = mqtt_client.publish(topic, command_text)
        info.wait_for_publish() # Block until message is actually sent to broker
        print(f"[COMMAND] Sent '{command_text}' to {topic} (Message ID: {info.mid})")
    else:
        print(f"[ERROR] Cannot send command: MQTT not connected! (Client: {mqtt_client}, Connected: {is_mqtt_connected})")

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
    # doc_snapshot is a list of documents if tracking collection, 
    # but for a single document watch, let's treat it carefully.
    
    for doc in doc_snapshot:
        if not doc.exists:
            continue
            
        data = doc.to_dict()
        doc_id = doc.id
        manual_feed_val = data.get('manual_feed')
        
        # [DEBUG] Print state of manual_feed to debug the button press
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
    
    # Get Malaysia Time
    try:
        kl_tz = pytz.timezone('Asia/Kuala_Lumpur')
        now = datetime.now(kl_tz)
        
        current_time_str = now.strftime("%H:%M") # e.g. "14:30"
        current_day_int = now.weekday()          # 0=Mon, 6=Sun
        
        # Only print this once in a while to avoid spamming logs
        # print(f"[SCHEDULER] Checking {current_time_str} on day {current_day_int}...")

        # Get all feeders
        docs = db.collection('feeders').stream()

        for doc in docs:
            data = doc.to_dict()
            device_id = doc.id
            routines = data.get('routines', [])
            
            for routine in routines:
                # Logic: Enabled? + Time Match? + Day Match?
                if (routine.get('enabled') == True and 
                    routine.get('time') == current_time_str and 
                    current_day_int in routine.get('days')):
                    
                    print(f"[SCHEDULE] Match found for {device_id} at {current_time_str}!")
                    send_mqtt_command(device_id, "FEED")
                    
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
            save_history(device_id, "feeding_logs", data)
            update_live_status(device_id, data)
            
        elif "telemetry" in msg.topic:
            # print(f"[TELEMETRY] Update from {device_id}") # Optional: Uncomment to see logs
            update_live_status(device_id, data)

    except Exception as e:
        print(f"[ERROR] {e}")

# --- MAIN SETUP ---
mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
#mqtt_client.tls_set(ca_certs="ca.crt")    #TLS Cert
#mqtt_client.tls_insecure_set(True)

# 1. Create a custom SSL context
context = ssl.create_default_context()

# 2. Tell the context to trust your CA file
context.load_verify_locations(cafile="ca.crt")

# 3. Disable strict checks (The "Nuclear" part)
context.check_hostname = False
context.verify_mode = ssl.CERT_NONE 

# 4. Apply the context to the client
mqtt_client.tls_set_context(context)

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
