import 'dart:io';
import 'dart:math' as math;

import 'package:controle_financeiro/services/update_service.dart';
import 'package:controle_financeiro/utils/dialog_fade.dart';
import 'package:controle_financeiro/widgets/animacoes_base.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

const _kRoxo = Color(0xFF3e3b79);
const _kUrlNovidades =
    'https://github.com/ViniciusNPP/Controle-Financeiro/releases';
const _kLarguraTelaPequena = 460.0;

Future<void> mostrarDialogoAtualizacao(BuildContext context, UpdateInfo info) {
  return mostrarDialogo<void>(
    context: context,
    builder: (_) => _UpdateDialog(info: info),
  );
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const _UpdateDialog({required this.info});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _atualizando = false;
  bool _erro = false;
  double _progresso = 0;

  Future<void> _abrirNovidades() => launchUrl(
    Uri.parse(_kUrlNovidades),
    mode: LaunchMode.externalApplication,
  );

    void _onProgresso(double p) {
    if (mounted) setState(() => _progresso = p);
  }

  Future<void> _atualizar() async {
    setState(() {
      _atualizando = true;
      _erro = false;
      _progresso = 0;
    });

    try {
      if (Platform.isAndroid) {
        await UpdateService.baixarEInstalarAndroid(widget.info, _onProgresso);
      } else {
        await UpdateService.baixarEInstalarWindows(widget.info, _onProgresso);
      }
      // No Android chega aqui quando o instalador do sistema abre.
      // Volta ao aviso para o usuário não ficar preso se cancelar a instalação.
      if (mounted) setState(() => _atualizando = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _atualizando = false;
          _erro = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_atualizando,
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: _atualizando ? _conteudoAtualizando() : _conteudoAviso(),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Aviso
  // --------------------------------------------------------------------------
  Widget _conteudoAviso() {
    final pequena = MediaQuery.of(context).size.width < _kLarguraTelaPequena;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/controle_financeiro_img.png',
                width: 48,
                height: 48,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Controle Financeiro ${widget.info.version} está disponível',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const Text(
          'Atualize para a versão mais recente',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        if (_erro) ...[
          const SizedBox(height: 10),
          const Text(
            'Não foi possível baixar a atualização. Tente novamente.',
            style: TextStyle(fontSize: 13, color: Colors.red),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            _botaoNovidades(pequena),
            const Spacer(),
            ToqueElastico(
              child: HoverAnimado(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: const ButtonStyle(
                    mouseCursor: WidgetStatePropertyAll(
                      SystemMouseCursors.click,
                    ),
                    foregroundColor: WidgetStatePropertyAll(_kRoxo),
                  ),
                  child: const Text('Depois'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ToqueElastico(
              child: HoverAnimado(
                child: FilledButton(
                  onPressed: _atualizar,
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(_kRoxo),
                    mouseCursor: WidgetStatePropertyAll(
                      SystemMouseCursors.click,
                    ),
                  ),
                  child: const Text('Atualizar'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _botaoNovidades(bool pequena) {
    const icone = Icon(Icons.north_west_rounded, size: 18);

    return ToqueElastico(
      child: HoverAnimado(
        child: pequena
            ? IconButton(
                tooltip: 'Novidades',
                icon: icone,
                color: _kRoxo,
                mouseCursor: SystemMouseCursors.click,
                onPressed: _abrirNovidades,
              )
            : TextButton.icon(
                icon: icone,
                label: const Text('Novidades'),
                style: const ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(_kRoxo),
                  mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
                ),
                onPressed: _abrirNovidades,
              ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Animação de espera
  // --------------------------------------------------------------------------
  Widget _conteudoAtualizando() {
    final pct = (_progresso * 100).clamp(0, 100).toStringAsFixed(0);

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Atualizando. . .',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          const _SpinnerArco(tamanho: 64, cor: _kRoxo),
          const SizedBox(height: 20),
          Text(
            '$pct%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Círculo que começa vazio, completa a volta rápido no início, desacelera
/// no fim e reinicia.
class _SpinnerArco extends StatefulWidget {
  final double tamanho;
  final Color cor;
  const _SpinnerArco({required this.tamanho, required this.cor});

  @override
  State<_SpinnerArco> createState() => _SpinnerArcoState();
}

class _SpinnerArcoState extends State<_SpinnerArco>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        size: Size.square(widget.tamanho),
        painter: _ArcoPainter(
          // easeOutCubic: começa rápido e termina devagar
          progresso: Curves.easeOutCubic.transform(_c.value),
          cor: widget.cor,
        ),
      ),
    );
  }
}

class _ArcoPainter extends CustomPainter {
  final double progresso;
  final Color cor;
  _ArcoPainter({required this.progresso, required this.cor});

  @override
  void paint(Canvas canvas, Size size) {
    const espessura = 6.0;
    final rect = Offset.zero & size;
    final area = rect.deflate(espessura / 2);

    // Trilho de fundo
    canvas.drawArc(
      area,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura
        ..color = cor.withValues(alpha: 0.12),
    );

    canvas.drawArc(
      area,
      -math.pi / 2,
      2 * math.pi * progresso,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura
        ..strokeCap = StrokeCap.round
        ..color = cor,
    );
  }

  @override
  bool shouldRepaint(_ArcoPainter old) =>
      old.progresso != progresso || old.cor != cor;
}

Future<void> mostrarDialogoAtualizado(BuildContext context) {
  return mostrarDialogo<void>(
    context: context,
    builder: (_) => const _AtualizadoDialog(),
  );
}

class _AtualizadoDialog extends StatelessWidget {
  const _AtualizadoDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.entrada, width: 6),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 44,
                    color: AppColors.entrada,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Atualizado com sucesso!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ToqueElastico(
                  child: HoverAnimado(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(_kRoxo),
                        mouseCursor: WidgetStatePropertyAll(
                          SystemMouseCursors.click,
                        ),
                      ),
                      child: const Text('Fechar'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}