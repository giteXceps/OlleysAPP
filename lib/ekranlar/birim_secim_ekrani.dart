import 'package:flutter/material.dart';
import 'coffee_go_ana_ekrani.dart';
import 'coffee_go_analiz_ekrani.dart';
import 'giris_ekrani.dart';
import 'urun_yonetim_ekrani.dart'; // Yeni oluşturduğumuz ekranı içe aktarıyoruz

class BirimSecimEkrani extends StatelessWidget {
  final String yetki;
  final String? hedefBirim;

  const BirimSecimEkrani({super.key, required this.yetki, this.hedefBirim});

  @override
  Widget build(BuildContext context) {
    // --- GÖRÜNÜRLÜK MANTIĞI ---

    // Coffee Go ana işlemlerine erişim (Genel yetki veya Coffee Go birimi ise)
    bool coffeeGoGorsun = yetki == 'genel' || hedefBirim == 'Coffee Go';

    // Analiz ekranına erişim (Genel yetki veya birim yöneticisi ise)
    bool analizGorsun =
        yetki == 'genel' || (yetki == 'birim' && hedefBirim == 'Coffee Go');

    // Ürün Kataloğu Yönetimi (Yöneticiler için: Genel veya Birim Yöneticisi)
    // Bar müdürü 'birim' yetkisiyle geldiği için bu şartı sağladık.
    bool katalogGorsun = yetki == 'genel' || yetki == 'birim';

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
              // 1. COFFEE GO İŞLEMLERİ (Personel ve Yönetici)
              if (coffeeGoGorsun)
                _birimKarti(
                  context,
                  baslik: 'Coffee Go İşlemleri',
                  ikon: Icons.coffee,
                  renk: Colors.brown,
                  sayfa: const CoffeeGoAnaEkrani(),
                ),

              // 2. COFFEE GO ANALİZ (Sadece Yöneticiler)
              if (analizGorsun)
                _birimKarti(
                  context,
                  baslik: 'Coffee Go Analiz',
                  ikon: Icons.analytics,
                  renk: Colors.blueGrey,
                  sayfa: const CoffeeGoAnalizEkrani(),
                ),

              // 3. ÜRÜN KATALOG YÖNETİMİ (Bar Müdürü / Yöneticiler)
              // Burası yeni eklediğimiz kısım!
              if (katalogGorsun)
                _birimKarti(
                  context,
                  baslik: 'Ürün Kataloğunu Yönet',
                  ikon: Icons.settings_suggest,
                  renk: Colors.teal,
                  sayfa: const UrunYonetimEkrani(),
                ),

              // 4. BOWLING (Sadece Genel Yönetici)
              if (yetki == 'genel')
                _birimKarti(
                  context,
                  baslik: 'Bowling',
                  ikon: Icons.sports_score,
                  renk: Colors.grey,
                  sayfa: null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Kart Tasarımı Yardımcı Fonksiyonu
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
