import 'package:cloud_firestore/cloud_firestore.dart';

class BrewEntry {
  final String id;
  final String tip; // 'cay' veya 'kahve'
  final DateTime demlemeZamani;
  final String tarih; // 'yyyy-MM-dd'
  final DateTime silinmeZamani;

  const BrewEntry({
    required this.id,
    required this.tip,
    required this.demlemeZamani,
    required this.tarih,
    required this.silinmeZamani,
  });

  factory BrewEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return BrewEntry(
      id: doc.id,
      tip: data['tip'] as String? ?? 'kahve',
      demlemeZamani: parseDate(data['demlemeZamani']),
      tarih: data['tarih'] as String? ?? '',
      silinmeZamani: parseDate(data['silinmeZamani']),
    );
  }

  int get gecenDakika {
    final diff = DateTime.now().difference(demlemeZamani).inMinutes;
    return diff < 0 ? 0 : diff;
  }
}

