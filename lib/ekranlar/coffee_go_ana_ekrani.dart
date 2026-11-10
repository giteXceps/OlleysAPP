import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../tema/app_theme.dart';
import 'pasta_takip_ekrani.dart';
import 'demleme_ekrani.dart';
import 'giris_ekrani.dart';
import 'dolap_sicaklik_ekrani.dart';

class CoffeeGoAnaEkrani extends StatelessWidget {
  const CoffeeGoAnaEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    double ekranGenisligi = MediaQuery.of(context).size.width;
    int yanYanaKartSayisi = ekranGenisligi > 800 ? 2 : 1;

    final String bugunTarih = DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5), // Sıcak süt köpüğü tonu
      appBar: AppBar(
        title: const Text('Coffee Go Barista İstasyonu'),
        backgroundColor: AppTheme.espresso,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Güvenli Çıkış',
            onPressed: () => _cikisYap(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── ÜST KARŞILAMA KARTI ──────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.mocha, AppTheme.espresso],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.espresso.withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.coffee_rounded,
                          size: 36,
                          color: AppTheme.caramel,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'İyi Çalışmalar, Barista 👋',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bugunTarih,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.caramel,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Hızlı İşlemler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.espresso,
                  ),
                ),
                const SizedBox(height: 14),

                // ── İŞLEM KARTLARI GRİDİ ─────────────────────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: yanYanaKartSayisi,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: ekranGenisligi > 500 ? 2.6 : 2.2,
                  children: [
                    _islemKarti(
                      context,
                      baslik: 'Pasta & Tatlı Takibi',
                      ikon: Icons.cake_rounded,
                      renk: AppTheme.pastryPrimary,
                      arkaplan: AppTheme.pastryBg,
                      aciklama: 'Günlük taze girişleri, SKT durumları ve fire kayıtları.',
                      sayfa: const PastaTakipEkrani(),
                    ),
                    _islemKarti(
                      context,
                      baslik: 'Dolap Sıcaklıkları',
                      ikon: Icons.ac_unit_rounded,
                      renk: AppTheme.arcticPrimary,
                      arkaplan: AppTheme.arcticBg,
                      aciklama: 'Dolap 1 ve 2 sıcaklıklarını kaydet, günlük grafiği izle.',
                      sayfa: const DolapSicaklikEkrani(),
                    ),
                    _islemKarti(
                      context,
                      baslik: 'Filtre Kahve Demleme',
                      ikon: Icons.coffee_maker_rounded,
                      renk: AppTheme.coffeePrimary,
                      arkaplan: AppTheme.coffeeBg,
                      aciklama: 'Demleme saatini kaydet, 90 dakikalık tazeliği canlı takip et.',
                      sayfa: const DemlemeEkrani(tip: Demlemetipi.filtre),
                    ),
                    _islemKarti(
                      context,
                      baslik: 'Çay Demleme',
                      ikon: Icons.local_drink_rounded,
                      renk: AppTheme.teaPrimary,
                      arkaplan: AppTheme.teaBg,
                      aciklama: 'Taze çay saatini kaydet, bayatlama süresini canlı takip et.',
                      sayfa: const DemlemeEkrani(tip: Demlemetipi.cay),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _cikisYap(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yapılsın mı?'),
        content: const Text('Oturumunuz kapatılacak ve giriş ekranına yönlendirileceksiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const GirisEkrani()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('ÇIKIŞ YAP'),
          ),
        ],
      ),
    );
  }

  Widget _islemKarti(
    BuildContext context, {
    required String baslik,
    required IconData ikon,
    required Color renk,
    required Color arkaplan,
    required String aciklama,
    required Widget? sayfa,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (sayfa != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => sayfa),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: arkaplan,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: renk.withOpacity(0.2), width: 1.5),
                  ),
                  child: Icon(ikon, size: 30, color: renk),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        baslik,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        aciklama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textMuted,
                    size: 20,
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
