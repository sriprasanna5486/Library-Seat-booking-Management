import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ignore use_key_in_widget_constructors
class GenerateQRScreen extends StatelessWidget {
  final seats = FirebaseFirestore.instance.collection('seats');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seat QR Codes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: seats.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final seat = docs[i];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(
                    data: seat.id, //  Seat ID encoded in QR
                    size: 100,
                  ),
                  Text(
                    seat.id,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
