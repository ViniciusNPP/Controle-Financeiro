import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de cores do app.
/// Vermelho para saída, verde para entrada, cinza-azulado neutro para saldo,
/// e um indigo profundo como cor de marca (usado na sidebar e nos destaques).
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color sidebarBg = Color(0xFF201D4D);

  static const Color primary = Color(0xFF2E2A6E);
  static const Color primaryLight = Color(0xFF4B47A0);

  static const Color entrada = Color(0xFF2FA875);
  static const Color entradaLight = Color(0xFFE3F5EC);

  static const Color saida = Color(0xFFD64550);
  static const Color saidaLight = Color(0xFFFBE7E8);

  static const Color saldo = Color(0xFF5B6472);
  static const Color saldoLight = Color(0xFFE7E9ED);

  static const Color textPrimary = Color(0xFF1A1B25);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EE);
  static const Color disabledFill = Color(0xFFECEDF2);

  /// Paleta usada para colorir categorias nos gráficos de pizza.
  static const List<Color> categoriaPalette = [
    Color(0xFF2E2A6E),
    Color(0xFF2FA875),
    Color(0xFFD64550),
    Color(0xFFE8A33D),
    Color(0xFF4B9FD6),
    Color(0xFF9B5DE5),
    Color(0xFF5B6472),
    Color(0xFFE4572E),
    Color(0xFF1F9E9E),
    Color(0xFFC44FA0),
    Color(0xFF7C6B4F),
    Color(0xFF4E6E58),
    Color(0xFFB8873F),
    Color(0xFF6E4E9E),
    Color(0xFF3F6E9E),
    Color(0xFF9E3F5B),
    Color(0xFF5F8B4C),
  ];

  static Color forIndex(int i) => categoriaPalette[i % categoriaPalette.length];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light();

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.entrada,
        surface: AppColors.surface,
        error: AppColors.saida,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.sora(
          fontSize: 38,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.sora(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineMedium: GoogleFonts.sora(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.sora(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textSecondary),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.sora(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.disabledFill,
          disabledForegroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }

  /// Usado em vez do CardTheme do Flutter para evitar depender de uma API
  /// que muda de nome entre versões — aplique isso num Container comum.
  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      );
}
