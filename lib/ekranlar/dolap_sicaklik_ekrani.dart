import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../tema/app_theme.dart';

class DolapSicaklikEkrani extends StatefulWidget {
  const DolapSicaklikEkrani({super.key});

  @override
  State<DolapSicaklikEkrani> createState() => _DolapSicaklikEkraniState();
}

class _DolapSicaklikEkraniState extends State<DolapSicaklikEkrani> {
  final TextEditingController _sicaklik1Controller = TextEditingController();
  final TextEditingController _sicaklik2Controller = TextEditingController();
  bool _kaydediliyor = false;

  Future<void> _kaydet() async {
    final s1Text = _sicaklik1Controller.text.trim();
    final s2Text = _sicaklik2Controller.text.trim();

    if (s1Text.isEmpty || s2Text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen iki dolap için de sıcaklık girin.'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final double? sicaklik1 = double.tryParse(s1Text);
    final double? sicaklik2 = double.tryParse(s2Text);

    if (sicaklik1 == null || sicaklik2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Geçerli sayısal değerler girin.'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _kaydediliyor = true);

    try {
      final now = DateTime.now();
      final silinmeZamani = now.add(const Duration(days: 90));
      final batch = FirebaseFirestore.instance.batch();

      final doc1Ref = FirebaseFirestore.instance
          .collection('dolap_sicakliklari')
          .doc();
      batch.set(doc1Ref, {
        'dolap': 'Dolap 1',
        'sicaklik': sicaklik1,
        'kayitZamani': now,
        'tarih': DateFormat('yyyy-MM-dd').format(now),
        'silinmeZamani': silinmeZamani,
      });

      final doc2Ref = FirebaseFirestore.instance
          .collection('dolap_sicakliklari')
          .doc();
      batch.set(doc2Ref, {
        'dolap': 'Dolap 2',
        'sicaklik': sicaklik2,
        'kayitZamani': now,
        'tarih': DateFormat('yyyy-MM-dd').format(now),
        'silinmeZamani': silinmeZamani,
      });

      await batch.commit();

      _sicaklik1Controller.clear();
      _sicaklik2Controller.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Her iki dolabın sıcaklığı başarıyla kaydedildi.'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  @override
  void dispose() {
    _sicaklik1Controller.dispose();
    _sicaklik2Controller.dispose();
    super.dispose();
  }

  Widget _buildGrafik(List<QueryDocumentSnapshot> docs) {
    final sorted = [...docs]
      ..sort((a, b) {
        final aTime = (a['kayitZamani'] as Timestamp).toDate();
        final bTime = (b['kayitZamani'] as Timestamp).toDate();
        return aTime.compareTo(bTime);
      });

    final List<FlSpot> spotsDolap1 = [];
    final List<FlSpot> spotsDolap2 = [];

    DateTime? ilkZaman;
    for (var doc in sorted) {
      final zaman = (doc['kayitZamani'] as Timestamp).toDate();
      final sicaklik = (doc['sicaklik'] as num).toDouble();
      final dolap = doc['dolap'] as String;

      if (ilkZaman == null) ilkZaman = zaman;
      final double x = zaman.difference(ilkZaman!).inMinutes.toDouble();

      if (dolap == 'Dolap 1') {
        spotsDolap1.add(FlSpot(x, sicaklik));
      } else {
        spotsDolap2.add(FlSpot(x, sicaklik));
      }
    }

    if (docs.isEmpty || (spotsDolap1.isEmpty && spotsDolap2.isEmpty)) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('Grafik için yeterli veri yok')),
      );
    }

    double maxY = 0;
    for (var spot in [...spotsDolap1, ...spotsDolap2]) {
      if (spot.y > maxY) maxY = spot.y;
    }
    maxY = maxY + 4;

    double minX = 0;
    double maxX = 0;
    if (spotsDolap1.isNotEmpty) {
      minX = spotsDolap1.first.x;
      maxX = spotsDolap1.last.x;
    }
    if (spotsDolap2.isNotEmpty) {
      if (spotsDolap2.first.x < minX) minX = spotsDolap2.first.x;
      if (spotsDolap2.last.x > maxX) maxX = spotsDolap2.last.x;
    }

    if (minX >= maxX) {
      maxX = minX + 60;
    }
    if (maxY <= 0) maxY = 15;

    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (val) => FlLine(
              color: const Color(0xFFE2E8F0),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: 4,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}°C',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 60,
                getTitlesWidget: (value, meta) {
                  if (ilkZaman == null) return const Text('');
                  final zaman = ilkZaman!.add(Duration(minutes: value.toInt()));
                  return Text(
                    DateFormat('HH:mm').format(zaman),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: minX,
          maxX: maxX,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            if (spotsDolap1.isNotEmpty)
              LineChartBarData(
                spots: spotsDolap1,
                isCurved: true,
                color: const Color(0xFF0284C7),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF0284C7).withOpacity(0.08),
                ),
              ),
            if (spotsDolap2.isNotEmpty)
              LineChartBarData(
                spots: spotsDolap2,
                isCurved: true,
                color: const Color(0xFFF59E0B),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFFF59E0B).withOpacity(0.08),
                ),
              ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => const Color(0xFF0F172A),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final isDolap1 = spotsDolap1.contains(spot);
                  return LineTooltipItem(
                    '${isDolap1 ? "Dolap 1" : "Dolap 2"}\n${spot.y.toStringAsFixed(1)}°C',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF), // Taze açık mavi
      appBar: AppBar(
        title: const Text('Dolap Sıcaklık Takibi'),
        backgroundColor: AppTheme.arcticPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── HACCP BİLGİ BİLGİLENDİRMESİ ──────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppTheme.arcticPrimary, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'HACCP Standardı: Pasta ve süt ürünleri için ideal dolap sıcaklığı 0°C ile +4°C arasıdır (Maksimum +8°C).',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0369A1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── YENİ SICAKLIK KAYDI FORMU ────────────────────
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.arcticBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.device_thermostat_rounded,
                              color: AppTheme.arcticPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Yeni Sıcaklık Kaydı',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _sicaklik1Controller,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Dolap 1 Sıcaklık',
                                prefixIcon: const Icon(Icons.ac_unit, color: Color(0xFF0284C7)),
                                suffixText: '°C',
                                suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppTheme.borderColor),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _sicaklik2Controller,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Dolap 2 Sıcaklık',
                                prefixIcon: const Icon(Icons.ac_unit, color: Color(0xFFF59E0B)),
                                suffixText: '°C',
                                suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppTheme.borderColor),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _kaydediliyor ? null : _kaydet,
                          icon: _kaydediliyor
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _kaydediliyor
                                ? 'Kaydediliyor...'
                                : 'İki Dolabı Birden Kaydet',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.arcticPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── GÜNLÜK SICAKLIK GRAFİĞİ ─────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
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
                            'Bugünkü Sıcaklık Grafiği',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Row(
                            children: [
                              _grafikEtiket(const Color(0xFF0284C7), "Dolap 1"),
                              const SizedBox(width: 12),
                              _grafikEtiket(const Color(0xFFF59E0B), "Dolap 2"),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('dolap_sicakliklari')
                            .where(
                              'tarih',
                              isEqualTo: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                            )
                            .orderBy('kayitZamani', descending: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                            return _buildGrafik(snapshot.data!.docs);
                          }
                          return const SizedBox(
                            height: 150,
                            child: Center(
                              child: Text(
                                'Bugün için grafik verisi bekleniyor...',
                                style: TextStyle(color: AppTheme.textMuted),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── BUGÜNKÜ KAYITLAR LİSTESİ ────────────────────
                const Text(
                  'Bugünkü Ölçümler',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('dolap_sicakliklari')
                      .where(
                        'tarih',
                        isEqualTo: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      )
                      .orderBy('kayitZamani', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Center(
                          child: Text(
                            'Bugün henüz sıcaklık ölçümü kaydedilmedi.',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final data = docs[index];
                          final zaman = (data['kayitZamani'] as Timestamp).toDate();
                          final dolap = data['dolap'] as String;
                          final sicaklik = (data['sicaklik'] as num).toDouble();
                          final isDolap1 = dolap == 'Dolap 1';
                          final Color renk =
                              isDolap1 ? const Color(0xFF0284C7) : const Color(0xFFF59E0B);

                          final bool uygun = sicaklik >= 0 && sicaklik <= 8;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 6,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: renk.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.ac_unit_rounded, color: renk, size: 22),
                            ),
                            title: Text(
                              '$dolap — ${sicaklik.toStringAsFixed(1)} °C',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textDark,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('HH:mm').format(zaman),
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: uygun
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: uygun
                                      ? const Color(0xFFA7F3D0)
                                      : const Color(0xFFFECACA),
                                ),
                              ),
                              child: Text(
                                uygun ? "Normal" : "⚠️ Yüksek",
                                style: TextStyle(
                                  color: uygun
                                      ? const Color(0xFF047857)
                                      : const Color(0xFFDC2626),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _grafikEtiket(Color renk, String metin) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: renk,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          metin,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
