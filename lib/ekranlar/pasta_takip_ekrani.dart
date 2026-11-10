import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PastaTakipEkrani extends StatefulWidget {
  const PastaTakipEkrani({super.key});

  @override
  State<PastaTakipEkrani> createState() => _PastaTakipEkraniState();
}

class _PastaTakipEkraniState extends State<PastaTakipEkrani> {
  // ARTIK SABİT LİSTE YOK! Veriler Firestore'dan gelecek.

  String? _secilenUrun;
  int? _secilenUrunRafOmru; // Seçilen ürünün raf ömrünü tutmak için
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
    );

    if (pickedDate != null) {
      setState(() {
        // Saat, dakika ve saniyeyi tamamen sıfırlıyoruz
        _secilenTarih = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
        );
      });
    }
  }

  Future<void> _rafaEkle() async {
    // 1. Girdi Kontrolü
    if (_secilenUrun == null ||
        _adetController.text.isEmpty ||
        _secilenUrunRafOmru == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eksik bilgi! Lütfen ürün ve adet seçin.'),
        ),
      );
      return;
    }

    DateTime simdi = DateTime.now();
    DateTime eklenmeZamani = _geriyeDonukMu
        ? _secilenTarih
        : DateTime(simdi.year, simdi.month, simdi.day);

    // SKT hesaplaması artık tam gün üzerinden dönecek
    DateTime skt = eklenmeZamani.add(Duration(days: _secilenUrunRafOmru!));

    // Veritabanından otomatik silinme tarihi (6 Ay = 182 Gün)
    DateTime silinmeZamani = eklenmeZamani.add(const Duration(days: 182));

    try {
      // 3. Firestore'a Kayıt
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

      // 4. Arayüzü Sıfırla
      setState(() {
        _secilenUrun = null;
        _secilenUrunRafOmru = null;
        _adetController.clear();
        _geriyeDonukMu = false;
        _secilenTarih = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ürün başarıyla rafa eklendi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata oluştu: $e')));
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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.yellow,
                    ),
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

  // --- 1. GÜNCELLENMİŞ LOG KAYDETME FONKSİYONU ---
  // Artık sadece logu kaydetmiyor, oluşturduğu logun ID'sini bize geri veriyor.
  Future<String?> _logKaydet(String isim, int adet) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String kullanici =
          prefs.getString('aktifKullanici') ?? 'Bilinmeyen Kullanıcı';

      // add() işlemi bir DocumentReference döndürür. Bunu docRef'e eşitliyoruz.
      var docRef = await FirebaseFirestore.instance
          .collection('imha_loglari')
          .add({
            'kullanici': kullanici,
            'urun': isim,
            'adet': adet,
            'tarih': DateTime.now(),
          });

      // Kayıt başarılıysa oluşturulan belgenin ID'sini geri gönder
      return docRef.id;
    } catch (e) {
      debugPrint("Log kaydetme hatası: $e");
      return null;
    }
  }

  // --- 2. GÜNCELLENMİŞ TOPLU İMHA FONKSİYONU ---
  Future<void> _imhaEt(String id, String isim, int mevcutAdet) async {
    // 1. Ürünü raftan kaldır ve imha sayısını artır
    await FirebaseFirestore.instance.collection('pastalar').doc(id).update({
      'durum': 'İmha Edildi',
      'adet': 0,
      'imhaEdilenAdet': FieldValue.increment(mevcutAdet),
    });

    // 2. Logu kaydet ve bize verdiği ID'yi değişkende tut!
    String? logId = await _logKaydet(isim, mevcutAdet);

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        backgroundColor: Colors.red.shade900,
        content: Text('$isim imha edildi. Kayıtlar güncellendi.'),
        action: SnackBarAction(
          label: 'GERİ AL',
          textColor: Colors.white,
          onPressed: () async {
            // A. Ürünü tekrar rafa koy (Stoku düzelt)
            await FirebaseFirestore.instance
                .collection('pastalar')
                .doc(id)
                .update({
                  'durum': 'Rafta',
                  'adet': mevcutAdet,
                  'imhaEdilenAdet': FieldValue.increment(-mevcutAdet),
                });

            // B. YENİ KOD: Eğer log başarıyla oluşmuşsa (logId null değilse), o logu veritabanından sil!
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

  // --- 3. GÜNCELLENMİŞ TEKLİ İMHA FONKSİYONU ---
  Future<void> _tekliImhaEt(String id, String isim, int mevcutAdet) async {
    if (mevcutAdet > 0) {
      int yeniAdet = mevcutAdet - 1;
      String yeniDurum = yeniAdet == 0 ? 'İmha Edildi' : 'Rafta';

      // 1. Stoktan 1 adet düş ve imha sayısını 1 artır
      await FirebaseFirestore.instance.collection('pastalar').doc(id).update({
        'adet': yeniAdet,
        'durum': yeniDurum,
        'imhaEdilenAdet': FieldValue.increment(1),
      });

      // 2. Logu kaydet ve ID'sini tut!
      String? logId = await _logKaydet(isim, 1);

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.orange.shade800,
          content: Text(
            '$isim ürününden 1 adet imha edildi. (Kalan: $yeniAdet)',
          ),
          action: SnackBarAction(
            label: 'GERİ AL',
            textColor: Colors.white,
            onPressed: () async {
              // A. Stok miktarını eski haline getir
              await FirebaseFirestore.instance
                  .collection('pastalar')
                  .doc(id)
                  .update({
                    'durum': 'Rafta',
                    'adet': mevcutAdet,
                    'imhaEdilenAdet': FieldValue.increment(-1),
                  });

              // B. YENİ KOD: Tutulan ID'ye ait logu sil!
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
    bool isTablet = MediaQuery.of(context).size.width > 600;

    Widget formAlani = Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Yeni Ürün Ekle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),

            // --- DİNAMİK DROPDOWN (Firestore'dan Veri Çeken Kısım) ---
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
                  return const Text(
                    "Önce katalogdan ürün eklemelisiniz!",
                    style: TextStyle(color: Colors.red),
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
                      child: Text("${doc['isim']} (${doc['rafOmruGun']} Gün)"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _secilenUrun = val;
                      final match = katalogItems.where((d) => d['isim'] == val);
                      _secilenUrunRafOmru = match.isNotEmpty ? match.first['rafOmruGun'] : null;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),
            TextField(
              controller: _adetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Adet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text(
                "Geriye dönük kayıt",
                style: TextStyle(fontSize: 14),
              ),
              value: _geriyeDonukMu,
              onChanged: (val) => setState(() => _geriyeDonukMu = val),
              activeColor: Colors.orange,
            ),
            if (_geriyeDonukMu)
              OutlinedButton.icon(
                onPressed: _tarihSaatSec,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  "Tarih: ${DateFormat('dd/MM HH:mm').format(_secilenTarih)}",
                ),
              ),
            const SizedBox(height: 15),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _rafaEkle,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                child: const Text(
                  'Rafa Ekle',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
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

        // Arama ve SKT filtrelemesi
        var filtrelenmis = pastalar.where((doc) {
          final isim = (doc['isim'] as String? ?? '').toLowerCase();
          if (_aramaMetni.isNotEmpty && !isim.contains(_aramaMetni.toLowerCase())) {
            return false;
          }

          if (_sadeceSktYaklasanlar) {
            final sktHam = (doc['sktZamani'] as Timestamp).toDate();
            final sktGun = DateTime(sktHam.year, sktHam.month, sktHam.day);
            final bugun = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
            final fark = sktGun.difference(bugun).inDays;
            if (fark > 1) return false;
          }

          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arama ve Filtre Çubuğu
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _aramaController,
                        decoration: const InputDecoration(
                          hintText: 'Raftaki pastalarda ara...',
                          border: InputBorder.none,
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
            ),
            const SizedBox(height: 8),

            // Filtre Butonları
            Row(
              children: [
                FilterChip(
                  label: Text('Tümü (${pastalar.length})'),
                  selected: !_sadeceSktYaklasanlar,
                  onSelected: (val) => setState(() => _sadeceSktYaklasanlar = false),
                  selectedColor: Colors.pink.shade100,
                  checkmarkColor: Colors.pink,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('⚠️ SKT Yaklaşanlar'),
                  selected: _sadeceSktYaklasanlar,
                  onSelected: (val) => setState(() => _sadeceSktYaklasanlar = true),
                  selectedColor: Colors.red.shade100,
                  checkmarkColor: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (filtrelenmis.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    pastalar.isEmpty
                        ? "Rafta ürün yok."
                        : "Arama kriterine uygun ürün bulunamadı.",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
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
                  DateTime sktSadeceGun = DateTime(sktHam.year, sktHam.month, sktHam.day);
                  DateTime bugun = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                  int fark = sktSadeceGun.difference(bugun).inDays;

                  Color kartRengi = Colors.white;
                  Color rozetRengi = Colors.green;
                  String durumRozeti = "$fark Gün Kaldı";

                  if (fark < 0) {
                    kartRengi = Colors.grey.shade200;
                    rozetRengi = Colors.red.shade900;
                    durumRozeti = "SKT GEÇTİ";
                  } else if (fark == 0) {
                    kartRengi = Colors.red.shade50;
                    rozetRengi = Colors.red;
                    durumRozeti = "SON GÜN";
                  } else if (fark == 1) {
                    kartRengi = Colors.orange.shade50;
                    rozetRengi = Colors.orange.shade800;
                    durumRozeti = "YARIN SON";
                  }

                  return Card(
                    color: kartRengi,
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: Colors.pink.shade50,
                        child: const Icon(Icons.cake, color: Colors.pink),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p['isim'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: rozetRengi.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: rozetRengi.withOpacity(0.4)),
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
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Mevcut Adet: ${p['adet']}   |   SKT: ${DateFormat('dd/MM/yyyy').format(sktHam)}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.orange,
                              size: 28,
                            ),
                            tooltip: '1 Adet İmha Et',
                            onPressed: () => _tekliImhaEt(p.id, p['isim'], p['adet']),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                              size: 30,
                            ),
                            tooltip: 'Tümünü İmha Et',
                            onPressed: () => _imhaEt(p.id, p['isim'], p['adet']),
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
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text('Olleys Pasta Takibi'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isTablet
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: formAlani),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: listeAlani),
                ],
              )
            : Column(
                children: [formAlani, const SizedBox(height: 20), listeAlani],
              ),
      ),
    );
  }
}
