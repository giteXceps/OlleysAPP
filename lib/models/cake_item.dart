import 'package:cloud_firestore/cloud_firestore.dart';

class CakeItem {
  final String id;
  final String isim;
  final int adet;
  final int ilkAdet;
  final int satilanAdet;
  final int imhaEdilenAdet;
  final DateTime eklenmeZamani;
  final DateTime sktZamani;
  final DateTime silinmeZamani;
  final String durum;

  const CakeItem({
    required this.id,
    required this.isim,
    required this.adet,
    required this.ilkAdet,
    required this.satilanAdet,
    required this.imhaEdilenAdet,
    required this.eklenmeZamani,
    required this.sktZamani,
    required this.silinmeZamani,
    required this.durum,
  });

  factory CakeItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return CakeItem(
      id: doc.id,
      isim: data['isim'] as String? ?? 'Bilinmeyen Ürün',
      adet: (data['adet'] as num?)?.toInt() ?? 0,
      ilkAdet: (data['ilkAdet'] as num?)?.toInt() ?? 0,
      satilanAdet: (data['satilanAdet'] as num?)?.toInt() ?? 0,
      imhaEdilenAdet: (data['imhaEdilenAdet'] as num?)?.toInt() ?? 0,
      eklenmeZamani: parseTimestamp(data['eklenmeZamani']),
      sktZamani: parseTimestamp(data['sktZamani']),
      silinmeZamani: parseTimestamp(data['silinmeZamani']),
      durum: data['durum'] as String? ?? 'Rafta',
    );
  }

  // Tam gün farkı hesabı (Saatleri göz ardı ederek)
  int get sktKalanGun {
    final sktGun = DateTime(sktZamani.year, sktZamani.month, sktZamani.day);
    final bugun = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return sktGun.difference(bugun).inDays;
  }

  bool get isSktGecti => sktKalanGun < 0;
  bool get isSonGun => sktKalanGun == 0;
  bool get isYarinSon => sktKalanGun == 1;

  Map<String, dynamic> toMap() {
    return {
      'isim': isim,
      'adet': adet,
      'ilkAdet': ilkAdet,
      'satilanAdet': satilanAdet,
      'imhaEdilenAdet': imhaEdilenAdet,
      'eklenmeZamani': Timestamp.fromDate(eklenmeZamani),
      'sktZamani': Timestamp.fromDate(sktZamani),
      'silinmeZamani': Timestamp.fromDate(silinmeZamani),
      'durum': durum,
    };
  }
}

