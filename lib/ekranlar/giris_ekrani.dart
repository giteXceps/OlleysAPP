import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tema/app_theme.dart';
import 'birim_secim_ekrani.dart';
import 'coffee_go_ana_ekrani.dart';
import 'root_yonetim_ekrani.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(mesaj)),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0E08),
              Color(0xFF2C1810),
              Color(0xFF3D2115),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 420,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo / İkon Alanı
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.caramel, AppTheme.mocha],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.caramel.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.coffee_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Başlık & Açıklama
                  const Text(
                    'Olleys Coffee Go',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.espresso,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Personel & Yönetim Giriş Portalı',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Kullanıcı Adı Girişi
                  TextField(
                    controller: _kullaniciAdiController,
                    enabled: !_yukleniyor,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Kullanıcı Adı',
                      hintText: 'örn: barista, mudur',
                      prefixIcon: const Icon(Icons.person_outline, color: AppTheme.mocha),
                      filled: true,
                      fillColor: const Color(0xFFFBF8F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _girisYap(),
                  ),
                  const SizedBox(height: 18),

                  // Şifre Girişi
                  TextField(
                    controller: _sifreController,
                    obscureText: _sifreGizli,
                    enabled: !_yukleniyor,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.mocha),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _sifreGizli ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => setState(() => _sifreGizli = !_sifreGizli),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFBF8F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _girisYap(),
                  ),
                  const SizedBox(height: 28),

                  // Giriş Yap Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.mocha, AppTheme.espresso],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.espresso.withOpacity(0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _yukleniyor ? null : _girisYap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _yukleniyor
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Giriş Yap',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Alt Bilgi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sistem Çevrimiçi & Aktif',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
