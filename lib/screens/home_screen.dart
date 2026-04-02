import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_seat_booking/screens/generate_qr_screen.dart';
import 'package:library_seat_booking/screens/qr_scanner_screen.dart';
import 'package:library_seat_booking/screens/seat_requirement_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _auth = AuthService();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.email == "admin@vitcc.ac.in"; //  role check

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Seat Management'),
        backgroundColor: const Color.fromARGB(255, 174, 129, 112),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _auth.signOut();
            },
          ),
        ],
      ),

      //  Add background image & overlay
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/images.jpeg', // make sure this file exists
              fit: BoxFit.fill,
            ),
          ),

          // Semi-transparent overlay for readability
          Container(color: Colors.black.withOpacity(0.25)),

          //  Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Card(
                color: Colors.white.withOpacity(0),
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Hello, ${user?.email ?? 'user'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Welcome to the Library Seat Management System !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 35),

                      //  Find & Reserve a Seat
                      ElevatedButton.icon(
                        icon: const Icon(Icons.event_seat_outlined),
                        label: const Text('Find & Reserve a Seat'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          //backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SeatRequirementScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      //  Admin: Generate QR Codes
                      if (isAdmin) ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.qr_code_2_outlined),
                          label: const Text('Generate Seat QR Codes'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            //backgroundColor: Colors.blueGrey.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GenerateQRScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      //  Student: Scan QR Code (verify seat)
                      if (!isAdmin) ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner_outlined),
                          label: const Text('Scan Seat QR Code'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            //backgroundColor: Colors.teal.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QRScannerScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      //  Check-Out (Release Seat)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Check-Out (Release Seat)'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color.fromARGB(
                            255,
                            255,
                            123,
                            123,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          await _checkOutSeat(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  Handles releasing the seat (check-out)
  Future<void> _checkOutSeat(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final seats = FirebaseFirestore.instance.collection('seats');

    try {
      final query = await seats
          .where('reservedBy', isEqualTo: user!.uid)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have no active seat to release.')),
        );
        return;
      }

      final seatDoc = query.docs.first;
      final seatId = seatDoc.id;

      await seats.doc(seatId).update({
        'status': 'available',
        'reservedBy': null,
        'reservedAt': null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' Seat $seatId has been released.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error while checking out: $e')));
    }
  }
}
