import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../tema/app_theme.dart';

class CoffeeGoAnalizEkrani extends StatefulWidget {
  const CoffeeGoAnalizEkrani({super.key});

  @override
  State<CoffeeGoAnalizEkrani> createState() => _CoffeeGoAnalizEkraniState();
}

class _CoffeeGoAnalizEkraniState extends State<CoffeeGoAnalizEkrani> {
  late DateTimeRange _secilenAralik;
  int _seciliFiltreGun = 7; // Aktif seçilen butonun takibi için

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _secilenAralik = DateTimeRange(
      start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  DateTime get _baslangicTarihi {
    final s = _secilenAralik.start;
    return DateTime(s.year, s.month, s.day, 0, 0, 0);
  }

  DateTime get _bitisTarihi {
    final e = _secilenAralik.end;
    return DateTime(e.year, e.month, e.day, 23, 59, 59, 999);
  }

  void _hazirFiltreSet(int gun) {
    final now = DateTime.now();
    final bugun = DateTime(now.year, now.month, now.day);
    setState(() {
      _seciliFiltreGun = gun;
      if (gun == 0) {
        _secilenAralik = DateTimeRange(start: bugun, end: bugun);
      } else {
        _secilenAralik = DateTimeRange(
          start: bugun.subtract(Duration(days: gun - 1)),
          end: bugun,
        );
      }
    });
  }

  Future<void> _ozelAralikSec() async {
    final DateTimeRange? pick = await showDateRangePicker(
      context: context,
      initialDateRange: _secilenAralik,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4338CA),
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pick != null) {
      setState(() {
        _seciliFiltreGun = -1; // Özel aralık seçildi
        _secilenAralik = pick;
      });
    }
  }

  String _tarihFormatla(DateTime tarih) {
    return "${tarih.day.toString().padLeft(2, '0')}/${tarih.month.toString().padLeft(2, '0')}/${tarih.year}";
  }

  @override
  Widget build(BuildContext context) {
    final start = _baslangicTarihi;
    final end = _bitisTarihi;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Satış & Fire Analiz Masası'),
        backgroundColor: const Color(0xFF1E1B4B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── ÜST FİLTRELEME ALANI ─────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Rapor Dönemi: ${_tarihFormatla(_secilenAralik.start)} - ${_tarihFormatla(_secilenAralik.end)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filtreChip("Bugün", 0),
                      const SizedBox(width: 8),
                      _filtreChip("Son 7 Gün", 7),
                      const SizedBox(width: 8),
                      _filtreChip("Son 30 Gün", 30),
                      const SizedBox(width: 8),
                      _filtreChip("Son 90 Gün", 90),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _ozelAralikSec,
                        icon: const Icon(Icons.date_range_rounded, size: 16),
                        label: Text(
                          _seciliFiltreGun == -1 ? "Özel Tarih Seçildi" : "Takvimden Seç",
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4338CA),
                          side: BorderSide(
                            color: _seciliFiltreGun == -1
                                ? const Color(0xFF4338CA)
                                : AppTheme.borderColor,
                            width: _seciliFiltreGun == -1 ? 2 : 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── ANALİZ VERİLERİ (STREAM) ──────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('satis_loglari')
                  .where('tarih', isGreaterThanOrEqualTo: start)
                  .where('tarih', isLessThanOrEqualTo: end)
                  .snapshots(),
              builder: (context, satisSnapshot) {
                if (satisSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (satisSnapshot.hasError) {
                  return Center(
                    child: Text("Satış verileri yüklenirken hata oluştu: ${satisSnapshot.error}"),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('imha_loglari')
                      .where('tarih', isGreaterThanOrEqualTo: start)
                      .where('tarih', isLessThanOrEqualTo: end)
                      .snapshots(),
                  builder: (context, imhaSnapshot) {
                    if (imhaSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (imhaSnapshot.hasError) {
                      return Center(
                        child: Text("İmha verileri yüklenirken hata oluştu: ${imhaSnapshot.error}"),
                      );
                    }

                    // 1. SATIŞLARI HESAPLA
                    int toplamSatilan = 0;
                    final Map<String, int> urunSatislari = {};

                    final satisDocs = satisSnapshot.data?.docs ?? [];
                    for (var doc in satisDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final toplamAdet = (data['toplamAdet'] as num?)?.toInt() ?? 0;
                      toplamSatilan += toplamAdet;

                      final detaylar = data['detaylar'] as Map<String, dynamic>? ?? {};
                      detaylar.forEach((urun, adet) {
                        final adetInt = (adet as num?)?.toInt() ?? 0;
                        urunSatislari[urun] = (urunSatislari[urun] ?? 0) + adetInt;
                      });
                    }

                    // 2. İMHALARI (FİRELERİ) HESAPLA
                    int toplamImha = 0;
                    final Map<String, int> urunFireleri = {};

                    final imhaDocs = imhaSnapshot.data?.docs ?? [];
                    for (var doc in imhaDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final urun = data['urun'] as String? ?? 'Bilinmeyen';
                      final adet = (data['adet'] as num?)?.toInt() ?? 0;

                      toplamImha += adet;
                      urunFireleri[urun] = (urunFireleri[urun] ?? 0) + adet;
                    }

                    // 3. ÜRÜNLERİ BİRLEŞTİR
                    final Set<String> tumUrunlerSet = {
                      ...urunSatislari.keys,
                      ...urunFireleri.keys,
                    };
                    final List<String> siraliUrunler = tumUrunlerSet.toList()..sort();

                    if (siraliUrunler.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: AppTheme.softShadow,
                                ),
                                child: const Icon(
                                  Icons.query_stats_rounded,
                                  size: 48,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Seçili Dönemde Veri Yok",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Bu tarih aralığı için henüz satış veya fire kaydı bulunmuyor.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final int toplamHaraket = toplamSatilan + toplamImha;
                    final double verimlilik = toplamHaraket == 0
                        ? 0.0
                        : (toplamSatilan / toplamHaraket) * 100;
                    final double fireOrani = toplamHaraket == 0
                        ? 0.0
                        : (toplamImha / toplamHaraket) * 100;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── KPI METRİK KARTLARI ──────────────────
                              Row(
                                children: [
                                  _metrikKarti(
                                    baslik: "Toplam Satış",
                                    deger: "$toplamSatilan Adet",
                                    altMetin: "Kasiyer tarafından satıldı",
                                    ikon: Icons.shopping_bag_rounded,
                                    renk: const Color(0xFF059669),
                                    bgRenk: const Color(0xFFECFDF5),
                                  ),
                                  const SizedBox(width: 14),
                                  _metrikKarti(
                                    baslik: "Toplam Fire (İmha)",
                                    deger: "$toplamImha Adet",
                                    altMetin: "Zayiat / SKT nedeniyle imha",
                                    ikon: Icons.delete_sweep_rounded,
                                    renk: const Color(0xFFDC2626),
                                    bgRenk: const Color(0xFFFEF2F2),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  _metrikKarti(
                                    baslik: "Satış Verimliliği",
                                    deger: "%${verimlilik.toStringAsFixed(1)}",
                                    altMetin: "Toplam stoğun başarı oranı",
                                    ikon: Icons.trending_up_rounded,
                                    renk: const Color(0xFF0F766E),
                                    bgRenk: const Color(0xFFCCFBF1),
                                  ),
                                  const SizedBox(width: 14),
                                  _metrikKarti(
                                    baslik: "Fire / Zayiat Oranı",
                                    deger: "%${fireOrani.toStringAsFixed(1)}",
                                    altMetin: "İmha edilen ürün yüzdesi",
                                    ikon: Icons.trending_down_rounded,
                                    renk: const Color(0xFFEA580C),
                                    bgRenk: const Color(0xFFFFF7ED),
                                  ),
                                ],
                              ),

                              // ── GRAFİK BÖLÜMÜ ─────────────────────────
                              const SizedBox(height: 28),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.borderColor),
                                  boxShadow: AppTheme.softShadow,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Ürün Bazlı Dağılım",
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            _lejantKutusu(const Color(0xFF059669), "Satış"),
                                            const SizedBox(width: 14),
                                            _lejantKutusu(const Color(0xFFDC2626), "Fire"),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 250,
                                      child: _urunlerBarGrafigi(
                                        siraliUrunler,
                                        urunSatislari,
                                        urunFireleri,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ── ÜRÜN BAZLI DETAY LİSTESİ ─────────────
                              const SizedBox(height: 28),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Ürün Performansı (${siraliUrunler.length} Ürün)",
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  Text(
                                    "Satış & Fire Kırılımı",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: siraliUrunler.length,
                                itemBuilder: (context, index) {
                                  final urun = siraliUrunler[index];
                                  final s = urunSatislari[urun] ?? 0;
                                  final f = urunFireleri[urun] ?? 0;
                                  final toplam = s + f;
                                  final double basariOrani = toplam == 0 ? 0 : (s / toplam);
                                  final double yuzde = basariOrani * 100;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppTheme.borderColor),
                                      boxShadow: AppTheme.softShadow,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.cake_rounded,
                                                color: Color(0xFF4338CA),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                urun,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppTheme.textDark,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: yuzde >= 70
                                                    ? const Color(0xFFECFDF5)
                                                    : const Color(0xFFFFF7ED),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: yuzde >= 70
                                                      ? const Color(0xFFA7F3D0)
                                                      : const Color(0xFFFED7AA),
                                                ),
                                              ),
                                              child: Text(
                                                "%${yuzde.toStringAsFixed(0)} Verim",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: yuzde >= 70
                                                      ? const Color(0xFF047857)
                                                      : const Color(0xFFC2410C),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Satış: $s adet",
                                              style: const TextStyle(
                                                color: Color(0xFF059669),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              "Fire: $f adet",
                                              style: const TextStyle(
                                                color: Color(0xFFDC2626),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              "Toplam: $toplam adet",
                                              style: const TextStyle(
                                                color: AppTheme.textMuted,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: basariOrani,
                                            minHeight: 8,
                                            backgroundColor: const Color(0xFFFEE2E2),
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              yuzde >= 70
                                                  ? const Color(0xFF059669)
                                                  : const Color(0xFFEA580C),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtreChip(String baslik, int gun) {
    final bool secili = _seciliFiltreGun == gun;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _hazirFiltreSet(gun),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: secili ? const Color(0xFF4338CA) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: secili ? const Color(0xFF4338CA) : AppTheme.borderColor,
            width: secili ? 1.5 : 1,
          ),
          boxShadow: secili
              ? [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          baslik,
          style: TextStyle(
            color: secili ? Colors.white : AppTheme.textDark,
            fontWeight: secili ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _metrikKarti({
    required String baslik,
    required String deger,
    required String altMetin,
    required IconData ikon,
    required Color renk,
    required Color bgRenk,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  baslik,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgRenk,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(ikon, color: renk, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              deger,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: renk,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              altMetin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lejantKutusu(Color renk, String metin) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: renk,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          metin,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _urunlerBarGrafigi(
    List<String> urunler,
    Map<String, int> satislar,
    Map<String, int> fireler,
  ) {
    double maxY = 0;
    for (var u in urunler) {
      final s = (satislar[u] ?? 0).toDouble();
      final f = (fireler[u] ?? 0).toDouble();
      if (s > maxY) maxY = s;
      if (f > maxY) maxY = f;
    }
    maxY = (maxY * 1.25).ceilToDouble();
    if (maxY <= 0) maxY = 5;

    final double grafikGenisligi =
        urunler.length > 5 ? urunler.length * 68.0 : double.infinity;

    Widget barChartWidget = BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFF1E1B4B),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final urun = urunler[group.x.toInt()];
              final tip = rodIndex == 0 ? "Satış" : "Fire";
              return BarTooltipItem(
                "$urun\n$tip: ${rod.toY.toInt()} adet",
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        barGroups: List.generate(urunler.length, (i) {
          final urun = urunler[i];
          final satis = (satislar[urun] ?? 0).toDouble();
          final fire = (fireler[urun] ?? 0).toDouble();
          return BarChartGroupData(
            x: i,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: satis,
                color: const Color(0xFF059669),
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: fire,
                color: const Color(0xFFDC2626),
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < urunler.length) {
                  final name = urunler[idx];
                  final shortName = name.length > 7 ? "${name.substring(0, 6)}.." : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      shortName,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: maxY > 10 ? (maxY / 4).ceilToDouble() : 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 10 ? (maxY / 4).ceilToDouble() : 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color(0xFFE2E8F0),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );

    if (urunler.length > 5) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: grafikGenisligi,
          child: barChartWidget,
        ),
      );
    }

    return barChartWidget;
  }
}
