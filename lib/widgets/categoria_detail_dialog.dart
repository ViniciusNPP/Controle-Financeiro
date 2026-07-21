import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';

class CategoriaDetailDialog extends StatefulWidget {
  final Categoria categoria;

  const CategoriaDetailDialog({super.key, required this.categoria});

  @override
  State<CategoriaDetailDialog> createState() => _CategoriaDetailDialogState();
}

class _CategoriaDetailDialogState extends State<CategoriaDetailDialog> {
  bool _editando = false;
  final _nomeController = TextEditingController();
  late TipoLancamento _tipo;

  bool get _valido => _nomeController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _resetarCampos();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _resetarCampos() {
    _nomeController.text = widget.categoria.nome;
    _tipo = widget.categoria.tipo;
  }

  Future<void> _salvar() async {
    if (!_valido) return;
    final atualizada = Categoria(id: widget.categoria.id, nome: _nomeController.text.trim(), tipo: _tipo);
    await context.read<FinanceProvider>().editarCategoria(atualizada);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Categoria atualizada!'), behavior: SnackBarBehavior.floating),
    );
  }

  void _confirmarExclusao() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Excluir categoria'),
        content: Text(
          'Tem certeza que deseja excluir "${widget.categoria.nome}"? Lançamentos já feitos com essa categoria não são afetados, mas ela deixa de aparecer para novos lançamentos.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.saida),
            onPressed: () async {
              await context.read<FinanceProvider>().excluirCategoria(widget.categoria.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cor = _tipo == TipoLancamento.entrada ? AppColors.entrada : AppColors.saida;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editando ? 'Editar categoria' : 'Detalhes da categoria',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 22),
              _linha(
                'Nome',
                _editando
                    ? TextField(
                        controller: _nomeController,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(hintText: 'Nome da categoria'),
                      )
                    : _valorEstatico(widget.categoria.nome),
              ),
              const SizedBox(height: 16),
              _linha(
                'Tipo',
                _editando
                    ? _botoesTipo()
                    : _valorEstatico(_tipo == TipoLancamento.entrada ? 'Entrada' : 'Saída', cor: cor),
              ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _botaoSecundario(),
                  Row(children: _botoesPrincipais()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linha(String rotulo, Widget conteudo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        conteudo,
      ],
    );
  }

  Widget _valorEstatico(String texto, {Color? cor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.disabledFill, borderRadius: BorderRadius.circular(12)),
      child: Text(texto, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cor ?? AppColors.textPrimary)),
    );
  }

  Widget _botoesTipo() {
    return Row(
      children: [
        Expanded(child: _botaoTipoItem('Entrada', TipoLancamento.entrada, AppColors.entrada)),
        const SizedBox(width: 10),
        Expanded(child: _botaoTipoItem('Saída', TipoLancamento.saida, AppColors.saida)),
      ],
    );
  }

  Widget _botaoTipoItem(String label, TipoLancamento tipo, Color cor) {
    final selecionado = _tipo == tipo;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _tipo = tipo),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selecionado ? cor.withOpacity(0.12) : AppColors.disabledFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selecionado ? cor : Colors.transparent, width: 1.5),
          ),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selecionado ? cor : AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _botaoSecundario() {
    if (_editando) {
      return TextButton.icon(
        onPressed: () => setState(() {
          _editando = false;
          _resetarCampos();
        }),
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: const Text('Voltar'),
        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
      );
    }
    return TextButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.close_rounded, size: 18),
      label: const Text('Cancelar'),
      style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
    );
  }

  List<Widget> _botoesPrincipais() {
    if (_editando) {
      return [
        ElevatedButton.icon(
          onPressed: _valido ? _salvar : null,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Salvar'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.entrada),
        ),
      ];
    }
    return [
      OutlinedButton.icon(
        onPressed: _confirmarExclusao,
        icon: const Icon(Icons.delete_outline_rounded, size: 18),
        label: const Text('Excluir'),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.saida, side: const BorderSide(color: AppColors.saida)),
      ),
      const SizedBox(width: 10),
      ElevatedButton.icon(
        onPressed: () => setState(() => _editando = true),
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: const Text('Editar'),
      ),
    ];
  }
}
