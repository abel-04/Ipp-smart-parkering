import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Smart Parkering ",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

//////////////////// AUTH PAGE ////////////////////

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const ParkingPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

//////////////////// LOGIN PAGE ////////////////////

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future signIn() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
  }

  Future register() async {
    print("TRY REGISTER");

    // 1. Check if the fields are empty before talking to Firebase!
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      print("ERROR: Fälten får inte vara tomma!"); // The fields cannot be empty
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      print("SUCCESS ");
    } on FirebaseAuthException catch (e) {
      print("CODE: ${e.code}");
      print("MESSAGE: ${e.message}");
    } catch (e) {
      print("OTHER ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Logga in ")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Lösenord"),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            ElevatedButton(onPressed: signIn, child: const Text("Logga in")),

            ElevatedButton(
              onPressed: register,
              child: const Text("Skapa konto"),
            ),
          ],
        ),
      ),
    );
  }
}

//////////////////// PARKING PAGE ////////////////////

class ParkingPage extends StatelessWidget {
  const ParkingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref("parking/spot1");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parkering "),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: StreamBuilder(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final statusString =
              snapshot.data!.snapshot.child("status").value as String? ??
              "free";
          final isOccupied = (statusString == "occupied");

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOccupied ? Icons.block : Icons.local_parking,
                  size: 120,
                  color: isOccupied ? Colors.red : Colors.green,
                ),
                const SizedBox(height: 20),

                Text(
                  isOccupied ? "Upptagen " : "Ledig ",
                  style: const TextStyle(fontSize: 32),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
