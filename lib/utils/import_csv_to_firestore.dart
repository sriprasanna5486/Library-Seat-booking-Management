import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

class CSVSeatImporter {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> importSeatsFromCSV(String csvPath) async {
    final data = await rootBundle.loadString(csvPath);
    final lines = const LineSplitter().convert(data);

    print("📥 Found ${lines.length - 1} seat entries in CSV.");

    for (int i = 1; i < lines.length; i++) {
      final fields = lines[i].split(',');
      if (fields.length < 6) continue;

      final seatId = fields[0].trim();
      final floor = fields[1].trim();
      final zone = fields[2].trim();
      final x = double.tryParse(fields[3].trim()) ?? 0.0;
      final y = double.tryParse(fields[4].trim()) ?? 0.0;
      final status = fields[5].trim();

      await _firestore.collection('seats').doc(seatId).set({
        'seatId': seatId,
        'floor': floor,
        'zone': zone,
        'x': x,
        'y': y,
        'status': status,
        'reservedBy': null,
      });

      print(' Imported $seatId');
    }

    print(" CSV import complete for $csvPath");
  }
}
