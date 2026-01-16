/*
 * SmartPet Firmware (ESP32)
 * Connects to Google Cloud (via MQTT Bridge)
 * Reads: Ultrasonic, Active IR, DHT11
 * Controls: Servo Motor
 */

/* 
REQUIRED LIBRARY

PubSubClient (by Nick O'Leary) - For MQTT.

ESP32Servo (by Kevin Harrington) - For the Servo Motor.

DHT sensor library (by Adafruit) - For the Temp sensor.

ArduinoJson (by Benoit Blanchon) - To create the data payload easily.

*/

#include <WiFi.h>
#include <PubSubClient.h>
#include <ESP32Servo.h>
#include <DHT.h>
#include <ArduinoJson.h>
#include "secret.h" 

// --- 1. PIN DEFINITIONS ---
// #define TRIG_PIN  5    // Ultrasonic Trigger
// #define ECHO_PIN  18   // Ultrasonic Echo
// #define IR_PIN    4    // Active IR Sensor (Obstacle)
// #define SERVO_PIN 13   // Servo Motor Signal
// #define DHT_PIN   14   // DHT11 Sensor Pin

// LEFT SIDE (5V High Power Components)
#define SERVO_PIN 13   // Servo Motor Signal
#define TRIG_PIN  27   // Ultrasonic Trigger (Changed from 5)
#define ECHO_PIN  26   // Ultrasonic Echo    (Changed from 18)

// RIGHT SIDE (3.3V Logic Components)
#define IR_PIN    4    // Active IR Sensor
#define DHT_PIN   18

#define BUTTON_PIN 14
#define LED_PIN 15

// --- 2. GLOBAL OBJECTS ---
DHT dht(DHT_PIN, DHT11);
Servo feederServo;
WiFiClient espClient;
PubSubClient client(espClient);

// --- 3. TIMING VARIABLES ---
unsigned long lastTelemetryTime = 0;
const long telemetryInterval = 10000; // Send data every 10 seconds

// ================================================================
//                      SENSOR FUNCTIONS
// ================================================================

// Function to read Ultrasonic Sensor and convert to %
int getFoodLevel() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  
  long duration = pulseIn(ECHO_PIN, HIGH);
  int distanceCm = duration * 0.034 / 2;

  Serial.printf("Ultrasonic sensor: Length %d cm\n", distanceCm);
  
  // Assume box height is 10 cm
  // 10 cm = empty
  // 2 cm = full
  int maxDepth = 10; 
  int minDepth = 1;
  
  int percentage = map(distanceCm, maxDepth, minDepth, 0, 100);

  return constrain(percentage, 0, 100); // Keep result between 0-100
}

// Function to move the Servo
void dispenseFood(String source) {
  Serial.println("--------------------------------");
  Serial.printf("STATUS: Feeding %s\n", source.c_str());
  
  // Servo action
  feederServo.attach(SERVO_PIN); 
  feederServo.write(180);
  delay(3000); 
  feederServo.write(0);  
  delay(500);
  feederServo.detach();

  // JSON Payload
  StaticJsonDocument<200> doc;
  doc["device_id"] = DEVICE_ID;
  doc["type"]      = "FEEDING_COMPLETE";
  doc["source"]    = source;
  doc["food_remaining"] = getFoodLevel();
  
  char jsonBuffer[512];
  serializeJson(doc, jsonBuffer);
  
  if (client.publish(EVENT_TOPIC, jsonBuffer)) {
    Serial.println("SUCCESS: Info updated to MQTT");
  } else {
    Serial.println("ERROR: Failed to send MQTT message");
  }

  Serial.println("--------------------------------");
}

// ================================================================
//                      MQTT FUNCTIONS
// ================================================================

// Callback: Runs when a message arrives on subscribed topic
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.println("====================================");
  Serial.println("    MQTT MESSAGE RECEIVED!");
  Serial.println("====================================");
  Serial.print("Topic: ");
  Serial.println(topic);
  Serial.print("Payload Length: ");
  Serial.println(length);
  Serial.print("Raw Payload: ");
  
  String message;
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
    message += (char)payload[i];
  }
  Serial.println();
  Serial.print("Parsed Message: ");
  Serial.println(message);
  Serial.println("====================================");

  // Check if the message says "FEED"
  if (String(topic) == COMMAND_TOPIC) {
    Serial.println("Topic matches COMMAND_TOPIC!");
    Serial.print("Checking for 'FEED' command in: ");
    Serial.println(message);
    
    if (message.indexOf("FEED") >= 0) {
      Serial.println("✅ FEED command detected! Starting dispense...");
      dispenseFood("SYSTEM");
    } else {
      Serial.println("❌ No FEED command found in message");
    }
  } else {
    Serial.print("Topic mismatch! Expected: ");
    Serial.print(COMMAND_TOPIC);
    Serial.print(", Got: ");
    Serial.println(topic);
  }
  Serial.println("====================================");
}

// Reconnect Loop
void reconnect() {
  // Loop until we're reconnected
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection to ");
    Serial.print(MQTT_SERVER);
    Serial.print(":");
    Serial.print(MQTT_PORT);
    Serial.print("...");
    
    // Create a random client ID so multiple devices don't clash
    String clientId = "ESP32Client-";
    clientId += String(random(0xffff), HEX);
    
    Serial.print(" (Client ID: ");
    Serial.print(clientId);
    Serial.print(")...");
    
    // Attempt to connect
    if (client.connect(clientId.c_str(), MQTT_USER, MQTT_PASS)) {
      Serial.println("✅ CONNECTED!");
      Serial.print("Subscribing to: ");
      Serial.println(COMMAND_TOPIC);
      
      // Once connected, resubscribe to the command topic
      bool subResult = client.subscribe(COMMAND_TOPIC);
      
      if (subResult) {
        Serial.println("✅ Subscription successful!");
      } else {
        Serial.println("❌ Subscription FAILED!");
      }
    } else {
      Serial.print("❌ FAILED, rc=");
      Serial.print(client.state());
      Serial.println(" | Retry in 5s...");
      Serial.println("Return codes: -4=timeout, -3=lost, -2=failed, -1=disconnected, 0=connected, 1=bad protocol, 2=rejected, 3=unavailable, 4=bad credentials, 5=unauthorized");
      delay(5000);
    }
  }
}

// ================================================================
//                          MAIN SETUP
// ================================================================
void setup() {
  Serial.begin(9600);
  delay(1000);
  
  Serial.println("\n\n====================================");
  Serial.println("   SMART PET FEEDER - ESP32");
  Serial.println("====================================");

  // Hardware Initialization
  Serial.println("Initializing Hardware...");
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(IR_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  dht.begin();
  Serial.println("✅ Hardware initialized");
  
  // WiFi Connection
  Serial.println("\n--- WiFi Connection ---");
  Serial.print("SSID: ");
  Serial.println(WIFI_SSID);
  Serial.print("Connecting");

  WiFi.begin(WIFI_SSID, WIFI_PASS);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi connected!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    Serial.print("Signal Strength (RSSI): ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
  } else {
    Serial.println("\n❌ WiFi connection FAILED!");
    Serial.println("Please check credentials in secret.h");
  }

  // MQTT Initialization
  Serial.println("\n--- MQTT Configuration ---");
  Serial.print("Server: ");
  Serial.println(MQTT_SERVER);
  Serial.print("Port: ");
  Serial.println(MQTT_PORT);
  Serial.print("Username: ");
  Serial.println(MQTT_USER);
  Serial.print("Command Topic: ");
  Serial.println(COMMAND_TOPIC);
  Serial.print("Event Topic: ");
  Serial.println(EVENT_TOPIC);
  Serial.print("Telemetry Topic: ");
  Serial.println(TELEMETRY_TOPIC);
  
  client.setServer(MQTT_SERVER, MQTT_PORT);
  client.setCallback(callback);
  
  Serial.println("\n====================================");
  Serial.println("   SETUP COMPLETE - STARTING LOOP");
  Serial.println("====================================\n");
}

// ================================================================
//                          MAIN LOOP
// ================================================================
void loop() {
  // 1. Ensure MQTT is connected
  if (!client.connected()) {
    reconnect();
  }
  client.loop(); // Important: Checks for incoming messages

  // Pet detection
  if (digitalRead(IR_PIN) == LOW) {
    digitalWrite(LED_PIN, HIGH); // Pet Detected -> Turn LED ON
  } else {
    digitalWrite(LED_PIN, LOW);  // No Pet -> Turn LED OFF
  }

  // Manual feeding button
  if (digitalRead(BUTTON_PIN) == LOW) {
    Serial.println("Manual feeding triggered");
    dispenseFood("MANUAL"); 
    delay(500); // Simple debounce (prevents double triggering)
  }

  // 2. Non-Blocking Timer for Telemetry (Every 10 seconds)
  unsigned long currentMillis = millis();
  if (currentMillis - lastTelemetryTime >= telemetryInterval) {
    lastTelemetryTime = currentMillis;

    // --- READ SENSORS ---
    int foodLevel = getFoodLevel();
    float temp = dht.readTemperature();
    float humidity = dht.readHumidity();
    
    // IR Sensor: LOW = pet coming
    bool detected = (digitalRead(IR_PIN) == LOW); 

    // Error handling for DHT
    if (isnan(temp) || isnan(humidity)) {
      Serial.println("Failed to read from DHT sensor!");
      temp = 0;
      humidity = 0;
    }

    // --- PREPARE JSON ---
    // Capacity 256 bytes is enough for this data
    StaticJsonDocument<256> doc;
    doc["device_id"] = DEVICE_ID;
    doc["food_level"] = foodLevel;
    doc["temp"] = temp;
    doc["humidity"] = humidity;
    doc["detected"] = detected;

    char jsonBuffer[512];
    serializeJson(doc, jsonBuffer);

    // --- PUBLISH TO MQTT ---
    client.publish(TELEMETRY_TOPIC, jsonBuffer);
    
    // Debug Print
    Serial.print("Sent Telemetry: ");
    Serial.println(jsonBuffer);
  }
}