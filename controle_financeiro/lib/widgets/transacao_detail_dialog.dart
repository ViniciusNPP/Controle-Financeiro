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
  final _descricaoController = TextEditingController();

  bool get _valido => _categoria != null && _valor > 0;

  @override
  void initState() {
    super.initState();
    _resetarCampos();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
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
    _descricaoController.text = widget.transacao.descricao ?? '';
  }

  Future<void> _salvar() async {
    if (!_valido) return;
    final descricao = _descricaoController.text.trim();
    final atualizada = Transacao(
      id: widget.transacao.id,
      data: _data,
      tipo: _tipo,
      categoriaId: _categoria!.id,
      categoriaNome: _categoria!.nome,
      valor: _valor,
      descricao: descricao.isEmpty ? null : descricao,
    );
    await context.read<FinanceProvider>().editarTransacao(atualizada);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lançamento atualizado!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmarExclusao() {
    confirmarExclusao(
      context: context,
      titulo: 'Excluir lançamento',
      mensagem: 'Tem certeza que deseja excluir este lançamento? Essa ação não pode ser desfeita.',
      corBotaoExcluir: AppColors.saida,
      aoConfirmar: () => context.read<FinanceProvider>().excluirTransacao(widget.transacao.id, _categoria!.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final corTipo = _tipo == TipoLancamento.entrada ? AppColors.entrada : AppColors.saida;
    void onVoltar() {
      setState(() {
        _editando = false;
        _resetarCampos();
      });
    }

    void onCancelar() => Navigator.of(context).pop();

    void onEditar() => setState(() => _editando = true);

    final temDescricao = (widget.transacao.descricao ?? '').trim().isNotEmpty;

    return DetailDialogShell(
      titulo: _editando ? 'Editar lançamento' : 'Detalhes do lançamento',
      maxWidth: 420,
      onCancelar: onCancelar,
      onVoltar: onVoltar,
      onSalvar: _salvar,
      onEditar: onEditar,
      onExcluir: _confirmarExclusao,
      editando: _editando,
      botaoSecundario: botaoSecundarioDialog(
        context: context,
        editando: _editando,
        onVoltar: onVoltar,
        onCancelar: onCancelar,
      ),
      botoesPrincipais: botoesPrincipaisDialog(
        context: context,
        editando: _editando,
        valido: _valido,
        onSalvar: _salvar,
        onExcluir: _confirmarExclusao,
        onEditar: () => onEditar(),
      ),
      children: [
        LinhaDetalhe(
          rotulo: 'Data',
          conteudo: _editando
              ? DatePickerField(
                  valor: _data,
                  onChanged: (d) => setState(() => _data = d),
                  compact: true,
                )
              : ValorEstatico(Formatters.data(widget.transacao.data)),
        ),
        LinhaDetalhe(
          rotulo: 'Tipo',
          conteudo: _editando
              ? SeletorTipo(
                  tipoSelecionado: _tipo,
                  onSelecionar: (t) => setState(() {
                    _tipo = t;
                    _categoria = null;
                  }),
                )
              : ValorEstatico(
                  _tipo == TipoLancamento.entrada ? 'Entrada' : 'Saída',
                  cor: corTipo,
                ),
        ),
        LinhaDetalhe(
          rotulo: 'Categoria',
          conteudo: _editando
              ? CategorySelector(
                  tipo: _tipo,
                  categoriaSelecionada: _categoria,
                  onSelecionar: (c) => setState(() => _categoria = c),
                  compact: true,
                )
              : ValorEstatico(widget.transacao.categoriaNome),
        ),
        // No modo visualização, a linha de Descrição só aparece se houver algo preenchido
        if (_editando || temDescricao)
          LinhaDetalhe(
            rotulo: 'Descrição',
            conteudo: _editando
                ? TextField(
                    controller: _descricaoController,
                    maxLength: 250,
                    maxLines: 2,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Observação...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  )
                : ValorEstatico(widget.transacao.descricao ?? ''),
          ),
        LinhaDetalhe(
          rotulo: 'Valor',
          conteudo: _editando
              ? CurrencyInput(
                  key: _valorKey,
                  valorInicial: widget.transacao.valor,
                  onChanged: (v) => _valor = v,
                )
              : ValorEstatico(
                  Formatters.moeda(widget.transacao.valor),
                  cor: corTipo,
                ),
        ),
      ],
    );
  }
}
