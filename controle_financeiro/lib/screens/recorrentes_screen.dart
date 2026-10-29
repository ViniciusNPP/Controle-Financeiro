import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../models/recorrencia.dart';
import '../models/transacao.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/layout_dois_containers.dart';
import '../widgets/transacao_detail_dialog.dart';

class RecorrentesScreen extends StatelessWidget {
  const RecorrentesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final emAndamento =
        finance.dados.recorrentes.where((r) => !r.finalizado).toList()
          ..sort((a, b) => a.dataRecorrencia.compareTo(b.dataRecorrencia));
    final finalizadas =
        finance.dados.recorrentes.where((r) => r.finalizado).toList()
          ..sort((a, b) => b.dataRecorrencia.compareTo(a.dataRecorrencia));

    return TelaDuasListas(
      titulo: 'Recorrências',
      primeiro: _config('Em andamento', AppColors.entrada, emAndamento),
      segundo: _config('Finalizadas', AppColors.textSecondary, finalizadas),
    );
  }

  ConfigBloco _config(
    String titulo,
    Color cor,
    List<LancamentoRecorrente> lista,
  ) {
    return ConfigBloco(
      titulo: titulo,
      cor: cor,
      quantidade: lista.length,
      mensagemVazia: 'Nenhuma recorrência ainda.',
      cabecalhoTabela: _cabecalhoTabela(),
      itemBuilder: (context, i) => _itemRecorrente(context, lista[i]),
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
            child: Text(
              'NOME',
              style: estilo,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
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
    final cor = r.tipo == TipoLancamento.entrada
        ? AppColors.entrada
        : AppColors.saida;
    final termino = r.dataTermino == null
        ? '-'
        : Formatters.data(r.dataTermino!);

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(12),
      onTap: () => showDialog(
        context: context,
        builder: (_) => TransacaoDetailDialog(
          transacao: _transacaoFake(r),
          recorrente: true,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                r.descricao?.isNotEmpty == true
                    ? r.descricao!
                    : r.categoriaNome,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
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
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: cor,
                ),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
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
