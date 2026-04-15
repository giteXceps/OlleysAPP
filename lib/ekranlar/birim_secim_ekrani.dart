import 'package:flutter/material.dart';
// Coffee Go ekranına geçiş yapabilmek için o dosyayı buraya çağırıyoruz:
import 'coffee_go_ana_ekrani.dart';

class BirimSecimEkrani extends StatelessWidget {
  const BirimSecimEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Birimler (Yönetici Paneli)')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 20,
              children: [
                // Coffee Go Butonu
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CoffeeGoAnaEkrani(),
                      ),
                    );
                  },
                  child: _birimKarti('Coffee Go', Icons.coffee, Colors.brown),
                ),

                // Diğer birimler (Şimdilik tıklanamaz, sadece görüntü)
                _birimKarti('Bowling', Icons.sports_volleyball, Colors.blue),
                _birimKarti('Food Court', Icons.fastfood, Colors.orange),
                _birimKarti('Oyun Parkı', Icons.toys, Colors.green),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _birimKarti(String isim, IconData ikon, Color renk) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        border: Border.all(color: renk, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(ikon, size: 50, color: renk),
          const SizedBox(height: 10),
          Text(
            isim,
            style: TextStyle(
              fontSize: 18,
              color: renk,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
