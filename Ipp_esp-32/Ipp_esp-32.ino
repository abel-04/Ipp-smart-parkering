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

// ===== NYA VARIABLER FÖR TIMERN =====
unsigned long objectDetectedTime = 0; // Sparar tidpunkten då något först dök upp
bool objectWasPresent = false;        // Håller koll på om det stod något där förra mätningen
String currentStatus = "free";        

void setup() {
  Serial.begin(115200);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  // WiFi anslutning 
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Ansluter till WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println();
  Serial.print("IP-adress: ");
  Serial.println(WiFi.localIP());
  Serial.println("WiFi ansluten ✅");

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

  // Om sensorn tappar kontakten eller visar 0, sätt ett högt värde så det inte misstolkas som nära
  if (distance == 0) {
    distance = 999;
  }

  Serial.print("Distance: ");
  Serial.print(distance);
  Serial.println(" cm");

  // === Logik för 45 cm och 2 sekunders fördröjning ===
  String nextStatus = currentStatus; // Utgå från att statusen är oförändrad

  if (distance <= 45) {
    // Något är framför sensorn!
    if (!objectWasPresent) {
      // Det här är första gången vi ser föremålet. Starta timern!
      objectDetectedTime = millis(); 
      objectWasPresent = true;
      Serial.println("⏳ Föremål upptäckt... väntar 2 sekunder för att bekräfta.");
    } else {
      // Föremålet stod här redan förra loopen. Kolla om det har gått 2 sekunder (2000 ms).
      if (millis() - objectDetectedTime >= 2000) {
        nextStatus = "occupied";
      }
    }
  } else {
    // Inget är framför sensorn (eller så försvann det)
    objectWasPresent = false;
    nextStatus = "free";
  }

  // === Skicka till Firebase ENBART om statusen faktiskt har ändrats ===
  if (nextStatus != currentStatus) {
    currentStatus = nextStatus; // Uppdatera vår lokala status

    if (currentStatus == "occupied") {
      Serial.println("🚗 UPPTAGEN (Bekräftat)");
    } else {
      Serial.println("🟢 LEDIG");
    }

    if (Firebase.RTDB.setString(&fbdo, "parking/spot1/status", currentStatus)) {
      Serial.println("Data skickad till Firebase ✅");
    } else {
      Serial.print("Fel vid sändning: ");
      Serial.println(fbdo.errorReason());
    }
  }

  delay(200); // Vi kör loopen oftare (5 gånger i sekunden) för att timern ska vara exakt!
}