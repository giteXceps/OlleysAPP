import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PastaTakipEkrani extends StatefulWidget {
  const PastaTakipEkrani({super.key});

  @override
  State<PastaTakipEkrani> createState() => _PastaTakipEkraniState();
}

class _PastaTakipEkraniState extends State<PastaTakipEkrani> {
  final List<Map<String, dynamic>> _urunKatalogu = [
    {'isim': 'Limonlu cheesecake', 'rafOmruGun': 4},
    {'isim': 'Frambuazlı cheesecake', 'rafOmruGun': 4},
    {'isim': 'Bitter çikolatalı profiterol', 'rafOmruGun': 4},
    {'isim': 'Beyaz çikolatalı profiterol', 'rafOmruGun': 4},
    {'isim': 'Cocostar', 'rafOmruGun': 4},
    {'isim': 'Cocomare', 'rafOmruGun': 4},
    {'isim': 'Orman meyveli pasta', 'rafOmruGun': 3},
    {'isim': 'Yaban mersinli pasta', 'rafOmruGun': 3},
    {'isim': 'Red velvet', 'rafOmruGun': 4},
    {'isim': 'Red love', 'rafOmruGun': 4},
    {'isim': 'Gökkuşağı pasta (carnaval)', 'rafOmruGun': 4},
    {'isim': 'Devils pasta', 'rafOmruGun': 5},
    {'isim': 'Mozaik pasta', 'rafOmruGun': 7},
    {'isim': 'Magnolia', 'rafOmruGun': 3},
    {'isim': 'Tiramisu', 'rafOmruGun': 3},
    {'isim': 'Brownie', 'rafOmruGun': 7},
    {'isim': 'İzmir bombası', 'rafOmruGun': 5},
    {'isim': 'Tartolet', 'rafOmruGun': 3},
    {'isim': 'Sandviç', 'rafOmruGun': 3},
    {'isim': 'Simit', 'rafOmruGun': 2},
  ];

  String? _secilenUrun;
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
    if (_secilenUrun == null || _adetController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Eksik bilgi!')));
      return;
    }

    var urunBilgisi = _urunKatalogu.firstWhere(
      (e) => e['isim'] == _secilenUrun,
    );
    DateTime eklenmeZamani = _geriyeDonukMu ? _secilenTarih : DateTime.now();
    DateTime skt = eklenmeZamani.add(Duration(days: urunBilgisi['rafOmruGun']));

    await FirebaseFirestore.instance.collection('pastalar').add({
      'isim': _secilenUrun,
      'adet': int.tryParse(_adetController.text) ?? 0,
      'ilkAdet': int.tryParse(_adetController.text) ?? 0,
      'eklenmeZamani': eklenmeZamani,
      'sktZamani': skt,
      'durum': 'Rafta',
      'satilanAdet': 0,
    });

    setState(() {
      _secilenUrun = null;
      _adetController.clear();
      _geriyeDonukMu = false;
      _secilenTarih = DateTime.now();
    });
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
          // BURASI ÖNEMLİ: Content içine Column ve Progress bar ekliyoruz
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$isim satıldı. (Kalan: ${mevcutAdet - 1})'),
              const SizedBox(height: 8),
              // ZAMAN ÇUBUĞU ANİMASYONU
              TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 10),
                tween: Tween(begin: 1.0, end: 0.0), // 1'den 0'a doğru azalsın
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.yellow,
                    ),
                    minHeight: 2, // Çubuğun kalınlığı
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

  // --- GÜNCELLENMİŞ İMHA ET FONKSİYONU (ZAMAN ÇUBUKLU) ---
  Future<void> _imhaEt(String id, String isim, int mevcutAdet) async {
    // 1. Önce işlemi yap (Durumu değiştir ve adedi sıfırla)
    await FirebaseFirestore.instance.collection('pastalar').doc(id).update({
      'durum': 'İmha Edildi',
      'adet': 0,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).clearSnackBars(); // Varsa eski bildirimleri temizle

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        backgroundColor:
            Colors.red.shade900, // İmha işlemi için daha koyu kırmızı
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$isim imha edildi. Kayıtlar güncellendi.'),
            const SizedBox(height: 8),
            // ZAMAN ÇUBUĞU ANİMASYONU
            TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 10),
              tween: Tween(
                begin: 1.0,
                end: 0.0,
              ), // 1.0'dan (dolu) 0.0'a (boş) doğru
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 2,
                );
              },
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'GERİ AL',
          textColor: Colors.white,
          onPressed: () async {
            // Geri ala basılırsa eski adediyle tekrar Rafta yap
            await FirebaseFirestore.instance
                .collection('pastalar')
                .doc(id)
                .update({'durum': 'Rafta', 'adet': mevcutAdet});
          },
        ),
      ),
    );
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
            DropdownButtonFormField<String>(
              value: _secilenUrun,
              hint: const Text('Ürün Seçin'),
              isExpanded: true,
              items: _urunKatalogu
                  .map(
                    (u) => DropdownMenuItem(
                      value: u['isim'] as String,
                      child: Text(u['isim']),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _secilenUrun = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
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
      // SKT'si yakın olan en üstte
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
              durumMesaji = "SÜRESİ DOLDU!";
            } else if (kalanSure.inHours < 2) {
              kartRengi = Colors.red.shade100;
              durumMesaji = "ACİL KALDIRIN!";
            } else if (kalanSure.inHours < 12) {
              kartRengi = Colors.orange.shade100;
              durumMesaji = "Bugün son!";
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Yazar Kasa İkonu (İsim eklendi)
                    IconButton(
                      icon: const Icon(
                        Icons.point_of_sale,
                        color: Colors.green,
                        size: 30,
                      ),
                      onPressed: () => _satildiIsaretle(
                        p.id,
                        p['isim'],
                        p['adet'],
                        p['satilanAdet'],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Çöp Kutusu İkonu (İsim eklendi)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                        size: 30,
                      ),
                      onPressed: () => _imhaEt(p.id, p['isim'], p['adet']),
                    ),
                  ],
                ),
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
