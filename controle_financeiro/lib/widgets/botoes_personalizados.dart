import 'package:controle_financeiro/theme/app_theme.dart';
import 'package:controle_financeiro/utils/app_shortcuts.dart';
import 'package:controle_financeiro/utils/dialog_fade.dart';
import 'package:controle_financeiro/widgets/animacoes_base.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

ButtonStyle estiloBotao({
  Color corForeGround = const Color(0xFFece6f0),
  Color corBackGround = const Color(0xFFece6f0),
  Color? corHover,
  bool isSide = false,
}) {
  return ButtonStyle(
    foregroundColor: WidgetStatePropertyAll(corForeGround),
    backgroundColor: WidgetStatePropertyAll(corBackGround),
    overlayColor: corHover == null
        ? null
        : WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) &&
                !states.contains(WidgetState.disabled)) {
              return corHover.withValues(alpha: 0.22);
            }
            return null;
          }),
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
  return mostrarDialogo(
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
              ToqueElastico(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: estiloBotao(
                    corForeGround: AppColors.textSecondary,
                    corBackGround: AppColors.disabledFill,
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              ToqueElastico(
                child: ElevatedButton(
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
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Mantida como função para não quebrar quem já chama (SeletorTipo, etc.).
Widget botaoSelecionavel({
  required String label,
  required bool selecionado,
  required Color cor,
  required VoidCallback onTap,
}) => BotaoSelecionavel(
  label: label,
  selecionado: selecionado,
  cor: cor,
  onTap: onTap,
);

class BotaoSelecionavel extends StatelessWidget {
  final String label;
  final bool selecionado;
  final Color cor;
  final VoidCallback onTap;

  const BotaoSelecionavel({
    super.key,
    required this.label,
    required this.selecionado,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const raio = 14.0;
    // Cor opaca equivalente ao tom translúcido sobre o fundo branco.
    final fundo = selecionado
        ? Color.alphaBlend(cor.withValues(alpha: 0.12), AppColors.surface)
        : AppColors.disabledFill;
    final corTexto = selecionado ? cor : AppColors.textSecondary;

    return ToqueElastico(
      escalaHover: 1.02,
      child: HoverAnimado(
        raio: raio,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.fade,
            // Borda por cima do fundo, para o fundo preencher a caixa toda.
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(raio),
              border: Border.all(
                color: selecionado ? cor : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: RevelacaoDeCor(
              cor: fundo,
              forma: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(raio),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: corTexto),
                    duration: AppMotion.fade,
                    builder: (context, c, _) => AnimatedSwitcher(
                      duration: AppMotion.fade,
                      child: Text(
                        label,
                        key: ValueKey(label),
                        style: TextStyle(fontWeight: FontWeight.w600, color: c),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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

class _BotaoSalvarAnimadoState extends State<BotaoSalvarAnimado> {
  EstadoBotaoSalvar _estado = EstadoBotaoSalvar.idle;
  AnimationController? _shake; // controller do flutter_animate

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
      _shake?.forward(from: 0);
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _estado = EstadoBotaoSalvar.idle);
  }

  // Loading mantém a cor do idle: só sucesso/erro disparam a expansão de cor.
  Color get _corAtual => switch (_estado) {
    EstadoBotaoSalvar.idle || EstadoBotaoSalvar.loading => widget.corIdle,
    EstadoBotaoSalvar.success => Colors.green,
    EstadoBotaoSalvar.fail => Colors.red,
  };

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

  /// Versão com ElevatedButton/IconButton (dialogs). O botão fica com fundo
  /// transparente; a cor vem do RevelacaoDeCor por baixo.
  Widget _botaoCompacto() {
    final estilo = estiloBotao(corBackGround: Colors.transparent, isSide: true);
    final icone = AnimatedSwitcher(
      duration: AppMotion.fade,
      child: _iconeCompacto(),
    );

    if (widget.telaPequena) {
      return RevelacaoDeCor(
        cor: _corAtual,
        forma: const StadiumBorder(),
        child: IconButton(
          onPressed: _habilitado ? _onTap : null,
          tooltip: widget.label,
          style: estilo.copyWith(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: icone,
        ),
      );
    }
    return RevelacaoDeCor(
      cor: _corAtual,
      forma: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ElevatedButton.icon(
        onPressed: _habilitado ? _onTap : null,
        style: estilo,
        icon: icone,
        label: Text(widget.label),
      ),
    );
  }

  /// Versão larga (tela Adicionar).
  Widget _botaoCheio() {
    return HoverAnimado(
      tom: TomHover.escuro,
      raio: 12,
      ativo: _habilitado,
      cursor: _habilitado ? SystemMouseCursors.click : MouseCursor.defer,
      child: RevelacaoDeCor(
        cor: _corAtual,
        forma: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: Center(
              child: AnimatedSwitcher(
                duration: AppMotion.fade,
                child: _conteudoAtual(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final botao = widget.compacto ? _botaoCompacto() : _botaoCheio();

    return ToqueElastico(
      ativo: _habilitado,
      escalaHover: widget.compacto ? 1.04 : 1.015,
      child: botao
          .animate(autoPlay: false, onInit: (c) => _shake = c)
          .shake(
            duration: const Duration(milliseconds: 500),
            hz: 4,
            offset: const Offset(8, 0),
            rotation: 0,
          ),
    );
  }
}
