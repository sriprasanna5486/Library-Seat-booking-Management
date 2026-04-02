import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeatLayoutScreen extends StatefulWidget {
  final String selectedFloor;
  final DateTime selectedDate;
  final String selectedTime;

  const SeatLayoutScreen({
    super.key,
    required this.selectedFloor,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  State<SeatLayoutScreen> createState() => _SeatLayoutScreenState();
}

class _SeatLayoutScreenState extends State<SeatLayoutScreen> {
  static final seatsCollection = FirebaseFirestore.instance.collection('seats');
  final TransformationController _controller = TransformationController();

  @override
  void initState() {
    super.initState();
    _autoReleaseOldReservations(); //  Auto cleanup when screen opens
  }

  //  Automatically release expired "reserved" seats (after 15 minutes)
  Future<void> _autoReleaseOldReservations() async {
    try {
      final now = DateTime.now();
      final snapshot = await seatsCollection
          .where('status', isEqualTo: 'reserved')
          .get();

      for (var doc in snapshot.docs) {
        // ignore: unnecessary_cast
        final data = doc.data() as Map<String, dynamic>;
        if (data['reservedAt'] == null) continue;

        final reservedAt = (data['reservedAt'] as Timestamp).toDate();
        final difference = now.difference(reservedAt).inMinutes;

        if (difference >= 15) {
          await seatsCollection.doc(doc.id).update({
            'status': 'available',
            'reservedBy': null,
            'reservedAt': null,
          });
          debugPrint(" Auto-released seat ${doc.id} after 15 minutes");
        }
      }
    } catch (e) {
      debugPrint("Error during auto release: $e");
    }
  }

  // 🔹 Helper: Show dark styled SnackBar
  void _showDarkSnackBar(
    BuildContext context,
    String message, {
    IconData? icon,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Map each floor to image
  String _getFloorImage(String floor) {
    switch (floor) {
      case 'Ground Floor':
        return 'assets/images/ground_floor.jpg';
      case 'First Floor':
        return 'assets/images/first_floor.jpg';
      case 'Second Floor':
        return 'assets/images/second_floor.jpg';
      case 'Third Floor':
        return 'assets/images/third_floor.jpg';
      default:
        return 'assets/images/first_floor.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String floorImage = _getFloorImage(widget.selectedFloor);

    return Scaffold(
      appBar: AppBar(
        title: Text('Library Seat Layout - ${widget.selectedFloor}'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset View',
            onPressed: () {
              _controller.value = Matrix4.identity();
              _autoReleaseOldReservations(); // recheck expired reservations
              _showDarkSnackBar(context, "View refreshed 🔄");
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: seatsCollection
            .where('floor', isEqualTo: widget.selectedFloor)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No seat data found for ${widget.selectedFloor}.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final seats = snapshot.data!.docs;

          return Container(
            color: Colors.grey[200],
            child: InteractiveViewer(
              transformationController: _controller,
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.6,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(300),
              constrained: false,
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 1.2,
                  height: MediaQuery.of(context).size.height * 1.2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: Image.asset(floorImage, fit: BoxFit.fill),
                      ),
                      for (var seat in seats) _buildSeatMarker(context, seat),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(Colors.green, 'Available'),
            const SizedBox(width: 10),
            _legendItem(Colors.red, 'Reserved'),
            const SizedBox(width: 10),
            _legendItem(Colors.yellow, 'Occupied'),
          ],
        ),
      ),
    );
  }

  // 🔹 Seat Marker
  Widget _buildSeatMarker(BuildContext context, QueryDocumentSnapshot seatDoc) {
    final data = seatDoc.data() as Map<String, dynamic>;
    final double x = (data['x'] ?? 0).toDouble();
    final double y = (data['y'] ?? 0).toDouble();
    final String seatId = data['seatId'] ?? seatDoc.id;
    final String status = data['status'] ?? 'available';

    Color seatColor;
    switch (status) {
      case 'reserved':
        seatColor = Colors.red;
        break;
      case 'occupied':
        seatColor = Colors.yellow;
        break;
      default:
        seatColor = Colors.green;
    }

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () async {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            _showDarkSnackBar(
              context,
              'Please login first!',
              icon: Icons.warning_amber_rounded,
            );
            return;
          }

          try {
            // 🔍 Check if user already has an active seat
            final existingBooking = await seatsCollection
                .where('reservedBy', isEqualTo: currentUser.uid)
                .where('status', whereIn: ['reserved', 'occupied'])
                .get();

            if (existingBooking.docs.isNotEmpty) {
              final bookedSeatId = existingBooking.docs.first.id;
              _showDarkSnackBar(
                context,
                '⚠️ You already booked seat $bookedSeatId. Release it first.',
                icon: Icons.error_outline,
              );
              return;
            }

            // 🪑 Reserve seat if available
            if (status == 'available') {
              await seatsCollection.doc(seatDoc.id).update({
                'status': 'reserved',
                'reservedBy': currentUser.uid,
                'reservedAt': FieldValue.serverTimestamp(),
              });

              _showDarkSnackBar(
                context,
                '✅ Seat $seatId reserved successfully!',
                icon: Icons.check_circle_outline,
              );
            } else {
              _showDarkSnackBar(
                context,
                'Seat $seatId not available',
                icon: Icons.error_outline,
              );
            }
          } catch (e) {
            _showDarkSnackBar(
              context,
              'Error while booking seat: $e',
              icon: Icons.error_outline,
            );
          }
        },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Seat Info'),
              content: Text(
                'Seat ID: $seatId\nStatus: $status\nFloor: ${widget.selectedFloor}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: seatColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 3,
                offset: Offset(1, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              seatId.replaceAll(RegExp(r'[^0-9]'), ''),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🧭 Legend Item
  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black26),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
