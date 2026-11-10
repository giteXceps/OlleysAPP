import 'package:cloud_firestore/cloud_firestore.dart';

class SaleLog {
  final String id;
  final String kullanici;
  final int toplamAdet;
  final Map<String, int> detaylar;
  final DateTime tarih;

  const SaleLog({
    required this.id,
    required this.kullanici,
    required this.toplamAdet,
    required this.detaylar,
    required this.tarih,
  });

  factory SaleLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    final rawDetaylar = data['detaylar'] as Map<String, dynamic>? ?? {};
    final Map<String, int> parsedDetaylar = {};
    rawDetaylar.forEach((k, v) {
      parsedDetaylar[k] = (v as num?)?.toInt() ?? 0;
    });

    return SaleLog(
      id: doc.id,
      kullanici: data['kullanici'] as String? ?? 'Bilinmeyen Kullanıcı',
      toplamAdet: (data['toplamAdet'] as num?)?.toInt() ?? 0,
      detaylar: parsedDetaylar,
      tarih: parseDate(data['tarih']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kullanici': kullanici,
      'toplamAdet': toplamAdet,
      'detaylar': detaylar,
      'tarih': Timestamp.fromDate(tarih),
    };
  }
}

