import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DemlemeAnalizEkrani extends StatefulWidget {
  const DemlemeAnalizEkrani({super.key});

  @override
  State<DemlemeAnalizEkrani> createState() => _DemlemeAnalizEkraniState();
}

class _DemlemeAnalizEkraniState extends State<DemlemeAnalizEkrani> {
  // Son 7 günün tarih listesi (bugün dahil, en yeni üstte)
  List<DateTime> get _sonYediGun {
    return List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
  }

  String _tarihStr(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _gunEtiketi(DateTime d) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (_tarihStr(d) == _tarihStr(today)) return 'Bugün';
    if (_tarihStr(d) == _tarihStr(yesterday)) return 'Dün';
    return DateFormat('EEE, d MMM').format(d);
  }

  // YENİ METOD: Belirli bir tarihteki tüm demlemeleri getirir (çay + kahve)
  Future<List<Map<String, dynamic>>> _gunlukDemlemeleriGetir(
    String tarihStr,
  ) async {
    // Çay demlemeleri
    var caySnap = await FirebaseFirestore.instance
        .collection('cay_demlemeleri')
        .where('tarih', isEqualTo: tarihStr)
        .get();

    // Kahve demlemeleri
    var kahveSnap = await FirebaseFirestore.instance
        .collection('kahve_demlemeleri')
        .where('tarih', isEqualTo: tarihStr)
        .get();

    List<Map<String, dynamic>> tumDemlemeler = [];

    for (var doc in caySnap.docs) {
      tumDemlemeler.add({
        'tip': 'çay',
        'zaman': (doc['demlemeZamani'] as Timestamp).toDate(),
      });
    }

    for (var doc in kahveSnap.docs) {
      tumDemlemeler.add({
        'tip': 'kahve',
        'zaman': (doc['demlemeZamani'] as Timestamp).toDate(),
      });
    }

    // Saate göre sırala (yeniden eskiye)
    tumDemlemeler.sort((a, b) => b['zaman'].compareTo(a['zaman']));
    return tumDemlemeler;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Demleme Analizi — 7 Gün'),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sonYediGun.length,
        itemBuilder: (context, index) {
          DateTime gun = _sonYediGun[index];
          String tarihStr = _tarihStr(gun);
          bool bugun = index == 0;

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _gunlukDemlemeleriGetir(tarihStr),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                // Yükleniyor
                return Card(
                  elevation: bugun ? 4 : 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: bugun
                        ? const BorderSide(color: Colors.blueGrey, width: 2)
                        : BorderSide.none,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        height: 24,
                        child: LinearProgressIndicator(),
                      ),
                    ),
                  ),
                );
              }

              final demlemeler = snapshot.data!;
              int cayAdet = demlemeler.where((d) => d['tip'] == 'çay').length;
              int kahveAdet = demlemeler
                  .where((d) => d['tip'] == 'kahve')
                  .length;

              return Card(
                elevation: bugun ? 4 : 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: bugun
                      ? const BorderSide(color: Colors.blueGrey, width: 2)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gün başlığı
                      Row(
                        children: [
                          Icon(
                            bugun ? Icons.today : Icons.calendar_today_outlined,
                            size: 18,
                            color: bugun
                                ? Colors.blueGrey[800]
                                : Colors.grey[500],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _gunEtiketi(gun),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: bugun
                                  ? Colors.blueGrey[800]
                                  : Colors.grey[700],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('dd/MM/yyyy').format(gun),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Çay ve Kahve sayaçları
                      Row(
                        children: [
                          Expanded(
                            child: _sayacKutusu(
                              ikon: Icons.local_drink,
                              renk: Colors.deepOrange,
                              baslik: 'Çay',
                              adet: cayAdet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _sayacKutusu(
                              ikon: Icons.coffee_maker,
                              renk: Colors.brown,
                              baslik: 'Filtre Kahve',
                              adet: kahveAdet,
                            ),
                          ),
                        ],
                      ),

                      // Toplam ve saatler (eğer demleme varsa)
                      if (demlemeler.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Divider(height: 1, color: Colors.grey[200]),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Demleme Saatleri:',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Saat etiketleri
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: demlemeler.map((dem) {
                            final tip = dem['tip'] as String;
                            final zaman = dem['zaman'] as DateTime;
                            final saatStr = DateFormat('HH:mm').format(zaman);
                            final isCay = tip == 'çay';
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isCay
                                    ? Colors.deepOrange.withOpacity(0.1)
                                    : Colors.brown.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isCay
                                      ? Colors.deepOrange.withOpacity(0.3)
                                      : Colors.brown.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isCay
                                        ? Icons.local_drink
                                        : Icons.coffee_maker,
                                    size: 12,
                                    color: isCay
                                        ? Colors.deepOrange
                                        : Colors.brown,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    saatStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isCay
                                          ? Colors.deepOrange[800]
                                          : Colors.brown[800],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Bu gün için kayıt bulunamadı',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Sayaç kutusu widget'ı (aynı)
  Widget _sayacKutusu({
    required IconData ikon,
    required Color renk,
    required String baslik,
    required int adet,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(ikon, color: renk, size: 26),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                baslik,
                style: TextStyle(
                  color: renk.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$adet demleme',
                style: TextStyle(
                  color: renk,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
