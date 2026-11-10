import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DemlemeAnalizEkrani extends StatefulWidget {
  const DemlemeAnalizEkrani({super.key});

  @override
  State<DemlemeAnalizEkrani> createState() => _DemlemeAnalizEkraniState();
}

class _DemlemeAnalizEkraniState extends State<DemlemeAnalizEkrani> {
  late final List<DateTime> _sonYediGun;
  late Future<Map<String, List<Map<String, dynamic>>>> _demlemelerFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _sonYediGun = List.generate(7, (i) {
      final d = now.subtract(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
    _demlemelerFuture = _tumDemlemeleriGetir();
  }

  String _tarihStr(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _gunEtiketi(DateTime d) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (_tarihStr(d) == _tarihStr(today)) return 'Bugün';
    if (_tarihStr(d) == _tarihStr(yesterday)) return 'Dün';
    return DateFormat('EEE, d MMM').format(d);
  }

  // 14 ayrı sorgu yerine 7 günlük veriyi TEK SEFERDE çekip tarihe göre gruplar
  Future<Map<String, List<Map<String, dynamic>>>> _tumDemlemeleriGetir() async {
    final enEskiGun = _sonYediGun.last;
    final baslangicStr = _tarihStr(enEskiGun);

    // Çay demlemeleri (Son 7 gün)
    final caySnap = await FirebaseFirestore.instance
        .collection('cay_demlemeleri')
        .where('tarih', isGreaterThanOrEqualTo: baslangicStr)
        .get();

    // Kahve demlemeleri (Son 7 gün)
    final kahveSnap = await FirebaseFirestore.instance
        .collection('kahve_demlemeleri')
        .where('tarih', isGreaterThanOrEqualTo: baslangicStr)
        .get();

    final Map<String, List<Map<String, dynamic>>> gunlukGruplar = {};
    for (var gun in _sonYediGun) {
      gunlukGruplar[_tarihStr(gun)] = [];
    }

    for (var doc in caySnap.docs) {
      final data = doc.data();
      final tarih = data['tarih'] as String? ?? '';
      if (gunlukGruplar.containsKey(tarih)) {
        gunlukGruplar[tarih]!.add({
          'tip': 'çay',
          'zaman': (data['demlemeZamani'] as Timestamp).toDate(),
        });
      }
    }

    for (var doc in kahveSnap.docs) {
      final data = doc.data();
      final tarih = data['tarih'] as String? ?? '';
      if (gunlukGruplar.containsKey(tarih)) {
        gunlukGruplar[tarih]!.add({
          'tip': 'kahve',
          'zaman': (data['demlemeZamani'] as Timestamp).toDate(),
        });
      }
    }

    // Her günün demlemelerini saate göre sırala (yeniden eskiye)
    gunlukGruplar.forEach((_, list) {
      list.sort((a, b) => (b['zaman'] as DateTime).compareTo(a['zaman'] as DateTime));
    });

    return gunlukGruplar;
  }

  Future<void> _yenile() async {
    setState(() {
      _demlemelerFuture = _tumDemlemeleriGetir();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Demleme Analizi — Son 7 Gün'),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _yenile,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _demlemelerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Veriler yüklenirken hata oluştu: ${snapshot.error}'),
            );
          }

          final tumGruplar = snapshot.data ?? {};

          return RefreshIndicator(
            onRefresh: _yenile,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sonYediGun.length,
              itemBuilder: (context, index) {
                final gun = _sonYediGun[index];
                final tarihStr = _tarihStr(gun);
                final bool bugun = index == 0;
                final demlemeler = tumGruplar[tarihStr] ?? [];

                final int cayAdet = demlemeler.where((d) => d['tip'] == 'çay').length;
                final int kahveAdet = demlemeler.where((d) => d['tip'] == 'kahve').length;

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
                              color: bugun ? Colors.blueGrey[800] : Colors.grey[500],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _gunEtiketi(gun),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: bugun ? Colors.blueGrey[800] : Colors.grey[700],
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
                                'Demleme Saatleri (${demlemeler.length} Toplam):',
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
                                      isCay ? Icons.local_drink : Icons.coffee_maker,
                                      size: 12,
                                      color: isCay ? Colors.deepOrange : Colors.brown,
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
            ),
          );
        },
      ),
    );
  }

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
