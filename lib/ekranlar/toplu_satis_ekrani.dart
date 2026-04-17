import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TopluSatisEkrani extends StatefulWidget {
  const TopluSatisEkrani({super.key});

  @override
  State<TopluSatisEkrani> createState() => _TopluSatisEkraniState();
}

class _TopluSatisEkraniState extends State<TopluSatisEkrani> {
  final Map<String, TextEditingController> _adetControllers = {};
  bool _islemYapiliyor = false;

  // Tarih seçimi — varsayılan bugün
  DateTime _secilenTarih = DateTime.now();

  // ----------------------------------------------------------------
  // TARİH SEÇİCİ
  // ----------------------------------------------------------------
  Future<void> _tarihSec() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _secilenTarih,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(), // Gelecek tarih seçilemesin
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueGrey,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _secilenTarih = picked);
    }
  }

  // Seçilen tarihin bugün olup olmadığını kontrol et
  bool get _bugun {
    final now = DateTime.now();
    return _secilenTarih.year == now.year &&
        _secilenTarih.month == now.month &&
        _secilenTarih.day == now.day;
  }

  // ----------------------------------------------------------------
  // RAFTA OLAN ÜRÜNLERİ GRUPLA
  // ----------------------------------------------------------------
  Map<String, int> _urunleriGrupla(List<QueryDocumentSnapshot> docs) {
    Map<String, int> gruplar = {};
    for (var doc in docs) {
      String isim = doc['isim'];
      int adet = doc['adet'] ?? 0;
      gruplar[isim] = (gruplar[isim] ?? 0) + adet;
    }
    return Map.fromEntries(
      gruplar.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  // ----------------------------------------------------------------
  // ANA İŞLEM: TOPLU STOKTAN DÜŞ
  // ----------------------------------------------------------------
  Future<void> _topluStokDus(Map<String, int> raftakiUrunler) async {
    Map<String, int> satislar = {};
    _adetControllers.forEach((urunIsmi, controller) {
      int? adet = int.tryParse(controller.text);
      if (adet != null && adet > 0) {
        satislar[urunIsmi] = adet;
      }
    });

    if (satislar.isEmpty) {
      _mesajGoster(
        'Lütfen en az bir ürün için satış adedi girin.',
        Colors.orange,
      );
      return;
    }

    // Raftakinden fazla girilmişse uyar
    for (var entry in satislar.entries) {
      int rafta = raftakiUrunler[entry.key] ?? 0;
      if (entry.value > rafta) {
        _mesajGoster(
          '⚠️ ${entry.key}: girilen adet (${entry.value}), '
          'raftaki miktardan ($rafta) fazla!',
          Colors.red,
        );
        return;
      }
    }

    bool? onaylandi = await _onayDiyalogu(satislar);
    if (onaylandi != true) return;

    setState(() => _islemYapiliyor = true);

    try {
      int toplamGuncellenen = 0;

      for (var entry in satislar.entries) {
        String urunIsmi = entry.key;
        int satilacakAdet = entry.value;

        var snapshot = await FirebaseFirestore.instance
            .collection('pastalar')
            .where('isim', isEqualTo: urunIsmi)
            .where('durum', isEqualTo: 'Rafta')
            .get();

        // Dart tarafında SKT'ye göre sırala (en yakın önce)
        var docs = snapshot.docs.toList()
          ..sort((a, b) {
            DateTime sktA = (a['sktZamani'] as Timestamp).toDate();
            DateTime sktB = (b['sktZamani'] as Timestamp).toDate();
            return sktA.compareTo(sktB);
          });

        int kalanDusulecek = satilacakAdet;

        for (var doc in docs) {
          if (kalanDusulecek <= 0) break;

          int mevcutAdet = doc['adet'] ?? 0;
          int mevcutSatilan = doc['satilanAdet'] ?? 0;
          if (mevcutAdet <= 0) continue;

          int buDokmandanDus = kalanDusulecek > mevcutAdet
              ? mevcutAdet
              : kalanDusulecek;

          await FirebaseFirestore.instance
              .collection('pastalar')
              .doc(doc.id)
              .update({
                'adet': mevcutAdet - buDokmandanDus,
                'satilanAdet': mevcutSatilan + buDokmandanDus,
                'durum': (mevcutAdet - buDokmandanDus) == 0
                    ? 'Tükendi'
                    : 'Rafta',
              });

          kalanDusulecek -= buDokmandanDus;
          toplamGuncellenen++;
        }
      }

      if (mounted) {
        _adetControllers.forEach((_, c) => c.clear());
        // Tarih seçimini bugüne sıfırla
        setState(() => _secilenTarih = DateTime.now());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Gün sonu satışları işlendi! $toplamGuncellenen kayıt güncellendi.',
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) _mesajGoster('Hata oluştu: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _islemYapiliyor = false);
    }
  }

  // ----------------------------------------------------------------
  // ONAY DİYALOĞU
  // ----------------------------------------------------------------
  Future<bool?> _onayDiyalogu(Map<String, int> satislar) {
    String tarihMetni = _bugun
        ? 'Bugün (${DateFormat('dd/MM/yyyy').format(_secilenTarih)})'
        : DateFormat('dd/MM/yyyy').format(_secilenTarih);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.blueGrey),
            SizedBox(width: 10),
            Text('Gün Sonu Satış Özeti'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarih bilgisi
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.blueGrey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tarih: $tarihMetni',
                      style: TextStyle(
                        color: Colors.blueGrey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Aşağıdaki satışlar stoktan düşülecek.\n'
                'SKT\'si en yakın ürünler öncelikli işlenecek.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Divider(),
              ...satislar.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${e.value} adet',
                          style: TextStyle(
                            color: Colors.blueGrey[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              const SizedBox(height: 4),
              Text(
                'Toplam: ${satislar.values.fold(0, (a, b) => a + b)} adet',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İPTAL'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check),
            label: const Text('ONAYLA & DÜŞÜR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[800],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _mesajGoster(String mesaj, Color renk) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: renk));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gün Sonu Satış Girişi'),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pastalar')
            .where('durum', isEqualTo: 'Rafta')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Şu an rafta hiç ürün yok.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          Map<String, int> raftakiUrunler = _urunleriGrupla(
            snapshot.data!.docs,
          );

          for (var isim in raftakiUrunler.keys) {
            _adetControllers.putIfAbsent(isim, () => TextEditingController());
          }

          List<String> urunListesi = raftakiUrunler.keys.toList();

          return Column(
            children: [
              // ── ÜST BİLGİ + TARİH SEÇİCİ ──────────────────────
              Container(
                width: double.infinity,
                color: Colors.blueGrey[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gün sonu raporuna bakarak satılan miktarları girin.\n'
                      'SKT\'si en yakın ürünler önce stoktan düşülür.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    // Tarih seçim butonu
                    GestureDetector(
                      onTap: _tarihSec,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _bugun
                                  ? 'Bugün — ${DateFormat('dd/MM/yyyy').format(_secilenTarih)}'
                                  : '${DateFormat('dd/MM/yyyy').format(_secilenTarih)} ← Geçmiş tarih',
                              style: TextStyle(
                                color: _bugun
                                    ? Colors.white
                                    : Colors.orange[200],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.edit_calendar,
                              color: Colors.white.withOpacity(0.7),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Geçmiş tarih seçilmişse uyarı göster
                    if (!_bugun) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[200],
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Geçmiş gün için satış girişi yapılıyor',
                            style: TextStyle(
                              color: Colors.orange[200],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── ÜRÜN LİSTESİ ───────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: urunListesi.length,
                  itemBuilder: (context, index) {
                    String isim = urunListesi[index];
                    int raftakiAdet = raftakiUrunler[isim]!;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blueGrey[50],
                              child: const Icon(
                                Icons.cake_outlined,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isim,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Rafta: $raftakiAdet adet',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: _adetControllers[isim],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(color: Colors.grey[300]),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.blueGrey,
                                      width: 2,
                                    ),
                                  ),
                                  suffixText: 'ad.',
                                  suffixStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      // ── ALT SABİT BUTON ──────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pastalar')
              .where('durum', isEqualTo: 'Rafta')
              .snapshots(),
          builder: (context, snapshot) {
            Map<String, int> raftakiUrunler = snapshot.hasData
                ? _urunleriGrupla(snapshot.data!.docs)
                : {};
            return SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _islemYapiliyor
                    ? null
                    : () => _topluStokDus(raftakiUrunler),
                icon: _islemYapiliyor
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.playlist_add_check),
                label: Text(
                  _islemYapiliyor ? 'İşleniyor...' : 'Satışları Stoktan Düşür',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
