import 'package:flutter/material.dart';
import 'coffee_go_ana_ekrani.dart';
import 'coffee_go_analiz_ekrani.dart';
import 'demleme_analiz_ekrani.dart'; // YENİ
import 'giris_ekrani.dart';
import 'toplu_satis_ekrani.dart';
import 'urun_yonetim_ekrani.dart';

class BirimSecimEkrani extends StatelessWidget {
  final String yetki;
  final String? hedefBirim;

  const BirimSecimEkrani({super.key, required this.yetki, this.hedefBirim});

  @override
  Widget build(BuildContext context) {
    // --- GÖRÜNÜRLÜK MANTIĞI ---
    bool coffeeGoGorsun = yetki == 'genel' || hedefBirim == 'Coffee Go';
    bool analizGorsun =
        yetki == 'genel' || (yetki == 'birim' && hedefBirim == 'Coffee Go');
    bool topluSatisGorsun =
        yetki == 'genel' || (yetki == 'birim' && hedefBirim == 'Coffee Go');
    bool katalogGorsun = yetki == 'genel' || yetki == 'birim';
    bool demlemeAnalizGorsun =
        yetki == 'genel' || (yetki == 'birim' && hedefBirim == 'Coffee Go');

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Panel | Birim Seçimi'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Çıkış Yap',
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              if (coffeeGoGorsun)
                _birimKarti(
                  context,
                  baslik: 'Coffee Go İşlemleri',
                  ikon: Icons.coffee,
                  renk: Colors.brown,
                  sayfa: const CoffeeGoAnaEkrani(),
                ),

              if (analizGorsun)
                _birimKarti(
                  context,
                  baslik: 'Coffee Go Analiz',
                  ikon: Icons.analytics,
                  renk: Colors.blueGrey,
                  sayfa: const CoffeeGoAnalizEkrani(),
                ),

              if (topluSatisGorsun)
                _birimKarti(
                  context,
                  baslik: 'Gün Sonu Satış Girişi',
                  ikon: Icons.playlist_add_check,
                  renk: Colors.teal[700]!,
                  sayfa: const TopluSatisEkrani(),
                ),

              if (demlemeAnalizGorsun)
                _birimKarti(
                  context,
                  baslik: 'Demleme Analizi',
                  ikon: Icons.local_cafe,
                  renk: Colors.deepOrange[700]!,
                  sayfa: const DemlemeAnalizEkrani(),
                ),

              if (katalogGorsun)
                _birimKarti(
                  context,
                  baslik: 'Ürün Kataloğunu Yönet',
                  ikon: Icons.settings_suggest,
                  renk: Colors.teal,
                  sayfa: const UrunYonetimEkrani(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _birimKarti(
    BuildContext context, {
    required String baslik,
    required IconData ikon,
    required Color renk,
    Widget? sayfa,
  }) {
    return GestureDetector(
      onTap: () {
        if (sayfa != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => sayfa),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bu bölüm henüz aktif değil.')),
          );
        }
      },
      child: Container(
        width: 200,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, size: 40, color: renk),
            const SizedBox(height: 12),
            Text(
              baslik,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
