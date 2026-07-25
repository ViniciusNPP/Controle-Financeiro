import 'package:controle_financeiro/widgets/others_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../models/transacao.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'form_fields.dart';
import 'category_selector.dart';
import 'botoes_personalizados.dart';
import 'custom_dialogs.dart';

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
    confirmarExclusao(
      context: context,
      titulo: 'Excluir lançamento',
      mensagem: 'Tem certeza que deseja excluir este lançamento? Essa ação não pode ser desfeita.',
      corBotaoExcluir: AppColors.saida,
      aoConfirmar: () => context.read<FinanceProvider>().excluirTransacao(widget.transacao.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final corTipo = _tipo == TipoLancamento.entrada ? AppColors.entrada : AppColors.saida;

    return DetailDialogShell(
      titulo: _editando ? 'Editar lançamento' : 'Detalhes do lançamento',
      maxWidth: 420,
      botaoSecundario: botaoSecundarioDialog(
        editando: _editando,
        onVoltar: () => setState(() {
          _editando = false;
          _resetarCampos();
        }),
        onCancelar: () => Navigator.of(context).pop(),
      ),
      botoesPrincipais: botoesPrincipaisDialog(
        editando: _editando,
        valido: _valido,
        onSalvar: _salvar,
        onExcluir: _confirmarExclusao,
        onEditar: () => setState(() => _editando = true),
      ),
      children: [
        LinhaDetalhe(
          rotulo: 'Data',
          conteudo: _editando
              ? DatePickerField(valor: _data, onChanged: (d) => setState(() => _data = d))
              : ValorEstatico(Formatters.data(widget.transacao.data)),
        ),
        LinhaDetalhe(
          rotulo: 'Tipo',
          conteudo: _editando
              ? SeletorTipo(tipoSelecionado: _tipo, onSelecionar: (t) => setState(() => _tipo = t))
              : ValorEstatico(_tipo == TipoLancamento.entrada ? 'Entrada' : 'Saída', cor: corTipo),
        ),
        LinhaDetalhe(
          rotulo: 'Categoria',
          conteudo: _editando
              ? CategorySelector(
                  tipo: _tipo,
                  categoriaSelecionada: _categoria,
                  onSelecionar: (c) => setState(() => _categoria = c),
                )
              : ValorEstatico(widget.transacao.categoriaNome),
        ),
        LinhaDetalhe(
          rotulo: 'Valor',
          conteudo: _editando
              ? CurrencyInput(key: _valorKey, valorInicial: widget.transacao.valor, onChanged: (v) => _valor = v)
              : ValorEstatico(Formatters.moeda(widget.transacao.valor), cor: corTipo),
        ),
      ],
      
    );
  }
}
