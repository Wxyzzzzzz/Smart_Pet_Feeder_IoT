"""
Test script to populate Firebase with mock sensor history data for analytics
Run this script to add 7 days of sensor data for consumption trend analysis
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import random

# Initialize Firebase Admin SDK
if not firebase_admin._apps:
    cred = credentials.Certificate('serviceAccountKey .json')
    firebase_admin.initialize_app(cred)
    print("Firebase initialized")
else:
    print("Firebase app already initialized")

db = firestore.client()
device_id = 'feeder_001'

def add_sensor_history():
    """Add 7 days of mock sensor history data"""
    
    print(f"Adding sensor history data for device: {device_id}")
    
    # Starting values
    food_level = 100  # Start at full
    base_temp = 27  # Base temperature in Celsius
    base_humidity = 68  # Base humidity percentage
    
    # Generate data for the last 7 days, with multiple readings per day
    now = datetime.now()
    
    for day in range(7, 0, -1):  # 7 days ago to 1 day ago
        # 4 readings per day (every 6 hours)
        for hour_offset in [0, 6, 12, 18]:
            timestamp = now - timedelta(days=day, hours=24-hour_offset)
            
            # Food level decreases over time (3-8% per reading)
            food_level = max(0, food_level - random.uniform(3, 8))
            
            # Temperature fluctuates slightly
            temp = base_temp + random.uniform(-2, 2)
            
            # Humidity fluctuates
            humidity = base_humidity + random.uniform(-5, 10)
            
            # Detect food presence if level > 10%
            detected = food_level > 10
            
            data = {
                'device_id': device_id,
                'food_level': int(food_level),
                'temp': int(temp),
                'humidity': int(humidity),
                'detected': detected,
                'timestamp': timestamp,
                'last_seen': timestamp,
            }
            
            # Add to sensor_history subcollection
            db.collection('feeders').document(device_id).collection('sensor_history').add(data)
            
            print(f"✓ Added sensor data: {timestamp.strftime('%Y-%m-%d %H:%M')} | "
                  f"Food: {int(food_level)}% | Temp: {int(temp)}°C | Humidity: {int(humidity)}%")
    
    # Also update the main document with latest values
    latest_data = {
        'device_id': device_id,
        'food_level': int(food_level),
        'temp': int(base_temp + random.uniform(-1, 1)),
        'humidity': int(base_humidity + random.uniform(-3, 5)),
        'detected': food_level > 10,
        'last_seen': firestore.SERVER_TIMESTAMP,
    }
    
    db.collection('feeders').document(device_id).set(latest_data, merge=True)
    print(f"\n✓ Updated main document with latest sensor data")
    print(f"✓ Current food level: {int(food_level)}%")
    print("\n✅ Sensor history data added successfully!")
    print("📊 Check the Analytics screen to see the consumption trend chart")

if __name__ == '__main__':
    add_sensor_history()
