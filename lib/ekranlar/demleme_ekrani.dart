import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../tema/app_theme.dart';

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
  Timer? _canliGuncellemeTimer;

  @override
  void initState() {
    super.initState();
    _canliGuncellemeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _canliGuncellemeTimer?.cancel();
    super.dispose();
  }

  String get _baslik =>
      widget.tip == Demlemetipi.cay ? 'Çay Demleme' : 'Filtre Kahve Demleme';

  String get _koleksiyon =>
      widget.tip == Demlemetipi.cay ? 'cay_demlemeleri' : 'kahve_demlemeleri';

  Color get _anaRenk =>
      widget.tip == Demlemetipi.cay ? AppTheme.teaPrimary : AppTheme.coffeePrimary;

  Color get _bgRenk =>
      widget.tip == Demlemetipi.cay ? AppTheme.teaBg : AppTheme.coffeeBg;

  IconData get _ikon =>
      widget.tip == Demlemetipi.cay ? Icons.local_drink_rounded : Icons.coffee_maker_rounded;

  Map<String, dynamic> _tazelikDurumu(DateTime demlemeZamani) {
    int dakika = DateTime.now().difference(demlemeZamani).inMinutes;
    if (dakika < 0) dakika = 0;

    if (dakika <= 30) {
      return {
        'renk': const Color(0xFF059669),
        'arkaRenk': const Color(0xFFECFDF5),
        'borderRenk': const Color(0xFFA7F3D0),
        'metin': 'Taze Demleme',
        'altMetin': '${30 - dakika} dk daha ideal tazelikte',
        'ikon': Icons.check_circle_rounded,
        'ilerleme': dakika / 90.0,
        'dakika': dakika,
      };
    } else if (dakika <= 60) {
      return {
        'renk': const Color(0xFFD97706),
        'arkaRenk': const Color(0xFFFFFBEB),
        'borderRenk': const Color(0xFFFDE68A),
        'metin': 'Ortalama Tazelik',
        'altMetin': '${60 - dakika} dk sonra bayatlamaya başlar',
        'ikon': Icons.schedule_rounded,
        'ilerleme': dakika / 90.0,
        'dakika': dakika,
      };
    } else if (dakika <= 90) {
      return {
        'renk': const Color(0xFFDC2626),
        'arkaRenk': const Color(0xFFFEF2F2),
        'borderRenk': const Color(0xFFFECACA),
        'metin': 'Bayata Gidiyor',
        'altMetin': '${90 - dakika} dk içinde yenilenmeli!',
        'ikon': Icons.warning_amber_rounded,
        'ilerleme': dakika / 90.0,
        'dakika': dakika,
      };
    } else {
      return {
        'renk': const Color(0xFF991B1B),
        'arkaRenk': const Color(0xFFFEF2F2),
        'borderRenk': const Color(0xFFF87171),
        'metin': 'BAYAT — Yenileyin!',
        'altMetin': '${dakika - 90} dakika önce tazeliğini yitirdi',
        'ikon': Icons.dangerous_rounded,
        'ilerleme': 1.0,
        'dakika': dakika,
      };
    }
  }

  Future<void> _zamanSec() async {
    final now = DateTime.now();
    final DateTime limitMin = now.subtract(const Duration(minutes: 15));
    final DateTime limitMax = now.add(const Duration(minutes: 15));

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_secilenZaman),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _anaRenk),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    DateTime secilen = DateTime(
      now.year,
      now.month,
      now.day,
      pickedTime.hour,
      pickedTime.minute,
    );

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

  Future<void> _demlemeyiKaydet() async {
    setState(() => _kaydediliyor = true);

    try {
      DateTime kayitZamani = _geriyeDonukMu ? _secilenZaman : DateTime.now();
      DateTime silinmeZamani = kayitZamani.add(const Duration(days: 90));

      await FirebaseFirestore.instance.collection(_koleksiyon).add({
        'tip': widget.tip == Demlemetipi.cay ? 'cay' : 'kahve',
        'demlemeZamani': kayitZamani,
        'tarih': DateFormat('yyyy-MM-dd').format(kayitZamani),
        'silinmeZamani': silinmeZamani,
      });

      if (!mounted) return;

      setState(() {
        _geriyeDonukMu = false;
        _secilenZaman = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${_baslik} ${DateFormat('HH:mm').format(kayitZamani)} saatinde kaydedildi.',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) _mesajGoster('Hata: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  void _mesajGoster(String mesaj, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: renk,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _sonDemlemeKarti(QueryDocumentSnapshot? sonDoc) {
    if (sonDoc == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Icon(_ikon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Bugün henüz demleme kaydı yapılmadı',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    DateTime demlemeZamani = (sonDoc['demlemeZamani'] as Timestamp).toDate();
    Map<String, dynamic> durum = _tazelikDurumu(demlemeZamani);
    Color renk = durum['renk'];
    Color arkaRenk = durum['arkaRenk'];
    Color borderRenk = durum['borderRenk'];
    int dakika = durum['dakika'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: arkaRenk,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderRenk, width: 2),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderRenk),
                ),
                child: Icon(durum['ikon'], color: renk, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      durum['metin'],
                      style: TextStyle(
                        color: renk,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Demlendi: ${DateFormat('HH:mm').format(demlemeZamani)} (${durum['altMetin']})',
                      style: TextStyle(
                        color: renk.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderRenk),
                ),
                child: Text(
                  dakika < 60 ? '$dakika dk' : '${dakika ~/ 60}s ${dakika % 60}dk',
                  style: TextStyle(
                    color: renk,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: durum['ilerleme'],
              minHeight: 10,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(renk),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_baslik),
        backgroundColor: _anaRenk,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── CANLI DEMLEME DURUMU ───────────────────────
                const Text(
                  'Canlı Tazelik Durumu',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),

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

                // ── YENİ DEMLEME KAYIT FORMU ───────────────────
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _bgRenk,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_ikon, color: _anaRenk, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Yeni Demleme Kaydı',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _anaRenk,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            'Geriye dönük saat kaydı',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            '±15 dakika tolerans ile demleme saatini ayarlayın',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
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
                      ),

                      if (_geriyeDonukMu) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _zamanSec,
                          icon: const Icon(Icons.access_time_rounded),
                          label: Text(
                            'Demleme Saati: ${DateFormat('HH:mm').format(_secilenZaman)}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _anaRenk,
                            side: BorderSide(color: _anaRenk, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

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
                              : const Icon(Icons.check_circle_outline_rounded),
                          label: Text(
                            _kaydediliyor
                                ? 'Kaydediliyor...'
                                : '${_baslik} Yapıldı — Şimdi Kaydet'
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

                const SizedBox(height: 28),

                // ── BUGÜNKÜ DEMLEME GEÇMİŞİ ────────────────────
                const Text(
                  'Bugünkü Demleme Geçmişi',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),

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
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Center(
                          child: Text(
                            'Bugün henüz demleme kaydı bulunmuyor.',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ),
                      );
                    }

                    var kayitlar = snapshot.data!.docs;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: kayitlar.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          var k = kayitlar[index];
                          DateTime zaman =
                              (k['demlemeZamani'] as Timestamp).toDate();
                          bool ilkMi = index == 0;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 6,
                            ),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: ilkMi ? _bgRenk : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '#${kayitlar.length - index}',
                                style: TextStyle(
                                  color: ilkMi ? _anaRenk : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            title: Text(
                              DateFormat('HH:mm').format(zaman),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ilkMi ? _anaRenk : AppTheme.textDark,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: ilkMi
                                ? Text(
                                    'Şu an serviste olan son demleme',
                                    style: TextStyle(
                                      color: _anaRenk,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                            trailing: ilkMi
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _bgRenk,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _anaRenk.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      'Aktif',
                                      style: TextStyle(
                                        color: _anaRenk,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
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
        ),
      ),
    );
  }
}
