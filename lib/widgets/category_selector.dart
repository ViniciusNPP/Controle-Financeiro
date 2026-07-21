import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';

/// Campo de categoria. Fica visualmente "apagado" e não clicável enquanto
/// nenhum tipo (Entrada/Saída) foi escolhido. Quando habilitado, mostra só
/// as categorias daquele tipo, mais a opção de criar uma categoria nova.
class CategorySelector extends StatelessWidget {
  final TipoLancamento? tipo;
  final Categoria? categoriaSelecionada;
  final ValueChanged<Categoria> onSelecionar;

  const CategorySelector({
    super.key,
    required this.tipo,
    required this.categoriaSelecionada,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    final habilitado = tipo != null;

    return Container(
      decoration: BoxDecoration(
        color: habilitado ? AppColors.surface : AppColors.disabledFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: IgnorePointer(
        ignoring: !habilitado,
        child: Opacity(
          opacity: habilitado ? 1 : 0.55,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _abrirSelecao(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.sell_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      categoriaSelecionada?.nome ??
                          (habilitado ? 'Escolha a categoria' : 'Escolha o tipo primeiro'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: categoriaSelecionada != null ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _abrirSelecao(BuildContext context) async {
    if (tipo == null) return;
    final provider = context.read<FinanceProvider>();
    final categorias = provider.categoriasPorTipo(tipo!);

    final resultado = await showModalBottomSheet<Categoria>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Categoria', style: Theme.of(context).textTheme.titleLarge),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in categorias)
                        ListTile(
                          title: Text(c.nome),
                          trailing: categoriaSelecionada?.id == c.id
                              ? const Icon(Icons.check_rounded, color: AppColors.primary)
                              : null,
                          onTap: () => Navigator.of(ctx).pop(c),
                        ),
                      ListTile(
                        leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                        title: const Text(
                          '+ Nova categoria',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                        onTap: () async {
                          Navigator.of(ctx).pop();
                          final nova = await _dialogNovaCategoria(context, tipo!);
                          if (nova != null) onSelecionar(nova);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (resultado != null) onSelecionar(resultado);
  }

  Future<Categoria?> _dialogNovaCategoria(BuildContext context, TipoLancamento tipo) async {
    final controller = TextEditingController();
    final provider = context.read<FinanceProvider>();

    return showDialog<Categoria>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Nova categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nome da categoria'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final nome = controller.text.trim();
              if (nome.isEmpty) return;
              final nova = await provider.adicionarCategoria(nome, tipo);
              if (ctx.mounted) Navigator.of(ctx).pop(nova);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}
