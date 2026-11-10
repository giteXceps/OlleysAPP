import 'package:cloud_firestore/cloud_firestore.dart';

class DisposalLog {
  final String id;
  final String kullanici;
  final String urun;
  final int adet;
  final DateTime tarih;

  const DisposalLog({
    required this.id,
    required this.kullanici,
    required this.urun,
    required this.adet,
    required this.tarih,
  });

  factory DisposalLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return DisposalLog(
      id: doc.id,
      kullanici: data['kullanici'] as String? ?? 'Bilinmeyen Kullanıcı',
      urun: data['urun'] as String? ?? 'Bilinmeyen Ürün',
      adet: (data['adet'] as num?)?.toInt() ?? 0,
      tarih: parseDate(data['tarih']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kullanici': kullanici,
      'urun': urun,
      'adet': adet,
      'tarih': Timestamp.fromDate(tarih),
    };
  }
}

