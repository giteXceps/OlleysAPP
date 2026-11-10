import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tema/app_theme.dart';

class PastaTakipEkrani extends StatefulWidget {
  const PastaTakipEkrani({super.key});

  @override
  State<PastaTakipEkrani> createState() => _PastaTakipEkraniState();
}

class _PastaTakipEkraniState extends State<PastaTakipEkrani> {
  String? _secilenUrun;
  int? _secilenUrunRafOmru;
  final TextEditingController _adetController = TextEditingController();
  final TextEditingController _aramaController = TextEditingController();

  bool _geriyeDonukMu = false;
  DateTime _secilenTarih = DateTime.now();
  String _aramaMetni = '';
  bool _sadeceSktYaklasanlar = false;

  @override
  void dispose() {
    _adetController.dispose();
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _tarihSaatSec() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _secilenTarih,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.pastryPrimary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _secilenTarih = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
        );
      });
    }
  }

  Future<void> _rafaEkle() async {
    if (_secilenUrun == null ||
        _adetController.text.isEmpty ||
        _secilenUrunRafOmru == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Eksik bilgi! Lütfen ürün ve adet seçin.'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    DateTime simdi = DateTime.now();
    DateTime eklenmeZamani = _geriyeDonukMu
        ? _secilenTarih
        : DateTime(simdi.year, simdi.month, simdi.day);

    DateTime skt = eklenmeZamani.add(Duration(days: _secilenUrunRafOmru!));
    DateTime silinmeZamani = eklenmeZamani.add(const Duration(days: 182));

    try {
      await FirebaseFirestore.instance.collection('pastalar').add({
        'isim': _secilenUrun,
        'adet': int.tryParse(_adetController.text) ?? 0,
        'ilkAdet': int.tryParse(_adetController.text) ?? 0,
        'eklenmeZamani': eklenmeZamani,
        'sktZamani': skt,
        'silinmeZamani': silinmeZamani,
        'durum': 'Rafta',
        'satilanAdet': 0,
        'imhaEdilenAdet': 0,
      });

      setState(() {
        _secilenUrun = null;
        _secilenUrunRafOmru = null;
        _adetController.clear();
        _geriyeDonukMu = false;
        _secilenTarih = DateTime.now();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Ürün başarıyla rafa eklendi.'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _satildiIsaretle(
    String id,
    String isim,
    int mevcutAdet,
    int toplamSatilan,
  ) async {
    if (mevcutAdet > 0) {
      await FirebaseFirestore.instance.collection('pastalar').doc(id).update({
        'adet': mevcutAdet - 1,
        'satilanAdet': toplamSatilan + 1,
        'durum': (mevcutAdet - 1) == 0 ? 'Tükendi' : 'Rafta',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$isim satıldı. (Kalan: ${mevcutAdet - 1})'),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 10),
                tween: Tween(begin: 1.0, end: 0.0),
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
                    minHeight: 2,
                  );
                },
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'GERİ AL',
            textColor: Colors.yellow,
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('pastalar')
                  .doc(id)
                  .update({
                    'adet': mevcutAdet,
                    'satilanAdet': toplamSatilan,
                    'durum': 'Rafta',
                  });
            },
          ),
        ),
      );
    }
  }

  Future<String?> _logKaydet(String isim, int adet) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String kullanici =
          prefs.getString('aktifKullanici') ?? 'Bilinmeyen Kullanıcı';

      var docRef = await FirebaseFirestore.instance
          .collection('imha_loglari')
          .add({
            'kullanici': kullanici,
            'urun': isim,
            'adet': adet,
            'tarih': DateTime.now(),
          });

      return docRef.id;
    } catch (e) {
      debugPrint("Log kaydetme hatası: $e");
      return null;
    }
  }

  Future<void> _imhaEt(String id, String isim, int mevcutAdet) async {
    await FirebaseFirestore.instance.collection('pastalar').doc(id).update({
      'durum': 'İmha Edildi',
      'adet': 0,
      'imhaEdilenAdet': FieldValue.increment(mevcutAdet),
    });

    String? logId = await _logKaydet(isim, mevcutAdet);

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade900,
        content: Text('$isim topluca imha edildi ($mevcutAdet adet).'),
        action: SnackBarAction(
          label: 'GERİ AL',
          textColor: Colors.white,
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('pastalar')
                .doc(id)
                .update({
                  'durum': 'Rafta',
                  'adet': mevcutAdet,
                  'imhaEdilenAdet': FieldValue.increment(-mevcutAdet),
                });

            if (logId != null) {
              await FirebaseFirestore.instance
                  .collection('imha_loglari')
                  .doc(logId)
                  .delete();
            }
          },
        ),
      ),
    );
  }

  Future<void> _tekliImhaEt(String id, String isim, int mevcutAdet) async {
    if (mevcutAdet > 0) {
      int yeniAdet = mevcutAdet - 1;
      String yeniDurum = yeniAdet == 0 ? 'İmha Edildi' : 'Rafta';

      await FirebaseFirestore.instance.collection('pastalar').doc(id).update({
        'adet': yeniAdet,
        'durum': yeniDurum,
        'imhaEdilenAdet': FieldValue.increment(1),
      });

      String? logId = await _logKaydet(isim, 1);

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange.shade800,
          content: Text('$isim ürününden 1 adet imha edildi. (Kalan: $yeniAdet)'),
          action: SnackBarAction(
            label: 'GERİ AL',
            textColor: Colors.white,
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('pastalar')
                  .doc(id)
                  .update({
                    'durum': 'Rafta',
                    'adet': mevcutAdet,
                    'imhaEdilenAdet': FieldValue.increment(-1),
                  });

              if (logId != null) {
                await FirebaseFirestore.instance
                    .collection('imha_loglari')
                    .doc(logId)
                    .delete();
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 750;

    Widget formAlani = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.pastryBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_shopping_cart_rounded,
                  color: AppTheme.pastryPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rafa Yeni Ürün Girişi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // DİNAMİK DROPDOWN
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('urun_katalogu')
                .orderBy('isim')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LinearProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Önce katalogdan ürün eklemelisiniz!",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                );
              }

              var katalogItems = snapshot.data!.docs;

              return DropdownButtonFormField<String>(
                value: _secilenUrun,
                hint: const Text('Katalogdan Ürün Seçin'),
                isExpanded: true,
                items: katalogItems.map((doc) {
                  return DropdownMenuItem(
                    value: doc['isim'] as String,
                    child: Text("${doc['isim']} (${doc['rafOmruGun']} Gün Raf Ömrü)"),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _secilenUrun = val;
                    final match = katalogItems.where((d) => d['isim'] == val);
                    _secilenUrunRafOmru =
                        match.isNotEmpty ? match.first['rafOmruGun'] : null;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Ürün Adı',
                  prefixIcon: const Icon(Icons.cake_outlined, color: AppTheme.pastryPrimary),
                  filled: true,
                  fillColor: const Color(0xFFFBF8F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),
          TextField(
            controller: _adetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Rafa Giren Adet',
              prefixIcon: const Icon(Icons.pin_outlined, color: AppTheme.pastryPrimary),
              filled: true,
              fillColor: const Color(0xFFFBF8F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Geriye Dönük Kayıt Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: const Text(
                "Geriye dönük kayıt",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                "Geçmiş bir günün girişini yapmak için açın",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              value: _geriyeDonukMu,
              onChanged: (val) => setState(() => _geriyeDonukMu = val),
              activeColor: AppTheme.pastryPrimary,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          if (_geriyeDonukMu) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _tarihSaatSec,
              icon: const Icon(Icons.calendar_month, color: AppTheme.pastryPrimary),
              label: Text(
                "Tarih: ${DateFormat('dd/MM/yyyy').format(_secilenTarih)}",
                style: const TextStyle(color: AppTheme.pastryPrimary, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.pastryPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _rafaEkle,
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
              label: const Text(
                'Rafa Ekle',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pastryPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );

    Widget listeAlani = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pastalar')
          .where('durum', isEqualTo: 'Rafta')
          .orderBy('sktZamani', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var pastalar = snapshot.data!.docs;

        var filtrelenmis = pastalar.where((doc) {
          final isim = (doc['isim'] as String? ?? '').toLowerCase();
          if (_aramaMetni.isNotEmpty && !isim.contains(_aramaMetni.toLowerCase())) {
            return false;
          }

          if (_sadeceSktYaklasanlar) {
            final sktHam = (doc['sktZamani'] as Timestamp).toDate();
            final sktGun = DateTime(sktHam.year, sktHam.month, sktHam.day);
            final bugun = DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            );
            final fark = sktGun.difference(bugun).inDays;
            if (fark > 1) return false;
          }

          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arama ve Filtre Çubuğu
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: AppTheme.softShadow,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppTheme.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _aramaController,
                      decoration: const InputDecoration(
                        hintText: 'Raftaki pastalarda ara...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (val) => setState(() => _aramaMetni = val.trim()),
                    ),
                  ),
                  if (_aramaMetni.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _aramaController.clear();
                        setState(() => _aramaMetni = '');
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Filtre Butonları
            Row(
              children: [
                FilterChip(
                  label: Text('Tümü (${pastalar.length})'),
                  selected: !_sadeceSktYaklasanlar,
                  onSelected: (val) => setState(() => _sadeceSktYaklasanlar = false),
                  selectedColor: AppTheme.pastryBg,
                  checkmarkColor: AppTheme.pastryPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('⚠️ SKT Yaklaşanlar'),
                  selected: _sadeceSktYaklasanlar,
                  onSelected: (val) => setState(() => _sadeceSktYaklasanlar = true),
                  selectedColor: Colors.red.shade50,
                  checkmarkColor: Colors.red.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (filtrelenmis.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        pastalar.isEmpty
                            ? "Rafta henüz ürün yok."
                            : "Arama kriterine uygun ürün bulunamadı.",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtrelenmis.length,
                itemBuilder: (context, index) {
                  var p = filtrelenmis[index];
                  DateTime sktHam = (p['sktZamani'] as Timestamp).toDate();
                  DateTime sktSadeceGun =
                      DateTime(sktHam.year, sktHam.month, sktHam.day);
                  DateTime bugun = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  );
                  int fark = sktSadeceGun.difference(bugun).inDays;

                  Color kartBorder = AppTheme.borderColor;
                  Color rozetRengi = const Color(0xFF059669);
                  String durumRozeti = "$fark Gün Kaldı";

                  if (fark < 0) {
                    kartBorder = Colors.red.shade300;
                    rozetRengi = Colors.red.shade900;
                    durumRozeti = "SKT GEÇTİ";
                  } else if (fark == 0) {
                    kartBorder = Colors.red.shade200;
                    rozetRengi = Colors.red.shade700;
                    durumRozeti = "SON GÜN";
                  } else if (fark == 1) {
                    kartBorder = Colors.orange.shade200;
                    rozetRengi = Colors.orange.shade800;
                    durumRozeti = "YARIN SON";
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kartBorder, width: fark <= 1 ? 1.5 : 1),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.pastryBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.cake_rounded,
                              color: AppTheme.pastryPrimary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p['isim'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: rozetRengi.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: rozetRengi.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        durumRozeti,
                                        style: TextStyle(
                                          color: rozetRengi,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Rafta: ${p['adet']} Adet',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'SKT: ${DateFormat('dd/MM/yyyy').format(sktHam)}',
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Tekli ve Toplu İmha Butonları
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: Colors.orange,
                                  size: 26,
                                ),
                                tooltip: '1 Adet İmha Et',
                                onPressed: () =>
                                    _tekliImhaEt(p.id, p['isim'], p['adet']),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_sweep_rounded,
                                  color: Colors.red.shade700,
                                  size: 26,
                                ),
                                tooltip: 'Tümünü İmha Et',
                                onPressed: () =>
                                    _imhaEt(p.id, p['isim'], p['adet']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5F8), // Açık patisserie kreması
      appBar: AppBar(
        title: const Text('Pasta & Tatlı Takibi'),
        backgroundColor: AppTheme.pastryPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: isTablet
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: formAlani),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: listeAlani),
                    ],
                  )
                : Column(
                    children: [
                      formAlani,
                      const SizedBox(height: 24),
                      listeAlani,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
