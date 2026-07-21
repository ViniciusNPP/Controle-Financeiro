import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../models/transacao.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'form_fields.dart';
import 'category_selector.dart';

class TransacaoDetailDialog extends StatefulWidget {
  final Transacao transacao;

  const TransacaoDetailDialog({super.key, required this.transacao});

  @override
  State<TransacaoDetailDialog> createState() => _TransacaoDetailDialogState();
}

class _TransacaoDetailDialogState extends State<TransacaoDetailDialog> {
  bool _editando = false;
  late DateTime _data;
  late TipoLancamento _tipo;
  Categoria? _categoria;
  double _valor = 0;
  final _valorKey = GlobalKey<CurrencyInputState>();

  bool get _valido => _categoria != null && _valor > 0;

  @override
  void initState() {
    super.initState();
    _resetarCampos();
  }

  void _resetarCampos() {
    _data = widget.transacao.data;
    _tipo = widget.transacao.tipo;
    _valor = widget.transacao.valor;
    _categoria = Categoria(
      id: widget.transacao.categoriaId,
      nome: widget.transacao.categoriaNome,
      tipo: widget.transacao.tipo,
    );
  }

  Future<void> _salvar() async {
    if (!_valido) return;
    final atualizada = Transacao(
      id: widget.transacao.id,
      data: _data,
      tipo: _tipo,
      categoriaId: _categoria!.id,
      categoriaNome: _categoria!.nome,
      valor: _valor,
    );
    await context.read<FinanceProvider>().editarTransacao(atualizada);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lançamento atualizado!'), behavior: SnackBarBehavior.floating),
    );
  }

  void _confirmarExclusao() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Excluir lançamento'),
        content: const Text('Tem certeza que deseja excluir este lançamento? Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.saida),
            onPressed: () async {
              await context.read<FinanceProvider>().excluirTransacao(widget.transacao.id);
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
    final corTipo = _tipo == TipoLancamento.entrada ? AppColors.entrada : AppColors.saida;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editando ? 'Editar lançamento' : 'Detalhes do lançamento',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 22),
              _linha(
                'Data',
                _editando
                    ? DatePickerField(valor: _data, onChanged: (d) => setState(() => _data = d))
                    : _valorEstatico(Formatters.data(widget.transacao.data)),
              ),
              const SizedBox(height: 16),
              _linha(
                'Tipo',
                _editando
                    ? _botoesTipo()
                    : _valorEstatico(_tipo == TipoLancamento.entrada ? 'Entrada' : 'Saída', cor: corTipo),
              ),
              const SizedBox(height: 16),
              _linha(
                'Categoria',
                _editando
                    ? CategorySelector(
                        tipo: _tipo,
                        categoriaSelecionada: _categoria,
                        onSelecionar: (c) => setState(() => _categoria = c),
                      )
                    : _valorEstatico(widget.transacao.categoriaNome),
              ),
              const SizedBox(height: 16),
              _linha(
                'Valor',
                _editando
                    ? CurrencyInput(key: _valorKey, valorInicial: widget.transacao.valor, onChanged: (v) => _valor = v)
                    : _valorEstatico(Formatters.moeda(widget.transacao.valor), cor: corTipo, destaque: true),
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

  Widget _valorEstatico(String texto, {Color? cor, bool destaque = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.disabledFill, borderRadius: BorderRadius.circular(12)),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: destaque ? 20 : 15,
          fontWeight: destaque ? FontWeight.w700 : FontWeight.w600,
          color: cor ?? AppColors.textPrimary,
        ),
      ),
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
        onTap: () => setState(() {
          _tipo = tipo;
          _categoria = null;
        }),
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
