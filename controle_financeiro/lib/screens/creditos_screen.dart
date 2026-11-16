import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/layout_dois_containers.dart';

class CreditosScreen extends StatelessWidget {
  const CreditosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TelaDuasListas(
      titulo: 'Crédito',
      primeiro: ConfigBloco(
        titulo: 'Negativo',
        cor: AppColors.saida,
        quantidade: 0,
        mensagemVazia: 'Nenhum crédito negativo.',
        itemBuilder: (context, index) => const SizedBox.shrink(),
      ),
      segundo: ConfigBloco(
        titulo: 'Positivo',
        cor: AppColors.entrada,
        quantidade: 0,
        mensagemVazia: 'Nenhum crédito negativo.',
        itemBuilder: (context, index) => const SizedBox.shrink(),
      ),
    );
  }
}
