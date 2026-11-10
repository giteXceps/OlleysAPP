import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class CoffeeGoAnalizEkrani extends StatefulWidget {
  const CoffeeGoAnalizEkrani({super.key});

  @override
  State<CoffeeGoAnalizEkrani> createState() => _CoffeeGoAnalizEkraniState();
}

class _CoffeeGoAnalizEkraniState extends State<CoffeeGoAnalizEkrani> {
  // Varsayılan olarak son 7 gün (Bugün dahil)
  late DateTimeRange _secilenAralik;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _secilenAralik = DateTimeRange(
      start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  // Tarih aralığını günün başlangıcı (00:00:00) ve bitişi (23:59:59) olarak normalleştirir
  DateTime get _baslangicTarihi {
    final s = _secilenAralik.start;
    return DateTime(s.year, s.month, s.day, 0, 0, 0);
  }

  DateTime get _bitisTarihi {
    final e = _secilenAralik.end;
    return DateTime(e.year, e.month, e.day, 23, 59, 59, 999);
  }

  // Hazır Gün Filtreleri (0: Bugün, 7, 30, 90)
  void _hazirFiltreSet(int gun) {
    final now = DateTime.now();
    final bugun = DateTime(now.year, now.month, now.day);
    setState(() {
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

  // Takvimden Özel Aralık Seçme
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
              primary: Colors.brown,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pick != null) {
      setState(() => _secilenAralik = pick);
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Coffee Go | Satış & Fire Analizi'),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ---------------------------------------------------------
          // ÜST KISIM: FİLTRELEME ÇUBUĞU
          // ---------------------------------------------------------
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text(
                      "Seçili Dönem: ${_tarihFormatla(_secilenAralik.start)} - ${_tarihFormatla(_secilenAralik.end)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filtreButonu("Bugün", () => _hazirFiltreSet(0)),
                      const SizedBox(width: 8),
                      _filtreButonu("Son 7 Gün", () => _hazirFiltreSet(7)),
                      const SizedBox(width: 8),
                      _filtreButonu("Son 30 Gün", () => _hazirFiltreSet(30)),
                      const SizedBox(width: 8),
                      _filtreButonu("Son 90 Gün", () => _hazirFiltreSet(90)),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _ozelAralikSec,
                        icon: const Icon(Icons.date_range, size: 18),
                        label: const Text("Takvimden Seç"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.brown[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------------------
          // ALT KISIM: GERÇEK ZAMANLI SATIŞ VE İMHA VERİLERİ
          // ---------------------------------------------------------
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

                    // --- 1. SATIŞLARI HESAPLA ---
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

                    // --- 2. İMHALARI (FİRELERİ) HESAPLA ---
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

                    // --- 3. TÜM ÜRÜNLERİ BİRLEŞTİR ---
                    final Set<String> tumUrunlerSet = {
                      ...urunSatislari.keys,
                      ...urunFireleri.keys,
                    };
                    final List<String> siraliUrunler = tumUrunlerSet.toList()..sort();

                    if (siraliUrunler.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                "Seçili tarih aralığında hiçbir satış veya imha kaydı bulunamadı.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 16),
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
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Dönem Özeti & Performans",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ÖZET KARTLAR (Satış & Fire)
                          Row(
                            children: [
                              _analizKarti(
                                "Toplam Satış",
                                "$toplamSatilan Adet",
                                Icons.shopping_bag,
                                Colors.green,
                              ),
                              const SizedBox(width: 12),
                              _analizKarti(
                                "Toplam Fire (İmha)",
                                "$toplamImha Adet",
                                Icons.delete_forever,
                                Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // VERİMLİLİK VE FİRE ORANI KARTLARI
                          Row(
                            children: [
                              Expanded(
                                child: _genisAnalizKarti(
                                  "Satış Verimliliği",
                                  "%${verimlilik.toStringAsFixed(1)}",
                                  Icons.trending_up,
                                  Colors.teal,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _genisAnalizKarti(
                                  "Fire Oranı",
                                  "%${fireOrani.toStringAsFixed(1)}",
                                  Icons.trending_down,
                                  Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),

                          // ==========================================
                          // GRAFİK BÖLÜMÜ
                          // ==========================================
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Grafiksel Analiz (Satış vs Fire)",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  _lejantKutusu(Colors.green, "Satış"),
                                  const SizedBox(width: 12),
                                  _lejantKutusu(Colors.red, "Fire"),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 260,
                            padding: const EdgeInsets.only(top: 20, right: 16, bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: _urunlerBarGrafigi(siraliUrunler, urunSatislari, urunFireleri),
                          ),

                          // ==========================================
                          // ÜRÜN BAZLI DETAYLAR LİSTESİ
                          // ==========================================
                          const SizedBox(height: 28),
                          Text(
                            "Ürün Bazlı Detaylar (${siraliUrunler.length} Ürün)",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(),

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

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.brown[100],
                                            child: const Icon(
                                              Icons.cake,
                                              color: Colors.brown,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              urun,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
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
                                                  ? Colors.green.shade50
                                                  : Colors.orange.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: yuzde >= 70
                                                    ? Colors.green.shade300
                                                    : Colors.orange.shade300,
                                              ),
                                            ),
                                            child: Text(
                                              "%${yuzde.toStringAsFixed(0)} Verim",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: yuzde >= 70
                                                    ? Colors.green.shade800
                                                    : Colors.orange.shade800,
                                                fontSize: 13,
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
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            "Fire: $f adet",
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            "Toplam: $toplam adet",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
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
                                          backgroundColor: Colors.red.shade100,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            yuzde >= 70 ? Colors.green : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
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

  Widget _filtreButonu(String baslik, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.brown[100],
        foregroundColor: Colors.brown[900],
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(baslik),
    );
  }

  Widget _lejantKutusu(Color renk, String metin) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: renk,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(metin, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

    // Ürün sayısı fazlaysa yatay kaydırılabilir yap
    final double grafikGenisligi = urunler.length > 5 ? urunler.length * 60.0 : double.infinity;

    Widget barChartWidget = BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey.shade800,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final urun = urunler[group.x.toInt()];
              final tip = rodIndex == 0 ? "Satış" : "Fire";
              return BarTooltipItem(
                "$urun\n$tip: ${rod.toY.toInt()} adet",
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                color: Colors.green,
                width: 10,
                borderRadius: BorderRadius.circular(3),
              ),
              BarChartRodData(
                toY: fire,
                color: Colors.red,
                width: 10,
                borderRadius: BorderRadius.circular(3),
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
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
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
            color: Colors.grey.shade200,
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

  Widget _analizKarti(String baslik, String deger, IconData icon, Color renk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: renk, size: 28),
            const SizedBox(height: 8),
            Text(
              baslik,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              deger,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: renk),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _genisAnalizKarti(String baslik, String deger, IconData icon, Color renk) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: renk.withOpacity(0.1),
            child: Icon(icon, color: renk, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(
                  deger,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: renk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
