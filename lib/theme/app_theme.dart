import 'package:flutter/material.dart';

class AppTheme {
  // ── Palette principale : #163E8C et blanc ─────────────────────────────────
  static const Color primary = Color(0xFF163E8C); // Bleu église
  static const Color white = Color(0xFFFFFFFF); // Blanc pur

  // ── Dérivés du bleu ───────────────────────────────────────────────────────
  static const Color blueDark =
      Color(0xFF0D2860); // Bleu très foncé (gradients)
  static const Color blueMid = Color(0xFF1D55C0); // Bleu moyen (hover, icones)
  static const Color blueLight = Color(0xFF3B7DD8); // Bleu clair (accents)
  static const Color blueGhost =
      Color(0xFFEAF0FC); // Bleu pâle (fonds de chips)

  // ── Alias sémantiques ─────────────────────────────────────────────────────
  static const Color teal = Color(0xFF16A34A); // Évangélisateurs (vert)
  static const Color secondary =
      Color(0xFFE53935); // Personnes touchées (cœur rouge)
  static const Color amber = Color(0xFFF59E0B); // Top classement (#1)

  // ── Fonds et surfaces (thème clair) ───────────────────────────────────────
  static const Color bgLight =
      Color(0xFFF4F7FD); // Fond principal (blanc bleuté)
  static const Color surface = Color(0xFFFFFFFF); // AppBar, NavBar, drawers
  static const Color card = Color(0xFFFFFFFF); // Cartes
  static const Color border = Color(0xFFD8E2F8); // Bordures légères

  // ── Texte (sombre sur fond clair) ─────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0D1B3E); // Quasi-noir bleuté
  static const Color textSecondary = Color(0xFF5B72AB); // Bleu-gris moyen

  // ── Thème ─────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: blueLight,
          surface: surface,
          background: bgLight,
          onPrimary: white,
          onSecondary: white,
          onSurface: textPrimary,
          onBackground: textPrimary,
        ),
        scaffoldBackgroundColor: bgLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: white),
        ),
        cardTheme: CardThemeData(
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: Color(0xFFABBDE0)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          shadowColor: border,
          indicatorColor: blueGhost,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: primary, fontWeight: FontWeight.w600, fontSize: 12);
            }
            return const TextStyle(color: textSecondary, fontSize: 12);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primary, size: 24);
            }
            return const IconThemeData(color: textSecondary, size: 22);
          }),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        dividerTheme:
            const DividerThemeData(color: border, thickness: 1, space: 1),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primary),
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      );
}
