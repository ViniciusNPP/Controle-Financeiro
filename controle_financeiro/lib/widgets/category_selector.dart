import 'package:controle_financeiro/utils/dialog_fade.dart';
import 'package:controle_financeiro/widgets/animacoes_base.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import 'botoes_personalizados.dart';

/// Campo de categoria. Fica visualmente "apagado" e não clicável enquanto
/// nenhum tipo (Entrada/Saída) foi escolhido. Quando habilitado, mostra só
/// as categorias daquele tipo, mais a opção de criar uma categoria nova.
class CategorySelector extends StatefulWidget {
  final TipoLancamento? tipo;
  final Categoria? categoriaSelecionada;
  final ValueChanged<Categoria> onSelecionar;
  final bool compact;

  const CategorySelector({
    super.key,
    required this.tipo,
    required this.categoriaSelecionada,
    required this.onSelecionar,
    this.compact = false,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  // Valor do item "Nova categoria" (os demais usam o índice na lista).
  static const int _novaCategoria = -1;

  bool _aberto = false;
  // Guardada quando o menu abre, para o índice escolhido apontar pra mesma lista.
  List<Categoria> _opcoes = const [];

  List<Categoria> categoriasPorUso(BuildContext context, TipoLancamento tipo) {
    final provider = context.read<FinanceProvider>();
    final categorias = provider.categoriasPorTipo(tipo);

    categorias.map((categoria) {
      final vezes = provider.transacoes
          .where((t) => t.categoriaNome == categoria.nome)
          .length;

      return categoria.copyWith(vezesUsada: vezes);
    }).toList();

    categorias.sort((a, b) => b.vezesUsada.compareTo(a.vezesUsada));
    return categorias;
  }

  Future<void> _aoSelecionar(int valor) async {
    setState(() => _aberto = false);

    if (valor == _novaCategoria) {
      // O menu já fechou; agora abre o pop-up de criação.
      final nova = await _dialogNovaCategoria(context, widget.tipo!);
      if (nova != null && mounted) widget.onSelecionar(nova);
      return;
    }
    widget.onSelecionar(_opcoes[valor]);
  }

  List<PopupMenuEntry<int>> _itens(BuildContext context) {
    _opcoes = categoriasPorUso(context, widget.tipo!);
    final selecionadaId = widget.categoriaSelecionada?.id;

    return [
      for (var i = 0; i < _opcoes.length; i++)
        PopupMenuItem<int>(
          value: i,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _opcoes[i].nome,
                  overflow: TextOverflow.ellipsis,
                  style: _opcoes[i].id == selecionadaId
                      ? const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ),
              if (_opcoes[i].id == selecionadaId)
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      const PopupMenuDivider(),
      // Item destacado: ao tocar, o menu fecha e abre o pop-up.
      PopupMenuItem<int>(
        value: _novaCategoria,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              SizedBox(width: 10),
              Text(
                'Nova categoria',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final habilitado = widget.tipo != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final restricao = constraints.hasBoundedWidth
            ? BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
                maxHeight: 280,
              )
            : const BoxConstraints(minWidth: 160, maxHeight: 280);

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: habilitado ? AppColors.surface : AppColors.disabledFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: IgnorePointer(
            ignoring: !habilitado,
            child: Opacity(
              opacity: habilitado ? 1 : 0.55,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: PopupMenuButton<int>(
                  enabled: habilitado,
                  tooltip: '',
                  popUpAnimationStyle: AppMotion.estiloDropdown,
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  constraints: restricao,
                  onOpened: () => setState(() => _aberto = true),
                  onCanceled: () => setState(() => _aberto = false),
                  onSelected: _aoSelecionar,
                  itemBuilder: _itens,
                  child: HoverAnimado(
                    raio: 14,
                    cursor: SystemMouseCursors.click,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: widget.compact ? 11 : 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sell_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.categoriaSelecionada?.nome ??
                                  (habilitado
                                      ? 'Escolha a categoria'
                                      : 'Escolha o tipo'),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: widget.categoriaSelecionada != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _aberto ? 0.5 : 0,
                            duration: AppMotion.fade,
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Categoria?> _dialogNovaCategoria(
    BuildContext context,
    TipoLancamento tipo,
  ) async {
    final controller = TextEditingController();
    final provider = context.read<FinanceProvider>();

    return mostrarDialogo<Categoria>(
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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: estiloBotao(corForeGround: Color(0xFF3e3b79)),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = controller.text.trim();
              if (nome.isEmpty) return;
              final nova = await provider.adicionarCategoria(nome, tipo);
              if (ctx.mounted) Navigator.of(ctx).pop(nova);
            },
            style: estiloBotao(corBackGround: Color(0xFF3e3b79), isSide: true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}
