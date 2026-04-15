import 'package:flutter/material.dart';
import 'pasta_takip_ekrani.dart';

class CoffeeGoAnaEkrani extends StatelessWidget {
  const CoffeeGoAnaEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    double ekranGenisligi = MediaQuery.of(context).size.width;
    int yanYanaKartSayisi = ekranGenisligi > 600 ? 2 : 1;

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text('Olleys Coffee Go Paneli'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: yanYanaKartSayisi,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _islemKarti(
              context,
              'Pasta Takibi',
              Icons.cake,
              Colors.pink,
              'Günlük taze girişleri ve SKT/Fire durumlarını kaydet.',
            ),
            _islemKarti(
              context,
              'Dolap Sıcaklığı',
              Icons.ac_unit,
              Colors.blue,
              '3 saatte bir dolap derecelerini kontrol et ve not al.',
            ),
            _islemKarti(
              context,
              'Filtre Kahve',
              Icons.coffee_maker,
              Colors.brown,
              '3 saatlik demleme döngüsünü başlat ve kaydet.',
            ),
            _islemKarti(
              context,
              'Çay Demleme',
              Icons.local_drink,
              Colors.deepOrange,
              'Taze çay demlendiğinde saatini sisteme gir.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _islemKarti(
    BuildContext context,
    String baslik,
    IconData ikon,
    Color renk,
    String aciklama,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (baslik == 'Pasta Takibi') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PastaTakipEkrani()),
            );
          } else {
            // Diğer butonlar için geçici mesaj
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$baslik sayfası yakında eklenecek...')),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: renk.withOpacity(0.1),
                child: Icon(ikon, size: 40, color: renk),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      baslik,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      aciklama,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
