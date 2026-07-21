import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/adicionar_categoria_dialog.dart';
import '../widgets/categoria_detail_dialog.dart';

class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final entradas = finance.categoriasPorTipo(TipoLancamento.entrada);
    final saidas = finance.categoriasPorTipo(TipoLancamento.saida);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categorias', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Toque numa categoria para editar ou excluir.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final blocoEntrada = _blocoCategorias(
                context,
                titulo: 'Categorias de entrada',
                categorias: entradas,
                tipo: TipoLancamento.entrada,
                cor: AppColors.entrada,
              );
              final blocoSaida = _blocoCategorias(
                context,
                titulo: 'Categorias de saída',
                categorias: saidas,
                tipo: TipoLancamento.saida,
                cor: AppColors.saida,
              );

              if (constraints.maxWidth >= 700) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: blocoEntrada),
                    const SizedBox(width: 20),
                    Expanded(child: blocoSaida),
                  ],
                );
              }
              return SingleChildScrollView(
                child: Column(
                  children: [blocoEntrada, const SizedBox(height: 20), blocoSaida],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _blocoCategorias(
    BuildContext context, {
    required String titulo,
    required List<Categoria> categorias,
    required TipoLancamento tipo,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(titulo, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('${categorias.length}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (categorias.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('Nenhuma categoria ainda.', style: Theme.of(context).textTheme.bodyMedium),
            ),
          for (final c in categorias) _itemCategoria(context, c, cor),
          _botaoAdicionar(context, tipo, cor),
        ],
      ),
    );
  }

  Widget _itemCategoria(BuildContext context, Categoria c, Color cor) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showDialog(context: context, builder: (_) => CategoriaDetailDialog(categoria: c)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(child: Text(c.nome, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _botaoAdicionar(BuildContext context, TipoLancamento tipo, Color cor) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showDialog(context: context, builder: (_) => AdicionarCategoriaDialog(tipo: tipo)),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.4)),
        ),
        child: Icon(Icons.add_rounded, color: cor),
      ),
    );
  }
}
