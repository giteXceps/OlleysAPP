import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tema/app_theme.dart';

class TopluSatisEkrani extends StatefulWidget {
  const TopluSatisEkrani({super.key});

  @override
  State<TopluSatisEkrani> createState() => _TopluSatisEkraniState();
}

class _TopluSatisEkraniState extends State<TopluSatisEkrani> {
  final Map<String, TextEditingController> _adetControllers = {};
  bool _islemYapiliyor = false;
  DateTime _secilenTarih = DateTime.now();

  @override
  void dispose() {
    for (var controller in _adetControllers.values) {
      controller.dispose();
    }
    _adetControllers.clear();
    super.dispose();
  }

  Future<void> _tarihSec() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _secilenTarih,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.posPrimary,
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

  bool get _bugun {
    final now = DateTime.now();
    return _secilenTarih.year == now.year &&
        _secilenTarih.month == now.month &&
        _secilenTarih.day == now.day;
  }

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
        Colors.orange.shade800,
      );
      return;
    }

    for (var entry in satislar.entries) {
      int rafta = raftakiUrunler[entry.key] ?? 0;
      if (entry.value > rafta) {
        _mesajGoster(
          '⚠️ ${entry.key}: girilen adet (${entry.value}), raftaki miktardan ($rafta) fazla!',
          Colors.red.shade800,
        );
        return;
      }
    }

    bool? onaylandi = await _onayDiyalogu(satislar);
    if (onaylandi != true) return;

    setState(() => _islemYapiliyor = true);

    try {
      final simdi = DateTime.now();
      final islemTarihi = _bugun
          ? simdi
          : DateTime(
              _secilenTarih.year,
              _secilenTarih.month,
              _secilenTarih.day,
              simdi.hour,
              simdi.minute,
              simdi.second,
            );

      final batch = FirebaseFirestore.instance.batch();
      int toplamGuncellenen = 0;

      for (var entry in satislar.entries) {
        String urunIsmi = entry.key;
        int satilacakAdet = entry.value;

        var snapshot = await FirebaseFirestore.instance
            .collection('pastalar')
            .where('isim', isEqualTo: urunIsmi)
            .where('durum', isEqualTo: 'Rafta')
            .get();

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

          batch.update(doc.reference, {
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

      final prefs = await SharedPreferences.getInstance();
      String kullanici =
          prefs.getString('aktifKullanici') ?? 'Bilinmeyen Kullanıcı';
      int toplamAdet = satislar.values.fold(0, (a, b) => a + b);

      final logDocRef = FirebaseFirestore.instance
          .collection('satis_loglari')
          .doc();
      batch.set(logDocRef, {
        'kullanici': kullanici,
        'toplamAdet': toplamAdet,
        'detaylar': satislar,
        'tarih': islemTarihi,
      });

      await batch.commit();

      if (mounted) {
        _adetControllers.forEach((_, c) => c.clear());
        setState(() => _secilenTarih = DateTime.now());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Gün sonu satışları işlendi ($toplamAdet ürün satıldı).'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
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

  Future<bool?> _onayDiyalogu(Map<String, int> satislar) {
    String tarihMetni = _bugun
        ? 'Bugün (${DateFormat('dd/MM/yyyy').format(_secilenTarih)})'
        : DateFormat('dd/MM/yyyy').format(_secilenTarih);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.point_of_sale_rounded, color: AppTheme.posPrimary),
            SizedBox(width: 10),
            Text('Satış Onayı & Stok Düşümü'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.posBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.posAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.posPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'İşlem Tarihi: $tarihMetni',
                      style: const TextStyle(
                        color: AppTheme.posPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Aşağıdaki adetler raftaki ürünlerden otomatik olarak düşülecek (SKT\'si en yakın olanlara öncelik verilir).',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${e.value} adet',
                          style: const TextStyle(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Toplam Satılan:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${satislar.values.fold(0, (a, b) => a + b)} adet',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.posPrimary,
                    ),
                  ),
                ],
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
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            label: const Text('ONAYLA & DÜŞÜR', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.posPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _mesajGoster(String mesaj, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: renk, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Gün Sonu Satış Masası'),
        backgroundColor: AppTheme.posPrimary,
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
                    const SizedBox(height: 14),
                    const Text(
                      'Şu an rafta satışa hazır ürün bulunmuyor.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          Map<String, int> raftakiUrunler = _urunleriGrupla(snapshot.data!.docs);

          for (var isim in raftakiUrunler.keys) {
            _adetControllers.putIfAbsent(isim, () => TextEditingController());
          }

          List<String> urunListesi = raftakiUrunler.keys.toList();

          return Column(
            children: [
              // ── ÜST BİLGİ & TARİH SEÇİCİ KARTI ───────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kasiyer / Z raporundan ürün bazlı satılan adetleri girin. Kayıt anında en yakın SKT\'li ürünlerden düşülür.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _tarihSec,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _bugun ? AppTheme.posBg : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _bugun
                                ? AppTheme.posAccent.withOpacity(0.4)
                                : Colors.orange.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: _bugun ? AppTheme.posPrimary : Colors.orange.shade800,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _bugun
                                  ? 'Bugün — ${DateFormat('dd/MM/yyyy').format(_secilenTarih)}'
                                  : 'Geçmiş Gün: ${DateFormat('dd/MM/yyyy').format(_secilenTarih)}',
                              style: TextStyle(
                                color: _bugun ? AppTheme.posPrimary : Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.edit_calendar_rounded,
                              size: 16,
                              color: _bugun ? AppTheme.posPrimary : Colors.orange.shade800,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── ÜRÜN GİRİŞ LİSTESİ ───────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  itemCount: urunListesi.length,
                  itemBuilder: (context, index) {
                    String isim = urunListesi[index];
                    int raftakiAdet = raftakiUrunler[isim]!;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.posBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.cake_rounded,
                              color: AppTheme.posPrimary,
                              size: 24,
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
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Rafta Mevcut: $raftakiAdet Adet',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                color: AppTheme.posPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                suffixText: 'ad.',
                                suffixStyle: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.posPrimary, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      // ── ALT SABİT BUTON ────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
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
            Map<String, int> raftakiUrunler =
                snapshot.hasData ? _urunleriGrupla(snapshot.data!.docs) : {};
            return SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _islemYapiliyor ? null : () => _topluStokDus(raftakiUrunler),
                icon: _islemYapiliyor
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                label: Text(
                  _islemYapiliyor ? 'İşleniyor...' : 'Satışları Stoktan Düşür',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.posPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
