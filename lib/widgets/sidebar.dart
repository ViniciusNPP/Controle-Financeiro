import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppSidebarContent extends StatelessWidget {
  final int abaSelecionada; // 0 = Adicionar, 1 = Gráficos, 2 = Histórico, 3 = Categorias
  final ValueChanged<int> onSelecionar;
  final VoidCallback onSincronizar;

  const AppSidebarContent({
    super.key,
    required this.abaSelecionada,
    required this.onSelecionar,
    required this.onSincronizar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.savings_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Meu Financeiro',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            _item(context, icon: Icons.add_circle_outline_rounded, label: 'Adicionar', indice: 0),
            _item(context, icon: Icons.bar_chart_rounded, label: 'Gráficos', indice: 1),
            _item(context, icon: Icons.history_rounded, label: 'Histórico', indice: 2),
            _item(context, icon: Icons.sell_outlined, label: 'Categorias', indice: 3),
            const Spacer(),
            _item(
              context,
              icon: Icons.sync_rounded,
              label: 'Sincronização',
              indice: -1,
              onTapExtra: onSincronizar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int indice,
    VoidCallback? onTapExtra,
  }) {
    final selecionado = indice >= 0 && indice == abaSelecionada;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selecionado ? Colors.white.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (onTapExtra != null) {
              onTapExtra();
            } else {
              onSelecionar(indice);
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: Colors.white.withOpacity(selecionado ? 1 : 0.7), size: 20),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(selecionado ? 1 : 0.7),
                    fontWeight: selecionado ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
