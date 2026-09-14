import 'package:controle_financeiro/theme/app_theme.dart';
import 'package:flutter/material.dart';

class LinhaDetalhe extends StatelessWidget {
  final String rotulo;
  final Widget conteudo;
  final bool erro;

  const LinhaDetalhe({super.key, required this.rotulo, required this.conteudo, this.erro = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: erro ? Colors.red : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        conteudo,
      ],
    );
  }
}

class CampoComErro extends StatelessWidget {
  final String rotulo;
  final bool erro;
  final Widget child;
  final double raioBorda;

  const CampoComErro({
    super.key,
    required this.rotulo,
    required this.erro,
    required this.child,
    this.raioBorda = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: erro ? Colors.red : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(raioBorda),
            border: Border.all(
              color: erro ? Colors.red : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class BordaComErro extends StatelessWidget {
  final bool erro;
  final Widget child;
  final double raioBorda;

  const BordaComErro({
    super.key,
    required this.erro,
    required this.child,
    this.raioBorda = 14,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(raioBorda),
        border: Border.all(
          color: erro ? Colors.red : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}