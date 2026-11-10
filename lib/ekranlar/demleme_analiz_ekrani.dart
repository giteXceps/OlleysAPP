import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../tema/app_theme.dart';

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
    return DateFormat('EEE, d MMMM', 'tr_TR').format(d);
  }

  Future<Map<String, List<Map<String, dynamic>>>> _tumDemlemeleriGetir() async {
    final enEskiGun = _sonYediGun.last;
    final baslangicStr = _tarihStr(enEskiGun);

    final caySnap = await FirebaseFirestore.instance
        .collection('cay_demlemeleri')
        .where('tarih', isGreaterThanOrEqualTo: baslangicStr)
        .get();

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Demleme Analizi (Son 7 Gün)'),
        backgroundColor: AppTheme.teaPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _sonYediGun.length,
                  itemBuilder: (context, index) {
                    final gun = _sonYediGun[index];
                    final tarihStr = _tarihStr(gun);
                    final bool bugun = index == 0;
                    final demlemeler = tumGruplar[tarihStr] ?? [];

                    final int cayAdet = demlemeler.where((d) => d['tip'] == 'çay').length;
                    final int kahveAdet =
                        demlemeler.where((d) => d['tip'] == 'kahve').length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: bugun ? AppTheme.teaPrimary : AppTheme.borderColor,
                          width: bugun ? 2 : 1,
                        ),
                        boxShadow: bugun ? AppTheme.hoverShadow : AppTheme.softShadow,
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gün Başlığı
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: bugun ? AppTheme.teaBg : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  bugun ? Icons.today_rounded : Icons.calendar_today_rounded,
                                  size: 16,
                                  color: bugun ? AppTheme.teaPrimary : AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _gunEtiketi(gun),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: bugun ? AppTheme.teaPrimary : AppTheme.textDark,
                                ),
                              ),
                              if (bugun) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.teaBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.teaPrimary.withOpacity(0.3)),
                                  ),
                                  child: const Text(
                                    'Aktif Gün',
                                    style: TextStyle(
                                      color: AppTheme.teaPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Text(
                                DateFormat('dd/MM/yyyy').format(gun),
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Çay ve Kahve Sayaçları
                          Row(
                            children: [
                              Expanded(
                                child: _sayacKutusu(
                                  ikon: Icons.local_drink_rounded,
                                  renk: AppTheme.teaPrimary,
                                  bgRenk: AppTheme.teaBg,
                                  baslik: 'Taze Çay',
                                  adet: cayAdet,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _sayacKutusu(
                                  ikon: Icons.coffee_maker_rounded,
                                  renk: AppTheme.coffeePrimary,
                                  bgRenk: AppTheme.coffeeBg,
                                  baslik: 'Filtre Kahve',
                                  adet: kahveAdet,
                                ),
                              ),
                            ],
                          ),

                          // Demleme Saatleri
                          if (demlemeler.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Divider(height: 1, color: Colors.grey.shade100),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Kayıtlı Saatler (${demlemeler.length} Toplam):',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                                    color: isCay ? AppTheme.teaBg : AppTheme.coffeeBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isCay
                                          ? AppTheme.teaPrimary.withOpacity(0.3)
                                          : AppTheme.coffeePrimary.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isCay
                                            ? Icons.local_drink_rounded
                                            : Icons.coffee_maker_rounded,
                                        size: 13,
                                        color: isCay
                                            ? AppTheme.teaPrimary
                                            : AppTheme.coffeePrimary,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        saatStr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isCay
                                              ? AppTheme.teaPrimary
                                              : AppTheme.coffeePrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Bu gün için demleme kaydı bulunmuyor.',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sayacKutusu({
    required IconData ikon,
    required Color renk,
    required Color bgRenk,
    required String baslik,
    required int adet,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: bgRenk,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: renk.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ikon, color: renk, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                baslik,
                style: TextStyle(
                  color: renk,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$adet demleme',
                style: TextStyle(
                  color: renk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
