import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Grafik için

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
        const SnackBar(
          content: Text('Lütfen iki dolap için de sıcaklık girin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final double? sicaklik1 = double.tryParse(s1Text);
    final double? sicaklik2 = double.tryParse(s2Text);

    if (sicaklik1 == null || sicaklik2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli sayısal değerler girin.'),
          backgroundColor: Colors.orange,
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
        const SnackBar(
          content: Text('Her iki dolap sıcaklığı kaydedildi.'),
          backgroundColor: Colors.green,
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

  // --------------------------------------------------------------
  // GRAFİK OLUŞTURMA FONKSİYONU
  // --------------------------------------------------------------
  Widget _buildGrafik(List<QueryDocumentSnapshot> docs) {
    // Verileri zamana göre sırala (eskiden yeniye)
    final sorted = [...docs]
      ..sort((a, b) {
        final aTime = (a['kayitZamani'] as Timestamp).toDate();
        final bTime = (b['kayitZamani'] as Timestamp).toDate();
        return aTime.compareTo(bTime);
      });

    // Dolap 1 ve Dolap 2 için ayrı noktalar
    final List<FlSpot> spotsDolap1 = [];
    final List<FlSpot> spotsDolap2 = [];

    // Zaman indeksi olarak dakika cinsinden fark kullanacağız (basitlik için)
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

    // Eğer hiç veri yoksa veya sadece bir nokta varsa grafik yerine mesaj göster
    if (docs.isEmpty || (spotsDolap1.isEmpty && spotsDolap2.isEmpty)) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('Grafik için yeterli veri yok')),
      );
    }

    // Maksimum sıcaklık değerini bul (grafik yüksekliği için)
    double maxY = 0;
    for (var spot in [...spotsDolap1, ...spotsDolap2]) {
      if (spot.y > maxY) maxY = spot.y;
    }
    maxY = maxY + 5; // Biraz boşluk

    // Min X ve max X
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

    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}°',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 60, // her 60 dakikada bir etiket
                getTitlesWidget: (value, meta) {
                  if (ilkZaman == null) return const Text('');
                  final zaman = ilkZaman!.add(Duration(minutes: value.toInt()));
                  return Text(
                    DateFormat('HH:mm').format(zaman),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          minX: minX,
          maxX: maxX,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            // Dolap 1 Çizgisi (Mavi)
            if (spotsDolap1.isNotEmpty)
              LineChartBarData(
                spots: spotsDolap1,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
              ),
            // Dolap 2 Çizgisi (Turuncu)
            if (spotsDolap2.isNotEmpty)
              LineChartBarData(
                spots: spotsDolap2,
                isCurved: true,
                color: Colors.orange,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
              ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dolap Sıcaklık Takibi'),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- Çift Giriş Formu ---
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Yeni Sıcaklık Kaydı',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sicaklik1Controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Dolap 1 Sıcaklık',
                            border: OutlineInputBorder(),
                            suffixText: '°C',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _sicaklik2Controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Dolap 2 Sıcaklık',
                            border: OutlineInputBorder(),
                            suffixText: '°C',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _kaydediliyor ? null : _kaydet,
                    icon: _kaydediliyor
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _kaydediliyor
                          ? 'Kaydediliyor...'
                          : 'İki Dolabı Birden Kaydet',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- GRAFİK ALANI (Bugünkü kayıtlardan) ---
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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildGrafik(snapshot.data!.docs),
                );
              }
              return const SizedBox(
                height: 150,
                child: Center(child: Text('Grafik için veri bekleniyor...')),
              );
            },
          ),

          const SizedBox(height: 12),

          // --- Bugünkü Kayıtlar Listesi ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: Colors.blueGrey),
                SizedBox(width: 8),
                Text(
                  'Bugünkü Sıcaklık Kayıtları',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                  return const Center(child: Text('Bugün henüz kayıt yok.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final zaman = (data['kayitZamani'] as Timestamp).toDate();
                    final dolap = data['dolap'];
                    final sicaklik = data['sicaklik'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey[100],
                          child: const Icon(
                            Icons.ac_unit,
                            color: Colors.blueGrey,
                          ),
                        ),
                        title: Text(
                          '$dolap — $sicaklik °C',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(DateFormat('HH:mm').format(zaman)),
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
}
