import 'package:flutter/material.dart';
import 'ekranlar/giris_ekrani.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      home: const GirisEkrani(),
    );
  }
}
