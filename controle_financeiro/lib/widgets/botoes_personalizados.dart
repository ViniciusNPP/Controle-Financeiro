import 'package:controle_financeiro/theme/app_theme.dart';
import 'package:controle_financeiro/utils/app_shortcuts.dart';
import 'package:flutter/material.dart';

ButtonStyle estiloBotao({
  Color corForeGround = const Color(0xFFece6f0),
  Color corBackGround = const Color(0xFFece6f0),
  bool isSide = false,
}) {
  return ButtonStyle(
    foregroundColor: WidgetStatePropertyAll(corForeGround),
    backgroundColor: WidgetStatePropertyAll(corBackGround),
    side: WidgetStatePropertyAll(
      BorderSide(
        color: isSide
            ? (corForeGround == Color(0xFFece6f0)
                  ? corBackGround
                  : corForeGround)
            : Color(0xFFece6f0),
      ),
    ),
    shadowColor: WidgetStatePropertyAll(Color(0xFFece6f0)),
    mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
    textStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
  );
}

/// Mostra um diálogo de confirmação de exclusão padrão do app.
Future<void> confirmarExclusao({
  required BuildContext context,
  required String titulo,
  required String mensagem,
  required Color corBotaoExcluir,
  required Future<void> Function() aoConfirmar,
  bool fecharTelaAposExcluir = true,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => Shortcuts(
      shortcuts: atalhosGlobais,
      child: Actions(
        actions: {
          AceitarIntent: CallbackAction<AceitarIntent>(
            onInvoke: (intent) async {
              await aoConfirmar();
              if (!fecharTelaAposExcluir) return null;
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: AlertDialog(
            title: Text(titulo),
            content: Text(mensagem),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: estiloBotao(
                  corForeGround: AppColors.textSecondary,
                  corBackGround: AppColors.disabledFill,
                ),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await aoConfirmar();
                  if (!fecharTelaAposExcluir) return;
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                style: estiloBotao(
                  corForeGround: Colors.white,
                  corBackGround: corBotaoExcluir,
                ),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget botaoSelecionavel({
  required String label,
  required bool selecionado,
  required Color cor,
  required VoidCallback onTap,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selecionado
              ? cor.withValues(alpha: 0.12)
              : AppColors.disabledFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selecionado ? cor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selecionado ? cor : AppColors.textSecondary,
          ),
        ),
      ),
    ),
  );
}

enum EstadoBotaoSalvar { idle, loading, success, fail }

class BotaoSalvarAnimado extends StatefulWidget {
  final String label;
  final Color corIdle;
  final Future<bool> Function() aoPressionar;
  final bool compacto;
  final bool telaPequena;
  final bool usarSucesso;

  const BotaoSalvarAnimado({
    super.key,
    required this.label,
    required this.corIdle,
    required this.aoPressionar,
    this.compacto = false,
    this.telaPequena = false,
    this.usarSucesso = true,
  });

  @override
  State<BotaoSalvarAnimado> createState() => _BotaoSalvarAnimadoState();
}

class _BotaoSalvarAnimadoState extends State<BotaoSalvarAnimado>
    with SingleTickerProviderStateMixin {
  EstadoBotaoSalvar _estado = EstadoBotaoSalvar.idle;

  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _shake = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: -1.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -1.0, end: 1.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: -1.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -1.0, end: 0.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  bool get _habilitado => _estado == EstadoBotaoSalvar.idle;

  Future<void> _onTap() async {
    if (!_habilitado) return;
    setState(() => _estado = EstadoBotaoSalvar.loading);

    bool sucesso;
    try {
      sucesso = await widget.aoPressionar();
    } catch (_) {
      sucesso = false;
    }

    if (!mounted) return;

    if (sucesso) {
      if (!widget.usarSucesso) return; // tela fecha sozinha nesse caso
      setState(() => _estado = EstadoBotaoSalvar.success);
    } else {
      setState(() => _estado = EstadoBotaoSalvar.fail);
      _shakeController.forward(from: 0);
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _estado = EstadoBotaoSalvar.idle);
  }

  Color get _corAtual {
    switch (_estado) {
      case EstadoBotaoSalvar.idle:
        return widget.corIdle;
      case EstadoBotaoSalvar.loading:
        return AppColors.disabledFill;
      case EstadoBotaoSalvar.success:
        return Colors.green;
      case EstadoBotaoSalvar.fail:
        return Colors.red;
    }
  }

  Widget _conteudoAtual() {
    switch (_estado) {
      case EstadoBotaoSalvar.idle:
        return Text(
          widget.label,
          key: const ValueKey('idle'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        );
      case EstadoBotaoSalvar.loading:
        return const SizedBox(
          key: ValueKey('loading'),
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        );
      case EstadoBotaoSalvar.success:
        return const Icon(
          Icons.check,
          key: ValueKey('success'),
          color: Colors.white,
        );
      case EstadoBotaoSalvar.fail:
        return const Icon(
          Icons.close,
          key: ValueKey('fail'),
          color: Colors.white,
        );
    }
  }

  Widget _iconeCompacto() {
    switch (_estado) {
      case EstadoBotaoSalvar.idle:
        return const Icon(Icons.save_rounded, key: ValueKey('idle'), size: 18);
      case EstadoBotaoSalvar.loading:
        return const SizedBox(
          key: ValueKey('loading'),
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        );
      case EstadoBotaoSalvar.success:
        return const Icon(
          Icons.check_rounded,
          key: ValueKey('success'),
          size: 18,
        );
      case EstadoBotaoSalvar.fail:
        return const Icon(Icons.close_rounded, key: ValueKey('fail'), size: 18);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compacto) {
      return AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final dx = _estado == EstadoBotaoSalvar.fail ? _shake.value * 8 : 0.0;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: _corAtual),
          duration: const Duration(milliseconds: 250),
          builder: (context, cor, child) {
            final style = estiloBotao(
              corBackGround: cor ?? widget.corIdle,
              isSide: true,
            );
            return widget.telaPequena
                ? IconButton(
                    onPressed: _habilitado ? _onTap : null,
                    tooltip: widget.label,
                    style: style,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _iconeCompacto(),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _habilitado ? _onTap : null,
                    style: style,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _iconeCompacto(),
                    ),
                    label: Text(widget.label),
                  );
          },
        ),
      );
    }

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final dx = _estado == EstadoBotaoSalvar.fail ? _shake.value * 8 : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: MouseRegion(
        cursor: _habilitado ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: _onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: double.infinity,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _corAtual,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _conteudoAtual(),
            ),
          ),
        ),
      ),
    );
  }
}
