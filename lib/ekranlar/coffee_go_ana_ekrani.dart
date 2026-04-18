import 'package:flutter/material.dart';
import 'pasta_takip_ekrani.dart';
import 'demleme_ekrani.dart';
import 'giris_ekrani.dart';
import 'dolap_sicaklik_ekrani.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const GirisEkrani()),
                (route) => false,
              );
            },
          ),
        ],
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
              baslik: 'Pasta Takibi',
              ikon: Icons.cake,
              renk: Colors.pink,
              aciklama: 'Günlük taze girişleri ve SKT/Fire durumlarını kaydet.',
              sayfa: const PastaTakipEkrani(),
            ),
            _islemKarti(
              context,
              baslik: 'Dolap Sıcaklığı',
              ikon: Icons.ac_unit,
              renk: Colors.blue,
              aciklama: 'Dolap sıcaklıklarını kaydet ve günlük takip et.',
              sayfa: const DolapSicaklikEkrani(), // null yerine bu
            ),
            _islemKarti(
              context,
              baslik: 'Filtre Kahve',
              ikon: Icons.coffee_maker,
              renk: Colors.brown,
              aciklama: 'Demleme yaptığında kaydet, tazelik durumunu takip et.',
              sayfa: const DemlemeEkrani(tip: Demlemetipi.filtre),
            ),
            _islemKarti(
              context,
              baslik: 'Çay Demleme',
              ikon: Icons.local_drink,
              renk: Colors.deepOrange,
              aciklama: 'Demleme yaptığında kaydet, tazelik durumunu takip et.',
              sayfa: const DemlemeEkrani(tip: Demlemetipi.cay),
            ),
          ],
        ),
      ),
    );
  }

  Widget _islemKarti(
    BuildContext context, {
    required String baslik,
    required IconData ikon,
    required Color renk,
    required String aciklama,
    required Widget? sayfa,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (sayfa != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => sayfa),
            );
          } else {
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
