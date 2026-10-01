import 'package:controle_financeiro/widgets/botoes_personalizados.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/dropdown.dart';
import '../widgets/form_fields.dart';

const double _larguraMinimaDesktop = 600;

/// Switch compacto de "lançamento recorrente"
class SwitchRecorrencia extends StatelessWidget {
  final bool ativo;
  final ValueChanged<bool> onChanged;

  const SwitchRecorrencia({
    super.key,
    required this.ativo,
    required this.onChanged,
  });

  static const double _largura = 40;
  static const double _altura = 22;
  static const double _diametroThumb = 16;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!ativo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: _largura,
          height: _altura,
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: ativo ? AppColors.primary : AppColors.disabledFill,
            borderRadius: BorderRadius.circular(_altura / 2),
            border: Border.all(
              color: ativo ? AppColors.primary : AppColors.border,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment: ativo ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _diametroThumb,
              height: _diametroThumb,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frequência da recorrência
enum PeriodoRecorrencia { diariamente, semanalmente, mensalmente, anualmente }

extension _PeriodoLabel on PeriodoRecorrencia {
  String get label {
    switch (this) {
      case PeriodoRecorrencia.diariamente:
        return 'Diariamente';
      case PeriodoRecorrencia.semanalmente:
        return 'Semanalmente';
      case PeriodoRecorrencia.mensalmente:
        return 'Mensalmente';
      case PeriodoRecorrencia.anualmente:
        return 'Anualmente';
    }
  }
}

/// Resultado devolvido quando o usuário confirma o dialog em "Salvar".
class ConfiguracaoRecorrencia {
  final PeriodoRecorrencia periodo;
  final DateTime dataInicio;

  /// `null` quando a recorrência é indeterminada (sem data de término).
  final DateTime? dataTermino;

  const ConfiguracaoRecorrencia({
    required this.periodo,
    required this.dataInicio,
    this.dataTermino,
  });
}

/// Dialog "Recorrência". Puramente visual por enquanto: devolve uma
/// [ConfiguracaoRecorrencia] via Navigator.pop quando o usuário aperta
/// Salvar, ou `null` quando cancela / fecha no X (chamador decide o que
/// fazer com o switch nesses casos).
class RecorrenciaDialog extends StatefulWidget {
  final ConfiguracaoRecorrencia? configuracaoInicial;

  const RecorrenciaDialog({super.key, this.configuracaoInicial});

  static Future<ConfiguracaoRecorrencia?> show(
    BuildContext context, {
    ConfiguracaoRecorrencia? configuracaoInicial,
  }) {
    return showDialog<ConfiguracaoRecorrencia>(
      context: context,
      builder: (_) =>
          RecorrenciaDialog(configuracaoInicial: configuracaoInicial),
    );
  }

  @override
  State<RecorrenciaDialog> createState() => _RecorrenciaDialogState();
}

class _RecorrenciaDialogState extends State<RecorrenciaDialog> {
  static DateTime _hoje() {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  late PeriodoRecorrencia _periodo =
      widget.configuracaoInicial?.periodo ?? PeriodoRecorrencia.mensalmente;
  late DateTime _dataInicio = widget.configuracaoInicial?.dataInicio ?? _hoje();
  late DateTime _dataTermino =
      widget.configuracaoInicial?.dataTermino ??
      _dataInicio.add(const Duration(days: 1));
  late bool _indeterminado = widget.configuracaoInicial?.dataTermino == null;

  void _salvar() {
    Navigator.of(context).pop(
      ConfiguracaoRecorrencia(
        periodo: _periodo,
        dataInicio: _dataInicio,
        dataTermino: _indeterminado ? null : _dataTermino,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recorrência',
                      style: Theme.of(context).textTheme.headlineMedium,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                    mouseCursor: SystemMouseCursors.click,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _rotulo('Repetir'),
              const SizedBox(height: 8),
              _seletorPeriodo(),
              const SizedBox(height: 20),
              _linhaData(
                rotulo: 'A partir de',
                campo: DatePickerField(
                  valor: _dataInicio,
                  firstDate: _hoje(),
                  onChanged: (d) => setState(() {
                    _dataInicio = d;
                    if (!_dataTermino.isAfter(_dataInicio)) {
                      _dataTermino = _dataInicio.add(const Duration(days: 1));
                    }
                  }),
                ),
              ),
              const SizedBox(height: 20),
              _linhaData(
                rotulo: 'Termina em',
                campo: DatePickerField(
                  valor: _dataTermino,
                  firstDate: _dataInicio.add(const Duration(days: 1)),
                  desativado: _indeterminado,
                  onChanged: (d) => setState(() => _dataTermino = d),
                ),
              ),
              const SizedBox(height: 12),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _indeterminado = !_indeterminado),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Indeterminado',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
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
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: MediaQuery.sizeOf(context).width < 600
                        ? IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            tooltip: 'Cancelar',
                            style: estiloBotao(
                              corForeGround: AppColors.textSecondary,
                            ),
                          )
                        : TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Cancelar'),
                            style: estiloBotao(
                              corForeGround: AppColors.textSecondary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MediaQuery.sizeOf(context).width < 600
                        ? IconButton(
                            onPressed: _salvar,
                            icon: const Icon(Icons.save_rounded, size: 18),
                            tooltip: 'Salvar',
                            style: estiloBotao(
                              corBackGround: AppColors.entrada,
                              isSide: true,
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _salvar,
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: const Text('Salvar'),
                            style: estiloBotao(
                              corBackGround: AppColors.entrada,
                              isSide: true,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rotulo(String texto) => Text(
    texto,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
    overflow: TextOverflow.ellipsis,
    softWrap: false,
  );

  /// Rótulo + campo de data
  Widget _linhaData({required String rotulo, required Widget campo}) {
    final largura = MediaQuery.sizeOf(context).width;
    final desktop = largura >= _larguraMinimaDesktop;

    if (desktop) {
      return Row(
        children: [
          _rotulo(rotulo),
          const SizedBox(width: 10),
          Flexible(child: campo),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_rotulo(rotulo), const SizedBox(height: 8), campo],
    );
  }

  Widget _seletorPeriodo() {
    return dropdownEstilizado(
      opcoes: [for (final p in PeriodoRecorrencia.values) p.label],
      valorSelecionado: _periodo.label,
      onSelecionar: (label) {
        final escolhido = PeriodoRecorrencia.values.firstWhere(
          (p) => p.label == label,
        );
        setState(() => _periodo = escolhido);
      },
    );
  }
}
