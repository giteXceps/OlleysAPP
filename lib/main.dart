import 'package:flutter/material.dart';
// Giriş ekranını kullanabilmek için dosyayı import ediyoruz:
import 'ekranlar/giris_ekrani.dart';

void main() {
  runApp(const OlleysApp());
}

class OlleysApp extends StatelessWidget {
  const OlleysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Olleys Yönetim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home:
          const GirisEkrani(), // Proje direkt ekranlar/giris_ekrani.dart dosyasından başlayacak
    );
  }
}
