import 'package:controle_financeiro/utils/sidebar_utils.dart';
import 'package:controle_financeiro/widgets/animacoes_base.dart';
import 'package:controle_financeiro/widgets/others_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dropdown.dart';
import '../widgets/form_fields.dart';
import '../widgets/category_selector.dart';
import '../widgets/botoes_personalizados.dart';
import '../widgets/recorrencia_widgets.dart';
import '../models/recorrencia.dart' as model;

const double _kLarguraMaxCardDesktop =
    880; // teto de crescimento do card (desktop)
const double _kLarguraLayoutLargo = 700; // ← virada LARGO / COMPACTO (px)
const double _kLarguraMaxCardMobile = 580; // teto do card no mobile

// PONTO DE CONTROLE 3: desktop x mobile por ALTURA
const double _kAlturaMinimaDesktopLargo = 865;
const double _kAlturaMinimaDesktopCompacto = 920;

const double _kMargemVerticalCard = 8;

class AddTransactionScreen extends StatefulWidget {
  final bool ativa;
  const AddTransactionScreen({super.key, this.ativa = true});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // ==========================================================================
  // ESTADO E LÓGICA COMPARTILHADOS (desktop + mobile)
  // ==========================================================================
  final _valorController = TextEditingController(text: '0,00');
  final _descricaoController = TextEditingController();

  DateTime _data = DateTime.now();
  TipoLancamento? _tipo;
  Categoria? _categoria;
  double _valor = 0;

  bool _erroTipo = false;
  bool _erroCategoria = false;
  bool _erroValor = false;

  // Recorrência: fonte única de verdade para desktop (campos inline)
  // e mobile (dialog preenche estes mesmos campos).
  bool _recorrenciaAtiva = false;
  PeriodoRecorrencia _periodo = PeriodoRecorrencia.mensalmente;
  DateTime _inicioRec = _hoje();
  DateTime _terminoRec = _amanha();
  bool _indeterminado = true;

  static DateTime _hoje() {
    final a = DateTime.now();
    return DateTime(a.year, a.month, a.day);
  }

  static DateTime _amanha() => _hoje().add(const Duration(days: 1));

  bool get _valido => _tipo != null && _categoria != null && _valor > 0;

  ConfiguracaoRecorrencia? get _config => !_recorrenciaAtiva
      ? null
      : ConfiguracaoRecorrencia(
          periodo: _periodo,
          dataInicio: _inicioRec,
          dataTermino: _indeterminado ? null : _terminoRec,
        );

  model.PeriodoRecorrencia _paraPeriodoModel(PeriodoRecorrencia p) =>
      switch (p) {
        PeriodoRecorrencia.diariamente => model.PeriodoRecorrencia.diariamente,
        PeriodoRecorrencia.semanalmente =>
          model.PeriodoRecorrencia.semanalmente,
        PeriodoRecorrencia.mensalmente => model.PeriodoRecorrencia.mensalmente,
        PeriodoRecorrencia.anualmente => model.PeriodoRecorrencia.anualmente,
      };

  // O `label` da extension em recorrencia_widgets.dart é privado, então
  // esta tela tem o seu próprio.
  String _labelPeriodo(PeriodoRecorrencia p) => switch (p) {
    PeriodoRecorrencia.diariamente => 'Diariamente',
    PeriodoRecorrencia.semanalmente => 'Semanalmente',
    PeriodoRecorrencia.mensalmente => 'Mensalmente',
    PeriodoRecorrencia.anualmente => 'Anualmente',
  };

  /// Deve ser chamado dentro de setState.
  void _resetarRecorrencia() {
    _recorrenciaAtiva = false;
    _periodo = PeriodoRecorrencia.mensalmente;
    _inicioRec = _hoje();
    _terminoRec = _amanha();
    _indeterminado = true;
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AddTransactionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ativa && !widget.ativa) {
      setState(() {
        _erroTipo = false;
        _erroCategoria = false;
        _erroValor = false;
        // Saiu da aba sem salvar: desfaz a recorrência pendente.
        _resetarRecorrencia();
      });
    }
  }

  void _selecionarTipo(TipoLancamento t) {
    setState(() {
      if (_tipo != t) _categoria = null;
      _tipo = t;
      _erroTipo = false;
    });
  }

  void _alternarTipo() {
    setState(() {
      _tipo = _tipo == TipoLancamento.entrada
          ? TipoLancamento.saida
          : TipoLancamento.entrada;
      _categoria = null;
      _erroTipo = false;
    });
  }

  /// Botão "Limpar" (desktop): volta a tela ao estado inicial.
  void _limpar() {
    _valorController.text = '0,00';
    _descricaoController.clear();
    setState(() {
      _data = DateTime.now();
      _tipo = null;
      _categoria = null;
      _valor = 0;
      _erroTipo = false;
      _erroCategoria = false;
      _erroValor = false;
      _resetarRecorrencia();
    });
  }

  Future<bool> _salvar() async {
    if (!_valido) {
      setState(() {
        _erroTipo = _tipo == null;
        _erroCategoria = _categoria == null;
        _erroValor = _valor <= 0;
      });
      return false;
    }

    try {
      final descricao = _descricaoController.text.trim();
      final config = _config;

      if (config == null) {
        await context.read<FinanceProvider>().adicionarTransacao(
          data: _data,
          tipo: _tipo!,
          categoriaId: _categoria!.id,
          categoriaNome: _categoria!.nome,
          valor: _valor,
          descricao: descricao.isEmpty ? null : descricao,
        );
      } else {
        await context.read<FinanceProvider>().adicionarTransacaoRecorrente(
          data: _data,
          tipo: _tipo!,
          categoriaId: _categoria!.id,
          categoriaNome: _categoria!.nome,
          valor: _valor,
          descricao: descricao.isEmpty ? null : descricao,
          periodo: _paraPeriodoModel(config.periodo),
          dataInicioRecorrencia: config.dataInicio,
          dataTermino: config.dataTermino,
        );
      }

      if (!mounted) return true;
      _valorController.text = '0,00';
      _descricaoController.clear();
      setState(() {
        _tipo = null;
        _categoria = null;
        _valor = 0;
        _resetarRecorrencia();
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Largo ou compacto, a partir da largura disponível (já considera o teto do card).
  bool _ehLargo(double larguraDisponivel) =>
      (larguraDisponivel < _kLarguraMaxCardDesktop
          ? larguraDisponivel
          : _kLarguraMaxCardDesktop) >=
      _kLarguraLayoutLargo;

  // --------------------------------------------------------------------------
  // Campos reutilizados pelos dois layouts
  // --------------------------------------------------------------------------
  Widget _rotulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      texto,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    ),
  );

  Widget _campoData() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _rotulo('Data'),
      DatePickerField(
        valor: _data,
        onChanged: (d) => setState(() => _data = d),
      ),
    ],
  );

  Widget _campoCategoria() => CampoComErro(
    rotulo: 'Categoria',
    erro: _erroCategoria,
    raioBorda: 16,
    child: CategorySelector(
      tipo: _tipo,
      categoriaSelecionada: _categoria,
      onSelecionar: (c) => setState(() {
        _categoria = c;
        _erroCategoria = false;
      }),
    ),
  );

  // O GlobalKey do valor só existe em UM lugar da árvore por vez.
  Widget _campoValor() => CampoComErro(
    rotulo: 'Valor',
    erro: _erroValor,
    child: CurrencyInput(
      controller: _valorController,
      onChanged: (v) => setState(() {
        _valor = v;
        _erroValor = false;
      }),
    ),
  );

  /// Campo cresce para ocupar a altura que sobrar.
  Widget _campoDescricao({bool expandir = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _rotulo('Descrição (opcional)'),
      if (expandir)
        Expanded(
          child: ConstrainedBox(
            // Altura mínima do campo antes de a tela precisar rolar.
            constraints: const BoxConstraints(minHeight: 96),
            child: TextField(
              controller: _descricaoController,
              maxLength: 250,
              maxLines: null,
              minLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(hintText: 'Observação...'),
            ),
          ),
        )
      else
        TextField(
          controller: _descricaoController,
          maxLength: 250,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(hintText: 'Observação...'),
        ),
    ],
  );

  /// Tipo no "meu modelo": um botão que alterna + ícone de trocar.
  /// Usado no MOBILE e no DESKTOP COMPACTO.
  Widget _tipoCiclico() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Tipo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _erroTipo ? Colors.red : AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 16,
            width: 16,
            child: IconButton(
              icon: const Icon(Icons.swap_horiz, size: 16),
              tooltip: 'Trocar tipo',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 16,
              mouseCursor: SystemMouseCursors.click,
              onPressed: _alternarTipo,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      BordaComErro(
        erro: _erroTipo,
        raioBorda: 16,
        child: botaoSelecionavel(
          label: _tipo == TipoLancamento.saida ? 'Saída' : 'Entrada',
          selecionado: _tipo != null,
          cor: _tipo == TipoLancamento.saida
              ? AppColors.saida
              : AppColors.entrada,
          onTap: _alternarTipo,
        ),
      ),
    ],
  );

    @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // ← PONTO DE CONTROLE 1 (largura, via sidebar) + 3 (altura).
        final largo = _ehLargo(c.maxWidth);
        final alturaNecessaria = largo
            ? _kAlturaMinimaDesktopLargo
            : _kAlturaMinimaDesktopCompacto;
        final desktop =
            sidebarVisivel(context) && c.maxHeight >= alturaNecessaria;

        // Cada layout tem a sua chave
        final chaveLayout = !desktop
            ? 'mobile'
            : (largo ? 'desktop_largo' : 'desktop_compacto');

        // MOBILE: altura natural, centralizado.
        // DESKTOP: card ocupa a altura disponível.
        final Widget layout = !desktop
            ? Center(child: SingleChildScrollView(child: _buildMobile(context)))
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _kLarguraMaxCardDesktop,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: _kMargemVerticalCard,
                    ),
                    child: _buildDesktop(context, largo),
                  ),
                ),
              );

        return TrocaFadeThrough(
          chave: chaveLayout,
          expandir: true,
          child: layout,
        );
      },
    );
  }

  /// Espaçamento mínimo abaixo de uma seção.
  Widget _sec(Widget child, {double depois = 20}) => Padding(
    padding: EdgeInsets.only(bottom: depois),
    child: child,
  );

  /// Card que preenche toda a altura que recebe.
  Widget _cartao({required double padding, required List<Widget> secoes}) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      child: LayoutBuilder(
        builder: (context, c) {
          final h = c.maxHeight - padding * 2;
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h > 0 ? h : 0.0),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: secoes,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // DESKTOP
  // ==========================================================================

  Widget _buildDesktop(BuildContext context, bool largo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Novo lançamento',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _cartao(
            padding: 28,
            secoes: [
              // Data | Tipo
              _sec(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _campoData()),
                    SizedBox(width: largo ? 16 : 12),
                    Expanded(child: largo ? _tipoDoisBotoes() : _tipoCiclico()),
                  ],
                ),
              ),
              // Categoria | Valor (largo: lado a lado / compacto: coluna)
              _sec(
                largo
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _campoCategoria()),
                          const SizedBox(width: 16),
                          Expanded(child: _campoValor()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _campoCategoria(),
                          const SizedBox(height: 20),
                          _campoValor(),
                        ],
                      ),
              ),
              Expanded(
                child: _sec(_campoDescricao(expandir: true), depois: 12),
              ),
              _sec(_switchRecorrenteDesktop(), depois: 16),
              _sec(_blocoRecorrencia(largo), depois: 28),
              _botoesDesktop(),
            ],
          ),
        ),
      ],
    );
  }

  /// Limpar | Salvar
  Widget _botoesDesktop() => Row(
    children: [
      SizedBox(
        height: 48,
        child: ToqueElastico(
          child: TextButton.icon(
            onPressed: _limpar,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Limpar'),
            style:
                estiloBotao(
                  corForeGround: AppColors.textSecondary,
                  corBackGround: AppColors.disabledFill,
                ).copyWith(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: BotaoSalvarAnimado(
          label: 'Salvar lançamento',
          corIdle: const Color(0xFF3e3b79),
          aoPressionar: _salvar,
        ),
      ),
    ],
  );

  /// Tipo com dois botões lado a lado (só no desktop LARGO).
  Widget _tipoDoisBotoes() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          'Tipo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _erroTipo ? Colors.red : AppColors.textSecondary,
          ),
        ),
      ),
      BordaComErro(
        erro: _erroTipo,
        raioBorda: 16,
        child: Row(
          children: [
            Expanded(child: _botaoTipo(TipoLancamento.entrada)),
            const SizedBox(width: 8),
            Expanded(child: _botaoTipo(TipoLancamento.saida)),
          ],
        ),
      ),
    ],
  );

  Widget _botaoTipo(TipoLancamento t) {
    final entrada = t == TipoLancamento.entrada;
    final sel = _tipo == t;
    final cor = entrada ? AppColors.entrada : AppColors.saida;
    final corConteudo = sel ? cor : AppColors.textSecondary;

    return HoverAnimado(
      raio: 14,
      escala: 1.03,
      child: GestureDetector(
        onTap: () => _selecionarTipo(t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? cor.withValues(alpha: 0.12) : AppColors.disabledFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? cor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                entrada
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 16,
                color: corConteudo,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  entrada ? 'Entrada' : 'Saída',
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: corConteudo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchRecorrenteDesktop() => Row(
    children: [
      SwitchRecorrencia(
        ativo: _recorrenciaAtiva,
        onChanged: (v) => setState(() => _recorrenciaAtiva = v),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recorrente',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Esta transação se repetirá automaticamente.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ],
  );

  /// Retângulo da recorrência (desktop). Cinza/desabilitado com o switch
  /// desligado; branco e interativo com o switch ligado.
  Widget _blocoRecorrencia(bool largo) {
    final ativo = _recorrenciaAtiva;
    final corTexto = ativo ? AppColors.textPrimary : AppColors.textSecondary;
    final corIcone = ativo ? const Color(0xFF3e3b79) : AppColors.textSecondary;

    Widget rotulo(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: corTexto,
        ),
      ),
    );

    final campoRepetir = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        rotulo('Repetir'),
        Opacity(
          opacity: ativo ? 1 : 0.55,
          child: dropdownEstilizado(
            opcoes: [
              for (final p in PeriodoRecorrencia.values) _labelPeriodo(p),
            ],
            valorSelecionado: _labelPeriodo(_periodo),
            onSelecionar: (label) {
              final escolhido = PeriodoRecorrencia.values.firstWhere(
                (p) => _labelPeriodo(p) == label,
              );
              setState(() => _periodo = escolhido);
            },
          ),
        ),
      ],
    );

    final switchIndeterminado = SizedBox(
      height: 52,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _indeterminado = !_indeterminado),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Indeterminado',
                softWrap: false,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: corTexto,
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
    );

    final campoInicio = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        rotulo('A partir de'),
        DatePickerField(
          valor: _inicioRec,
          firstDate: _hoje(),
          desativado: !ativo,
          onChanged: (d) => setState(() {
            _inicioRec = d;
            if (!_terminoRec.isAfter(_inicioRec)) {
              _terminoRec = _inicioRec.add(const Duration(days: 1));
            }
          }),
        ),
      ],
    );

    // Só habilita quando o bloco está ativo E "Indeterminado" está desligado.
    final campoTermino = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        rotulo('Termina em'),
        DatePickerField(
          valor: _terminoRec,
          firstDate: _inicioRec.add(const Duration(days: 1)),
          desativado: !ativo || _indeterminado,
          onChanged: (d) => setState(() => _terminoRec = d),
        ),
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ativo ? AppColors.surface : AppColors.disabledFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      // Bloqueia toda interação enquanto o switch "Recorrente" está desligado.
      child: IgnorePointer(
        ignoring: !ativo,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: corIcone.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: corIcone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Configuração da recorrência',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: corTexto,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Repetir + Indeterminado na mesma linha
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: campoRepetir),
                const SizedBox(width: 16),
                switchIndeterminado,
              ],
            ),
            const SizedBox(height: 16),

            // A partir de | Termina em (largo: lado a lado / compacto: coluna)
            if (largo)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: campoInicio),
                  const SizedBox(width: 16),
                  Expanded(child: campoTermino),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  campoInicio,
                  const SizedBox(height: 16),
                  campoTermino,
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // MOBILE
  // ==========================================================================

  /// No mobile a recorrência continua sendo configurada pelo dialog,
  /// que preenche os mesmos campos usados pelo desktop.
  Future<void> _alternarRecorrenciaMobile(bool valor) async {
    if (!valor) {
      setState(_resetarRecorrencia);
      return;
    }

    // Ativa visualmente o switch já ao ligar, e abre o dialog em seguida.
    setState(() => _recorrenciaAtiva = true);

    final resultado = await RecorrenciaDialog.show(
      context,
      configuracaoInicial: _config,
    );

    if (!mounted) return;

    if (resultado == null) {
      // Cancelou ou fechou no X: volta pro estado desativado.
      setState(_resetarRecorrencia);
    } else {
      setState(() {
        _periodo = resultado.periodo;
        _inicioRec = resultado.dataInicio;
        _indeterminado = resultado.dataTermino == null;
        _terminoRec =
            resultado.dataTermino ??
            resultado.dataInicio.add(const Duration(days: 1));
      });
    }
  }

  Widget _buildMobile(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _kLarguraMaxCardMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _campoData()),
                    const SizedBox(width: 12),
                    Expanded(child: _tipoCiclico()),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _campoCategoria()),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _rotulo('Recorrente'),
                        SizedBox(
                          height: 52,
                          child: Center(
                            child: SwitchRecorrencia(
                              ativo: _recorrenciaAtiva,
                              onChanged: _alternarRecorrenciaMobile,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _campoDescricao(),
                const SizedBox(height: 8),
                _campoValor(),
                const SizedBox(height: 28),
                _botoesDesktop(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
