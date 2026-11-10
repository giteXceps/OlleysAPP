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
  final TextEditingController _sifreController = TextEditingController();
  bool _sifreGizli = true;
  bool _yukleniyor = false;

  @override
  void dispose() {
    _kullaniciAdiController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    String girilenAd = _kullaniciAdiController.text.trim().toLowerCase();
    String girilenSifre = _sifreController.text.trim();

    if (girilenAd.isEmpty || girilenSifre.isEmpty) {
      _mesajGoster("Lütfen kullanıcı adı ve şifre girin.");
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      // Firestore'da kullanıcıyı bul
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('kullaniciAdi', isEqualTo: girilenAd)
          .where('sifre', isEqualTo: girilenSifre)
          .get();

      if (!mounted) return;

      if (userDoc.docs.isNotEmpty) {
        var veri = userDoc.docs.first.data();
        String rol = veri['rol'] ?? '';
        String birim = veri['birim'] ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('aktifKullanici', girilenAd);
        await prefs.setString('aktifRol', rol);
        await prefs.setString('aktifBirim', birim);

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
          } else {
            _mesajGoster("Bu birim için tanımlı işlem paneli bulunamadı: $birim");
          }
        } else {
          _mesajGoster("Tanımsız kullanıcı rolü: $rol");
        }
      } else {
        _mesajGoster("Hatalı kullanıcı adı veya şifre!");
      }
    } catch (e) {
      if (mounted) {
        _mesajGoster("Bağlantı hatası: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  void _mesajGoster(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                const Icon(Icons.coffee, size: 54, color: Colors.brown),
                const SizedBox(height: 12),
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
                  enabled: !_yukleniyor,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  onSubmitted: (_) => _girisYap(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sifreController,
                  obscureText: _sifreGizli,
                  enabled: !_yukleniyor,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _sifreGizli ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _sifreGizli = !_sifreGizli);
                      },
                    ),
                  ),
                  onSubmitted: (_) => _girisYap(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _yukleniyor ? null : _girisYap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                    child: _yukleniyor
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Giriş Yap',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
