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

  /// Entradas: tons igualmente espaçados do verde escuro ao verde de entrada.
  static const List<Color> entradaPalette = [
    Color(0xFF0A5C36),
    Color(0xFF0E6B40),
    Color(0xFF13784B),
    Color(0xFF198555),
    Color(0xFF209260),
    Color(0xFF279D6B),
    Color(0xFF2FA875),
  ];

  /// Saídas: tons igualmente espaçados do vermelho ao amarelo-ouro.
  static const List<Color> saidaPalette = [
    Color(0xFFC62828),
    Color(0xFFC93B26),
    Color(0xFFCB4E24),
    Color(0xFFCE6323),
    Color(0xFFD17921),
    Color(0xFFD3911F),
    Color(0xFFD6A91D),
  ];

  /// Escolhe a cor da posição [i] entre [n] elementos, espalhando-os por toda
  /// a paleta: i = 0 pega a primeira cor, i = n-1 pega a última e as demais
  /// ficam igualmente espaçadas.
  static Color amostrarPaleta(List<Color> paleta, int n, int i) {
    if (paleta.length == 1 || n <= 1) return paleta.first;
    final pos = (i.clamp(0, n - 1) / (n - 1)) * (paleta.length - 1);
    final baixo = pos.floor();
    final alto = pos.ceil();
    return Color.lerp(paleta[baixo], paleta[alto], pos - baixo)!;
  }
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
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13.5,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hoverColor: Colors.black.withValues(alpha: 0.04),
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

/// Durações e curvas de animação do app (vamos acrescentando aqui).
class AppMotion {
  AppMotion._();

  static const Duration transicaoAba = Duration(milliseconds: 300);

  static const Duration fade = Duration(milliseconds: 200);
  static const Duration fadeThrough = Duration(milliseconds: 300);

  /// Estilo de fade padrão para dialogs e seletores
  static const AnimationStyle estiloFade = AnimationStyle(
    duration: fade,
    reverseDuration: fade,
  );

  // Botões
  static const Duration pressionar = Duration(milliseconds: 90);
  static const Duration soltar = Duration(milliseconds: 600);
  static const Duration revelacaoCor = Duration(milliseconds: 450);

  // Dropdown / menus
  static const Duration dropdownAbrir = Duration(milliseconds: 200);
  static const Duration dropdownFechar = Duration(milliseconds: 160);
  static const Curve curvaAbrir = Curves.easeOut;
  static const Curve curvaFechar = Curves.ease;
  static const AnimationStyle estiloDropdown = AnimationStyle(
    curve: curvaAbrir,
    reverseCurve: curvaFechar,
    duration: dropdownAbrir,
    reverseDuration: dropdownFechar,
  );

  static const Duration hover = Duration(milliseconds: 180);
  static const Duration contagem = Duration(milliseconds: 350);
}
