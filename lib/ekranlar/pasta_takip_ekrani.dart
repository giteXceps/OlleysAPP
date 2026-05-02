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

  bool _geriyeDonukMu = false;
  DateTime _secilenTarih = DateTime.now();

  Future<void> _tarihSaatSec() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _secilenTarih,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_secilenTarih),
      );

      if (pickedTime != null) {
        setState(() {
          _secilenTarih = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
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

    // 2. Zaman Hesaplamaları
    DateTime eklenmeZamani = _geriyeDonukMu ? _secilenTarih : DateTime.now();

    // Raf ömrüne göre SKT hesapla (Artık dinamik gelen _secilenUrunRafOmru kullanılıyor)
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

  Future<void> _logKaydet(String isim, int adet) async {
    try {
      // Hafızadan aktif kullanıcıyı alıyoruz
      final prefs = await SharedPreferences.getInstance();
      String kullanici =
          prefs.getString('aktifKullanici') ?? 'Bilinmeyen Kullanıcı';

      // Firestore'a logu gönderiyoruz
      await FirebaseFirestore.instance.collection('imha_loglari').add({
        'kullanici': kullanici,
        'urun': isim,
        'adet': adet,
        'tarih': DateTime.now(),
      });

      // Geliştirici konsoluna başarılı yazısı düşürelim ki çalıştığını görelim
      debugPrint("Başarılı: $isim loglandı!");
    } catch (e) {
      debugPrint("Log kaydetme hatası: $e");
    }
  }

  // --- GÜNCELLENMİŞ TOPLU İMHA FONKSİYONU ---
  Future<void> _imhaEt(String id, String isim, int mevcutAdet) async {
    // 1. Veritabanında durumu güncelle
    await FirebaseFirestore.instance.collection('pastalar').doc(id).update({
      'durum': 'İmha Edildi',
      'adet': 0,
    });

    // 2. YENİ EKLENEN KISIM: İşlem biter bitmez logu kaydet!
    await _logKaydet(isim, mevcutAdet);

    // 3. Arayüz bildirimleri (SnackBar)
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
            // Geri alınırsa durumu düzeltiyoruz (İstersen buraya log silme de eklenebilir)
            await FirebaseFirestore.instance
                .collection('pastalar')
                .doc(id)
                .update({'durum': 'Rafta', 'adet': mevcutAdet});
          },
        ),
      ),
    );
  }

  // --- GÜNCELLENMİŞ TEKLİ İMHA FONKSİYONU ---
  Future<void> _tekliImhaEt(String id, String isim, int mevcutAdet) async {
    if (mevcutAdet > 0) {
      int yeniAdet = mevcutAdet - 1;
      String yeniDurum = yeniAdet == 0 ? 'İmha Edildi' : 'Rafta';

      // 1. Veritabanında adedi güncelle
      await FirebaseFirestore.instance.collection('pastalar').doc(id).update({
        'adet': yeniAdet,
        'durum': yeniDurum,
      });

      // 2. YENİ EKLENEN KISIM: 1 adet imha edildiğini loglara kaydet!
      await _logKaydet(isim, 1);

      // 3. Arayüz bildirimleri (SnackBar)
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
              await FirebaseFirestore.instance
                  .collection('pastalar')
                  .doc(id)
                  .update({'durum': 'Rafta', 'adet': mevcutAdet});
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
                      // Seçilen ürünün dökümanından raf ömrünü alıyoruz
                      var secilenDoc = katalogItems.firstWhere(
                        (d) => d['isim'] == val,
                      );
                      _secilenUrunRafOmru = secilenDoc['rafOmruGun'];
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
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var pastalar = snapshot.data!.docs;

        if (pastalar.isEmpty) {
          return const Center(child: Text("Rafta ürün yok."));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pastalar.length,
          itemBuilder: (context, index) {
            var p = pastalar[index];
            DateTime skt = (p['sktZamani'] as Timestamp).toDate();
            Duration kalanSure = skt.difference(DateTime.now());

            Color kartRengi = Colors.white;
            String durumMesaji = "";
            if (kalanSure.isNegative) {
              kartRengi = Colors.grey.shade300;
              durumMesaji = "SKT GEÇTİ!";
            } else if (kalanSure.inHours < 2) {
              kartRengi = Colors.red.shade100;
              durumMesaji = "2 SAAT KALDI!";
            } else if (kalanSure.inHours < 12) {
              kartRengi = Colors.orange.shade100;
              durumMesaji = "12 SAAT KALDI!";
            }

            return Card(
              color: kartRengi,
              child: ListTile(
                title: Text(
                  p['isim'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Adet: ${p['adet']} | SKT: ${DateFormat('dd/MM HH:mm').format(skt)}\n$durumMesaji',
                ),
                // --- DEĞİŞTİRİLEN KOD: Butonların Yan Yana Geldiği Kısım ---
                trailing: Row(
                  mainAxisSize:
                      MainAxisSize.min, // Sadece gerektiği kadar yer kapla
                  children: [
                    // 1. Buton: Tekli İmha Butonu (Eksi İkonu)
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.orange,
                        size: 28,
                      ),
                      tooltip: '1 Adet İmha Et', // Üzerine gelince çıkacak yazı
                      onPressed: () => _tekliImhaEt(p.id, p['isim'], p['adet']),
                    ),

                    // 2. Buton: Toplu İmha Butonu (Mevcut Çöp Kutusu İkonu)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                        size: 30,
                      ),
                      tooltip: 'Tümünü İmha Et', // Üzerine gelince çıkacak yazı
                      onPressed: () => _imhaEt(p.id, p['isim'], p['adet']),
                    ),
                  ],
                ),
                // -----------------------------------------------------------
              ),
            );
          },
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
