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

# Configurations
BROKER = "localhost" 
PORT = 8883
USERNAME = "esp32_user"
PASSWORD = "1234" 

# Topics
TOPIC_EVENTS    = "feeder/+/events"
TOPIC_TELEMETRY = "feeder/+/telemetry"
TOPIC_COMMAND_ALL = "feeder/+/command"
TOPIC_CMD_PREFIX = "feeder/"

# Paths
KEY_PATH = "serviceAccountKey.json"
EVENT_FILE  = "../output/feeding_history.json"
SENSOR_FILE = "../output/sensor_log.json"

# Firebase Setup
cred = credentials.Certificate(KEY_PATH)
try:
    app = firebase_admin.initialize_app(cred)
    print(f"[SYSTEM] Firebase Connected. Project ID: {cred.project_id}")
except ValueError:
    app = firebase_admin.get_app()
    print(f"[SYSTEM] Firebase Re-Connected. Project ID: {cred.project_id}")

db = firestore.client()

mqtt_client = None  
is_mqtt_connected = False

# Functions
def send_mqtt_command(device_id, command_text):
    """Sends a command (like 'FEED') to the ESP32"""
    topic = f"{TOPIC_CMD_PREFIX}{device_id}/command"
    
    if mqtt_client and is_mqtt_connected:
        info = mqtt_client.publish(topic, command_text)
        info.wait_for_publish() 
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
    
# Real-time
def on_snapshot(doc_snapshot, changes, read_time):
    for doc in doc_snapshot:
        if not doc.exists:
            continue
            
        data = doc.to_dict()
        doc_id = doc.id
        manual_feed_val = data.get('manual_feed')
        
        if manual_feed_val is True:
             print(f"[DEBUG] Document {doc_id} STATE CHANGE: manual_feed = {manual_feed_val}")

        if manual_feed_val == True:
            print(f"[MANUAL] Trigger received for {doc_id}!")
            
            # 1. Send Command
            send_mqtt_command(doc_id, "FEED")
            
            # 2. Reset switch
            doc.reference.update({'manual_feed': False})

            # 3. Update commands
            try:
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

# Listen 
print(f"[SYSTEM] Listening for Manual Control on 'feeders/feeder_001'...")
feeder_watch = db.collection("feeders").document("feeder_001").on_snapshot(on_snapshot)

def check_schedules():
    
    # Malaysia Time
    try:
        kl_tz = pytz.timezone('Asia/Kuala_Lumpur')
        now = datetime.now(kl_tz)
        
        current_time_str = now.strftime("%H:%M") 
        current_day_int = now.weekday()      

        # Get all feeders
        docs = db.collection('feeders').stream()

        for doc in docs:
            data = doc.to_dict()
            device_id = doc.id
            routines = data.get('routines', [])
            
            for routine in routines:
                if (routine.get('enabled') == True and 
                    routine.get('time') == current_time_str and 
                    current_day_int in routine.get('days')):
                    
                    print(f"[SCHEDULE] Match found for {device_id} at {current_time_str}!")
                    send_mqtt_command(device_id, "FEED")
                    
    except Exception as e:
        print(f"[SCHEDULER ERROR] {e}")

# Callnbacks
def on_connect(client, userdata, flags, rc, properties=None):
    global is_mqtt_connected
    if rc == 0:
        print(f"[SYSTEM] MQTT Connected Successfully.")
        is_mqtt_connected = True
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
            update_live_status(device_id, data)

    except Exception as e:
        print(f"[ERROR] {e}")

mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
#mqtt_client.tls_set(ca_certs="ca.crt")    #TLS Cert
#mqtt_client.tls_insecure_set(True)

# 1. Custom SSL
context = ssl.create_default_context()

# 2. Verify CA file
context.load_verify_locations(cafile="ca.crt")

context.check_hostname = False
context.verify_mode = ssl.CERT_NONE 

mqtt_client.tls_set_context(context)

mqtt_client.username_pw_set(USERNAME, PASSWORD)
mqtt_client.on_connect = on_connect
mqtt_client.on_disconnect = on_disconnect
mqtt_client.on_message = on_message

print("[SYSTEM] Starting Background Services...")


try:
    print(f"[SYSTEM] Connecting to MQTT Broker at {BROKER}...")
    mqtt_client.connect(BROKER, PORT, 60)
    mqtt_client.loop_start()
except Exception as e:
    print(f"[CRITICAL] MQTT Failed: {e}")

last_checked_minute = -1


while True:
    try:
        # Get current minute
        current_minute = datetime.now().minute
        
        if current_minute != last_checked_minute:
            check_schedules()
            last_checked_minute = current_minute
        
        # Sleep 
        time.sleep(5)
        
    except KeyboardInterrupt:
        print("\n[SYSTEM] Stopping...")
        mqtt_client.loop_stop()
        break
    except Exception as e:
        print(f"[ERROR] Main Loop: {e}")
        time.sleep(5)
