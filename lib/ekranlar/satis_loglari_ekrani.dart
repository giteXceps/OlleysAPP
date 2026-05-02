import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SatisLoglariEkrani extends StatelessWidget {
  const SatisLoglariEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gün Sonu Satış Kayıtları'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('satis_loglari')
            .orderBy('tarih', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Henüz bir satış kaydı bulunmuyor.'),
            );
          }

          var loglar = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: loglar.length,
            itemBuilder: (context, index) {
              var log = loglar[index];
              DateTime islemZamani = (log['tarih'] as Timestamp).toDate();
              String formatliTarih = DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(islemZamani);

              // Firestore'dan gelen detaylar haritasını (Map) alıyoruz
              Map<String, dynamic> detaylar = log['detaylar'] ?? {};

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal[50],
                    child: const Icon(Icons.receipt, color: Colors.teal),
                  ),
                  title: Text(
                    'Satış İşlemi',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Kullanıcı: ${log['kullanici']} \nTarih: $formatliTarih',
                  ),
                  trailing: Text(
                    '${log['toplamAdet']} Ürün', // Toplam adedi gösteriyoruz
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.teal,
                    ),
                  ),
                  // --- YENİ EKLENEN KOD: Tıklama Özelliği ---
                  onTap: () {
                    // Karta tıklandığında ekranın altından bir pencere açılır
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$formatliTarih - Satış Detayı',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              // Detaylar (Map) içindeki her bir ürünü döngüyle ekrana yazdırıyoruz
                              ...detaylar.entries.map((urun) {
                                return ListTile(
                                  leading: const Icon(
                                    Icons.arrow_right,
                                    color: Colors.teal,
                                  ),
                                  title: Text(urun.key), // Ürün adı
                                  trailing: Text(
                                    '${urun.value} Adet',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Kapat'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
