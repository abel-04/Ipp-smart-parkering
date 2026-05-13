import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'; // Ändrat till Mapbox!
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  MapboxOptions.setAccessToken(
    "pk.eyJ1IjoiaXR6YWJlbCIsImEiOiJjbW55MWt5Z2UwOTMxMnBzOTZpOHBqeTUyIn0.3Q1h7Jw-_7eDcc7P7SOFqA",
  );
  runApp(const ParklyApp());
}

// 1. HUVUDAPP & TEMA
class ParklyApp extends StatelessWidget {
  const ParklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parkly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1D4ED8),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D4ED8)),
      ),
      home: const LoginScreen(),
    );
  }
}

// 2. INLOGGNINGSSKÄRMEN (Nu med Riktig Firebase Auth)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Dessa "controllers" läser av vad användaren skriver i rutorna
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // En variabel för att visa en laddningssnurra när vi pratar med Firebase
  bool isLoading = false;

  // FUNKTION: Logga in befintlig användare
  Future<void> signIn() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      // Om det lyckas, gå till kartan!
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? "Något gick fel vid inloggningen.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // FUNKTION: Skapa ett helt nytt konto
  Future<void> signUp() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      // Om kontot skapas, gå rakt in i kartan!
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? "Kunde inte skapa konto.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // FUNKTION: Visa felmeddelanden snyggt (t.ex. fel lösenord)
  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Kom ihåg att städa upp controllers när skärmen stängs
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // 1. Center håller allt snyggt i mitten när tangentbordet är nere
        child: Center(
          // 2. SingleChildScrollView gör att man kan scrolla när tangentbordet är uppe!
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logga (Spacer() är borttagen här)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D9488),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "PARKLY",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Let's find your spot.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Textfält Email
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.mail_outline,
                      color: Colors.grey,
                    ),
                    hintText: "Email",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1D4ED8)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Textfält Lösenord
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.grey,
                    ),
                    hintText: "Password",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1D4ED8)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Log In Knapp
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Log In",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "OR",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),

                // Sociala inloggningar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _socialButton(Icons.apple, Colors.black),
                    _socialButton(Icons.g_mobiledata, Colors.red),
                    _socialButton(Icons.facebook, Colors.blue),
                  ],
                ),
                const SizedBox(
                  height: 40,
                ), // Ersatte nedre Spacer() med en fast marginal
                // Sign Up Knapp
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: isLoading ? null : signUp,
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, Color color) {
    return Container(
      width: 80,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}

// ==========================================
// NAVIGATION
// ==========================================
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _isParkingActive = false;
  DateTime? _parkingStartTime;

  void _startParking() {
    setState(() {
      _isParkingActive = true;
      _parkingStartTime = DateTime.now();
      _currentIndex = 1; // Byter flik till Active
    });
  }

  List<Widget> get _pages => [
    MapScreen(
      onParkConfirmed:
          _startParking, // Skickar signalen till funktionen ovanför
    ),
    ActiveSessionScreen(
      isActive: _isParkingActive, // Berättar om parkeringen är igång
      startTime: _parkingStartTime, // Skickar med tiden
      onFinished: () {
        setState(() {
          _isParkingActive = false; // Stänger av parkeringen
        });
      },
    ),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1D4ED8),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Active"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// ==========================================
// 3. MAPBOX KARTA MED KLICKBARA INDIKATORER
// ==========================================
class MapScreen extends StatefulWidget {
  final VoidCallback onParkConfirmed;

  const MapScreen({super.key, required this.onParkConfirmed});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapboxMap;
  PolygonAnnotationManager? zoneManager;
  PolygonAnnotationManager? spotManager;

  final Position mapCenter = Position(17.282833, 62.391347);

  String? selectedSpot;
  bool isOccupied = false;
  StreamSubscription? _parkingSub;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _flutterTts.setLanguage("sv-SE");
    _flutterTts.setSpeechRate(0.5);

    final ref = FirebaseDatabase.instance.ref("parking/spot1");
    _parkingSub = ref.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final statusString =
            event.snapshot.child("status").value as String? ?? "free";
        setState(() {
          isOccupied = (statusString == "occupied");
        });
        _updateSpots();
      }
    });
  }

  // --- VOICE RECOGNITION FUNCTION ---
  void _listenForCommands() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);

        // Start listening to the microphone
        _speech.listen(
          localeId: "sv_SE",
          onResult: (val) async {
            String spokenWords = val.recognizedWords.toLowerCase();

            // If the app hears the word "navigate" or "navigera"
            if (spokenWords.contains('navigate') ||
                spokenWords.contains('navigera')) {
              _speech.stop(); // Stäng av mikrofonen
              setState(() => _isListening = false);

              // 1. APPEN PRATAR TILLBAKA! 🔊
              await _flutterTts.speak("Navigerar till Sidsjövägens parkering.");

              // 2. Vi pausar koden i 2 sekunder så att rösten hinner prata klart
              await Future.delayed(const Duration(seconds: 2));

              // 3. Sen öppnar vi Google Maps
              final Uri googleMapsUrl = Uri.parse(
                "https://www.google.com/maps/dir/?api=1&destination=62.391347,17.282833",
              );
              await launchUrl(
                googleMapsUrl,
                mode: LaunchMode.externalApplication,
              );
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _parkingSub?.cancel();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    zoneManager = await mapboxMap.annotations.createPolygonAnnotationManager();
    spotManager = await mapboxMap.annotations.createPolygonAnnotationManager();

    zoneManager?.addOnPolygonAnnotationClickListener(
      PolygonClickListener((PolygonAnnotation annotation) {
        mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: mapCenter),
            zoom: 18.0,
            pitch: 30.0,
          ),
          MapAnimationOptions(duration: 800),
        );
      }),
    );

    spotManager?.addOnPolygonAnnotationClickListener(
      PolygonClickListener((PolygonAnnotation annotation) {
        setState(() {
          selectedSpot = '1';
        });
        _updateSpots();

        mapboxMap.flyTo(
          CameraOptions(
            center: Point(coordinates: mapCenter),
            zoom: 21.5,
            pitch: 50.0,
          ),
          MapAnimationOptions(duration: 800),
        );
      }),
    );

    _drawZone();
    _updateSpots();
  }

  void _drawZone() async {
    if (zoneManager == null) return;

    List<Position> zonePoints = [
      Position(17.283564, 62.391804),
      Position(17.283177, 62.391056),
      Position(17.282899, 62.391017),
      Position(17.281882, 62.391160),
      Position(17.281727, 62.391265),
      Position(17.281737, 62.391364),
      Position(17.281814, 62.391462),
      Position(17.282043, 62.391641),
      Position(17.282539, 62.391693),
      Position(17.282692, 62.391687),
      Position(17.283060, 62.391821),
      Position(17.283217, 62.391845),
      Position(17.283564, 62.391804),
    ];

    PolygonAnnotationOptions options = PolygonAnnotationOptions(
      geometry: Polygon(coordinates: [zonePoints]),
      fillColor: const Color(0xFF6B21A8).value,
      fillOpacity: 0.1,
      fillOutlineColor: const Color(0xFF6B21A8).value,
    );

    await zoneManager!.create(options);
  }

  void _updateSpots() async {
    if (spotManager == null) return;

    await spotManager!.deleteAll();

    List<Position> points = [
      Position(17.282833, 62.391361),
      Position(17.282861, 62.391361),
      Position(17.282833, 62.391333),
      Position(17.282806, 62.391333),
      Position(17.282833, 62.391361),
    ];

    int color = isOccupied ? Colors.red.value : Colors.green.value;
    int strokeColor = selectedSpot == '1' ? Colors.blue.value : color;

    PolygonAnnotationOptions options = PolygonAnnotationOptions(
      geometry: Polygon(coordinates: [points]),
      fillColor: color,
      fillOpacity: 0.6,
      fillOutlineColor: strokeColor,
    );

    await spotManager!.create(options);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            styleUri: MapboxStyles.MAPBOX_STREETS,
            cameraOptions: CameraOptions(
              center: Point(coordinates: mapCenter),
              zoom: 17.0,
            ),
            onMapCreated: _onMapCreated,
            onTapListener: (MapContentGestureContext context) {
              if (selectedSpot != null) {
                setState(() {
                  selectedSpot = null;
                });
                _updateSpots();

                mapboxMap?.flyTo(
                  CameraOptions(
                    center: Point(coordinates: mapCenter),
                    zoom: 14.0,
                    pitch: 0.0,
                  ),
                  MapAnimationOptions(duration: 800),
                );
              }
            },
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 20),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFF1D4ED8)),
                          SizedBox(width: 8),
                          Text(
                            "PARKLY",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.flash_on,
                              color: Color(0xFF1D4ED8),
                              size: 16,
                            ),
                            Text(
                              " LIVE",
                              style: TextStyle(
                                color: Color(0xFF1D4ED8),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          selectedSpot == null
              ? _buildOverviewSheet()
              : _buildSpotCheckoutSheet(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize
            .min, // VIKTIGT: Säger åt kolumnen att vara så liten som möjligt
        children: [
          FloatingActionButton.extended(
            onPressed: _listenForCommands,
            backgroundColor: _isListening
                ? Colors.red
                : const Color(0xFF1D4ED8),
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
            label: Text(
              _isListening ? "Lyssnar... Säg 'Navigera'" : "Röststyrning",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(
            height: 6,
          ), // Ett litet mellanrum mellan knappen och texten
          // Hjälptexten (jag lade till en liten vit bakgrund så den syns bra över kartan!)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85), // Halvgenomskinlig vit
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "💡 Tips: Tryck och säg 'Navigera'",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .centerFloat, // Placerar den snyggt i mitten längst ner
      // ======================================
    );
  }

  Widget _buildOverviewSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.1,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Sidsjövägen Garage",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Sidsjövägen 6, Sundsvall",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoBox(
                      Icons.location_on,
                      isOccupied ? "0/1" : "1/1",
                      "SPOTS",
                      isOccupied ? Colors.red : Colors.green,
                    ),
                    _infoBox(
                      Icons.attach_money,
                      "25 kr",
                      "PER HOUR",
                      const Color(0xFF1D4ED8),
                    ),
                    _infoBox(
                      Icons.schedule,
                      isOccupied ? "Full" : "Open",
                      "STATUS",
                      isOccupied ? Colors.red : Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // === NYA KNAPPRADEN (Navigate + View Spots) ===
                Row(
                  children: [
                    // Knapp 1: Navigera
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Den korrekta, officiella länken till din parkering!
                            final Uri mapUrl = Uri.parse(
                              "https://www.google.com/maps/dir/?api=1&destination=62.391347,17.282833",
                            );

                            // Vi hoppar över "canLaunchUrl" och tvingar den att öppna utanför appen
                            if (!await launchUrl(
                              mapUrl,
                              mode: LaunchMode.externalApplication,
                            )) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Kunde inte öppna Google Maps",
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF1E293B,
                            ), // Snygg mörkgrå färg så den sticker ut från den blåa
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.navigation,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Navigate",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16), // Mellanrum mellan knapparna
                    // Knapp 2: Visa parkeringsplatserna (Din gamla knapp)
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            mapboxMap?.flyTo(
                              CameraOptions(
                                center: Point(coordinates: mapCenter),
                                zoom: 20.0,
                                pitch: 30.0,
                              ),
                              MapAnimationOptions(duration: 800),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "View Spots",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpotCheckoutSheet() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () async {
                    // Riktig Google Maps-länk för vägbeskrivning
                    final Uri googleMapsUrl = Uri.parse(
                      "https://www.google.com/maps/dir/?api=1&destination=62.391347,17.282833",
                    );

                    if (await canLaunchUrl(googleMapsUrl)) {
                      await launchUrl(
                        googleMapsUrl,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      // LÖSNINGEN: Kolla att skärmen fortfarande är öppen innan vi använder 'context'
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Kunde inte öppna Google Maps"),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOccupied ? Colors.red : const Color(0xFF1D4ED8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_car, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Spot $selectedSpot",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Sidsjövägen Ytparkering",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _infoBox(
                    Icons.schedule,
                    isOccupied ? "Occupied" : "Available",
                    isOccupied ? "Not ready" : "Ready to use",
                    isOccupied ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoBox(
                    Icons.attach_money,
                    "25 SEK",
                    "Per hour",
                    const Color(0xFF1D4ED8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isOccupied
                    ? null
                    : () {
                        // 2. Skicka signalen till Huvudmenyn
                        widget.onParkConfirmed();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOccupied
                      ? Colors.grey.shade400
                      : const Color(0xFF1D4ED8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isOccupied ? "Spot Taken" : "Park in Spot $selectedSpot",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
  ) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class PolygonClickListener extends OnPolygonAnnotationClickListener {
  final void Function(PolygonAnnotation annotation) onAnnotationClick;
  PolygonClickListener(this.onAnnotationClick);

  @override
  void onPolygonAnnotationClick(PolygonAnnotation annotation) {
    onAnnotationClick(annotation);
  }
}

// ==========================================
// 4. PLATSVÄLJARE
// ==========================================
class SpotSelectionScreen extends StatelessWidget {
  const SpotSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, color: Colors.green.shade700, size: 16),
                Text(
                  " 24 Available",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Storgatan Parkering",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Storgatan 45, Sundsvall",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const Text(
                      " 25 SEK/hr   ",
                      style: TextStyle(color: Color(0xFF475569)),
                    ),
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const Text(
                      " 24/50 spots",
                      style: TextStyle(color: Color(0xFF475569)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _levelTab("All Levels", true),
                    _levelTab("P2", false),
                    _levelTab("P1", false),
                    _levelTab("P3", false),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 30),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GridView.count(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
                    children: [
                      _spotItem("C05", isEV: true, isOccupied: true),
                      _spotItem("A05", isEV: true, isOccupied: true),
                      _spotItem("C02", isOccupied: true),
                      _spotItem("A04", isAvailable: true),
                      _spotItem("C04", isOccupied: true),
                      _spotItem("B05", isEV: true, isOccupied: true),
                      _spotItem("C03", isOccupied: true),
                      _spotItem("D05", isEV: true, isOccupied: true),
                      _spotItem("B03", isOccupied: true),
                      _spotItem("A01", isHandicap: true, isSelected: true),
                      _spotItem("D01", isOccupied: true),
                      _spotItem("A03", isAvailable: true),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D4ED8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.directions_car,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Spot A05",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Level P1",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.bolt,
                              color: Colors.orange,
                              size: 30,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _spotDetailBox(
                                Icons.schedule,
                                "Available Now",
                                "Ready to use",
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _spotDetailBox(
                                Icons.attach_money,
                                "25 SEK",
                                "Per hour",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D4ED8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Park in Spot A05",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelTab(String title, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1D4ED8) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _spotItem(
    String id, {
    bool isAvailable = false,
    bool isOccupied = false,
    bool isEV = false,
    bool isHandicap = false,
    bool isSelected = false,
  }) {
    Color borderColor = Colors.grey.shade300;
    Color bgColor = Colors.white;
    Widget icon = const SizedBox.shrink();

    if (isOccupied) {
      bgColor = const Color(0xFFF1F5F9);
      borderColor = const Color(0xFFE2E8F0);
    }
    if (isAvailable) {
      borderColor = Colors.green;
      icon = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      );
    }
    if (isEV) icon = Icon(Icons.bolt, color: Colors.orange.shade300, size: 20);
    if (isHandicap)
      icon = const Icon(Icons.accessible, color: Colors.blue, size: 20);
    if (isSelected) {
      borderColor = const Color(0xFF1D4ED8);
      bgColor = Colors.blue.shade50;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isSelected || isAvailable ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isEV || isHandicap) ...[icon, const SizedBox(height: 4)],
          Text(
            id,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOccupied && !isEV ? Colors.grey : Colors.black87,
            ),
          ),
          if (isAvailable) ...[const SizedBox(height: 4), icon],
        ],
      ),
    );
  }

  Widget _spotDetailBox(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1D4ED8)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. AKTIV SESSION
// ==========================================
// ==========================================
// 5. AKTIV SESSION (Nu med riktig timer och knappar!)
// ==========================================
// Lägg denna högst upp för kartan

class ActiveSessionScreen extends StatefulWidget {
  final bool isActive;
  final DateTime? startTime;
  final VoidCallback onFinished;

  const ActiveSessionScreen({
    super.key,
    required this.isActive,
    this.startTime,
    required this.onFinished,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  // Timer-variabler
  Timer? _timer;
  int _totalSeconds =
      3600; // Total tid från början (t.ex. 1 timme = 3600 sekunder)
  int _remainingSeconds =
      3501; // Tiden som är kvar (börjar på 58:21 för att matcha din design)

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    // Viktigt: Stäng av timern när man lämnar skärmen så appen inte kraschar!
    _timer?.cancel();
    super.dispose();
  }

  // Räknar ner en sekund i taget
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        // Här kan du lägga till en funktion som skickar en notis om att tiden är ute!
      }
    });
  }

  // Konverterar sekunder (t.ex. 3501) till en snygg text ("58:21")
  String get _formattedTime {
    int h = _remainingSeconds ~/ 3600;
    int m = (_remainingSeconds % 3600) ~/ 60;
    int s = _remainingSeconds % 60;

    if (h > 0) {
      return '${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // Räknar ut hur mycket den gröna cirkeln ska fyllas (0.0 till 1.0)
  double get _progressValue {
    return _remainingSeconds / _totalSeconds;
  }

  // Funktion för att hitta bilen med Google Maps/Apple Maps
  Future<void> _findMyCar() async {
    // Koordinaterna till din parkering på Sidsjövägen
    final Uri googleMapsUrl = Uri.parse(
      "http://maps.google.com/maps?daddr=62.391347,17.282833",
    );
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kunde inte öppna kartan.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_parking, size: 80, color: Colors.grey.shade300),
              const Text(
                "Ingen aktiv parkering",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Gjorde tillbakaknappen funktionell!
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF0D9488),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "PARKLY",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Cirkulär Timer
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value:
                          _progressValue, // DYNAMISK VÄRDE! Uppdateras varje sekund
                      strokeWidth: 15,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        // Blir röd om det är mindre än 5 minuter kvar!
                        _remainingSeconds < 300 ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formattedTime, // DYNAMISK TID!
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        "TIME LEFT",
                        style: TextStyle(
                          color: Colors.grey,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Platsinformation
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF1D4ED8),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Location:",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const Text(
                          "SIDSJÖVÄGEN GARAGE",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // Räkna ut vilken tid parkeringen slutar automatiskt baserat på klockan just nu!
                          "Paid until: ${TimeOfDay.fromDateTime(DateTime.now().add(Duration(seconds: _remainingSeconds))).format(context)}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.near_me_outlined, color: Color(0xFF1D4ED8)),
                ],
              ),
            ),
            const Spacer(),

            // Förläng session-knapp
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _remainingSeconds +=
                        900; // Lägger till 15 minuter (900 sekunder)
                    _totalSeconds +=
                        900; // Utökar max-värdet så cirkeln blir rätt
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Parkeringen förlängd med 15 minuter!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ADE80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "EXTEND SESSION",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hitta bilen-knapp
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _findMyCar, // Startar navigeringen!
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "FIND MY CAR",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. PROFILSKÄRMEN (Nu funktionell med Firebase)
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // FUNKTION: Logga ut användaren från Firebase
  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Navigera tillbaka till inloggningsskärmen och rensa historiken
    // så att man inte kan klicka "bakåt" in i appen igen.
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hämta den inloggade användaren från Firebase
    final user = FirebaseAuth.instance.currentUser;
    final String userEmail = user?.email ?? "okänd@användare.se";

    // Skapa ett snyggt visningsnamn baserat på e-posten (t.ex. "test" från "test@test.com")
    String displayName = "Användare";
    if (user != null && user.email != null) {
      displayName = user.email!.split('@')[0];
      // Gör första bokstaven stor för att det ska se snyggare ut
      if (displayName.isNotEmpty) {
        displayName = displayName[0].toUpperCase() + displayName.substring(1);
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF0D9488),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "PARKLY",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Color(0xFFF1F5F9), thickness: 2),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DYNAMISK PROFIL-INFO
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Color(
                          0xFFFFC107,
                        ), // Parkly gul från din bild
                        child: Icon(Icons.face, size: 40, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName, // Visar nu ditt riktiga namn/mail-prefix!
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            userEmail, // Visar din riktiga inloggade e-post!
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: Color(0xFF1D4ED8),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Account Details",
                        style: TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // My Vehicles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "My Vehicles",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.directions_car_outlined,
                        color: Colors.blue.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _vehicleCard("Toyota", "Camry"),
                      const SizedBox(width: 16),
                      _vehicleCard("Honda", "CRV"),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Payment Methods
                  const Text(
                    "Payment Methods",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _paymentCard(),
                  const SizedBox(height: 12),
                  _paymentCard(),

                  const SizedBox(height: 32),
                  // Find Parking (Knapp)
                  // Find Parking (Knapp) - NU KLICKBAR!
                  GestureDetector(
                    onTap: () {
                      // Återställ navigeringen och hoppa tillbaka till huvudmenyn (Kartan)
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainNavigation(),
                        ),
                        (route) => false,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D4ED8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Find Parking",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "View available spots nearby",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Active Parking (Menyval)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Active Parking",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // LOGGA UT KNAPPEN (Nu klickbar!)
                  GestureDetector(
                    onTap: () =>
                        _signOut(context), // Kallar på Firebase utloggning!
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red.shade600),
                        const SizedBox(width: 12),
                        Text(
                          "Log Out",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hjälp-widgets för att hålla koden ren
  Widget _vehicleCard(String make, String model) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.directions_car_outlined, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            Text(make, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              model,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              Transform.translate(
                offset: const Offset(-10, 0),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const Icon(Icons.credit_card, color: Colors.white),
        ],
      ),
    );
  }
}
