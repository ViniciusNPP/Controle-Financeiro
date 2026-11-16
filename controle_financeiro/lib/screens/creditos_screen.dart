import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/categoria.dart';
import '../models/transacao.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dialog_fade.dart';
import '../widgets/animacoes_base.dart';
import 'package:controle_financeiro/widgets/dialogs/config_credito_dialog.dart';
import '../widgets/botoes_personalizados.dart';
import '../widgets/layout_dois_containers.dart';

class CreditosScreen extends StatelessWidget {
  /// true = escolhendo a despesa de um reembolso (só "Negativo" ativo).
  final bool modoSelecao;

  /// Despesa escolhida, ou null se o usuário cancelou.
  final ValueChanged<Transacao?> onSelecionarDespesa;

  const CreditosScreen({
    super.key,
    this.modoSelecao = false,
    required this.onSelecionarDespesa,
  });

  static String _brl(double v) {
    final partes = v.toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $inteiro,${partes[1]}';
  }

  Widget _botaoPago(BuildContext context, Transacao t) {
    final ativo = !modoSelecao;
    return Opacity(
      opacity: ativo ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !ativo, // no modo seleção o toque vai para a linha
        child: ToqueElastico(
          child: SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: () => context.read<FinanceProvider>().marcarComoPago(t.id),
              style: estiloBotao(
                corForeGround: Colors.white,
                corBackGround: AppColors.credito,
              ).copyWith(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 14),
                ),
                minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              child: const Text('Pago'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botaoTudoPago(BuildContext context) {
    final ativo = !modoSelecao;
    return Opacity(
      opacity: ativo ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !ativo,
        child: ToqueElastico(
          escalaHover: 1.01,
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () =>
                  context.read<FinanceProvider>().marcarTodosComoPagos(),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Tudo pago'),
              style: estiloBotao(
                corForeGround: Colors.white,
                corBackGround: AppColors.credito,
              ).copyWith(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botaoConfiguracao(BuildContext context) {
    return IgnorePointer(
      ignoring: modoSelecao,
      child: Opacity(
        opacity: modoSelecao ? 0.4 : 1,
        child: HoverAnimado(
          raio: 20,
          escala: 1.04,
          child: InkWell(
            hoverColor: Colors.transparent,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(12),
            onTap: () => mostrarDialogo(
              context: context,
              builder: (_) => const ConfigCreditoDialog(),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: AppTheme.cardDecoration(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Configuração',
                    style: TextStyle(
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
    );
  }

  Widget _linha(
    BuildContext context,
    Transacao t,
    Color cor, {
    required bool selecionavel,
    bool mostrarPago = false,
  }) {
    final d = t.data;
    final data =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final desc = (t.descricao?.isNotEmpty ?? false) ? ' · ${t.descricao}' : '';

    final conteudo = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.categoriaNome,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$data$desc',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _brl(t.valor),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: cor,
            ),
          ),
          if (mostrarPago) ...[
            const SizedBox(width: 10),
            _botaoPago(context, t),
          ],
        ],
      ),
    );

    if (!selecionavel) return conteudo;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      mouseCursor: SystemMouseCursors.click,
      onTap: () => onSelecionarDespesa(t),
      child: conteudo,
    );
  }

  Widget _bannerSelecao() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const Icon(Icons.touch_app_rounded, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Selecione a despesa que será reembolsada',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          style: const ButtonStyle(
            mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
          ),
          onPressed: () => onSelecionarDespesa(null),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final todas = context.watch<FinanceProvider>().transacoes;

    final negativos = todas.where((t) => t.pendenteNoCredito).toList()
      ..sort((a, b) => b.data.compareTo(a.data));

    final positivos = todas
        .where((t) => t.tipo == TipoLancamento.entrada && t.pagamento != null)
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));

    final totalNeg = negativos.fold<double>(0, (s, t) => s + t.valor);
    final totalPos = positivos.fold<double>(0, (s, t) => s + t.valor);

    return Column(
      children: [
        if (modoSelecao) _bannerSelecao(),
        Expanded(
          child: TelaDuasListas(
            titulo: 'Crédito',
            acao: _botaoConfiguracao(context),
            primeiro: ConfigBloco(
              titulo: 'Negativo',
              cor: AppColors.saida,
              quantidade: negativos.length,
              totalTexto: _brl(totalNeg),
              destacado: totalNeg > totalPos,
              mensagemVazia: 'Nenhum crédito negativo.',
              rodape: negativos.isEmpty ? null : _botaoTudoPago(context),
              itemBuilder: (context, i) => _linha(
                context,
                negativos[i],
                AppColors.saida,
                selecionavel: modoSelecao,
                mostrarPago: true,
              ),
            ),
            segundo: ConfigBloco(
              titulo: 'Positivo',
              cor: AppColors.entrada,
              quantidade: positivos.length,
              totalTexto: _brl(totalPos),
              destacado: totalPos > totalNeg,
              mensagemVazia: 'Nenhum crédito positivo.',
              desabilitado: modoSelecao,
              itemBuilder: (context, i) => _linha(
                context,
                positivos[i],
                AppColors.entrada,
                selecionavel: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}