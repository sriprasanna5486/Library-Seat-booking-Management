import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:library_seat_booking/firebase_options.dart';
//import 'utils/import_csv_to_firestore.dart'; // import your helper file

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /* Run CSV Import Once
  # This is for creating the seats in the backend automatically 
    final importer = CSVSeatImporter();

    Specify the file path you want to upload
    await importer.importSeatsFromCSV('assets/files/third_floor_seats.csv');

    print(" CSV Import completed! Now comment this line after import.");*/

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library Seat Management',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user != null) return HomeScreen(); // logged in
          return LoginScreen(); // not logged in
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
