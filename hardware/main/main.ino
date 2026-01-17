#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ESP32Servo.h>
#include <DHT.h>
#include <ArduinoJson.h>
#include "secret.h" 

// --- PIN DEFINITIONS ---
#define SERVO_PIN 13
#define TRIG_PIN 27
#define ECHO_PIN 26
#define IR_PIN 4
#define DHT_PIN 18
#define BUTTON_PIN 14
#define LED_PIN 15

// --- GLOBAL OBJECTS ---
DHT dht(DHT_PIN, DHT11);
Servo feederServo;

// --- TLS-MQTT Client ---
WiFiClientSecure secureClient; 
PubSubClient client(secureClient);
// WiFiClient espClient;
// PubSubClient client(espClient);

// --- TIMING VARIABLES ---
unsigned long lastTelemetryTime = 0;
const long telemetryInterval = 10000;

// --- FUNCTIONS ---
// Ultrasonic Sensor
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
  int maxDepth = 10; 
  int minDepth = 1;
  
  int percentage = map(distanceCm, maxDepth, minDepth, 0, 100);

  return constrain(percentage, 0, 100); 
}

// Servo Motor Control
void dispenseFood(String source) {
  Serial.println("--------------------------------");
  Serial.printf("STATUS: Feeding %s\n", source.c_str());
  
  feederServo.attach(SERVO_PIN); 
  feederServo.write(180);
  delay(3000); 
  feederServo.write(0);  
  delay(500);
  feederServo.detach();

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

// --- MQTT Functions ---
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("]: ");
  
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.println(message);

  // Check if the message says "FEED"
  if (String(topic) == COMMAND_TOPIC) {
    if (message.indexOf("FEED") >= 0) {
      dispenseFood("SYSTEM");
    }
  }
}

// Reconnect Loop
void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    
    String clientId = "ESP32Client-";
    clientId += String(random(0xffff), HEX);
    
    if (client.connect(clientId.c_str(), MQTT_USER, MQTT_PASS)) {
      Serial.println("connected");

      client.subscribe(COMMAND_TOPIC);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(9600);

  // Hardware Initialize
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(IR_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  dht.begin();
  
  // WiFi Connect
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(WIFI_SSID);

  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());

  secureClient.setCACert(ca_cert);
  secureClient.setInsecure();

  // MQTT Initialize
  client.setServer(MQTT_SERVER, MQTT_PORT);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop(); 

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
    delay(500); 
  }

  // Every 10s, send telemetry
  unsigned long currentMillis = millis();
  if (currentMillis - lastTelemetryTime >= telemetryInterval) {
    lastTelemetryTime = currentMillis;

    int foodLevel = getFoodLevel();
    float temp = dht.readTemperature();
    float humidity = dht.readHumidity();
    bool detected = (digitalRead(IR_PIN) == LOW); 

    // Error handling 
    if (isnan(temp) || isnan(humidity)) {
      Serial.println("Failed to read from DHT sensor!");
      temp = 0;
      humidity = 0;
    }

    StaticJsonDocument<256> doc;
    doc["device_id"] = DEVICE_ID;
    doc["food_level"] = foodLevel;
    doc["temp"] = temp;
    doc["humidity"] = humidity;
    doc["detected"] = detected;

    char jsonBuffer[512];
    serializeJson(doc, jsonBuffer);

    client.publish(TELEMETRY_TOPIC, jsonBuffer);
    
    Serial.print("Sent Telemetry: ");
    Serial.println(jsonBuffer);
  }
}