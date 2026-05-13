#include <WiFi.h>
#include <Firebase_ESP_Client.h>

// ===== WIFI =====
#define WIFI_SSID "iPhone"
#define WIFI_PASSWORD "123457895"

// ===== FIREBASE =====
#define API_KEY "AIzaSyAMIWDurP4Aw-6_ax4OtXYRx3SVC-EsEf8"
#define DATABASE_URL "https://ipp-databas-default-rtdb.europe-west1.firebasedatabase.app/"

// ===== SENSOR PINS =====
#define TRIG_PIN 5
#define ECHO_PIN 18

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

long duration;
float distance;

void setup() {
  Serial.begin(115200);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  // WiFi anslutning
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Ansluter till WiFi");

  while (WiFi.status() != WL_CONNECTED) {
  delay(500);
  Serial.print("Status: ");
  Serial.println(WiFi.status()); 
}

  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  
  Serial.println();
  Serial.print("IP-adress: ");
  Serial.println(WiFi.localIP());

  Serial.println("\nWiFi ansluten ✅");

  // Firebase setup
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

    if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase signup OK");
  } else {
    Serial.printf("Signup error: %s\n", config.signer.signupError.message.c_str());
  }

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {

  // === Mät avstånd ===
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);

  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);

  digitalWrite(TRIG_PIN, LOW);

  duration = pulseIn(ECHO_PIN, HIGH, 25000);
  distance = duration * 0.034 / 2;

  Serial.print("Distance: ");
  Serial.print(distance);
  Serial.println(" cm");

  // === Avgör status ===
  String status;

  if (distance < 50) {
    status = "occupied";
    Serial.println("🚗 UPPTAGEN");
  } else {
    status = "free";
    Serial.println("🟢 LEDIG");
  }

  // === Skicka till Firebase ===
  if (Firebase.RTDB.setString(&fbdo, "parking/spot1/status", status)) {
    Serial.println("Data skickad ✅");
  } else {
    Serial.println("Fel:");
    Serial.println(fbdo.errorReason());
  }

  delay(5000); // uppdatera var 5:e sekund
}