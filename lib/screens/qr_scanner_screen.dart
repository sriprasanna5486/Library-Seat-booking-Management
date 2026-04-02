import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;

  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Seat QR Code'),
        backgroundColor: Colors.indigo,
      ),
      body: Stack(
        children: [
          QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
          if (isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) async {
      if (isProcessing) return;
      setState(() => isProcessing = true);

      final seatId = scanData.code?.trim();
      if (seatId == null || seatId.isEmpty) {
        _showMessage('Invalid QR code.');
        setState(() => isProcessing = false);
        return;
      }

      await _validateSeatScan(seatId);
    });
  }

  Future<void> _validateSeatScan(String seatId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showMessage('Please login first.');
        return;
      }

      final seatDoc = await FirebaseFirestore.instance
          .collection('seats')
          .doc(seatId)
          .get();

      if (!seatDoc.exists) {
        _showMessage('Seat not found in database.');
        return;
      }

      final data = seatDoc.data()!;
      final reservedBy = data['reservedBy'];
      final status = data['status'];

      if (reservedBy == null || status == 'available') {
        _showMessage('⚠️ This seat is not booked by anyone.');
      } else if (reservedBy != currentUser.uid) {
        _showMessage('❌ You are not authorized for this seat.');
      } else if (status == 'occupied') {
        _showMessage('✅ Seat already marked as occupied.');
      } else {
        // Update Firestore: Mark as occupied
        await FirebaseFirestore.instance.collection('seats').doc(seatId).update(
          {'status': 'occupied'},
        );

        _showMessage('✅ You are now checked in! Seat marked as occupied.');
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
