import 'package:cloud_firestore/cloud_firestore.dart';

class CatalogProduct {
  final String id;
  final String isim;
  final int rafOmruGun;
  final DateTime? olusturmaZamani;

  const CatalogProduct({
    required this.id,
    required this.isim,
    required this.rafOmruGun,
    this.olusturmaZamani,
  });

  factory CatalogProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    return CatalogProduct(
      id: doc.id,
      isim: data['isim'] as String? ?? '',
      rafOmruGun: (data['rafOmruGun'] as num?)?.toInt() ?? 1,
      olusturmaZamani: parseDate(data['olusturmaZamani']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isim': isim,
      'rafOmruGun': rafOmruGun,
      'olusturmaZamani': olusturmaZamani != null
          ? Timestamp.fromDate(olusturmaZamani!)
          : FieldValue.serverTimestamp(),
    };
  }
}

