import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ImhaLoglariEkrani extends StatelessWidget {
  const ImhaLoglariEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text('İmha Kayıtları'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      // StreamBuilder ile Firestore'daki 'imha_loglari' tablosunu dinliyoruz
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('imha_loglari')
            .orderBy(
              'tarih',
              descending: true,
            ) // En yeni işlem en üstte görünsün
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Henüz bir imha kaydı bulunmuyor.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          var loglar = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: loglar.length,
            itemBuilder: (context, index) {
              var log = loglar[index];
              // Firestore zaman damgasını normal tarihe çeviriyoruz
              DateTime islemZamani = (log['tarih'] as Timestamp).toDate();
              String formatliTarih = DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(islemZamani);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.delete_sweep, color: Colors.white),
                  ),
                  title: Text(
                    log['urun'], // Ürün adı
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Kullanıcı: ${log['kullanici']} \nTarih: $formatliTarih',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${log['adet']} Adet', // Kaç adet imha edildiği
                      style: TextStyle(
                        color: Colors.red[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
