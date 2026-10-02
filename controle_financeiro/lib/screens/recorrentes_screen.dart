import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../models/recorrencia.dart';
import '../models/transacao.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/transacao_detail_dialog.dart';

class RecorrentesScreen extends StatefulWidget {
  const RecorrentesScreen({super.key});

  @override
  State<RecorrentesScreen> createState() => _RecorrentesScreenState();
}

class _RecorrentesScreenState extends State<RecorrentesScreen> {
  bool _mostrarFinalizadasCompacto = false;
  static const _minWidth = 500.0;

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final emAndamento = finance.dados.recorrentes.where((r) => !r.finalizado).toList()
      ..sort((a, b) => a.dataRecorrencia.compareTo(b.dataRecorrencia));
    final finalizadas = finance.dados.recorrentes.where((r) => r.finalizado).toList()
      ..sort((a, b) => b.dataRecorrencia.compareTo(a.dataRecorrencia));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recorrente', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Toque numa recorrência para editar ou excluir',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= _minWidth) {
                final blocoAndamento = _blocoRecorrentes(
                  context,
                  titulo: 'Em andamento',
                  lista: emAndamento,
                  indicadorCor: AppColors.entrada,
                );
                final blocoFinalizadas = _blocoRecorrentes(
                  context,
                  titulo: 'Finalizadas',
                  lista: finalizadas,
                  indicadorCor: AppColors.textSecondary,
                );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: blocoAndamento),
                    const SizedBox(width: 20),
                    Expanded(child: blocoFinalizadas),
                  ],
                );
              }

              final listaCompacto = _mostrarFinalizadasCompacto ? finalizadas : emAndamento;
              final tituloCompacto = _mostrarFinalizadasCompacto ? 'Finalizadas' : 'Em andamento';
              final corCompacto = _mostrarFinalizadasCompacto ? AppColors.textSecondary : AppColors.entrada;

              return _blocoRecorrentes(
                context,
                titulo: tituloCompacto,
                lista: listaCompacto,
                indicadorCor: corCompacto,
                onTrocar: () => setState(() => _mostrarFinalizadasCompacto = !_mostrarFinalizadasCompacto),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _blocoRecorrentes(
    BuildContext context, {
    required String titulo,
    required List<LancamentoRecorrente> lista,
    required Color indicadorCor,
    VoidCallback? onTrocar, // se não-nulo, usa o layout "compacto" do cabeçalho
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: onTrocar != null
                      ? [
                          Text(
                            '${lista.length}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: indicadorCor),
                          ),
                          const SizedBox(width: 8),
                          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                        ]
                      : [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: indicadorCor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                        ],
                ),
                if (onTrocar != null)
                  InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(20),
                    onTap: onTrocar,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.sync_alt_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                  )
                else
                  Text(
                    '${lista.length}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (lista.isNotEmpty) _cabecalhoTabela(),
          Expanded(
            child: ListView.builder(
              itemCount: lista.isEmpty ? 1 : lista.length,
              itemBuilder: (context, index) {
                if (lista.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text('Nenhuma recorrência ainda.', style: Theme.of(context).textTheme.bodyMedium),
                  );
                }
                return _itemRecorrente(context, lista[index]);
              },
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('NOME', style: estilo, overflow: TextOverflow.ellipsis, softWrap: false),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'PRÓXIMA',
              style: estilo,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TÉRMINO',
              style: estilo,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'VALOR',
              style: estilo,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          const SizedBox(width: 18),
        ],
      ),
    );
  }

  Widget _itemRecorrente(BuildContext context, LancamentoRecorrente r) {
    final cor = r.tipo == TipoLancamento.entrada ? AppColors.entrada : AppColors.saida;
    final termino = r.dataTermino == null ? '-' : Formatters.data(r.dataTermino!);

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(12),
      onTap: () => showDialog(
        context: context,
        builder: (_) => TransacaoDetailDialog(transacao: _transacaoFake(r)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                r.descricao?.isNotEmpty == true ? r.descricao! : r.categoriaNome,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                Formatters.data(r.dataRecorrencia),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                termino,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                Formatters.moeda(r.valor),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: cor),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  /// Monta uma Transacao
  Transacao _transacaoFake(LancamentoRecorrente r) {
    return Transacao(
      id: r.id,
      data: r.dataRecorrencia,
      tipo: r.tipo,
      categoriaId: r.categoriaId,
      categoriaNome: r.categoriaNome,
      valor: r.valor,
      descricao: r.descricao,
    );
  }
}