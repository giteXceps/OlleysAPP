import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'tema/app_theme.dart';
import 'ekranlar/giris_ekrani.dart';
import 'ekranlar/birim_secim_ekrani.dart';
import 'ekranlar/coffee_go_ana_ekrani.dart';
import 'ekranlar/root_yonetim_ekrani.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('tr_TR', null);

  final prefs = await SharedPreferences.getInstance();
  final String? aktifKullanici = prefs.getString('aktifKullanici');
  final String? aktifRol = prefs.getString('aktifRol');
  final String? aktifBirim = prefs.getString('aktifBirim');

  Widget baslangicEkrani = const GirisEkrani();
  if (aktifKullanici != null && aktifRol != null) {
    if (aktifRol == 'root') {
      baslangicEkrani = const RootYonetimEkrani();
    } else if (aktifRol == 'genel_yonetici') {
      baslangicEkrani = const BirimSecimEkrani(yetki: 'genel');
    } else if (aktifRol == 'birim_yoneticisi') {
      baslangicEkrani = BirimSecimEkrani(yetki: 'birim', hedefBirim: aktifBirim);
    } else if (aktifRol == 'personel' && aktifBirim == 'Coffee Go') {
      baslangicEkrani = const CoffeeGoAnaEkrani();
    }
  }

  runApp(OlleysApp(baslangicEkrani: baslangicEkrani));
}

class OlleysApp extends StatelessWidget {
  final Widget baslangicEkrani;

  const OlleysApp({super.key, required this.baslangicEkrani});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Olleys Yönetim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: baslangicEkrani,
    );
  }
}
