import 'package:cloud_firestore/cloud_firestore.dart';

class FridgeTempEntry {
  final String id;
  final String dolap; // 'Dolap 1' veya 'Dolap 2'
  final double sicaklik;
  final DateTime kayitZamani;
  final String tarih; // 'yyyy-MM-dd'
  final DateTime silinmeZamani;

  const FridgeTempEntry({
    required this.id,
    required this.dolap,
    required this.sicaklik,
    required this.kayitZamani,
    required this.tarih,
    required this.silinmeZamani,
  });

  factory FridgeTempEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return FridgeTempEntry(
      id: doc.id,
      dolap: data['dolap'] as String? ?? 'Dolap 1',
      sicaklik: (data['sicaklik'] as num?)?.toDouble() ?? 0.0,
      kayitZamani: parseDate(data['kayitZamani']),
      tarih: data['tarih'] as String? ?? '',
      silinmeZamani: parseDate(data['silinmeZamani']),
    );
  }

  // Gıda güvenliği kontrolü (HACCP): 0°C ile 8°C arası güvenli
  bool get isUyariGerektiriyor => sicaklik < 0 || sicaklik > 8.0;

  Map<String, dynamic> toMap() {
    return {
      'dolap': dolap,
      'sicaklik': sicaklik,
      'kayitZamani': Timestamp.fromDate(kayitZamani),
      'tarih': tarih,
      'silinmeZamani': Timestamp.fromDate(silinmeZamani),
    };
  }
}

