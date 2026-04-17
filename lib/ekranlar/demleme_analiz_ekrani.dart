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
    return DateFormat('EEE, d MMM').format(d); // örn: "Çar, 16 Nis"
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

          return FutureBuilder<List<int>>(
            future: Future.wait([
              _gunlukSayi('cay_demlemeleri', tarihStr),
              _gunlukSayi('kahve_demlemeleri', tarihStr),
            ]),
            builder: (context, snapshot) {
              int cayAdet = snapshot.data?[0] ?? 0;
              int kahveAdet = snapshot.data?[1] ?? 0;
              bool yukleniyor = !snapshot.hasData;

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

                      if (yukleniyor)
                        const Center(
                          child: SizedBox(
                            height: 24,
                            child: LinearProgressIndicator(),
                          ),
                        )
                      else
                        Row(
                          children: [
                            // Çay kutusu
                            Expanded(
                              child: _sayacKutusu(
                                ikon: Icons.local_drink,
                                renk: Colors.deepOrange,
                                baslik: 'Çay',
                                adet: cayAdet,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Kahve kutusu
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

                      // Toplam demleme sayısı (boş değilse)
                      if (!yukleniyor && (cayAdet + kahveAdet) > 0) ...[
                        const SizedBox(height: 10),
                        Divider(height: 1, color: Colors.grey[200]),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.summarize_outlined,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Toplam ${cayAdet + kahveAdet} demleme',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Boş gün mesajı
                      if (!yukleniyor && cayAdet == 0 && kahveAdet == 0) ...[
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

  // Firestore'dan belirli gün + koleksiyon için sayım
  Future<int> _gunlukSayi(String koleksiyon, String tarihStr) async {
    var snap = await FirebaseFirestore.instance
        .collection(koleksiyon)
        .where('tarih', isEqualTo: tarihStr)
        .get();
    return snap.docs.length;
  }

  // Sayaç kutusu widget'ı
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
