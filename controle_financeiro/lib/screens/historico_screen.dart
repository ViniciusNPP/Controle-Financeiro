import 'package:controle_financeiro/utils/sidebar_utils.dart';
import 'package:controle_financeiro/widgets/animacoes_base.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../models/filtro_historico.dart';
import '../models/transacao.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatadores.dart';
import '../widgets/historico_filtro.dart';
import '../widgets/dialogs/transacao_detalhes_dialog.dart';
import '../utils/dialog_fade.dart';

enum _ModoOrdenacao {
  dataDecrescente,
  dataCrescente,
  maiorValor,
  menorValor,
  alfabeticaCrescente,
  alfabeticaDecrescente,
}

class HistoricoScreen extends StatefulWidget {
  /// Filtros vindos de fora para serem adicionados como filtros ativos normais
  final List<FiltroHistorico>? filtrosExternos;
  final Object? pedidoExternoId;

  const HistoricoScreen({
    super.key,
    this.filtrosExternos,
    this.pedidoExternoId,
  });

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final List<FiltroHistorico> _filtros = [];
  FiltroHistorico? _filtroRapido;
  int _resetFiltroRapido = 0;
  _ModoOrdenacao _ordenacao = _ModoOrdenacao.dataDecrescente;
  Object? _ultimoPedidoExternoId;
  bool _filtrosAbertos = false;
  bool _painelNaTela = false;
  static const _larguraMaximaFiltro = 510.0;

  /// Largura máxima do container de filtros.
  static const _alturaCabecalho = 40.0;

  @override
  void initState() {
    super.initState();
    _aplicarFiltrosExternosSeHouver();
  }

  @override
  void didUpdateWidget(covariant HistoricoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _aplicarFiltrosExternosSeHouver();
  }

  /// Substitui os filtros de categoria/data vindos do gráfico anterior pelos novos
  void _aplicarFiltrosExternosSeHouver() {
    final filtros = widget.filtrosExternos;
    if (filtros == null || filtros.isEmpty) return;
    if (widget.pedidoExternoId == _ultimoPedidoExternoId) return;
    _ultimoPedidoExternoId = widget.pedidoExternoId;

    setState(() {
      _filtros
          .clear(); // descarta filtros antigos (de gráficos anteriores ou manuais)
      _filtros.addAll(filtros);
      _filtroRapido = null; // descarta o filtro rápido pendente
      _resetFiltroRapido++; // avisa o FiltroBuilder para limpar os campos
    });
  }

  void _adicionarFiltro(FiltroHistorico f) => setState(() => _filtros.add(f));
  void _removerFiltro(String id) =>
      setState(() => _filtros.removeWhere((f) => f.id == id));
  void _limparTodosFiltros() => setState(() => _filtros.clear());
  void _setFiltroRapido(FiltroHistorico? f) =>
      setState(() => _filtroRapido = f);

  void _definirFiltrosAbertos(bool abrir) {
    setState(() {
      _filtrosAbertos = abrir;
      if (abrir) _painelNaTela = true;
    });
  }

  void _mudarOrdenacao(int direcao) {
    setState(() {
      final valores = _ModoOrdenacao.values;
      final indiceAtual = valores.indexOf(_ordenacao);
      _ordenacao =
          valores[(indiceAtual + direcao + valores.length) % valores.length];
    });
  }

  String _rotuloPagamento(Transacao t) =>
      t.ehCredito ? 'Crédito' : (t.ehReembolso ? 'Reembolso' : '');

  double _valorComSinal(Transacao t) =>
      t.tipo == TipoLancamento.saida ? -t.valor : t.valor;
    
  bool get _creditoAtivo =>
      _filtros.any((f) => f.ehCredito) || (_filtroRapido?.ehCredito ?? false);

  IconData get _iconeOrdenacao {
    switch (_ordenacao) {
      case _ModoOrdenacao.dataCrescente:
      case _ModoOrdenacao.dataDecrescente:
        return Icons.calendar_month_rounded;
      case _ModoOrdenacao.alfabeticaCrescente:
      case _ModoOrdenacao.alfabeticaDecrescente:
        return Icons.sort_by_alpha_rounded;
      case _ModoOrdenacao.maiorValor:
      case _ModoOrdenacao.menorValor:
        return Icons.attach_money_rounded;
    }
  }

  bool get _setaParaCima {
    switch (_ordenacao) {
      case _ModoOrdenacao.dataCrescente:
      case _ModoOrdenacao.alfabeticaCrescente:
      case _ModoOrdenacao.menorValor:
        return true;
      default:
        return false;
    }
  }

  String get _rotuloOrdenacao {
    switch (_ordenacao) {
      case _ModoOrdenacao.dataCrescente:
        return 'Data (mais antiga)';
      case _ModoOrdenacao.dataDecrescente:
        return 'Data (mais recente)';
      case _ModoOrdenacao.alfabeticaCrescente:
        return 'Categoria (A-Z)';
      case _ModoOrdenacao.alfabeticaDecrescente:
        return 'Categoria (Z-A)';
      case _ModoOrdenacao.maiorValor:
        return 'Maior valor';
      case _ModoOrdenacao.menorValor:
        return 'Menor valor';
    }
  }

  List<Transacao> _filtrarEOrdenar(List<Transacao> todas) {
    final lista = todas.where((t) {
      final passaFiltrosAtivos = _filtros.every((f) => f.aplica(t));
      final passaFiltroRapido = _filtroRapido?.aplica(t) ?? true;
      return passaFiltrosAtivos && passaFiltroRapido;
    }).toList();

    switch (_ordenacao) {
      case _ModoOrdenacao.dataCrescente:
        lista.sort((a, b) => a.data.compareTo(b.data));
        break;
      case _ModoOrdenacao.dataDecrescente:
        lista.sort((a, b) => b.data.compareTo(a.data));
        break;
      case _ModoOrdenacao.alfabeticaCrescente:
        lista.sort(
          (a, b) => a.categoriaNome.toLowerCase().compareTo(
            b.categoriaNome.toLowerCase(),
          ),
        );
        break;
      case _ModoOrdenacao.alfabeticaDecrescente:
        lista.sort(
          (a, b) => b.categoriaNome.toLowerCase().compareTo(
            a.categoriaNome.toLowerCase(),
          ),
        );
        break;
      case _ModoOrdenacao.maiorValor:
        lista.sort((a, b) => _valorComSinal(b).compareTo(_valorComSinal(a)));
        break;
      case _ModoOrdenacao.menorValor:
        lista.sort((a, b) => _valorComSinal(a).compareTo(_valorComSinal(b)));
        break;
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final sugestoesCategorias =
        finance.categorias.map((c) => c.nome).toSet().toList()..sort();
    final lista = _filtrarEOrdenar(finance.transacoes);

    DateTime? dataMinima;
    DateTime? dataMaxima;
    for (final t in finance.transacoes) {
      if (dataMinima == null || t.data.isBefore(dataMinima))
        dataMinima = t.data;
      if (dataMaxima == null || t.data.isAfter(dataMaxima)) dataMaxima = t.data;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mostrarTitulo = sidebarVisivel(context);

          final filtroBuilder = FiltroBuilder(
            filtrosAtivos: _filtros,
            sugestoesCategorias: sugestoesCategorias,
            onAdicionar: _adicionarFiltro,
            onRemover: _removerFiltro,
            onLimparTodos: _limparTodosFiltros,
            onFiltroRapidoChanged: _setFiltroRapido,
            dataMinima: dataMinima,
            dataMaxima: dataMaxima,
            resetToken: _resetFiltroRapido,
          );

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: _alturaCabecalho,
                    child: Row(
                      children: [
                        if (mostrarTitulo)
                          Text(
                            'Histórico',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        const Spacer(),
                        _botaoFiltros(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${lista.length} lançamento(s)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Tooltip(
                        message:
                            'Clique para mudar · botão direito para voltar',
                        child: GestureDetector(
                          onSecondaryTap: () => _mudarOrdenacao(-1),
                          child: HoverAnimado(
                            // ← novo
                            raio: 20,
                            escala: 1.04,
                            child: InkWell(
                              hoverColor: Colors.transparent, // ← novo
                              mouseCursor: SystemMouseCursors.click,
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _mudarOrdenacao(1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: AppTheme.cardDecoration(),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _iconeOrdenacao,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    Icon(
                                      _setaParaCima
                                          ? Icons.arrow_upward_rounded
                                          : Icons.arrow_downward_rounded,
                                      size: 13,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _rotuloOrdenacao,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _cabecalhoTabela(),
                  const Divider(height: 1, color: AppColors.border),
                  Expanded(
                    child: TrocaFadeThrough(
                      // Muda quando o resultado muda (filtros, ordem ou dados).
                      chave: Object.hashAll(lista.map((t) => t.id)),
                      expandir: true,
                      child: lista.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhum lançamento encontrado',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              itemCount: lista.length,
                              separatorBuilder: (_, _) => const Divider(
                                height: 1,
                                color: AppColors.border,
                              ),
                              itemBuilder: (context, i) =>
                                  _linhaTabela(context, lista[i]),
                            ),
                    ),
                  ),
                  _linhaTotal(lista),
                ],
              ),

              // Área invisível: clicar em qualquer lugar fora do painel fecha o filtro.
              if (_filtrosAbertos)
                Positioned.fill(
                  key: const ValueKey('filtro_fora'),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _filtrosAbertos = false),
                  ),
                ),

              // Fade ao abrir/fechar. Continua montado (preserva os campos do
              // filtro rápido) e só sai da tela depois do fade de saída.
              Positioned(
                key: const ValueKey('filtro_painel'),
                top: _alturaCabecalho + 4,
                left: 0,
                right: 0,
                child: Offstage(
                  offstage: !_painelNaTela,
                  child: IgnorePointer(
                    ignoring: !_filtrosAbertos,
                    child: AnimatedOpacity(
                      opacity: _filtrosAbertos ? 1 : 0,
                      duration: AppMotion.fade,
                      onEnd: () {
                        if (!_filtrosAbertos && _painelNaTela) {
                          setState(() => _painelNaTela = false);
                        }
                      },
                      child: Align(
                        alignment: Alignment.topRight,
                        heightFactor: 1,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _larguraMaximaFiltro,
                          ),
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(20),
                            clipBehavior: Clip.antiAlias,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: constraints.maxHeight * 0.8,
                              ),
                              child: SingleChildScrollView(
                                child: filtroBuilder,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _botaoFiltros() {
    return HoverAnimado(
      raio: 20,
      escala: 1.04,
      child: InkWell(
        hoverColor: Colors.transparent,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(12),
        onTap: () => _definirFiltrosAbertos(!_filtrosAbertos),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: AppTheme.cardDecoration(),
          child: Text(
            _filtrosAbertos ? 'Filtro ▴' : 'Filtro ▾',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalhoTabela() {
    const estilo = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: _ColunasHistorico(
        data: Text('DATA', style: estilo),
        categoria: Text('CATEGORIA', style: estilo),
        pagamento: _TextoCortado('PAGAMENTO', estilo: estilo),
        valor: Text('VALOR', style: estilo, textAlign: TextAlign.right),
      ),
    );
  }

  Widget _linhaTabela(BuildContext context, Transacao t) {
    final cor = t.tipo == TipoLancamento.entrada
        ? AppColors.entrada
        : AppColors.saida;
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () => mostrarDialogo(
        context: context,
        builder: (_) => TransacaoDetailDialog(transacao: t),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: _ColunasHistorico(
          data: Text(
            Formatters.data(t.data),
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(fontSize: 13.5),
          ),
          categoria: Text(
            t.categoriaNome,
            style: const TextStyle(fontSize: 13.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          pagamento: _TextoCortado(
            _rotuloPagamento(t),
            estilo: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          valor: Text(
            Formatters.moeda(t.valor),
            textAlign: TextAlign.right,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _linhaTotal(List<Transacao> lista) {
    final total = lista
        .where((t) => _creditoAtivo || !t.neutralizadaPorReembolso)
        .fold<double>(0, (soma, t) => soma + _valorComSinal(t));
    final cor = total < 0 ? AppColors.saida : AppColors.entrada;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          Text(
            Formatters.moeda(total.abs()),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Divide a largura da linha entre as 4 colunas: Data e Valor nunca ficam
/// abaixo do mínimo; o que sobra é dividido entre Categoria e Pagamento.
class _ColunasHistorico extends StatelessWidget {
  final Widget data;
  final Widget categoria;
  final Widget pagamento;
  final Widget valor;

  static const _minData = 84.0; // cabe "dd/mm/aaaa" em uma linha
  static const _minValor = 100.0; // cabe "R$ 123.456,78"
  static const _pesoCategoria = 5.0; // sobra: Categoria 5 x Pagamento 3
  static const _pesoPagamento = 3.0;

  const _ColunasHistorico({
    required this.data,
    required this.categoria,
    required this.pagamento,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final total = box.maxWidth;
        final wData = (total * 3 / 13).clamp(_minData, double.infinity);
        final wValor = (total * 3 / 13).clamp(_minValor, double.infinity);
        final resto = (total - wData - wValor).clamp(0.0, double.infinity);
        final soma = _pesoCategoria + _pesoPagamento;
        final wCategoria = resto * _pesoCategoria / soma;
        final wPagamento = resto * _pesoPagamento / soma;

        return Row(
          children: [
            SizedBox(width: wData, child: data),
            SizedBox(width: wCategoria, child: categoria),
            SizedBox(width: wPagamento, child: pagamento),
            SizedBox(width: wValor, child: valor),
          ],
        );
      },
    );
  }
}

/// Texto de uma linha só. Se não couber, corta e termina com "." (ex.: "Créd.").
class _TextoCortado extends StatelessWidget {
  final String texto;
  final TextStyle estilo;

  const _TextoCortado(this.texto, {required this.estilo});

  double _largura(String s) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: estilo),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final w = tp.width;
    tp.dispose();
    return w;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        var t = texto;
        if (texto.isNotEmpty && _largura(texto) > box.maxWidth) {
          var n = texto.length - 1;
          while (n > 1 && _largura('${texto.substring(0, n)}.') > box.maxWidth) {
            n--;
          }
          t = '${texto.substring(0, n)}.';
        }
        return Text(
          t,
          style: estilo,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
        );
      },
    );
  }
}