import 'package:flutter/material.dart';
// Giriş ekranını kullanabilmek için dosyayı import ediyoruz:
import 'ekranlar/giris_ekrani.dart';
import 'package:firebase_core/firebase_core.dart'; // Yeni eklendi
import 'firebase_options.dart'; // FlutterFire'ın otomatik oluşturduğu ayar dosyası
import 'ekranlar/giris_ekrani.dart';

void main() async {
  // Flutter'ın çekirdek motorunu başlat
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i bizim projemizin ayarlarıyla başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const OlleysApp());
}

// ... (OlleysApp sınıfı aşağıda aynen kalacak)

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
