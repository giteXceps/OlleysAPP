import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../tema/app_theme.dart';

class UrunYonetimEkrani extends StatefulWidget {
  const UrunYonetimEkrani({super.key});

  @override
  State<UrunYonetimEkrani> createState() => _UrunYonetimEkraniState();
}

class _UrunYonetimEkraniState extends State<UrunYonetimEkrani> {
  final TextEditingController _isimController = TextEditingController();
  final TextEditingController _omurController = TextEditingController();
  bool _ekleniyor = false;

  final CollectionReference _urunlerRef = FirebaseFirestore.instance.collection(
    'urun_katalogu',
  );

  @override
  void dispose() {
    _isimController.dispose();
    _omurController.dispose();
    super.dispose();
  }

  Future<void> _urunEkle() async {
    String isim = _isimController.text.trim();
    int? omur = int.tryParse(_omurController.text);

    if (isim.isEmpty || omur == null || omur <= 0) {
      _mesajGoster("Lütfen geçerli bir isim ve pozitif gün girin!", Colors.orange.shade800);
      return;
    }

    setState(() => _ekleniyor = true);

    try {
      final existing = await _urunlerRef.where('isim', isEqualTo: isim).get();
      if (existing.docs.isNotEmpty) {
        if (!mounted) return;
        _mesajGoster("Bu isimde bir ürün zaten katalogda var!", Colors.orange.shade800);
        return;
      }

      await _urunlerRef.add({
        'isim': isim,
        'rafOmruGun': omur,
        'olusturmaZamani': FieldValue.serverTimestamp(),
      });

      _isimController.clear();
      _omurController.clear();
      if (!mounted) return;
      _mesajGoster("Yeni ürün kataloğa eklendi!", Colors.green.shade700);
    } catch (e) {
      if (mounted) _mesajGoster("Ekleme hatası: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _ekleniyor = false);
    }
  }

  void _urunSilOnay(String id, String isim) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Sil?'),
        content: Text('$isim katalogdan silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _urunlerRef.doc(id).delete();
                if (!mounted) return;
                _mesajGoster('$isim katalogdan silindi.', Colors.red.shade700);
              } catch (e) {
                if (!mounted) return;
                _mesajGoster('Silme hatası: $e', Colors.red);
              }
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

  void _mesajGoster(String mesaj, Color renk) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: renk, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ürün Katalog Yönetimi'),
        backgroundColor: const Color(0xFFB45309),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // ÜST FORMU
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_business_rounded,
                              color: Color(0xFFB45309),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Kataloğa Yeni Tatlı / Ürün Ekle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _isimController,
                        decoration: InputDecoration(
                          labelText: 'Pasta / Tatlı İsmi (Örn: San Sebastian)',
                          prefixIcon: const Icon(Icons.cake_outlined, color: Color(0xFFB45309)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _omurController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Standart Raf Ömrü (Gün)',
                          prefixIcon: const Icon(Icons.timelapse_rounded, color: Color(0xFFB45309)),
                          suffixText: 'Gün',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _ekleniyor ? null : _urunEkle,
                          icon: _ekleniyor
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                          label: const Text(
                            "Kataloğa Ekle",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB45309),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ALT KATALOG LİSTESİ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 18, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                    const Text(
                      'Mevcut Katalog Ürünleri',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _urunlerRef.orderBy('isim').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "Katalogda henüz ürün bulunmuyor.",
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      );
                    }

                    var urunler = snapshot.data!.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: urunler.length,
                      itemBuilder: (context, index) {
                        var u = urunler[index];
                        final String isim = u['isim'] ?? 'İsimsiz';
                        final int omur = u['rafOmruGun'] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.cake_rounded,
                                  color: Color(0xFFB45309),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isim,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "Raf Ömrü: $omur Gün",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                tooltip: 'Sil',
                                onPressed: () => _urunSilOnay(u.id, isim),
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
        ),
      ),
    );
  }
}
