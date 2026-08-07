import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/adicionar_categoria_dialog.dart';
import '../widgets/categoria_detail_dialog.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  TipoLancamento _tipoCompacto = TipoLancamento.entrada;
  static const _minWidth = 500.0;

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
        Text('Toque numa categoria para editar ou excluir.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= _minWidth) {
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

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: blocoEntrada),
                    const SizedBox(width: 20),
                    Expanded(child: blocoSaida),
                  ],
                );
              }

              final categoriasCompacto = _tipoCompacto == TipoLancamento.entrada ? entradas : saidas;
              final corCompacto = _tipoCompacto == TipoLancamento.entrada ? AppColors.entrada : AppColors.saida;
              final tituloCompacto =
                  _tipoCompacto == TipoLancamento.entrada ? 'Categorias de entrada' : 'Categorias de saída';

              return _blocoCategorias(
                context,
                titulo: tituloCompacto,
                categorias: categoriasCompacto,
                tipo: _tipoCompacto,
                cor: corCompacto,
                onTrocar: () => setState(() {
                  _tipoCompacto =
                      _tipoCompacto == TipoLancamento.entrada ? TipoLancamento.saida : TipoLancamento.entrada;
                }),
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
    VoidCallback? onTrocar, // se não-nulo, usa o layout "compacto" do cabeçalho
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: onTrocar != null
                      ? [
                          Text('${categorias.length}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cor)),
                          const SizedBox(width: 8),
                          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                        ]
                      : [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                        ],
                ),
                if (onTrocar != null)
                  InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(20),
                    onTap: onTrocar,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.sync_alt_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                  )
                else
                  Text(
                    '${categorias.length}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: categorias.isEmpty ? 1 : categorias.length,
              itemBuilder: (context, index) {
                if (categorias.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text('Nenhuma categoria ainda.', style: Theme.of(context).textTheme.bodyMedium),
                  );
                }
                return _itemCategoria(context, categorias[index], cor);
              },
            ),
          ),
          const SizedBox(height: 8),
          _botaoAdicionar(context, tipo, cor),
        ],
      ),
    );
  }

  
  
  Widget _itemCategoria(BuildContext context, Categoria c, Color cor) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
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
      mouseCursor: SystemMouseCursors.click,
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
