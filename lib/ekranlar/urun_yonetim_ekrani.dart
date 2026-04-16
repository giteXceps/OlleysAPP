import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UrunYonetimEkrani extends StatefulWidget {
  const UrunYonetimEkrani({super.key});

  @override
  State<UrunYonetimEkrani> createState() => _UrunYonetimEkraniState();
}

class _UrunYonetimEkraniState extends State<UrunYonetimEkrani> {
  final TextEditingController _isimController = TextEditingController();
  final TextEditingController _omurController = TextEditingController();

  // Koleksiyon adı: urun_katalogu. Değişken adı: _urunlerRef
  final CollectionReference _urunlerRef = FirebaseFirestore.instance.collection(
    'urun_katalogu',
  );

  void _urunEkle() async {
    String isim = _isimController.text.trim();
    int? omur = int.tryParse(_omurController.text);

    if (isim.isEmpty || omur == null) {
      _mesajGoster("Lütfen geçerli bir isim ve gün girin!", Colors.orange);
      return;
    }

    // BURASI DÜZELTİLDİ: _urunRef yerine _urunlerRef kullanıldı
    await _urunlerRef.add({
      'isim': isim,
      'rafOmruGun': omur,
      'olusturmaZamani': FieldValue.serverTimestamp(),
    });

    _isimController.clear();
    _omurController.clear();
    _mesajGoster("Yeni ürün kataloğa eklendi!", Colors.green);
  }

  void _urunSil(String id) {
    // BURASI DÜZELTİLDİ: _urunRef yerine _urunlerRef kullanıldı
    _urunlerRef.doc(id).delete();
  }

  void _mesajGoster(String mesaj, Color renk) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: renk));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Katalog Yönetimi'),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ÜST KISIM: EKLEME FORMU
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _isimController,
                      decoration: const InputDecoration(
                        labelText: 'Pasta İsmi (Örn: San Sebastian)',
                      ),
                    ),
                    TextField(
                      controller: _omurController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Raf Ömrü (Gün)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _urunEkle,
                      icon: const Icon(Icons.add),
                      label: const Text("Kataloğa Ekle"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          // ALT KISIM: MEVCUT KATALOG LİSTESİ
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // BURASI DÜZELTİLDİ: _urunRef yerine _urunlerRef kullanıldı
              stream: _urunlerRef.orderBy('isim').snapshots(),
              builder: (context, snapshot) {
                // BURASI DÜZELTİLDİ: if bloğu süslü parantez içine alındı
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var urunler = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: urunler.length,
                  itemBuilder: (context, index) {
                    var u = urunler[index];
                    return ListTile(
                      title: Text(u['isim']),
                      subtitle: Text("Raf Ömrü: ${u['rafOmruGun']} Gün"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _urunSil(u.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
