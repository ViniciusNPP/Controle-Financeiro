import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../models/filtro_historico.dart';
import '../models/transacao.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/filtro_builder.dart';
import '../widgets/transacao_detail_dialog.dart';

enum _ModoOrdenacao {
  dataDecrescente,
  dataCrescente,
  maiorValor,
  menorValor,
  alfabeticaCrescente,
  alfabeticaDecrescente,
}

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final List<FiltroHistorico> _filtros = [];
  _ModoOrdenacao _ordenacao = _ModoOrdenacao.dataDecrescente;

  void _adicionarFiltro(FiltroHistorico f) => setState(() => _filtros.add(f));
  void _removerFiltro(String id) => setState(() => _filtros.removeWhere((f) => f.id == id));

  void _proximaOrdenacao() {
    setState(() {
      final valores = _ModoOrdenacao.values;
      _ordenacao = valores[(valores.indexOf(_ordenacao) + 1) % valores.length];
    });
  }

  void _ordenacaoAnterior() {
    setState(() {
      final valores = _ModoOrdenacao.values;
      final indiceAtual = valores.indexOf(_ordenacao);
      _ordenacao = valores[(indiceAtual - 1 + valores.length) % valores.length];
    });
  }

  /// Saídas contam como valor negativo na comparação (mesmo sem mostrar o
  /// sinal na tabela), então uma entrada de R$50 é "maior" que uma saída de
  /// R$60 (que vale -60 na prática).
  double _valorComSinal(Transacao t) => t.tipo == TipoLancamento.saida ? -t.valor : t.valor;

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
    final lista = todas.where((t) => _filtros.every((f) => f.aplica(t))).toList();

    switch (_ordenacao) {
      case _ModoOrdenacao.dataCrescente:
        lista.sort((a, b) => a.data.compareTo(b.data));
        break;
      case _ModoOrdenacao.dataDecrescente:
        lista.sort((a, b) => b.data.compareTo(a.data));
        break;
      case _ModoOrdenacao.alfabeticaCrescente:
        lista.sort((a, b) => a.categoriaNome.toLowerCase().compareTo(b.categoriaNome.toLowerCase()));
        break;
      case _ModoOrdenacao.alfabeticaDecrescente:
        lista.sort((a, b) => b.categoriaNome.toLowerCase().compareTo(a.categoriaNome.toLowerCase()));
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
    final sugestoesCategorias = finance.categorias.map((c) => c.nome).toSet().toList()..sort();
    final lista = _filtrarEOrdenar(finance.transacoes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Histórico', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        FiltroBuilder(
          filtrosAtivos: _filtros,
          sugestoesCategorias: sugestoesCategorias,
          onAdicionar: _adicionarFiltro,
          onRemover: _removerFiltro,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text('${lista.length} lançamento(s)', style: Theme.of(context).textTheme.bodyMedium),
            ),
            Tooltip(
              message: 'Clique para mudar · botão direito para voltar',
              child: GestureDetector(
                onSecondaryTap: _ordenacaoAnterior,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _proximaOrdenacao,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: AppTheme.cardDecoration(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconeOrdenacao, size: 16, color: AppColors.primary),
                        Icon(
                          _setaParaCima ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _rotuloOrdenacao,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
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
          child: lista.isEmpty
              ? Center(child: Text('Nenhum lançamento encontrado', style: Theme.of(context).textTheme.bodyMedium))
              : ListView.separated(
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, i) => _linhaTabela(context, lista[i]),
                ),
        ),
      ],
    );
  }

  Widget _cabecalhoTabela() {
    const estilo = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('DATA', style: estilo)),
          Expanded(flex: 3, child: Text('TIPO', style: estilo)),
          Expanded(flex: 4, child: Text('CATEGORIA', style: estilo)),
          Expanded(flex: 3, child: Text('VALOR', style: estilo, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _linhaTabela(BuildContext context, Transacao t) {
    final cor = t.tipo == TipoLancamento.entrada ? AppColors.entrada : AppColors.saida;
    return InkWell(
      onTap: () => showDialog(context: context, builder: (_) => TransacaoDetailDialog(transacao: t)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(Formatters.data(t.data), style: const TextStyle(fontSize: 13.5))),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: cor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    t.tipo == TipoLancamento.entrada ? 'Entrada' : 'Saída',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cor),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(t.categoriaNome, style: const TextStyle(fontSize: 13.5), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 3,
              child: Text(
                Formatters.moeda(t.valor),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: cor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
