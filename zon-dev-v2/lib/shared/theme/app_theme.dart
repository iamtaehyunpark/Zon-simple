import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ZON design tokens — Direction D (Final)
/// Source: zon-tokens.jsx
class Z {
  // Brand
  static const brand      = Color(0xFF8B6EC4);
  static const brandDark  = Color(0xFF6B50A4);
  static const brandLight = Color(0xFFA98EDC);
  static const brandSoft  = Color(0x218B6EC4); // rgba(139,110,196,0.13)
  static const brandSoft2 = Color(0x108B6EC4); // rgba(139,110,196,0.06)

  // Semantic
  static const checkin     = Color(0xFF3B82F6);
  static const checkinSoft = Color(0x1F3B82F6);
  static const following   = Color(0xFFF59E0B);
  static const story       = Color(0xFFEC4899);
  static const note        = Color(0xFFD97706);
  static const noteSoft    = Color(0x1AD97706);
  static const auto        = Color(0xFF9CA3AF);
  static const error       = Color(0xFFEF4444);
  static const success     = Color(0xFF10B981);

  // Surfaces
  static const surface0 = Color(0xFFF7F4EE); // scaffold / page bg
  static const surface1 = Color(0xFFFFFFFF); // card / header bg
  static const surface2 = Color(0xFFF0EDE6); // sheet bg
  static const surface3 = Color(0xFFE8E4DC); // toggle track off

  // Text
  static const text      = Color(0xFF1A1714);
  static const textMuted = Color(0xFF8A8278);
  static const textFaint = Color(0xFFC0BAB2);

  // Outline
  static const outline  = Color(0xFFE8E4DC);
  static const outline2 = Color(0xFFC8C2BA);

  // Radius helpers
  static BorderRadius get r8   => BorderRadius.circular(8);
  static BorderRadius get r12  => BorderRadius.circular(12);
  static BorderRadius get r14  => BorderRadius.circular(14);
  static BorderRadius get r16  => BorderRadius.circular(16);
  static BorderRadius get r20  => BorderRadius.circular(20);
  static BorderRadius get r24  => BorderRadius.circular(24);
  static BorderRadius get rFull => BorderRadius.circular(9999);
}

/// Build the MaterialApp ThemeData using DM Sans + Z tokens.
class AppTheme {
  static ThemeData get theme {
    final base = GoogleFonts.dmSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Z.brand,
        surface: Z.surface1,
        primary: Z.brand,
        onPrimary: Colors.white,
        secondary: Z.brand,
        onSurface: Z.text,
      ),
      scaffoldBackgroundColor: Z.surface0,
      textTheme: base.copyWith(
        displayLarge:  base.displayLarge?.copyWith(color: Z.text, fontWeight: FontWeight.w800),
        titleLarge:    base.titleLarge?.copyWith(color: Z.text, fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium:   base.titleMedium?.copyWith(color: Z.text, fontWeight: FontWeight.w700, fontSize: 17),
        titleSmall:    base.titleSmall?.copyWith(color: Z.text, fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge:     base.bodyLarge?.copyWith(color: Z.text, fontSize: 15, height: 1.55),
        bodyMedium:    base.bodyMedium?.copyWith(color: Z.text, fontSize: 14, height: 1.55),
        bodySmall:     base.bodySmall?.copyWith(color: Z.textMuted, fontSize: 12),
        labelSmall:    base.labelSmall?.copyWith(color: Z.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Z.surface1,
        foregroundColor: Z.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Z.text,
        ),
      ),
      dividerColor: Z.outline,
      dividerTheme: const DividerThemeData(
        color: Z.outline,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: Z.surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: Z.r16,
          side: const BorderSide(color: Z.outline),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Z.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: Z.r16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Z.text,
          side: const BorderSide(color: Z.outline2),
          minimumSize: const Size(0, 44),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: Z.rFull),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Z.surface0,
        hintStyle: GoogleFonts.dmSans(fontSize: 14, color: Z.textMuted),
        border: OutlineInputBorder(
          borderRadius: Z.r12,
          borderSide: const BorderSide(color: Z.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Z.r12,
          borderSide: const BorderSide(color: Z.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Z.r12,
          borderSide: const BorderSide(color: Z.brand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Z.surface1,
        selectedColor: Z.brand,
        labelStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
        side: const BorderSide(color: Z.outline, width: 1.5),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      iconTheme: const IconThemeData(color: Z.textMuted),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Z.brand;
          return Z.surface3;
        }),
      ),
    );
  }
}
