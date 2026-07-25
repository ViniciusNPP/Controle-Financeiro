import 'package:controle_financeiro/theme/app_theme.dart';
import 'package:flutter/material.dart';

class LinhaDetalhe extends StatelessWidget {
  final String rotulo;
  final Widget conteudo;

  const LinhaDetalhe({super.key, required this.rotulo, required this.conteudo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        conteudo,
      ],
    );
  }
}