import 'package:controle_financeiro/utils/dialog_fade.dart';
import 'package:controle_financeiro/utils/dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
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
  List<Categoria> _categoriasPorUso(
    FinanceProvider provider,
    TipoLancamento tipo,
  ) {
    final uso = <String, int>{};
    for (final t in provider.transacoes) {
      uso[t.categoriaNome] = (uso[t.categoriaNome] ?? 0) + 1;
    }
    final lista = [...provider.categoriasPorTipo(tipo)];
    lista.sort((a, b) => (uso[b.nome] ?? 0).compareTo(uso[a.nome] ?? 0));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final tipo = widget.tipo;
    final habilitado = tipo != null;
    final categorias = habilitado
        ? _categoriasPorUso(provider, tipo)
        : const <Categoria>[];

    return dropdownEstilizado(
      habilitado: habilitado,
      icone: Icons.sell_outlined,
      opcoes: [for (final c in categorias) c.nome],
      valorSelecionado: widget.categoriaSelecionada?.nome,
      hint: habilitado ? 'Escolha a categoria' : 'Escolha o tipo',
      rotuloNovo: 'Nova categoria',
      onSelecionar: (nome) =>
          widget.onSelecionar(categorias.firstWhere((c) => c.nome == nome)),
      onNovo: () async {
        final nova = await _dialogNovaCategoria(context, tipo!);
        if (nova != null && mounted) widget.onSelecionar(nova);
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
