import 'package:controle_financeiro/widgets/animacoes_base.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/adicionar_categoria_dialog.dart';
import '../widgets/categoria_detail_dialog.dart';
import '../widgets/layout_dois_containers.dart';
import '../utils/dialog_fade.dart';

class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    return TelaDuasListas(
      titulo: 'Categorias',
      primeiro: _config(context, finance, TipoLancamento.entrada),
      segundo: _config(context, finance, TipoLancamento.saida),
    );
  }

  ConfigBloco _config(
    BuildContext context,
    FinanceProvider finance,
    TipoLancamento tipo,
  ) {
    final entrada = tipo == TipoLancamento.entrada;
    final cor = entrada ? AppColors.entrada : AppColors.saida;
    final categorias = finance.categoriasPorTipo(tipo);

    return ConfigBloco(
      titulo: entrada ? 'Categorias de entrada' : 'Categorias de saída',
      cor: cor,
      quantidade: categorias.length,
      mensagemVazia: 'Nenhuma categoria ainda.',
      itemBuilder: (context, i) => _itemCategoria(context, categorias[i], cor),
      rodape: _botaoAdicionar(context, tipo, cor),
    );
  }

  Widget _itemCategoria(BuildContext context, Categoria c, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HoverAnimado(
        raio: 12,
        child: InkWell(
          hoverColor: Colors.transparent,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12),
          onTap: () => mostrarDialogo(
            context: context,
            builder: (_) => CategoriaDetailDialog(categoria: c),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  c.nome,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${c.vezesUsada}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _botaoAdicionar(BuildContext context, TipoLancamento tipo, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: HoverAnimado(
        raio: 12,
        escala: 1.02,
        corHover: cor.withValues(alpha: 0.08),
        child: InkWell(
          hoverColor: Colors.transparent,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12),
          onTap: () => mostrarDialogo(
            context: context,
            builder: (_) => AdicionarCategoriaDialog(tipo: tipo),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cor.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.add_rounded, color: cor),
          ),
        ),
      ),
    );
  }
}
