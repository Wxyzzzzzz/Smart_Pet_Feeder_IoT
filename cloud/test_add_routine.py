"""
Test script to add a routine directly to Firebase
"""

import firebase_admin
from firebase_admin import credentials, firestore

print("=== Test: Add Routine to Firebase ===\n")

# Initialize Firebase
KEY_PATH = "serviceAccountKey.json"
try:
    cred = credentials.Certificate(KEY_PATH)
    app = firebase_admin.initialize_app(cred)
except ValueError:
    app = firebase_admin.get_app()

db = firestore.client()

# Get feeder document
device_id = "feeder_001"
feeder_ref = db.collection("feeders").document(device_id)

print("1. Getting current document...")
doc = feeder_ref.get()

if doc.exists:
    data = doc.to_dict()
    print(f"   ✅ Document exists")
    print(f"   Fields: {list(data.keys())}")
    
    if 'routines' in data:
        print(f"   'routines' field EXISTS: {data['routines']}")
        print(f"   Type: {type(data['routines'])}")
    else:
        print(f"   'routines' field DOES NOT EXIST")
else:
    print(f"   ❌ Document does not exist!")

print("\n2. Adding test routine...")

# Create test routine
test_routine = {
    'time': '19:00',
    'portion_size': 20,
    'days': [0, 1, 2, 3, 4, 5, 6],
    'enabled': True
}

# Update document
try:
    # Get existing routines or create new list
    if doc.exists:
        data = doc.to_dict()
        routines = data.get('routines', [])
        
        # Ensure it's a list
        if not isinstance(routines, list):
            print(f"   ⚠️  routines is not a list (type: {type(routines)}), replacing...")
            routines = []
    else:
        routines = []
    
    routines.append(test_routine)
    
    feeder_ref.set({
        'routines': routines
    }, merge=True)
    
    print(f"   ✅ Routine added successfully!")
    print(f"   Total routines: {len(routines)}")
    
except Exception as e:
    print(f"   ❌ Error: {e}")

print("\n3. Verifying...")
doc = feeder_ref.get()
data = doc.to_dict()
print(f"   Routines in Firebase: {data.get('routines')}")

print("\n=== Test Complete ===")
