import 'package:controle_financeiro/widgets/others_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import 'botoes_personalizados.dart';
import 'custom_dialogs.dart';

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
    confirmarExclusao(
      context: context,
      titulo: 'Excluir categoria',
      mensagem:
          'Tem certeza que deseja excluir "${widget.categoria.nome}"? Lançamentos já feitos com essa categoria não são afetados, mas ela deixa de aparecer para novos lançamentos.',
      corBotaoExcluir: AppColors.saida,
      aoConfirmar: () => context.read<FinanceProvider>().excluirCategoria(widget.categoria.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cor = _tipo == TipoLancamento.entrada ? AppColors.entrada : AppColors.saida;

    return DetailDialogShell(
      titulo: _editando ? 'Editar categoria' : 'Detalhes da categoria',
      maxWidth: 400,
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
         rotulo: 'Nome',
         conteudo: _editando
              ? TextField(
                  controller: _nomeController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Nome da categoria'),
                )
              : ValorEstatico(widget.categoria.nome),
        ),
        LinhaDetalhe(
         rotulo: 'Tipo',
         conteudo: _editando
              ? SeletorTipo(tipoSelecionado: _tipo, onSelecionar: (t) => setState(() => _tipo = t))
              : ValorEstatico(_tipo == TipoLancamento.entrada ? 'Entrada' : 'Saída', cor: cor),
        ),
      ],
      
    );
  }
}
