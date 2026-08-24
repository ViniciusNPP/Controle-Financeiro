import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

enum GranularidadeNavegador { mes, ano }

//Barra reutilizável de navegação por mês ou ano
class MonthYearNavigator extends StatelessWidget {
  final GranularidadeNavegador granularidade;
  final DateTime valor;
  final ValueChanged<DateTime> onChanged;
  final String? rotulo;
  final bool abreviado;
  final DateTime? dataMinima;
  final DateTime? dataMaxima;

  const MonthYearNavigator({
    super.key,
    required this.granularidade,
    required this.valor,
    required this.onChanged,
    this.rotulo,
    this.abreviado = false,
    this.dataMinima,
    this.dataMaxima,
  });

  Future<void> _abrirSeletor(BuildContext context) async {
    final escolhida = granularidade == GranularidadeNavegador.mes
        ? await _mostrarSeletorMes(context, valor, dataMinima: dataMinima, dataMaxima: dataMaxima)
        : await _mostrarSeletorAno(context, valor, dataMinima: dataMinima, dataMaxima: dataMaxima);
    if (escolhida != null) onChanged(escolhida);
  }

  bool get _podeVoltar {
    if (dataMinima == null) return true;
    if (granularidade == GranularidadeNavegador.ano) {
      return valor.year > dataMinima!.year;
    }
    final anterior = DateTime(valor.year, valor.month - 1);
    return !anterior.isBefore(DateTime(dataMinima!.year, dataMinima!.month));
  }

  bool get _podeAvancar {
    if (dataMaxima == null) return true;
    if (granularidade == GranularidadeNavegador.ano) {
      return valor.year < dataMaxima!.year;
    }
    final proximo = DateTime(valor.year, valor.month + 1);
    return !proximo.isAfter(DateTime(dataMaxima!.year, dataMaxima!.month));
  }

  void _navegar(int delta) {
    if (delta < 0 && !_podeVoltar) return;
    if (delta > 0 && !_podeAvancar) return;
    final novo = granularidade == GranularidadeNavegador.mes
        ? DateTime(valor.year, valor.month + delta)
        : DateTime(valor.year + delta, valor.month);
    onChanged(novo);
  }

  String get _texto {
    if (granularidade == GranularidadeNavegador.ano) return '${valor.year}';
    final nomes = abreviado ? Formatters.nomesMesesAbrev : Formatters.nomesMesesCompleto;
    return '${nomes[valor.month]} ${valor.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rotulo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Text(rotulo!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        Tooltip(
          message: 'Botão direito (ou toque longo) para escolher direto',
          child: GestureDetector(
            onSecondaryTap: () => _abrirSeletor(context),
            onLongPress: () => _abrirSeletor(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(color: AppColors.disabledFill, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    onPressed: _podeVoltar ? () => _navegar(-1) : null,
                  ),
                  Text(_texto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    onPressed: _podeAvancar ? () => _navegar(1) : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<DateTime?> _mostrarSeletorAno(
  BuildContext context,
  DateTime valorAtual, {
  DateTime? dataMinima,
  DateTime? dataMaxima,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 280,
          height: 320,
          child: Column(
            children: [
              const Text('Selecione o ano', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 16),
              Expanded(
                child: _GradeAnos(
                  valorAtual: valorAtual,
                  anoMinimo: dataMinima?.year,
                  anoMaximo: dataMaxima?.year,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GradeAnos extends StatefulWidget {
  final DateTime valorAtual;
  final int? anoMinimo;
  final int? anoMaximo;
  const _GradeAnos({required this.valorAtual, this.anoMinimo, this.anoMaximo});

  @override
  State<_GradeAnos> createState() => _GradeAnosState();
}

class _GradeAnosState extends State<_GradeAnos> {
  static const _crossAxisCount = 3;
  static const _spacing = 8.0;
  static const _aspectRatio = 1.6;
  static const _larguraCelula = (240.0 - _spacing * (_crossAxisCount - 1)) / _crossAxisCount; // 240 = 280 - padding(20*2)
  static const _alturaLinha = (_larguraCelula / _aspectRatio) + _spacing;
  static const _alturaVisivel = 320.0 - 322.0 - 16.0 - 21.0; // altura do diálogo - padding - espaçamento - título

  // Sem limites informados, mantém o comportamento original: 100 anos atrás.
  late final int _anoBase = widget.anoMinimo ?? (DateTime.now().year - 100);
  late final int _anoTopo = widget.anoMaximo ?? (DateTime.now().year + 1);
  late final int _totalAnos = _anoTopo - _anoBase + 1;
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    final linhaSelecionada = (widget.valorAtual.year - _anoBase) ~/ _crossAxisCount;
    final offsetCentralizado = (linhaSelecionada * _alturaLinha) - (_alturaVisivel / 2) + (_alturaLinha / 2);
    _controller = ScrollController(initialScrollOffset: offsetCentralizado.clamp(0.0, double.infinity));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _controller,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        mainAxisSpacing: _spacing,
        crossAxisSpacing: _spacing,
        childAspectRatio: _aspectRatio,
      ),
      itemCount: _totalAnos,
      itemBuilder: (context, i) {
        final ano = _anoBase + i;
        return _celulaSeletor(
          texto: '$ano',
          selecionado: ano == widget.valorAtual.year,
          onTap: () => Navigator.pop(context, DateTime(ano, widget.valorAtual.month)),
        );
      },
    );
  }
}

Future<DateTime?> _mostrarSeletorMes(
  BuildContext context,
  DateTime valorAtual, {
  DateTime? dataMinima,
  DateTime? dataMaxima,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) {
      var anoExibido = valorAtual.year;

      bool mesHabilitado(int ano, int mes) {
        if (dataMinima != null && DateTime(ano, mes + 1, 0).isBefore(DateTime(dataMinima.year, dataMinima.month, 1))) {
          return false;
        }
        if (dataMaxima != null && DateTime(ano, mes, 1).isAfter(DateTime(dataMaxima.year, dataMaxima.month + 1, 0))) {
          return false;
        }
        return true;
      }

      return StatefulBuilder(
        builder: (context, setStateDialog) {
          final podeVoltarAno = dataMinima == null || anoExibido > dataMinima.year;
          final podeAvancarAno = dataMaxima == null || anoExibido < dataMaxima.year;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: podeVoltarAno ? () => setStateDialog(() => anoExibido--) : null,
                        ),
                        Text('$anoExibido', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: podeAvancarAno ? () => setStateDialog(() => anoExibido++) : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, i) {
                        final mes = i + 1;
                        final selecionado = mes == valorAtual.month && anoExibido == valorAtual.year;
                        final habilitado = mesHabilitado(anoExibido, mes);
                        return _celulaSeletor(
                          texto: Formatters.nomesMesesAbrev[mes],
                          selecionado: selecionado,
                          habilitado: habilitado,
                          onTap: habilitado ? () => Navigator.pop(context, DateTime(anoExibido, mes)) : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _celulaSeletor({
  required String texto,
  required bool selecionado,
  VoidCallback? onTap,
  bool habilitado = true,
}) {
  final cor = selecionado
      ? AppColors.primary
      : habilitado
          ? AppColors.disabledFill
          : AppColors.disabledFill.withValues(alpha: 0.4);
  final corTexto = selecionado
      ? Colors.white
      : habilitado
          ? AppColors.textPrimary
          : AppColors.textSecondary.withValues(alpha: 0.4);

  return MouseRegion(
    cursor: habilitado ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          texto,
          style: TextStyle(fontWeight: FontWeight.w600, color: corTexto),
        ),
      ),
    ),
  );
}