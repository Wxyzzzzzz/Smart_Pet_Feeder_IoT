"""
Notification Monitor Script
Monitors Firestore for feeding events and sensor data to trigger notifications.
This should be run alongside backend.py or integrated into it.
"""

import firebase_admin
from firebase_admin import credentials, firestore, messaging
import time
from datetime import datetime

# Initialize Firebase (if not already done)
try:
    db = firestore.client()
except:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()

# Thresholds
LOW_FOOD_THRESHOLD = 30.0  # Below 30%
HIGH_MOISTURE_THRESHOLD = 60.0  # Above 60%

# Track notification states to avoid spam
last_low_food_notification = {}
last_high_moisture_notification = {}
COOLDOWN_MINUTES = 30

def send_fcm_notification(title, body, data=None):
    """Send FCM notification to all subscribed users"""
    try:
        # Create notification message
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            topic='all_users'  # Send to topic (users need to subscribe to this)
        )
        
        # Send the message
        response = messaging.send(message)
        print(f"[NOTIFICATION] Sent: {title} - {response}")
        return response
    except Exception as e:
        print(f"[ERROR] Failed to send notification: {e}")
        return None

def can_send_notification(device_id, notification_type, last_notifications_dict):
    """Check if cooldown period has passed"""
    if device_id not in last_notifications_dict:
        return True
    
    last_time = last_notifications_dict[device_id]
    now = datetime.now()
    diff_minutes = (now - last_time).total_seconds() / 60
    
    return diff_minutes >= COOLDOWN_MINUTES

def monitor_sensor_data(doc_snapshot, changes, read_time):
    """Monitor sensor data for alerts"""
    for doc in doc_snapshot:
        if not doc.exists:
            continue
            
        data = doc.to_dict()
        device_id = doc.id
        
        # Check food level
        food_level = data.get('food_level', 100)
        humidity = data.get('humidity', 0)
        
        # Calculate food percentage (assuming food_level is 0-100)
        food_percentage = food_level
        
        # Low food alert
        if food_percentage <= LOW_FOOD_THRESHOLD:
            if can_send_notification(device_id, 'low_food', last_low_food_notification):
                send_fcm_notification(
                    title='🍽️ Food Level Low!',
                    body=f'Food is at {food_percentage:.1f}%. Please refill the container soon.',
                    data={'type': 'low_food', 'device_id': device_id}
                )
                last_low_food_notification[device_id] = datetime.now()
        
        # High moisture alert
        if humidity >= HIGH_MOISTURE_THRESHOLD:
            if can_send_notification(device_id, 'high_moisture', last_high_moisture_notification):
                send_fcm_notification(
                    title='⚠️ High Moisture Alert!',
                    body=f'Moisture is at {humidity}%. Food might be contaminated. Please check the container.',
                    data={'type': 'high_moisture', 'device_id': device_id}
                )
                last_high_moisture_notification[device_id] = datetime.now()

def monitor_feeding_logs(collection_snapshot, changes, read_time):
    """Monitor feeding logs for scheduled feed completions"""
    for change in changes:
        if change.type.name == 'ADDED':
            doc = change.document
            data = doc.to_dict()
            
            source = data.get('source', '')
            device_id = data.get('device_id', 'feeder_001')
            food_remaining = data.get('food_remaining', 0)
            
            # Only notify for scheduled feeds (not manual)
            if source == 'scheduled':
                send_fcm_notification(
                    title='✅ Scheduled Feeding Complete',
                    body=f'Scheduled feeding completed! Food remaining: {food_remaining}%',
                    data={'type': 'scheduled_feed', 'device_id': device_id}
                )
                
                # Also check if food is low after feeding
                if food_remaining <= LOW_FOOD_THRESHOLD:
                    if can_send_notification(device_id, 'low_food', last_low_food_notification):
                        send_fcm_notification(
                            title='🍽️ Food Level Low!',
                            body=f'Food is at {food_remaining}%. Please refill the container soon.',
                            data={'type': 'low_food', 'device_id': device_id}
                        )
                        last_low_food_notification[device_id] = datetime.now()

def start_monitoring():
    """Start all monitoring services"""
    print("[NOTIFICATION MONITOR] Starting...")
    
    # Monitor main feeder document for sensor data
    feeder_watch = db.collection("feeders").document("feeder_001").on_snapshot(
        monitor_sensor_data
    )
    
    # Monitor feeding logs for scheduled feeds
    feeding_logs_watch = db.collection("feeders").document("feeder_001")\
        .collection("feeding_logs").on_snapshot(monitor_feeding_logs)
    
    print("[NOTIFICATION MONITOR] Monitoring active")
    print("- Watching sensor data for food level and moisture")
    print("- Watching feeding logs for scheduled completions")
    
    # Keep running
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n[NOTIFICATION MONITOR] Stopping...")
        feeder_watch.unsubscribe()
        feeding_logs_watch.unsubscribe()

if __name__ == "__main__":
    start_monitoring()
