import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'animacoes_base.dart';
import 'botoes_personalizados.dart';

class ReembolsoDialog extends StatelessWidget {
  final VoidCallback onEscolherDespesa;
  const ReembolsoDialog({super.key, required this.onEscolherDespesa});

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border),
    );

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reembolso',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              const Text(
                'Despesa',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              HoverAnimado(
                raio: 14,
                child: Material(
                  color: AppColors.surface,
                  shape: forma,
                  child: InkWell(
                    customBorder: forma,
                    hoverColor: Colors.transparent,
                    mouseCursor: SystemMouseCursors.click,
                    onTap: onEscolherDespesa,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Selecionar despesa',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ToqueElastico(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: estiloBotao(
                      corForeGround: AppColors.textSecondary,
                      corBackGround: AppColors.disabledFill,
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}