import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import random

# Initialize Firebase Admin SDK
if not firebase_admin._apps:
    cred = credentials.Certificate('serviceAccountKey .json')
    firebase_admin.initialize_app(cred)

db = firestore.client()

def add_feeding_logs_for_days():
    """Add feeding logs for Monday, Tuesday, Wednesday with 625g each day"""
    device_id = 'feeder_001'
    
    # Calculate dates for Mon, Tue, Wed of this week
    today = datetime.now()
    
    # Find the Monday of current week (today is Friday Jan 17, 2026)
    # Monday would be Jan 13, Tuesday Jan 14, Wednesday Jan 15
    days_since_monday = today.weekday()  # 0=Monday, 4=Friday
    monday = today - timedelta(days=days_since_monday)
    
    days_to_add = [
        ('Monday', monday, 625),
        ('Tuesday', monday + timedelta(days=1), 625),
        ('Wednesday', monday + timedelta(days=2), 625)
    ]
    
    print(f"Adding feeding logs for device: {device_id}")
    
    for day_name, date, total_grams in days_to_add:
        # Split 625g into 2 feedings per day (morning and evening)
        feedings_per_day = 2
        portion_size = total_grams / feedings_per_day  # 312.5g each
        
        for feeding_num in range(feedings_per_day):
            # Morning (8 AM) and Evening (6 PM)
            hour = 8 if feeding_num == 0 else 18
            timestamp = date.replace(hour=hour, minute=random.randint(0, 59), second=random.randint(0, 59))
            
            feeding_log = {
                'device_id': device_id,
                'food_remaining': random.randint(70, 90),  # Mock remaining food percentage
                'last_seen': timestamp,
                'source': 'scheduled',
                'timestamp': timestamp,
                'portion_size': portion_size,
            }
            
            # Add to Firestore subcollection under feeders/feeder_001/feeding_logs
            db.collection('feeders').document(device_id).collection('feeding_logs').add(feeding_log)
            print(f"✓ Added feeding log: {day_name} {timestamp.strftime('%H:%M')} | {portion_size}g")
    
    print(f"\n✅ Feeding logs added successfully!")
    print(f"📊 Check the Analytics screen to see the Daily Food Consumption chart")

if __name__ == '__main__':
    add_feeding_logs_for_days()
