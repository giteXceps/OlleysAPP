import 'package:flutter/material.dart';
import 'birim_secim_ekrani.dart';
import 'coffee_go_ana_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final TextEditingController _kullaniciAdiController = TextEditingController();

  void _girisYap() {
    // Kullanıcının yazdığı metni al, boşlukları sil ve küçük harfe çevir
    String girilenAd = _kullaniciAdiController.text.trim().toLowerCase();

    if (girilenAd == 'admin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BirimSecimEkrani()),
      );
    } else if (girilenAd == 'personel') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CoffeeGoAnaEkrani()),
      );
    } else {
      // Hatalı girişte alt tarafta uyarı mesajı (SnackBar) çıkar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hatalı giriş! (İpucu: Sadece "admin" veya "personel" yazın)',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Olleys Eğlence Merkezi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Sistem Girişi', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),

              TextField(
                controller: _kullaniciAdiController,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Şifre (Şimdilik Boş Bırakın)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _girisYap, // İŞTE KRİTİK NOKTA BURASI
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Giriş Yap',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
