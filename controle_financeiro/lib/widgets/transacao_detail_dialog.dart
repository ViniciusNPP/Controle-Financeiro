import 'package:controle_financeiro/widgets/others_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../models/recorrencia.dart';
import '../models/transacao.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dropdown.dart';
import '../utils/formatters.dart';
import 'form_fields.dart';
import 'category_selector.dart';
import 'botoes_personalizados.dart';
import 'custom_dialogs.dart';
import 'recorrencia_widgets.dart' show SwitchRecorrencia;

class TransacaoDetailDialog extends StatefulWidget {
  final Transacao transacao;

  /// true = [transacao] é só uma "fachada" de um LancamentoRecorrente
  /// (mesmo id). Editar/excluir passa a atuar no molde da recorrência.
  final bool recorrente;

  const TransacaoDetailDialog({
    super.key,
    required this.transacao,
    this.recorrente = false,
  });

  @override
  State<TransacaoDetailDialog> createState() => _TransacaoDetailDialogState();
}

class _TransacaoDetailDialogState extends State<TransacaoDetailDialog> {
  bool _editando = false;
  int _pagina = 0;

  // Página 1
  late DateTime _data;
  late TipoLancamento _tipo;
  Categoria? _categoria;
  double _valor = 0;
  final _valorKey = GlobalKey<CurrencyInputState>();
  final _descricaoController = TextEditingController();

  // Página 2 (só recorrência)
  LancamentoRecorrente? _molde;
  late PeriodoRecorrencia _periodo;
  late DateTime _dataInicio;
  late DateTime _dataProxima;
  late DateTime _dataTermino;
  late bool _indeterminado;

  bool _erroCategoria = false;
  bool _erroValor = false;

  bool get _valido => _categoria != null && _valor > 0;

  static String _labelPeriodo(PeriodoRecorrencia p) => switch (p) {
    PeriodoRecorrencia.diariamente => 'Diariamente',
    PeriodoRecorrencia.semanalmente => 'Semanalmente',
    PeriodoRecorrencia.mensalmente => 'Mensalmente',
    PeriodoRecorrencia.anualmente => 'Anualmente',
  };

  @override
  void initState() {
    super.initState();
    if (widget.recorrente) {
      _molde = context.read<FinanceProvider>().dados.recorrentes.firstWhere(
        (r) => r.id == widget.transacao.id,
      );
    }
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

    final m = _molde;
    if (m != null) {
      _periodo = m.periodo;
      _dataInicio = m.dataInicio;
      _dataProxima = m.dataRecorrencia;
      _dataTermino = m.dataTermino ?? m.dataInicio.add(const Duration(days: 1));
      _indeterminado = m.dataTermino == null;
    }
  }

  Future<bool> _salvar() async {
    if (!_valido) {
      setState(() {
        _pagina = 0; // os erros de validação ficam na página 1
        _erroCategoria = _categoria == null;
        _erroValor = _valor <= 0;
      });
      return false;
    }
    try {
      final descricao = _descricaoController.text.trim();
      final provider = context.read<FinanceProvider>();

      if (widget.recorrente) {
        await provider.editarRecorrente(
          LancamentoRecorrente(
            id: _molde!.id,
            tipo: _tipo,
            categoriaId: _categoria!.id,
            categoriaNome: _categoria!.nome,
            valor: _valor,
            descricao: descricao.isEmpty ? null : descricao,
            periodo: _periodo,
            dataInicio: _dataInicio,
            dataRecorrencia: _dataProxima,
            dataTermino: _indeterminado ? null : _dataTermino,
          ),
        );
      } else {
        await provider.editarTransacao(
          Transacao(
            id: widget.transacao.id,
            data: _data,
            tipo: _tipo,
            categoriaId: _categoria!.id,
            categoriaNome: _categoria!.nome,
            valor: _valor,
            descricao: descricao.isEmpty ? null : descricao,
          ),
        );
      }
      if (!mounted) return true;
      Navigator.of(context).pop();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _confirmarExclusao() {
    final recorrente = widget.recorrente;
    confirmarExclusao(
      context: context,
      titulo: recorrente ? 'Excluir recorrência' : 'Excluir lançamento',
      mensagem: recorrente
          ? 'Tem certeza que deseja excluir esta recorrência? Os lançamentos já gerados continuam no histórico. Essa ação não pode ser desfeita.'
          : 'Tem certeza que deseja excluir este lançamento? Essa ação não pode ser desfeita.',
      corBotaoExcluir: AppColors.saida,
      aoConfirmar: () {
        final provider = context.read<FinanceProvider>();
        return recorrente
            ? provider.excluirRecorrente(widget.transacao.id)
            : provider.excluirTransacao(widget.transacao.id, _categoria!.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final corTipo = _tipo == TipoLancamento.entrada
        ? AppColors.entrada
        : AppColors.saida;
    void onVoltar() {
      setState(() {
        _editando = false;
        _resetarCampos();
      });
    }

    void onCancelar() => Navigator.of(context).pop();

    void onEditar() => setState(() => _editando = true);

    final temDescricao = (widget.transacao.descricao ?? '').trim().isNotEmpty;
    final rec = widget.recorrente;

    final String titulo = rec
        ? (_editando ? 'Editar recorrência' : 'Detalhes da recorrência')
        : (_editando ? 'Editar lançamento' : 'Detalhes do lançamento');

    return DetailDialogShell(
      titulo: titulo,
      maxWidth: 420,
      onCancelar: onCancelar,
      onVoltar: onVoltar,
      onSalvar: () => _salvar(),
      onEditar: onEditar,
      onExcluir: _confirmarExclusao,
      editando: _editando,
      pagina: _pagina,
      onPagina: rec ? (p) => setState(() => _pagina = p) : null,
      children2: rec ? _paginaRegra() : null,
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
        onSalvar: () => _salvar(),
        onExcluir: _confirmarExclusao,
        onEditar: () => onEditar(),
        botaoSalvarCustom: BotaoSalvarAnimado(
          label: 'Salvar',
          corIdle: AppColors.entrada,
          compacto: true,
          telaPequena: MediaQuery.sizeOf(context).width < 600,
          usarSucesso: false,
          aoPressionar: _salvar,
        ),
      ),
      children: [
        // Na recorrência a data é "Próxima", que fica na página 2.
        if (!rec)
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
          erro: _editando && _erroCategoria,
          conteudo: _editando
              ? BordaComErro(
                  erro: _erroCategoria,
                  raioBorda: 16,
                  child: CategorySelector(
                    tipo: _tipo,
                    categoriaSelecionada: _categoria,
                    onSelecionar: (c) => setState(() {
                      _categoria = c;
                      _erroCategoria = false;
                    }),
                    compact: true,
                  ),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  )
                : ValorEstatico(widget.transacao.descricao ?? ''),
          ),
        LinhaDetalhe(
          rotulo: 'Valor',
          erro: _editando && _erroValor,
          conteudo: _editando
              ? BordaComErro(
                  erro: _erroValor,
                  child: CurrencyInput(
                    key: _valorKey,
                    valorInicial: _valor,
                    onChanged: (v) => setState(() {
                      _valor = v;
                      _erroValor = false;
                    }),
                  ),
                )
              : ValorEstatico(
                  Formatters.moeda(widget.transacao.valor),
                  cor: corTipo,
                ),
        ),
      ],
    );
  }

  /// Página 2: detalhes da regra de recorrência.
  List<Widget> _paginaRegra() {
    return [
      LinhaDetalhe(
        rotulo: 'Repetir',
        conteudo: _editando
            ? dropdownEstilizado(
                opcoes: [for (final p in PeriodoRecorrencia.values) _labelPeriodo(p)],
                valorSelecionado: _labelPeriodo(_periodo),
                onSelecionar: (label) => setState(() {
                  _periodo = PeriodoRecorrencia.values.firstWhere(
                    (p) => _labelPeriodo(p) == label,
                  );
                }),
              )
            : ValorEstatico(_labelPeriodo(_periodo)),
      ),
      LinhaDetalhe(
        rotulo: 'A partir de',
        conteudo: _editando
            ? DatePickerField(
                valor: _dataInicio,
                compact: true,
                onChanged: (d) => setState(() {
                  _dataInicio = d;
                  if (_dataProxima.isBefore(_dataInicio)) _dataProxima = _dataInicio;
                  if (!_dataTermino.isAfter(_dataInicio)) {
                    _dataTermino = _dataInicio.add(const Duration(days: 1));
                  }
                }),
              )
            : ValorEstatico(Formatters.data(_dataInicio)),
      ),
      LinhaDetalhe(
        rotulo: 'Próxima',
        conteudo: _editando
            ? DatePickerField(
                valor: _dataProxima,
                firstDate: _dataInicio,
                compact: true,
                onChanged: (d) => setState(() => _dataProxima = d),
              )
            : ValorEstatico(Formatters.data(_dataProxima)),
      ),
      LinhaDetalhe(
        rotulo: 'Termina em',
        conteudo: _editando
            ? DatePickerField(
                valor: _dataTermino,
                firstDate: _dataInicio.add(const Duration(days: 1)),
                desativado: _indeterminado,
                compact: true,
                onChanged: (d) => setState(() => _dataTermino = d),
              )
            : ValorEstatico(
                _indeterminado ? 'Indeterminado' : Formatters.data(_dataTermino),
              ),
      ),
      if (_editando)
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _indeterminado = !_indeterminado),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Indeterminado',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                SwitchRecorrencia(
                  ativo: _indeterminado,
                  onChanged: (v) => setState(() => _indeterminado = v),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}