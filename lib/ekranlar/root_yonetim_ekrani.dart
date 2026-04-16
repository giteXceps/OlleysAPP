import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'giris_ekrani.dart';

class RootYonetimEkrani extends StatefulWidget {
  const RootYonetimEkrani({super.key});

  @override
  State<RootYonetimEkrani> createState() => _RootYonetimEkraniState();
}

class _RootYonetimEkraniState extends State<RootYonetimEkrani> {
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();
  String _secilenRol = 'personel';
  String _secilenBirim = 'Coffee Go';

  // --- KULLANICI EKLEME FONKSİYONU ---
  void _kullaniciEkle() async {
    if (_adController.text.isEmpty || _sifreController.text.isEmpty) {
      _mesajGoster("Lütfen tüm alanları doldurun!", Colors.orange);
      return;
    }

    await FirebaseFirestore.instance.collection('users').add({
      'kullaniciAdi': _adController.text.trim().toLowerCase(),
      'sifre': _sifreController.text.trim(),
      'rol': _secilenRol,
      'birim': _secilenBirim,
    });

    _adController.clear();
    _sifreController.clear();
    _mesajGoster('Kullanıcı Başarıyla Eklendi!', Colors.green);
  }

  // --- VERİ TEMİZLEME MANTIĞI (3 AYDAN ESKİLER) ---
  Future<void> _eskiVerileriTemizle() async {
    // 90 gün öncesinin tarihini alıyoruz
    DateTime ucAyOnce = DateTime.now().subtract(const Duration(days: 90));

    try {
      var eskiKayitlar = await FirebaseFirestore.instance
          .collection('pastalar')
          .where('eklenmeZamani', isLessThan: ucAyOnce)
          .get();

      if (eskiKayitlar.docs.isEmpty) {
        _mesajGoster('Temizlenecek eski veri bulunamadı.', Colors.blueGrey);
        return;
      }

      // Her bir dökümanı tek tek siler
      for (var doc in eskiKayitlar.docs) {
        await doc.reference.delete();
      }

      _mesajGoster(
        '${eskiKayitlar.docs.length} adet eski kayıt silindi!',
        Colors.green,
      );
    } catch (e) {
      _mesajGoster('Hata oluştu: $e', Colors.red);
    }
  }

  // --- TEMİZLİK ONAY PENCERESİ ---
  void _temizlikOnayDiyalogu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Verileri Temizle'),
        content: const Text(
          '3 aydan eski tüm kayıtlar kalıcı olarak silinecek. Analiz verilerin etkilenebilir. Emin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eskiVerileriTemizle();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('EVET, TEMİZLE'),
          ),
        ],
      ),
    );
  }

  // Yardımcı Mesaj Fonksiyonu
  void _mesajGoster(String mesaj, Color renk) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: renk));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Root Paneli & Bakım'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const GirisEkrani()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Yeni Kullanıcı Tanımla",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _adController,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sifreController,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _secilenRol,
              items: [
                'root',
                'genel_yonetici',
                'birim_yoneticisi',
                'personel',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _secilenRol = v!),
              decoration: const InputDecoration(labelText: 'Yetki Seviyesi'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _secilenBirim,
              items: [
                'Coffee Go',
                'Genel',
                'Bowling',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _secilenBirim = v!),
              decoration: const InputDecoration(labelText: 'Birim Tanımla'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _kullaniciEkle,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.blueGrey[800],
                foregroundColor: Colors.white,
              ),
              child: const Text('Yeni Kullanıcı Oluştur'),
            ),

            // --- SİSTEM BAKIMI BÖLÜMÜ ---
            const SizedBox(height: 40),
            const Divider(thickness: 2),
            const SizedBox(height: 10),
            const Text(
              "Sistem Bakımı",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Veritabanı alanını boşaltmak için eski kayıtları temizleyin.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _temizlikOnayDiyalogu,
              icon: const Icon(Icons.delete_sweep),
              label: const Text('3 Aydan Eski Kayıtları Sil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
