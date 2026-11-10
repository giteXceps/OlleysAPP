import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tema/app_theme.dart';
import 'coffee_go_ana_ekrani.dart';
import 'coffee_go_analiz_ekrani.dart';
import 'demleme_analiz_ekrani.dart';
import 'giris_ekrani.dart';
import 'toplu_satis_ekrani.dart';
import 'urun_yonetim_ekrani.dart';
import 'imha_loglari_ekrani.dart';
import 'satis_loglari_ekrani.dart';

class BirimSecimEkrani extends StatelessWidget {
  final String yetki; // 'genel' veya 'birim'
  final String? hedefBirim;

  const BirimSecimEkrani({super.key, required this.yetki, this.hedefBirim});

  @override
  Widget build(BuildContext context) {
    final bool yetkili =
        yetki == 'genel' || (yetki == 'birim' && hedefBirim == 'Coffee Go');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Yönetim Masası & Modüller'),
        backgroundColor: AppTheme.executivePrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Çıkış Yap',
            onPressed: () => _cikisYap(context),
          ),
        ],
      ),
      body: yetkili
          ? SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── ÜST YÖNETİCİ KARTI ────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E1B4B).withOpacity(0.25),
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
                                Icons.admin_panel_settings_rounded,
                                size: 36,
                                color: Color(0xFF818CF8),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Yönetici Masası',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4F46E5),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          yetki == 'genel' ? 'Genel Yetki' : 'Birim Yetkisi',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Coffee Go operasyonel kontrolleri, analizler ve kayıt denetimi.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFC7D2FE),
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
                        'Modüller & Raporlar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── MODÜL KARTLARI ───────────────────────────
                      GridView.extent(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        maxCrossAxisExtent: 260,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.05,
                        children: [
                          _birimKarti(
                            context,
                            baslik: 'Coffee Go Barista',
                            altBaslik: 'Günlük Personel İşlemleri',
                            ikon: Icons.coffee_rounded,
                            renk: AppTheme.espresso,
                            bgRenk: const Color(0xFFFBF4ED),
                            sayfa: const CoffeeGoAnaEkrani(),
                          ),
                          _birimKarti(
                            context,
                            baslik: 'Satış & Fire Analizi',
                            altBaslik: 'Verimlilik & Ürün Raporu',
                            ikon: Icons.insights_rounded,
                            renk: const Color(0xFF4338CA),
                            bgRenk: const Color(0xFFEEF2FF),
                            sayfa: const CoffeeGoAnalizEkrani(),
                          ),
                          _birimKarti(
                            context,
                            baslik: 'Gün Sonu Satış Girişi',
                            altBaslik: 'Raftan Toplu Düşüm',
                            ikon: Icons.point_of_sale_rounded,
                            renk: AppTheme.posPrimary,
                            bgRenk: AppTheme.posBg,
                            sayfa: const TopluSatisEkrani(),
                          ),
                          _birimKarti(
                            context,
                            baslik: 'Demleme Analizi',
                            altBaslik: 'Son 7 Gün İstatistikleri',
                            ikon: Icons.local_cafe_rounded,
                            renk: AppTheme.teaPrimary,
                            bgRenk: AppTheme.teaBg,
                            sayfa: const DemlemeAnalizEkrani(),
                          ),
                          _birimKarti(
                            context,
                            baslik: 'Ürün Kataloğu',
                            altBaslik: 'Tatlı & Raf Ömrü Ayarları',
                            ikon: Icons.inventory_2_rounded,
                            renk: const Color(0xFFB45309),
                            bgRenk: const Color(0xFFFEF3C7),
                            sayfa: const UrunYonetimEkrani(),
                          ),
                          _birimKarti(
                            context,
                            baslik: 'İmha Logları',
                            altBaslik: 'SKT & Zayiat Geçmişi',
                            ikon: Icons.auto_delete_rounded,
                            renk: const Color(0xFFB91C1C),
                            bgRenk: const Color(0xFFFEF2F2),
                            sayfa: const ImhaLoglariEkrani(),
                          ),
                          _birimKarti(
                            context,
                            baslik: 'Satış Logları',
                            altBaslik: 'Kasiyer Satış Geçmişi',
                            ikon: Icons.receipt_long_rounded,
                            renk: const Color(0xFF0F766E),
                            bgRenk: const Color(0xFFCCFBF1),
                            sayfa: const SatisLoglariEkrani(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const Center(
              child: Text(
                'Bu hesabın yetkisi için tanımlı birim bulunamadı.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
    );
  }

  void _cikisYap(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yapılsın mı?'),
        content: const Text('Oturum kapatılarak giriş ekranına dönülecek.'),
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

  Widget _birimKarti(
    BuildContext context, {
    required String baslik,
    required String altBaslik,
    required IconData ikon,
    required Color renk,
    required Color bgRenk,
    Widget? sayfa,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: bgRenk,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: renk.withOpacity(0.2), width: 1.5),
                  ),
                  child: Icon(ikon, size: 28, color: renk),
                ),
                const SizedBox(height: 14),
                Text(
                  baslik,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  altBaslik,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
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
