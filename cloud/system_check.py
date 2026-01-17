import os
import sys
import firebase_admin
from firebase_admin import credentials, firestore

def check_firebase():
    print("\n=== FIREBASE STATUS ===")
    
    key_path = "serviceAccountKey.json"
    if not os.path.exists(key_path):
        print(f"{key_path} not found!")
        print(f"   Current directory: {os.getcwd()}")
        return False
    
    print(f"{key_path} exists")
    
    try:
        cred = credentials.Certificate(key_path)
        try:
            app = firebase_admin.initialize_app(cred)
        except ValueError:
            app = firebase_admin.get_app()
        
        print(f"✅ Firebase connected")
        print(f"   Project ID: {cred.project_id}")
        
        # Test Firestore access
        db = firestore.client()
        feeder_ref = db.collection("feeders").document("feeder_001")
        doc = feeder_ref.get()
        
        if doc.exists:
            print(f"Feeder document exists")
            data = doc.to_dict()
            print(f"   - food_level: {data.get('food_level')}")
            print(f"   - temp: {data.get('temp')}")
            print(f"   - humidity: {data.get('humidity')}")
            print(f"   - manual_feed: {data.get('manual_feed')}")
            
            if 'last_seen' in data:
                from datetime import datetime
                try:
                    last_seen = data['last_seen']
                    if hasattr(last_seen, 'timestamp'):
                        last_seen_dt = datetime.fromtimestamp(last_seen.timestamp())
                        now = datetime.now()
                        diff = now - last_seen_dt
                        print(f"   - last_seen: {diff.total_seconds():.0f} seconds ago")
                        
                        if diff.total_seconds() < 60:
                            print("   Device is ONLINE (recent update)")
                        elif diff.total_seconds() < 300:
                            print("   Device last seen recently")
                        else:
                            print("   Device appears OFFLINE")
                except:
                    print(f"   - last_seen: {data.get('last_seen')}")
        else:
            print(f"Feeder document does not exist!")
            print("   Run the backend or ESP32 first to create it")
            return False
        
        return True
        
    except Exception as e:
        print(f"Firebase error: {e}")
        return False

def check_mqtt_config():
    print("\n=== MQTT CONFIGURATION ===")
    
    backend_file = "backend.py"
    if not os.path.exists(backend_file):
        print(f"{backend_file} not found!")
        return False
    
    print(f"{backend_file} exists")
    
    with open(backend_file, 'r') as f:
        content = f.read()
        
        # Extract config values
        import re
        broker = re.search(r'BROKER = ["\'](.+?)["\']', content)
        port = re.search(r'PORT = (\d+)', content)
        username = re.search(r'USERNAME = ["\'](.+?)["\']', content)
        
        if broker:
            print(f"   Broker: {broker.group(1)}")
        if port:
            print(f"   Port: {port.group(1)}")
        if username:
            print(f"   Username: {username.group(1)}")
    
    return True

def check_secret_h():
    """Check if ESP32 secret.h exists"""
    print("\n=== ESP32 CONFIGURATION ===")
    
    secret_path = "../hardware/main/secret.h"
    if not os.path.exists(secret_path):
        print(f"{secret_path} not found!")
        print("   Copy secret.h.template and fill in your credentials")
        return False
    
    print(f"{secret_path} exists")
    
    with open(secret_path, 'r') as f:
        content = f.read()
        
        # Check if template values are still present
        if 'YOUR_WIFI_SSID' in content:
            print("Secret file still has template values!")
            print("   Edit secret.h with your actual WiFi/MQTT credentials")
            return False
        
        print("Secret file appears configured")
        
        import re
        mqtt_server = re.search(r'#define MQTT_SERVER ["\'](.+?)["\']', content)
        command_topic = re.search(r'#define COMMAND_TOPIC ["\'](.+?)["\']', content)
        
        if mqtt_server:
            print(f"   MQTT Server: {mqtt_server.group(1)}")
        if command_topic:
            print(f"   Command Topic: {command_topic.group(1)}")
    
    return True

def check_dependencies():
    """Check Python dependencies"""
    print("\n=== PYTHON DEPENDENCIES ===")
    
    required = [
        'paho-mqtt',
        'firebase-admin',
        'pytz'
    ]
    
    missing = []
    for package in required:
        try:
            __import__(package.replace('-', '_'))
            print(f"{package}")
        except ImportError:
            print(f"{package} - NOT INSTALLED")
            missing.append(package)
    
    if missing:
        print(f"\nInstall missing packages:")
        print(f"   pip install {' '.join(missing)}")
        return False
    
    return True

def main():
    print("="*50)
    print("  SMART PET FEEDER - SYSTEM STATUS CHECK")
    print("="*50)
    
    results = {
        "Dependencies": check_dependencies(),
        "Firebase": check_firebase(),
        "MQTT Config": check_mqtt_config(),
        "ESP32 Config": check_secret_h(),
    }
    
    print("\n" + "="*50)
    print("  SUMMARY")
    print("="*50)
    
    for component, status in results.items():
        icon = "✅" if status else "❌"
        print(f"{icon} {component}")
    
    all_ok = all(results.values())
    
    if all_ok:
        print("All systems ready!")
    else:
        print("Some components need attention")
    
    print("="*50)

if __name__ == "__main__":
    main()
