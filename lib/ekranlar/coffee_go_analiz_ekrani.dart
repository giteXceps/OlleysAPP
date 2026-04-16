import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // GRAFİK PAKETİNİ EKLEDİK

class CoffeeGoAnalizEkrani extends StatefulWidget {
  const CoffeeGoAnalizEkrani({super.key});

  @override
  State<CoffeeGoAnalizEkrani> createState() => _CoffeeGoAnalizEkraniState();
}

class _CoffeeGoAnalizEkraniState extends State<CoffeeGoAnalizEkrani> {
  // Varsayılan olarak Son 7 Günü seçili getiriyoruz
  DateTimeRange _secilenAralik = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  // Hazır Gün Filtreleri (7, 30, 90)
  void _hazirFiltreSet(int gun) {
    setState(() {
      _secilenAralik = DateTimeRange(
        start: DateTime.now().subtract(Duration(days: gun)),
        end: DateTime.now(),
      );
    });
  }

  // Takvimden Özel Aralık Seçme
  Future<void> _ozelAralikSec() async {
    final DateTimeRange? pick = await showDateRangePicker(
      context: context,
      initialDateRange: _secilenAralik,
      firstDate: DateTime(2023), // Uygulamanın en eski kayıt yılı
      lastDate: DateTime.now(), // Gelecek seçilemesin
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.brown, // Takvim rengi
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

  // Tarihi ekranda güzel göstermek için yardımcı fonksiyon
  String _tarihFormatla(DateTime tarih) {
    return "${tarih.day.toString().padLeft(2, '0')}/${tarih.month.toString().padLeft(2, '0')}/${tarih.year}";
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  "Seçili Dönem: ${_tarihFormatla(_secilenAralik.start)} - ${_tarihFormatla(_secilenAralik.end)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      ElevatedButton(
                        onPressed: () => _hazirFiltreSet(7),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[100],
                          foregroundColor: Colors.brown[900],
                        ),
                        child: const Text("Son 7 Gün"),
                      ),
                      ElevatedButton(
                        onPressed: () => _hazirFiltreSet(30),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[100],
                          foregroundColor: Colors.brown[900],
                        ),
                        child: const Text("Son 30 Gün"),
                      ),
                      ElevatedButton(
                        onPressed: () => _hazirFiltreSet(90),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[100],
                          foregroundColor: Colors.brown[900],
                        ),
                        child: const Text("Son 90 Gün"),
                      ),
                      OutlinedButton.icon(
                        onPressed: _ozelAralikSec,
                        icon: const Icon(Icons.calendar_month, size: 18),
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
          // ALT KISIM: DİNAMİK VERİLER VE GRAFİKLER
          // ---------------------------------------------------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pastalar')
                  .where(
                    'eklenmeZamani',
                    isGreaterThanOrEqualTo: _secilenAralik.start,
                  )
                  .where(
                    'eklenmeZamani',
                    isLessThanOrEqualTo: _secilenAralik.end,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Veriler yüklenirken hata oluştu."),
                  );
                }

                var pastalar = snapshot.data?.docs ?? [];

                if (pastalar.isEmpty) {
                  return const Center(
                    child: Text(
                      "Bu tarih aralığında hiçbir kayıt bulunamadı.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                int toplamSatilan = 0;
                int toplamImha = 0;
                Map<String, int> urunSatislari = {};
                Map<String, int> urunFireleri = {};

                for (var doc in pastalar) {
                  String isim = doc['isim'];
                  int satilan = doc['satilanAdet'] ?? 0;
                  String durum = doc['durum'];
                  int ilkAdet = doc['ilkAdet'] ?? 0;

                  toplamSatilan += satilan;
                  urunSatislari[isim] = (urunSatislari[isim] ?? 0) + satilan;

                  if (durum == 'İmha Edildi') {
                    int imhaMiktari = ilkAdet - satilan;
                    toplamImha += imhaMiktari;
                    urunFireleri[isim] =
                        (urunFireleri[isim] ?? 0) + imhaMiktari;
                  }
                }

                double verimlilik = (toplamSatilan + toplamImha) == 0
                    ? 0
                    : (toplamSatilan / (toplamSatilan + toplamImha)) * 100;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Seçili Dönem Performansı",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _analizKarti(
                            "Toplam Satış",
                            "$toplamSatilan",
                            Icons.shopping_bag,
                            Colors.green,
                          ),
                          const SizedBox(width: 12),
                          _analizKarti(
                            "Toplam Fire",
                            "$toplamImha",
                            Icons.delete_forever,
                            Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _genisAnalizKarti(
                        "İşletme Verimliliği",
                        "%${verimlilik.toStringAsFixed(1)}",
                        Icons.analytics,
                        Colors.blue,
                      ),

                      // ==========================================
                      // GRAFİK BÖLÜMÜ BURAYA EKLENDİ
                      // ==========================================
                      const SizedBox(height: 32),
                      const Text(
                        "Grafiksel Analiz (Satış vs Fire)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 250,
                        padding: const EdgeInsets.only(top: 20, right: 10),
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
                        // Senin verilerini grafiğe çizen fonksiyonu çağırıyoruz
                        child: _urunlerBarGrafigi(urunSatislari, urunFireleri),
                      ),

                      // ==========================================
                      const SizedBox(height: 32),
                      const Text(
                        "Ürün Bazlı Detaylar (Seçili Dönem)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: urunSatislari.keys.length,
                        itemBuilder: (context, index) {
                          String urun = urunSatislari.keys.elementAt(index);
                          int s = urunSatislari[urun] ?? 0;
                          int f = urunFireleri[urun] ?? 0;
                          double basariOrani = (s + f) == 0 ? 0 : (s / (s + f));

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.brown,
                                      child: Icon(
                                        Icons.cake,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      urun,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Satış: $s adet  |  Fire: $f adet",
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: basariOrani,
                                      minHeight: 8,
                                      backgroundColor: Colors.red[100],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        s >= f ? Colors.green : Colors.orange,
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
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GRAFİĞİ ÇİZEN YARDIMCI FONKSİYON (YENİ)
  // ==========================================
  Widget _urunlerBarGrafigi(
    Map<String, int> satislar,
    Map<String, int> fireler,
  ) {
    List<String> urunler = satislar.keys.toList();
    if (urunler.isEmpty)
      return const Center(child: Text("Grafik için veri yok"));

    // Grafiğin tepe noktasını bulalım ki çubuklar ekrandan taşmasın
    double maxY = 0;
    for (var u in urunler) {
      if ((satislar[u] ?? 0) > maxY) maxY = (satislar[u] ?? 0).toDouble();
      if ((fireler[u] ?? 0) > maxY) maxY = (fireler[u] ?? 0).toDouble();
    }
    maxY = maxY + (maxY * 0.2); // Üstte %20 boşluk kalsın
    if (maxY == 0) maxY = 10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barGroups: List.generate(urunler.length, (i) {
          String urun = urunler[i];
          double satis = (satislar[urun] ?? 0).toDouble();
          double fire = (fireler[urun] ?? 0).toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: satis,
                color: Colors.green,
                width: 8,
                borderRadius: BorderRadius.circular(2),
              ),
              BarChartRodData(
                toY: fire,
                color: Colors.red,
                width: 8,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < urunler.length) {
                  // İsimler uzunsa ilk 5 harfini alıp koyalım ki birbirine girmesin
                  String name = urunler[value.toInt()];
                  String shortName = name.length > 5
                      ? name.substring(0, 5)
                      : name;
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
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ), // Sol sayıları kapattık ferah dursun
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false), // Arka plan çizgilerini gizle
        borderData: FlBorderData(show: false), // Dış çerçeveyi gizle
      ),
    );
  }

  // Arayüz Çizim Yardımcıları (Senin orijinal kodun)
  Widget _analizKarti(String baslik, String deger, IconData icon, Color renk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: renk, size: 32),
            const SizedBox(height: 12),
            Text(
              baslik,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              deger,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genisAnalizKarti(
    String baslik,
    String deger,
    IconData icon,
    Color renk,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            backgroundColor: renk.withOpacity(0.1),
            child: Icon(icon, color: renk),
          ),
          const SizedBox(width: 16),
          Text(baslik, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(
            deger,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }
}
