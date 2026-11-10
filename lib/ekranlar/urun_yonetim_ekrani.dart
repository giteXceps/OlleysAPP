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
  bool _ekleniyor = false;

  final CollectionReference _urunlerRef = FirebaseFirestore.instance.collection(
    'urun_katalogu',
  );

  @override
  void dispose() {
    _isimController.dispose();
    _omurController.dispose();
    super.dispose();
  }

  Future<void> _urunEkle() async {
    String isim = _isimController.text.trim();
    int? omur = int.tryParse(_omurController.text);

    if (isim.isEmpty || omur == null || omur <= 0) {
      _mesajGoster("Lütfen geçerli bir isim ve pozitif gün girin!", Colors.orange);
      return;
    }

    setState(() => _ekleniyor = true);

    try {
      // Mükerrer ürün kontrolü
      final existing = await _urunlerRef.where('isim', isEqualTo: isim).get();
      if (existing.docs.isNotEmpty) {
        if (!mounted) return;
        _mesajGoster("Bu isimde bir ürün zaten katalogda var!", Colors.orange);
        return;
      }

      await _urunlerRef.add({
        'isim': isim,
        'rafOmruGun': omur,
        'olusturmaZamani': FieldValue.serverTimestamp(),
      });

      _isimController.clear();
      _omurController.clear();
      if (!mounted) return;
      _mesajGoster("Yeni ürün kataloğa eklendi!", Colors.green);
    } catch (e) {
      if (mounted) _mesajGoster("Ekleme hatası: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _ekleniyor = false);
    }
  }

  void _urunSilOnay(String id, String isim) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Sil?'),
        content: Text('$isim katalogdan silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _urunlerRef.doc(id).delete();
                if (!mounted) return;
                _mesajGoster('$isim katalogdan silindi.', Colors.red);
              } catch (e) {
                if (!mounted) return;
                _mesajGoster('Silme hatası: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('SİL'),
          ),
        ],
      ),
    );
  }

  void _mesajGoster(String mesaj, Color renk) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
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
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _isimController,
                      decoration: const InputDecoration(
                        labelText: 'Pasta / Tatlı İsmi (Örn: San Sebastian)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _omurController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Raf Ömrü (Gün)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timelapse),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _ekleniyor ? null : _urunEkle,
                        icon: _ekleniyor
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: const Text("Kataloğa Ekle", style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                        ),
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
              stream: _urunlerRef.orderBy('isim').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Katalogda henüz ürün bulunmuyor."));
                }

                var urunler = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: urunler.length,
                  itemBuilder: (context, index) {
                    var u = urunler[index];
                    final String isim = u['isim'] ?? 'İsimsiz';
                    final int omur = u['rafOmruGun'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.brown[50],
                          child: const Icon(Icons.cake, color: Colors.brown),
                        ),
                        title: Text(isim, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Raf Ömrü: $omur Gün"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Sil',
                          onPressed: () => _urunSilOnay(u.id, isim),
                        ),
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
