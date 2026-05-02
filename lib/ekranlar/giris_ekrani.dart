import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'birim_secim_ekrani.dart';
import 'coffee_go_ana_ekrani.dart';
import 'root_yonetim_ekrani.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final TextEditingController _kullaniciAdiController = TextEditingController();
  final TextEditingController _sifreController =
      TextEditingController(); // Şifre için eklendi

  void _girisYap() async {
    String girilenAd = _kullaniciAdiController.text.trim().toLowerCase();
    String girilenSifre = _sifreController.text.trim();

    if (girilenAd.isEmpty || girilenSifre.isEmpty) {
      _mesajGoster("Lütfen kullanıcı adı ve şifre girin.");
      return;
    }

    try {
      // Firestore'da kullanıcıyı bul
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('kullaniciAdi', isEqualTo: girilenAd)
          .where('sifre', isEqualTo: girilenSifre)
          .get();

      if (userDoc.docs.isNotEmpty) {
        var veri = userDoc.docs.first.data();
        String rol = veri['rol'];
        String birim = veri['birim'] ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('aktifKullanici', girilenAd);

        if (!mounted) return;

        // YETKİYE GÖRE YÖNLENDİRME
        if (rol == 'root') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RootYonetimEkrani()),
          );
        } else if (rol == 'genel_yonetici') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const BirimSecimEkrani(yetki: 'genel'),
            ),
          );
        } else if (rol == 'birim_yoneticisi') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BirimSecimEkrani(yetki: 'birim', hedefBirim: birim),
            ),
          );
        } else if (rol == 'personel') {
          if (birim == 'Coffee Go') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CoffeeGoAnaEkrani(),
              ),
            );
          }
        }
      } else {
        _mesajGoster("Hatalı kullanıcı adı veya şifre!");
      }
    } catch (e) {
      _mesajGoster("Bağlantı hatası: $e");
    }
  }

  void _mesajGoster(String mesaj) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: Colors.red));
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
                'Coffee Go | Yönetim',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
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
              TextField(
                controller: _sifreController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _girisYap,
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
