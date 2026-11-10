import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tema/app_theme.dart';
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

  @override
  void dispose() {
    _adController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  void _kullaniciEkle() async {
    if (_adController.text.isEmpty || _sifreController.text.isEmpty) {
      _mesajGoster("Lütfen tüm alanları doldurun!", Colors.orange.shade800);
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
    _mesajGoster('Kullanıcı Başarıyla Eklendi!', Colors.green.shade700);
  }

  void _kullaniciSil(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      _mesajGoster('Kullanıcı başarıyla silindi.', Colors.red.shade700);
    } catch (e) {
      _mesajGoster('Silme işlemi başarısız: $e', Colors.red);
    }
  }

  void _kullaniciSilOnay(String docId, String isim) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Sil?'),
        content: Text(
          '$isim isimli kullanıcı sistemden silinecek. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _kullaniciSil(docId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('SİL'),
          ),
        ],
      ),
    );
  }

  Future<void> _eskiVerileriTemizle() async {
    final DateTime ucAyOnce = DateTime.now().subtract(const Duration(days: 90));
    try {
      final koleksiyonlar = [
        'pastalar',
        'cay_demlemeleri',
        'kahve_demlemeleri',
        'dolap_sicakliklari',
        'satis_loglari',
        'imha_loglari',
      ];
      int toplamSilinen = 0;

      for (String koleksiyonAdi in koleksiyonlar) {
        String tarihAlani;
        if (koleksiyonAdi == 'pastalar') {
          tarihAlani = 'eklenmeZamani';
        } else if (koleksiyonAdi == 'dolap_sicakliklari') {
          tarihAlani = 'kayitZamani';
        } else if (koleksiyonAdi == 'satis_loglari' || koleksiyonAdi == 'imha_loglari') {
          tarihAlani = 'tarih';
        } else {
          tarihAlani = 'demlemeZamani';
        }

        final eskiKayitlar = await FirebaseFirestore.instance
            .collection(koleksiyonAdi)
            .where(tarihAlani, isLessThan: ucAyOnce)
            .get();

        for (var i = 0; i < eskiKayitlar.docs.length; i += 400) {
          final chunk = eskiKayitlar.docs.skip(i).take(400);
          final batch = FirebaseFirestore.instance.batch();
          for (var doc in chunk) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }

        toplamSilinen += eskiKayitlar.docs.length;
      }

      if (mounted) {
        _mesajGoster('$toplamSilinen adet eski kayıt silindi!', Colors.green.shade700);
      }
    } catch (e) {
      if (mounted) {
        _mesajGoster('Temizlik hatası: $e', Colors.red);
      }
    }
  }

  void _temizlikOnayDiyalogu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Verileri Temizle'),
          ],
        ),
        content: const Text(
          '3 aydan eski tüm operasyonel kayıtlar kalıcı olarak silinecek. Devam etmek istiyor musunuz?',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('EVET, TEMİZLE'),
          ),
        ],
      ),
    );
  }

  void _mesajGoster(String mesaj, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: renk, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Sistem Yönetimi & Root Konsolu'),
        backgroundColor: AppTheme.rootPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Çıkış Yap',
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── YENİ KULLANICI TANIMLAMA FORMU ─────────────
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
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: AppTheme.rootPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Yeni Kullanıcı Hesabı Tanımla",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _adController,
                        decoration: InputDecoration(
                          labelText: 'Kullanıcı Adı',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _sifreController,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _secilenRol,
                              items: [
                                'root',
                                'genel_yonetici',
                                'birim_yoneticisi',
                                'personel',
                              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (v) => setState(() => _secilenRol = v!),
                              decoration: InputDecoration(
                                labelText: 'Yetki Rolü',
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
                            child: DropdownButtonFormField<String>(
                              value: _secilenBirim,
                              items: [
                                'Coffee Go',
                                'Genel',
                              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (v) => setState(() => _secilenBirim = v!),
                              decoration: InputDecoration(
                                labelText: 'Birim',
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
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _kullaniciEkle,
                          icon: const Icon(Icons.check_rounded, color: Colors.white),
                          label: const Text(
                            'Kullanıcıyı Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.rootPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── SİSTEMDEKİ KULLANICILAR ────────────────────
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, color: AppTheme.textMuted, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Kayıtlı Kullanıcılar",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var docs = snapshot.data!.docs;
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
                          var u = docs[index];
                          final bool isRoot = u['rol'] == 'root';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 6,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isRoot
                                    ? const Color(0xFFFEF2F2)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isRoot ? Icons.security_rounded : Icons.person_rounded,
                                color: isRoot ? Colors.red.shade700 : AppTheme.rootPrimary,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              u['kullaniciAdi'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textDark,
                              ),
                            ),
                            subtitle: Text(
                              "Rol: ${u['rol']} • Birim: ${u['birim']}",
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                            trailing: isRoot
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Text(
                                      'Root',
                                      style: TextStyle(
                                        color: Colors.red.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                    onPressed: () =>
                                        _kullaniciSilOnay(u.id, u['kullaniciAdi']),
                                  ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // ── SİSTEM BAKIMI & TEMİZLİK ───────────────────
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cleaning_services_rounded, color: Colors.red.shade800),
                          const SizedBox(width: 10),
                          Text(
                            "Veritabanı Temizliği",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "90 günden eski pastalar, demlemeler, dolap sıcaklıkları ve loglar silinerek veritabanı boyutu optimize edilir.",
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _temizlikOnayDiyalogu,
                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                        label: const Text(
                          '3 Aydan Eski Kayıtları Temizle',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
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
