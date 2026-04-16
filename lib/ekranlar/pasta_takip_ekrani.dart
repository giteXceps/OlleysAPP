import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PastaTakipEkrani extends StatefulWidget {
  const PastaTakipEkrani({super.key});

  @override
  State<PastaTakipEkrani> createState() => _PastaTakipEkraniState();
}

class _PastaTakipEkraniState extends State<PastaTakipEkrani> {
  // GERÇEK ÜRÜN LİSTESİ VE GÜN BAZINDA RAF ÖMÜRLERİ
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

  Future<void> _rafaEkle() async {
    if (_secilenUrun == null || _adetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ürün seçin ve adet girin!')),
      );
      return;
    }

    // Seçilen ürünün katalog bilgilerini alalım
    var urunBilgisi = _urunKatalogu.firstWhere(
      (element) => element['isim'] == _secilenUrun,
    );
    int rafOmruGun = urunBilgisi['rafOmruGun'];

    // SKT Hesaplama: Şu anki zaman + Raf Ömrü (Gün)
    DateTime eklenme = DateTime.now();
    DateTime skt = eklenme.add(Duration(days: rafOmruGun));

    await FirebaseFirestore.instance.collection('pastalar').add({
      'isim': _secilenUrun,
      'adet': int.tryParse(_adetController.text) ?? 0,
      'ilkAdet':
          int.tryParse(_adetController.text) ?? 0, // Yönetici analizi için
      'eklenmeZamani': eklenme,
      'sktZamani': skt,
      'durum': 'Rafta',
      'satilanAdet': 0, // Başlangıçta hiç satılmadı
    });

    setState(() {
      _secilenUrun = null;
      _adetController.clear();
    });
  }

  // SATILDI BUTONU: Adedi 1 azaltır, satılan adet sayısını 1 artırır
  Future<void> _satildiIsaretle(
    String id,
    int mevcutAdet,
    int toplamSatilan,
  ) async {
    if (mevcutAdet > 0) {
      await FirebaseFirestore.instance.collection('pastalar').doc(id).update({
        'adet': mevcutAdet - 1,
        'satilanAdet': toplamSatilan + 1,
        'durum': (mevcutAdet - 1) == 0 ? 'Tükendi' : 'Rafta',
      });
    }
  }

  // İMHA ET BUTONU: Çöpe giden ürün
  Future<void> _imhaEt(String id) async {
    await FirebaseFirestore.instance.collection('pastalar').doc(id).update({
      'durum': 'İmha Edildi',
      'adet': 0,
    });
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

            // Ürün Seçim Listesi (Dropdown)
            DropdownButtonFormField<String>(
              value: _secilenUrun,
              hint: const Text('Ürün Seçin'),
              isExpanded: true, // Yazıların sığması için genişlet
              items: _urunKatalogu
                  .map(
                    (u) => DropdownMenuItem(
                      value: u['isim'] as String,
                      child: Text(
                        u['isim'] as String,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                labelText: 'Vitrine Konan Adet',
                border: OutlineInputBorder(),
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

    // ... (Önceki kodun üst kısımları aynı)

    Widget listeAlani = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pastalar')
          .where('durum', isEqualTo: 'Rafta')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var pastalar = snapshot.data!.docs;
        if (pastalar.isEmpty)
          return const Center(child: Text('Rafta ürün yok.'));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pastalar.length,
          itemBuilder: (context, index) {
            var p = pastalar[index];
            DateTime skt = (p['sktZamani'] as Timestamp).toDate();

            // --- RENK MANTIĞI BURADA ---
            Duration kalanSure = skt.difference(DateTime.now());
            Color kartRengi = Colors.white; // Varsayılan
            String durumMesaji = "";

            if (kalanSure.isNegative) {
              kartRengi = Colors.grey.shade300; // Süresi geçmiş
              durumMesaji = "SÜRESİ DOLDU!";
            } else if (kalanSure.inHours < 2) {
              kartRengi = Colors.red.shade100; // Kritik (Son 2 saat)
              durumMesaji = "ACİL KALDIRIN!";
            } else if (kalanSure.inHours < 12) {
              kartRengi = Colors.orange.shade100; // Uyarı (Son 12 saat)
              durumMesaji = "Bugün imha edilecek";
            }
            // ---------------------------

            String formatliSkt =
                "${skt.day}/${skt.month} ${skt.hour}:${skt.minute.toString().padLeft(2, '0')}";

            return Card(
              color: kartRengi, // Dinamik renk burada uygulanıyor
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(
                  p['isim'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kalan Adet: ${p['adet']}'),
                    Text(
                      'SKT: $formatliSkt',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (durumMesaji.isNotEmpty)
                      Text(
                        durumMesaji,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () =>
                          _satildiIsaretle(p.id, p['adet'], p['satilanAdet']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () => _imhaEt(p.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // ... (Geri kalanı aynı)

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
                  Expanded(flex: 1, child: formAlani),
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
