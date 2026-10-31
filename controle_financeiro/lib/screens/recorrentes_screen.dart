import 'package:controle_financeiro/widgets/animacoes_base.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../models/categoria.dart';
import '../models/recorrencia.dart';
import '../models/transacao.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/layout_dois_containers.dart';
import '../widgets/transacao_detail_dialog.dart';
import '../utils/dialog_fade.dart';

enum _Campo { nome, proxima, termino, valor }

class _Coluna {
  const _Coluna(
    this.campo,
    this.rotulo,
    this.flex,
    this.larguraMin,
    this.prioridade,
    this.alinhamento,
  );

  final _Campo campo;
  final String rotulo;
  final int flex;
  final double larguraMin; // espaço mínimo para o valor não ser cortado
  final int prioridade; // 1 = mais importante
  final TextAlign alinhamento;
}

// Ordem de exibição. CAMPO , RÓTULO , FLEX , LARGURA MÍNIMA , PRIORIDADE , ALINHAMENTO
const _colunas = [
  _Coluna(_Campo.nome, 'NOME', 3, 110, 1, TextAlign.left),
  _Coluna(_Campo.proxima, 'PRÓXIMA', 2, 80, 2, TextAlign.center),
  _Coluna(_Campo.termino, 'TÉRMINO', 2, 80, 3, TextAlign.center),
  _Coluna(_Campo.valor, 'VALOR', 2, 100, 1, TextAlign.right),
];

const _larguraChevron = 20.0; // SizedBox(2) + ícone de 18

/// Tira as colunas de menor importância e volta quando alarga a tela
List<_Coluna> _colunasVisiveis(double largura) {
  final maxNivel = _colunas.map((c) => c.prioridade).reduce(max);
  for (var nivel = maxNivel; nivel > 1; nivel--) {
    final visiveis = _colunas.where((c) => c.prioridade <= nivel).toList();
    final somaFlex = visiveis.fold<int>(0, (s, c) => s + c.flex);
    final cabe = visiveis.every(
      (c) => (largura - _larguraChevron) * c.flex / somaFlex >= c.larguraMin,
    );
    if (cabe) return visiveis;
  }
  // Nome e Valor nunca saem
  return _colunas.where((c) => c.prioridade == 1).toList();
}

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
      child: LayoutBuilder(
        builder: (context, c) {
          final colunas = _colunasVisiveis(c.maxWidth);
          return TrocaFadeThrough(
            chave: colunas.map((col) => col.campo.name).join(','),
            child: Row(
              children: [
                for (final col in colunas) _texto(col, col.rotulo, estilo),
                const SizedBox(width: _larguraChevron),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _itemRecorrente(BuildContext context, LancamentoRecorrente r) {
    final cor = r.tipo == TipoLancamento.entrada
        ? AppColors.entrada
        : AppColors.saida;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8), // a margem saiu do Container
      child: HoverAnimado(
        raio: 12,
        child: InkWell(
          hoverColor: Colors.transparent, // o hover é do HoverAnimado
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12),
          onTap: () => mostrarDialogo(
            context: context,
            builder: (_) => TransacaoDetailDialog(
              transacao: _transacaoFake(r),
              recorrente: true,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final colunas = _colunasVisiveis(c.maxWidth);
                return TrocaFadeThrough(
                  chave: colunas.map((col) => col.campo.name).join(','),
                  child: Row(
                    children: [
                      for (final col in colunas) _celula(col, r, cor),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _texto(_Coluna col, String texto, TextStyle estilo) {
    return Expanded(
      flex: col.flex,
      child: Text(
        texto,
        textAlign: col.alinhamento,
        style: estilo,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  Widget _celula(_Coluna col, LancamentoRecorrente r, Color cor) {
    switch (col.campo) {
      case _Campo.nome:
        return _texto(
          col,
          r.descricao?.isNotEmpty == true ? r.descricao! : r.categoriaNome,
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        );
      case _Campo.proxima:
        return _texto(
          col,
          Formatters.data(r.dataRecorrencia),
          const TextStyle(fontSize: 13.5),
        );
      case _Campo.termino:
        return _texto(
          col,
          r.dataTermino == null ? '-' : Formatters.data(r.dataTermino!),
          const TextStyle(fontSize: 13.5),
        );
      case _Campo.valor:
        return _texto(
          col,
          Formatters.moeda(r.valor),
          TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: cor),
        );
    }
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
