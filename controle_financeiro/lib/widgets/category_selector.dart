import 'package:controle_financeiro/utils/dialog_fade.dart';
import 'package:controle_financeiro/utils/dropdown.dart';
import 'package:controle_financeiro/widgets/animacoes_base.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import 'botoes_personalizados.dart';

enum _AcaoCategoria { nova }

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
  bool _aberto = false;

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

  Future<void> _aoSelecionar(Object valor) async {
    setState(() => _aberto = false);

    if (valor == _AcaoCategoria.nova) {
      // O menu já fechou; agora abre o pop-up de criação.
      final nova = await _dialogNovaCategoria(context, widget.tipo!);
      if (nova != null && mounted) widget.onSelecionar(nova);
      return;
    }

    if (valor is! Categoria) {
      throw StateError('Opção de categoria desconhecida: $valor');
    }
    widget.onSelecionar(valor);
  }

  List<PopupMenuEntry<Object>> _itens(BuildContext context) {
    final opcoes = categoriasPorUso(context, widget.tipo!);
    final selecionadaId = widget.categoriaSelecionada?.id;

    return [
      for (final categoria in opcoes)
        popupMenuItemTexto<Object>(
          value: categoria,
          texto: categoria.nome,
          overflow: TextOverflow.ellipsis,
          selecionado: categoria.id == selecionadaId,
          habilitado: categoria.id != selecionadaId,
        ),
      const PopupMenuDivider(),
      // Item destacado: ao tocar, o menu fecha e abre o pop-up.
      popupMenuItemEstilizado<Object>(
        value: _AcaoCategoria.nova,
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
          child: PopupMenuEstilizado<Object>(
            enabled: habilitado,
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
