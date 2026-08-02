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

  const MonthYearNavigator({
    super.key,
    required this.granularidade,
    required this.valor,
    required this.onChanged,
    this.rotulo,
    this.abreviado = false,
  });

  Future<void> _abrirSeletor(BuildContext context) async {
    final escolhida = granularidade == GranularidadeNavegador.mes
        ? await _mostrarSeletorMes(context, valor)
        : await _mostrarSeletorAno(context, valor);
    if (escolhida != null) onChanged(escolhida);
  }

  void _navegar(int delta) {
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
                    onPressed: () => _navegar(-1),
                  ),
                  Text(_texto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    onPressed: () => _navegar(1),
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

Future<DateTime?> _mostrarSeletorAno(BuildContext context, DateTime valorAtual) {
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
              Expanded(child: _GradeAnos(valorAtual: valorAtual)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GradeAnos extends StatefulWidget {
  final DateTime valorAtual;
  const _GradeAnos({required this.valorAtual});

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

  late final int _anoBase = DateTime.now().year - 100;
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
      itemCount: 102,
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

Future<DateTime?> _mostrarSeletorMes(BuildContext context, DateTime valorAtual) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) {
      var anoExibido = valorAtual.year;
      return StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
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
                        onPressed: () => setStateDialog(() => anoExibido--),
                      ),
                      Text('$anoExibido', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () => setStateDialog(() => anoExibido++),
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
                      return _celulaSeletor(
                        texto: Formatters.nomesMesesAbrev[mes],
                        selecionado: selecionado,
                        onTap: () => Navigator.pop(context, DateTime(anoExibido, mes)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _celulaSeletor({required String texto, required bool selecionado, required VoidCallback onTap}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selecionado ? AppColors.primary : AppColors.disabledFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          texto,
          style: TextStyle(fontWeight: FontWeight.w600, color: selecionado ? Colors.white : AppColors.textPrimary),
        ),
      ),
    ),
  );
}