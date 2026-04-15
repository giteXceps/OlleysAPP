import 'package:flutter/material.dart';

class PastaTakipEkrani extends StatefulWidget {
  const PastaTakipEkrani({super.key});

  @override
  State<PastaTakipEkrani> createState() => _PastaTakipEkraniState();
}

class _PastaTakipEkraniState extends State<PastaTakipEkrani> {
  // Metin kutularını okumak için kontrolcüler
  final TextEditingController _pastaAdiController = TextEditingController();
  final TextEditingController _gelenMiktarController = TextEditingController();
  final TextEditingController _fireMiktarController = TextEditingController();

  // Günlük girilen pastaları geçici olarak tutacağımız liste
  final List<Map<String, String>> _gunlukKayitlar = [];

  void _kaydiEkle() {
    if (_pastaAdiController.text.isEmpty ||
        _gelenMiktarController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen en azından pasta adını ve gelen miktarı girin!',
          ),
        ),
      );
      return; // Alanlar boşsa kaydetme işlemini durdur
    }

    // Listeye yeni veriyi ekle ve ekranı güncelle (setState)
    setState(() {
      _gunlukKayitlar.add({
        'isim': _pastaAdiController.text,
        'gelen': _gelenMiktarController.text,
        'fire': _fireMiktarController.text.isEmpty
            ? '0'
            : _fireMiktarController.text,
        'saat': '${DateTime.now().hour}:${DateTime.now().minute}',
      });
    });

    // Kayıt sonrası kutuları temizle
    _pastaAdiController.clear();
    _gelenMiktarController.clear();
    _fireMiktarController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text('Günlük Pasta Takibi'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SOL TARAF: Veri Giriş Formu (Ekranın 1/3'ünü kaplar)
            Expanded(
              flex: 1,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Yeni Kayıt Gir',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _pastaAdiController,
                        decoration: const InputDecoration(
                          labelText: 'Pasta Türü (Örn: San Sebastian)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _gelenMiktarController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Vitrine Giren Miktar',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _fireMiktarController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Çöpe Atılan (Fire) Miktar',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _kaydiEkle,
                          icon: const Icon(Icons.save),
                          label: const Text(
                            'Sisteme Kaydet',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            // SAĞ TARAF: Günlük Kayıt Listesi (Ekranın 2/3'ünü kaplar)
            Expanded(
              flex: 2,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bugünün Kayıtları',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: _gunlukKayitlar.isEmpty
                            ? const Center(
                                child: Text(
                                  'Henüz bir kayıt girilmedi.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _gunlukKayitlar.length,
                                itemBuilder: (context, index) {
                                  var kayit = _gunlukKayitlar[index];
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.pink,
                                      child: Icon(
                                        Icons.cake,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      kayit['isim']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Gelen: ${kayit['gelen']} adet  |  Fire: ${kayit['fire']} adet',
                                    ),
                                    trailing: Text(
                                      kayit['saat']!,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
