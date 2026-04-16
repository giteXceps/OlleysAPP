import 'package:flutter/material.dart';
import 'coffee_go_ana_ekrani.dart';
import 'coffee_go_analiz_ekrani.dart'; // YENİ EKLEDİK

class BirimSecimEkrani extends StatelessWidget {
  const BirimSecimEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Admin Panel | Birim Seçimi'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Wrap(
            // Grid yerine Wrap kullanarak daha esnek bir yapı kurduk
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              // 1. KART: COFFEE GO PERSONEL PANELİ
              _birimKarti(
                context,
                baslik: 'Coffee Go İşlemleri',
                altBaslik: 'Satış, Rafa Ekleme, SKT Takip',
                ikon: Icons.coffee,
                renk: Colors.brown,
                sayfa: const CoffeeGoAnaEkrani(),
              ),

              // 2. KART: COFFEE GO YÖNETİCİ ANALİZİ (YENİ!)
              _birimKarti(
                context,
                baslik: 'Coffee Go Analiz',
                altBaslik: 'Verimlilik, Satış ve Fire Raporları',
                ikon: Icons.analytics,
                renk: Colors.blueGrey,
                sayfa: const CoffeeGoAnalizEkrani(),
              ),

              // Gelecekte eklenecek diğer birimler için yer tutucular
              _birimKarti(
                context,
                baslik: 'Bowling',
                altBaslik: 'Yakında eklenecek...',
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

  Widget _birimKarti(
    BuildContext context, {
    required String baslik,
    required String altBaslik,
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
        width: 250,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, size: 50, color: renk),
            const SizedBox(height: 12),
            Text(
              baslik,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              altBaslik,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
