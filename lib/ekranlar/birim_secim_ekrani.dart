import 'package:flutter/material.dart';
import 'coffee_go_ana_ekrani.dart';
import 'coffee_go_analiz_ekrani.dart';
import 'demleme_analiz_ekrani.dart';
import 'giris_ekrani.dart';
import 'toplu_satis_ekrani.dart';
import 'urun_yonetim_ekrani.dart';

class BirimSecimEkrani extends StatelessWidget {
  final String yetki; // 'genel' veya 'birim'
  final String? hedefBirim;

  const BirimSecimEkrani({super.key, required this.yetki, this.hedefBirim});

  @override
  Widget build(BuildContext context) {
    // Uygulama sadece Coffee Go — genel yönetici her şeyi,
    // birim yöneticisi de Coffee Go'ya atanmışsa aynı şeyi görür.
    final bool yetkili =
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
          child: yetkili
              ? Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    _birimKarti(
                      context,
                      baslik: 'Coffee Go İşlemleri',
                      ikon: Icons.coffee,
                      renk: Colors.brown,
                      sayfa: const CoffeeGoAnaEkrani(),
                    ),
                    _birimKarti(
                      context,
                      baslik: 'Coffee Go Analiz',
                      ikon: Icons.analytics,
                      renk: Colors.blueGrey,
                      sayfa: const CoffeeGoAnalizEkrani(),
                    ),
                    _birimKarti(
                      context,
                      baslik: 'Gün Sonu Satış Girişi',
                      ikon: Icons.playlist_add_check,
                      renk: Colors.teal[700]!,
                      sayfa: const TopluSatisEkrani(),
                    ),
                    _birimKarti(
                      context,
                      baslik: 'Demleme Analizi',
                      ikon: Icons.local_cafe,
                      renk: Colors.deepOrange[700]!,
                      sayfa: const DemlemeAnalizEkrani(),
                    ),
                    _birimKarti(
                      context,
                      baslik: 'Ürün Kataloğunu Yönet',
                      ikon: Icons.settings_suggest,
                      renk: Colors.teal,
                      sayfa: const UrunYonetimEkrani(),
                    ),
                  ],
                )
              : const Center(
                  child: Text(
                    'Bu hesabın yetkisi için tanımlı birim bulunamadı.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
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
