import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum Demlemetipi { cay, filtre }

class DemlemeEkrani extends StatefulWidget {
  final Demlemetipi tip;

  const DemlemeEkrani({super.key, required this.tip});

  @override
  State<DemlemeEkrani> createState() => _DemlemeEkraniState();
}

class _DemlemeEkraniState extends State<DemlemeEkrani> {
  bool _geriyeDonukMu = false;
  DateTime _secilenZaman = DateTime.now();
  bool _kaydediliyor = false;

  // ----------------------------------------------------------------
  // EKRANA GÖRE SABİTLER
  // ----------------------------------------------------------------
  String get _baslik =>
      widget.tip == Demlemetipi.cay ? 'Çay Demleme' : 'Filtre Kahve';

  String get _koleksiyon =>
      widget.tip == Demlemetipi.cay ? 'cay_demlemeleri' : 'kahve_demlemeleri';

  Color get _anaRenk =>
      widget.tip == Demlemetipi.cay ? Colors.deepOrange : Colors.brown;

  IconData get _ikon =>
      widget.tip == Demlemetipi.cay ? Icons.local_drink : Icons.coffee_maker;

  // ----------------------------------------------------------------
  // TAZELIK DURUMU HESAPLA (dakika bazında)
  // 0-30 dk  → Taze   (yeşil)
  // 30-60 dk → Orta   (turuncu)
  // 60-90 dk → Bayata Gidiyor (kırmızı)
  // 90+ dk   → Bayat! Değiştir (koyu kırmızı + uyarı)
  // ----------------------------------------------------------------
  Map<String, dynamic> _tazelikDurumu(DateTime demlemeZamani) {
    int dakika = DateTime.now().difference(demlemeZamani).inMinutes;

    if (dakika < 0) dakika = 0; // Geriye dönük girilmişse negatif olmasın

    if (dakika <= 30) {
      return {
        'renk': Colors.green,
        'arkaRenk': Colors.green.shade50,
        'metin': 'Taze',
        'altMetin': '${30 - dakika} dakika daha taze kalır',
        'ikon': Icons.check_circle,
        'ilerleme': dakika / 90.0,
        'dakika': dakika,
      };
    } else if (dakika <= 60) {
      return {
        'renk': Colors.orange,
        'arkaRenk': Colors.orange.shade50,
        'metin': 'Ortalama',
        'altMetin': '${60 - dakika} dakika sonra bayatlamaya başlar',
        'ikon': Icons.schedule,
        'ilerleme': dakika / 90.0,
        'dakika': dakika,
      };
    } else if (dakika <= 90) {
      return {
        'renk': Colors.red,
        'arkaRenk': Colors.red.shade50,
        'metin': 'Bayata Gidiyor',
        'altMetin': '${90 - dakika} dakika içinde değiştirilmeli!',
        'ikon': Icons.warning_amber_rounded,
        'ilerleme': dakika / 90.0,
        'dakika': dakika,
      };
    } else {
      return {
        'renk': Colors.red.shade900,
        'arkaRenk': Colors.red.shade100,
        'metin': 'BAYAT — Değiştir!',
        'altMetin': '${dakika - 90} dakika önce değiştirilmeliydi',
        'ikon': Icons.dangerous,
        'ilerleme': 1.0,
        'dakika': dakika,
      };
    }
  }

  // ----------------------------------------------------------------
  // ZAMAN SEÇİCİ (±15 dakika limiti)
  // ----------------------------------------------------------------
  Future<void> _zamanSec() async {
    final now = DateTime.now();
    final DateTime limitMin = now.subtract(const Duration(minutes: 15));
    final DateTime limitMax = now.add(const Duration(minutes: 15));

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_secilenZaman),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: _anaRenk)),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    // Seçilen saati bugünün tarihi ile birleştir
    DateTime secilen = DateTime(
      now.year,
      now.month,
      now.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // ±15 dakika kontrolü
    if (secilen.isBefore(limitMin)) {
      if (!mounted) return;
      _mesajGoster('En fazla 15 dakika geriye girebilirsiniz!', Colors.orange);
      return;
    }
    if (secilen.isAfter(limitMax)) {
      if (!mounted) return;
      _mesajGoster('En fazla 15 dakika ileriye girebilirsiniz!', Colors.orange);
      return;
    }

    setState(() => _secilenZaman = secilen);
  }

  // ----------------------------------------------------------------
  // DEMLEMEYİ KAYDET
  // ----------------------------------------------------------------
  Future<void> _demlemeyiKaydet() async {
    setState(() => _kaydediliyor = true);

    try {
      DateTime kayitZamani = _geriyeDonukMu ? _secilenZaman : DateTime.now();

      await FirebaseFirestore.instance.collection(_koleksiyon).add({
        'tip': widget.tip == Demlemetipi.cay ? 'cay' : 'kahve',
        'demlemeZamani': kayitZamani,
        'tarih': DateFormat(
          'yyyy-MM-dd',
        ).format(kayitZamani), // Günlük gruplama için
      });

      if (!mounted) return;

      setState(() {
        _geriyeDonukMu = false;
        _secilenZaman = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${_baslik} ${DateFormat('HH:mm').format(kayitZamani)} '
            'saatinde kaydedildi.',
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (mounted) _mesajGoster('Hata: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  void _mesajGoster(String mesaj, Color renk) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: renk));
  }

  // ----------------------------------------------------------------
  // SON DEMLEMEYE AİT CANLI DURUM KARTI
  // ----------------------------------------------------------------
  Widget _sonDemlemeKarti(QueryDocumentSnapshot? sonDoc) {
    if (sonDoc == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(_ikon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Henüz demleme kaydı yok',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    DateTime demlemeZamani = (sonDoc['demlemeZamani'] as Timestamp).toDate();
    Map<String, dynamic> durum = _tazelikDurumu(demlemeZamani);
    Color renk = durum['renk'];
    int dakika = durum['dakika'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: durum['arkaRenk'],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: renk.withOpacity(0.4), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(durum['ikon'], color: renk, size: 28),
              const SizedBox(width: 10),
              Text(
                durum['metin'],
                style: TextStyle(
                  color: renk,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Geçen süre rozeti
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: renk.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dakika < 60
                      ? '$dakika dk'
                      : '${dakika ~/ 60}s ${dakika % 60}dk',
                  style: TextStyle(
                    color: renk,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tazelik ilerleme çubuğu
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: durum['ilerleme'],
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.6),
              valueColor: AlwaysStoppedAnimation<Color>(renk),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Demlendi: ${DateFormat('HH:mm').format(demlemeZamani)}',
                style: TextStyle(
                  color: renk.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                durum['altMetin'],
                style: TextStyle(color: renk.withOpacity(0.8), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_baslik),
        backgroundColor: _anaRenk,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── SON DEMLEME CANLI DURUMU ──────────────────────────
            const Text(
              'Son Demleme Durumu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(_koleksiyon)
                  .orderBy('demlemeZamani', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                QueryDocumentSnapshot? sonDoc =
                    snapshot.data?.docs.isNotEmpty == true
                    ? snapshot.data!.docs.first
                    : null;
                return _sonDemlemeKarti(sonDoc);
              },
            ),

            const SizedBox(height: 28),

            // ── YENİ DEMLEME KAYIT FORMU ──────────────────────────
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(_ikon, color: _anaRenk, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Yeni Demleme Kaydet',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _anaRenk,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Geriye dönük toggle
                    SwitchListTile(
                      title: const Text(
                        'Geriye dönük kayıt',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: const Text(
                        '±15 dakika içinde saat düzenlenebilir',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: _geriyeDonukMu,
                      activeColor: _anaRenk,
                      onChanged: (val) {
                        setState(() {
                          _geriyeDonukMu = val;
                          _secilenZaman = DateTime.now();
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Saat seçici (geriye dönük açıksa)
                    if (_geriyeDonukMu) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _zamanSec,
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          'Demleme Saati: ${DateFormat('HH:mm').format(_secilenZaman)}',
                          style: const TextStyle(fontSize: 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _anaRenk,
                          side: BorderSide(color: _anaRenk),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Kaydet butonu
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _kaydediliyor ? null : _demlemeyiKaydet,
                        icon: _kaydediliyor
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add_circle_outline),
                        label: Text(
                          _kaydediliyor
                              ? 'Kaydediliyor...'
                              : '${_baslik} Yapıldı — Kaydet'
                                    '${_geriyeDonukMu ? ' (${DateFormat('HH:mm').format(_secilenZaman)})' : ''}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _anaRenk,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── BUGÜNKÜ DEMLEME GEÇMİŞİ ─────────────────────────
            const Text(
              'Bugünkü Demleme Geçmişi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(_koleksiyon)
                  .where(
                    'tarih',
                    isEqualTo: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  )
                  .orderBy('demlemeZamani', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Bugün henüz demleme kaydı yok.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  );
                }

                var kayitlar = snapshot.data!.docs;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: kayitlar.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      var k = kayitlar[index];
                      DateTime zaman = (k['demlemeZamani'] as Timestamp)
                          .toDate();
                      bool ilkMi = index == 0;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ilkMi
                              ? _anaRenk.withOpacity(0.15)
                              : Colors.grey[100],
                          child: Text(
                            '${kayitlar.length - index}',
                            style: TextStyle(
                              color: ilkMi ? _anaRenk : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          DateFormat('HH:mm').format(zaman),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ilkMi ? _anaRenk : Colors.black87,
                            fontSize: 17,
                          ),
                        ),
                        subtitle: ilkMi
                            ? Text(
                                'Son demleme',
                                style: TextStyle(color: _anaRenk, fontSize: 12),
                              )
                            : null,
                        trailing: ilkMi
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _anaRenk.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Aktif',
                                  style: TextStyle(
                                    color: _anaRenk,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
