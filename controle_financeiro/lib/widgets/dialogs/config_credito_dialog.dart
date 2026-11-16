import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/config_credito.dart';
import '../../providers/finance_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/dialog_fade.dart';
import '../../utils/formatadores.dart';
import '../animacoes_base.dart';
import '../botoes_personalizados.dart';
import '../recorrencia_widgets.dart' show SwitchRecorrencia;

class ConfigCreditoDialog extends StatefulWidget {
  const ConfigCreditoDialog({super.key});

  @override
  State<ConfigCreditoDialog> createState() => _ConfigCreditoDialogState();
}

class _ConfigCreditoDialogState extends State<ConfigCreditoDialog> {
  late final ConfigCredito _inicial;
  late bool _debito;
  late DebitoEm _debitoEm;
  DateTime? _fechamento;
  DateTime? _vencimento;
  late bool _debitoExpandido;
  bool _faturaExpandida = true;

  final _fechCtrl = TextEditingController();
  final _vencCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inicial = context.read<FinanceProvider>().configCredito;
    _debito = _inicial.debitoAutomatico;
    _debitoEm = _inicial.debitoEm;
    _fechamento = _inicial.fechamento;
    _vencimento = _inicial.vencimento;
    _debitoExpandido = _debito;
    if (_fechamento != null) _fechCtrl.text = Formatters.data(_fechamento!);
    if (_vencimento != null) _vencCtrl.text = Formatters.data(_vencimento!);
  }

  @override
  void dispose() {
    _fechCtrl.dispose();
    _vencCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- estado

  ConfigCredito get _atual => ConfigCredito(
    debitoAutomatico: _debito,
    debitoEm: _debitoEm,
    fechamento: _fechamento,
    vencimento: _vencimento,
  );

  bool get _alterado => _atual != _inicial;

  static bool _pendente(TextEditingController c, DateTime? d) =>
      c.text.isNotEmpty && d == null; // digitou algo que não virou data

  String? get _erroFechamento =>
      _fechCtrl.text.length == 10 && _fechamento == null
      ? 'Data inválida'
      : null;

  String? get _erroVencimento {
    if (_vencCtrl.text.length == 10 && _vencimento == null) {
      return 'Data inválida';
    }
    final f = _fechamento, v = _vencimento;
    if (f != null && v != null && !v.isAfter(f)) {
      return 'Deve ser depois do fechamento';
    }
    return null;
  }

  String? get _erroDebito {
    if (!_debito) return null;
    final d = _debitoEm == DebitoEm.fechamento ? _fechamento : _vencimento;
    if (d != null) return null;
    return 'Preencha a data de ${_debitoEm == DebitoEm.fechamento ? 'fechamento' : 'vencimento'}';
  }

  bool get _valido =>
      !_pendente(_fechCtrl, _fechamento) &&
      !_pendente(_vencCtrl, _vencimento) &&
      _erroVencimento == null &&
      _erroDebito == null;

  static DateTime? _parseData(String texto) {
    final p = texto.split('/');
    if (p.length != 3 || p[2].length != 4) return null;
    final d = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final a = int.tryParse(p[2]);
    if (d == null || m == null || a == null || a < 2000 || a > 2100) {
      return null;
    }
    final data = DateTime(a, m, d);
    return (data.month == m && data.day == d) ? data : null; // rejeita 31/02
  }

  // ----------------------------------------------------------------- ações

  Future<void> _salvar() async {
    await context.read<FinanceProvider>().salvarConfigCredito(_atual);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _sair() {
    if (!_alterado) {
      Navigator.of(context).pop();
      return;
    }
    mostrarDialogo(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Sair'),
        content: const Text('Deseja sair sem salvar as mudanças?'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          ToqueElastico(
            child: TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: estiloBotao(
                corForeGround: AppColors.textSecondary,
                corBackGround: AppColors.disabledFill,
              ),
              child: const Text('Não'),
            ),
          ),
          ToqueElastico(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              style: estiloBotao(
                corForeGround: Colors.white,
                corBackGround: AppColors.credito,
              ),
              child: const Text('Sim'),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- campos

  Widget _campoData({
    required String rotulo,
    required TextEditingController controller,
    required ValueChanged<DateTime?> onChanged,
    DateTime? valor,
    String? erro,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: erro != null ? Colors.red : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [_DataInputFormatter()],
          decoration: InputDecoration(
            hintText: 'dd/mm/aaaa',
            isDense: true,
            errorText: erro,
            prefixIcon: IconButton(
              mouseCursor: SystemMouseCursors.click,
              icon: const Icon(Icons.calendar_today_rounded, size: 16),
              onPressed: () async {
                final escolhida = await showDatePicker(
                  context: context,
                  initialDate: valor ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  locale: const Locale('pt', 'BR'),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      textButtonTheme: TextButtonThemeData(
                        style: estiloBotao(
                          corForeGround: const Color(0xFF2e2a6e),
                        ),
                      ),
                      iconButtonTheme: IconButtonThemeData(style: estiloBotao()),
                    ),
                    child: child!,
                  ),
                );
                if (escolhida == null || !mounted) return;
                controller.text = Formatters.data(escolhida);
                setState(() => onChanged(escolhida));
              },
            ),
          ),
          onChanged: (t) => setState(() => onChanged(_parseData(t))),
        ),
      ],
    );
  }

  Widget _conteudoDebito() {
    final erro = _erroDebito;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Debitar na data de',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: botaoSelecionavel(
                label: 'Fechamento',
                selecionado: _debitoEm == DebitoEm.fechamento,
                cor: AppColors.credito,
                onTap: () => setState(() => _debitoEm = DebitoEm.fechamento),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: botaoSelecionavel(
                label: 'Vencimento',
                selecionado: _debitoEm == DebitoEm.vencimento,
                cor: AppColors.credito,
                onTap: () => setState(() => _debitoEm = DebitoEm.vencimento),
              ),
            ),
          ],
        ),
        if (erro != null && _debito)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              erro,
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _conteudoFatura() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _campoData(
        rotulo: 'Fechamento',
        controller: _fechCtrl,
        valor: _fechamento,
        erro: _erroFechamento,
        onChanged: (d) => _fechamento = d,
      ),
      const SizedBox(height: 14),
      _campoData(
        rotulo: 'Vencimento',
        controller: _vencCtrl,
        valor: _vencimento,
        erro: _erroVencimento,
        onChanged: (d) => _vencimento = d,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final podeSalvar = _alterado && _valido;

    return PopScope(
      canPop: !_alterado,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _sair();
      },
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuração',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                _SecaoExpansivel(
                  titulo: 'Débito automático',
                  expandido: _debitoExpandido,
                  desabilitada: !_debito,
                  onAlternar: () =>
                      setState(() => _debitoExpandido = !_debitoExpandido),
                  trailing: SwitchRecorrencia(
                    ativo: _debito,
                    onChanged: (v) => setState(() {
                      _debito = v;
                      _debitoExpandido = v;
                    }),
                  ),
                  child: _conteudoDebito(),
                ),
                const SizedBox(height: 14),
                _SecaoExpansivel(
                  titulo: 'Data de fatura do cartão',
                  expandido: _faturaExpandida,
                  onAlternar: () =>
                      setState(() => _faturaExpandida = !_faturaExpandida),
                  child: _conteudoFatura(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ToqueElastico(
                      child: TextButton.icon(
                        onPressed: _sair,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Sair'),
                        style: estiloBotao(
                          corForeGround: AppColors.textSecondary,
                          corBackGround: AppColors.disabledFill,
                        ),
                      ),
                    ),
                    ToqueElastico(
                      ativo: podeSalvar,
                      child: AnimatedOpacity(
                        opacity: podeSalvar ? 1 : 0.4,
                        duration: AppMotion.fade,
                        child: ElevatedButton.icon(
                          onPressed: podeSalvar ? _salvar : null,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Salvar'),
                          style: estiloBotao(
                            corForeGround: Colors.white,
                            corBackGround: AppColors.credito,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Container com cabeçalho clicável (seta gira) e corpo que abre/fecha.
class _SecaoExpansivel extends StatelessWidget {
  final String titulo;
  final bool expandido;
  final bool desabilitada;
  final VoidCallback onAlternar;
  final Widget? trailing;
  final Widget child;

  static const _duracao = Duration(milliseconds: 300);

  const _SecaoExpansivel({
    required this.titulo,
    required this.expandido,
    required this.onAlternar,
    required this.child,
    this.desabilitada = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final conteudoAtivo = expandido && !desabilitada;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            hoverColor: Colors.transparent,
            mouseCursor: SystemMouseCursors.click,
            onTap: onAlternar,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: desabilitada ? 0.5 : 1,
                      duration: AppMotion.fade,
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    trailing!,
                    const SizedBox(width: 8),
                  ],
                  AnimatedRotation(
                    turns: expandido ? 0.5 : 0,
                    duration: _duracao,
                    curve: Curves.easeInOut,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              heightFactor: expandido ? 1.0 : 0.0,
              duration: _duracao,
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: !expandido ? 0 : (desabilitada ? 0.5 : 1),
                duration: _duracao,
                curve: Curves.easeInOut,
                child: IgnorePointer(
                  ignoring: !conteudoAtivo,
                  child: ExcludeFocus(
                    excluding: !conteudoAtivo,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formata a digitação como dd/mm/aaaa.
class _DataInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.length > 8) digitos = digitos.substring(0, 8);

    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digitos[i]);
    }
    final formatado = buffer.toString();
    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}