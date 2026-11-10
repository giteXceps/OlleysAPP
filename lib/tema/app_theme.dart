import 'package:flutter/material.dart';

/// OlleysAPP Modern Tasarım Sistemi & Renk Paletleri
/// Her birim ve ekran kendi kimliğine ve rengine sahiptir.
class AppTheme {
  // ── 1. GLOBAL RENKLER ──────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8F9FB);
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  // ── 2. EKRAN BAZLI RENK PALETLERİ ─────────────────────────────

  // GİRİŞ & KAHVE (Espresso & Golden Amber)
  static const Color espresso = Color(0xFF2B1810);
  static const Color mocha = Color(0xFF4A2818);
  static const Color caramel = Color(0xFFD4A373);
  static const Color latteCream = Color(0xFFFFFBF5);

  // PASTA & TATLI (Patisserie Rose & Berry)
  static const Color pastryPrimary = Color(0xFFBE185D);
  static const Color pastryAccent = Color(0xFFF472B6);
  static const Color pastryBg = Color(0xFFFDF2F8);

  // DOLAP & SOĞUK ZİNCİR (Arctic Ice & Cyan)
  static const Color arcticPrimary = Color(0xFF0284C7);
  static const Color arcticAccent = Color(0xFF38BDF8);
  static const Color arcticBg = Color(0xFFF0F9FF);

  // DEMLEME - ÇAY (Ruby Sunset Tea)
  static const Color teaPrimary = Color(0xFFC2410C);
  static const Color teaAccent = Color(0xFFFB923C);
  static const Color teaBg = Color(0xFFFFF7ED);

  // DEMLEME - KAHVE (Warm Roast)
  static const Color coffeePrimary = Color(0xFF78350F);
  static const Color coffeeAccent = Color(0xFFB45309);
  static const Color coffeeBg = Color(0xFFFEF3C7);

  // ANALİZ & YÖNETİM (Executive Slate & Indigo)
  static const Color executivePrimary = Color(0xFF1E1B4B);
  static const Color executiveAccent = Color(0xFF6366F1);
  static const Color executiveBg = Color(0xFFF5F3FF);

  // GÜN SONU SATIŞ / POS (Emerald & Teal)
  static const Color posPrimary = Color(0xFF047857);
  static const Color posAccent = Color(0xFF10B981);
  static const Color posBg = Color(0xFFECFDF5);

  // ROOT / SİSTEM (Deep Obsidian & Crimson)
  static const Color rootPrimary = Color(0xFF0F172A);
  static const Color rootAccent = Color(0xFFEF4444);
  static const Color rootBg = Color(0xFFFEF2F2);

  // ── 3. ORTAK KART VE GÖLGE STİLLERİ ───────────────────────────
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get hoverShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // ── 4. MODERN MATERIAL 3 THEMEDATA ────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: espresso,
        primary: espresso,
        surface: cardLight,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: caramel, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}

