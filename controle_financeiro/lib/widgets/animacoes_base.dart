import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:animations/animations.dart';

/// Efeito elástico ao apertar
class ToqueElastico extends StatefulWidget {
  final Widget child;
  final double escala; // ao apertar
  final double escalaHover; // ao passar o mouse (1.0 = não cresce)
  final bool ativo;

  const ToqueElastico({
    super.key,
    required this.child,
    this.escala = 0.94,
    this.escalaHover = 1.04,
    this.ativo = true,
  });

  @override
  State<ToqueElastico> createState() => _ToqueElasticoState();
}

class _ToqueElasticoState extends State<ToqueElastico> {
  bool _pressionado = false;
  bool _hover = false;
  Curve _curva = Curves.ease;
  Duration _duracao = AppMotion.hover;

  void _apertar(bool valor) {
    if (valor && !widget.ativo) return;
    if (_pressionado == valor) return;
    setState(() {
      _pressionado = valor;
      // Apertar: rápido. Soltar: elástico.
      _curva = valor ? Curves.easeOut : Curves.elasticOut;
      _duracao = valor ? AppMotion.pressionar : AppMotion.soltar;
    });
  }

  void _passar(bool valor) {
    if (_hover == valor) return;
    setState(() {
      _hover = valor;
      if (!_pressionado) {
        // Hover usa ease (sem elástico).
        _curva = Curves.ease;
        _duracao = AppMotion.hover;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hover = _hover && widget.ativo;
    final escala = _pressionado
        ? widget.escala
        : (hover ? widget.escalaHover : 1.0);

    return MouseRegion(
      onEnter: (_) => _passar(true),
      onExit: (_) => _passar(false),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _apertar(true),
        onPointerUp: (_) => _apertar(false),
        onPointerCancel: (_) => _apertar(false),
        child: AnimatedScale(
          scale: escala,
          duration: _duracao,
          curve: _curva,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Fundo que, ao mudar de cor, expande a cor nova em círculo a partir de onde o usuário clicou
class RevelacaoDeCor extends StatefulWidget {
  final Color cor;
  final ShapeBorder forma;
  final Duration duracao;
  final Curve curva;
  final Widget child;

  const RevelacaoDeCor({
    super.key,
    required this.cor,
    required this.forma,
    required this.child,
    this.duracao = AppMotion.revelacaoCor,
    this.curva = Curves.easeOutCubic,
  });

  @override
  State<RevelacaoDeCor> createState() => _RevelacaoDeCorState();
}

class _RevelacaoDeCorState extends State<RevelacaoDeCor>
    with SingleTickerProviderStateMixin {
  // Um clique mais antigo que isso não vale como origem da expansão.
  static const _validadeToque = Duration(seconds: 4);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duracao,
  );
  late Color _corBase = widget.cor;
  late Color _corNova = widget.cor;

  Offset? _ultimoToque;
  DateTime? _instanteToque;
  Offset? _origemAtiva; // null = fade

  @override
  void didUpdateWidget(covariant RevelacaoDeCor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cor == _corNova) return;

    _corBase = _corNova;
    _corNova = widget.cor;

    final instante = _instanteToque;
    final recente =
        instante != null &&
        DateTime.now().difference(instante) < _validadeToque;
    _origemAtiva = recente ? _ultimoToque : null;

    _controller.duration = widget.duracao;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _ultimoToque = e.localPosition;
        _instanteToque = DateTime.now();
      },
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: widget.forma),
        child: CustomPaint(
          painter: _PintorRevelacao(
            animacao: _controller,
            curva: widget.curva,
            base: _corBase,
            nova: _corNova,
            origem: _origemAtiva,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _PintorRevelacao extends CustomPainter {
  final Animation<double> animacao;
  final Curve curva;
  final Color base;
  final Color nova;
  final Offset? origem;

  _PintorRevelacao({
    required this.animacao,
    required this.curva,
    required this.base,
    required this.nova,
    required this.origem,
  }) : super(repaint: animacao);

  @override
  void paint(Canvas canvas, Size size) {
    final retangulo = Offset.zero & size;
    final t = curva.transform(animacao.value);
    final centro = origem;

    if (centro == null) {
      canvas.drawRect(retangulo, Paint()..color = Color.lerp(base, nova, t)!);
      return;
    }

    canvas.drawRect(retangulo, Paint()..color = base);
    if (t <= 0) return;

    // Raio até o canto mais distante: com t = 1 o círculo cobre tudo.
    var raioMax = 0.0;
    for (final canto in [
      retangulo.topLeft,
      retangulo.topRight,
      retangulo.bottomLeft,
      retangulo.bottomRight,
    ]) {
      raioMax = math.max(raioMax, (canto - centro).distance);
    }
    canvas.drawCircle(centro, raioMax * t, Paint()..color = nova);
  }

  @override
  bool shouldRepaint(covariant _PintorRevelacao old) =>
      old.base != base || old.nova != nova || old.origem != origem;
}

class ChipAnimado extends StatelessWidget {
  final String label;
  final bool selecionado;
  final VoidCallback onTap;
  final Color fundoSelecionado;
  final Color fundoNormal;
  final Color textoSelecionado;
  final Color textoNormal;
  final Color? bordaSelecionada;
  final Color? bordaNormal;
  final EdgeInsetsGeometry padding;
  final double raio;
  final double? fontSize;

  const ChipAnimado({
    super.key,
    required this.label,
    required this.selecionado,
    required this.onTap,
    required this.fundoSelecionado,
    required this.fundoNormal,
    required this.textoSelecionado,
    required this.textoNormal,
    this.bordaSelecionada,
    this.bordaNormal,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.raio = 10,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final temBorda = bordaSelecionada != null && bordaNormal != null;
    final fundoAtual = selecionado ? fundoSelecionado : fundoNormal;
    final escuro =
        Color.alphaBlend(fundoAtual, Colors.white).computeLuminance() < 0.4;

    return HoverAnimado(
      tom: escuro ? TomHover.escuro : TomHover.claro,
      raio: raio,
      escala: 1.04,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fade,
          curve: Curves.easeInOut,
          padding: padding,
          decoration: BoxDecoration(
            color: fundoAtual,
            borderRadius: BorderRadius.circular(raio),
            border: temBorda
                ? Border.all(
                    color: selecionado ? bordaSelecionada! : bordaNormal!,
                  )
                : null,
          ),
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              end: selecionado ? textoSelecionado : textoNormal,
            ),
            duration: AppMotion.fade,
            builder: (context, cor, _) => Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: cor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fade through quando [chave] muda
class TrocaFadeThrough extends StatelessWidget {
  final Object chave;
  final Widget child;
  final bool expandir;
  final AlignmentGeometry alinhamento;
  final Duration duracao;

  const TrocaFadeThrough({
    super.key,
    required this.chave,
    required this.child,
    this.expandir = false,
    this.alinhamento = Alignment.topCenter,
    this.duracao = AppMotion.fadeThrough,
  });

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: duracao,
      layoutBuilder: (entries) => Stack(
        alignment: alinhamento,
        fit: expandir ? StackFit.expand : StackFit.loose,
        children: entries,
      ),
      transitionBuilder: (child, animation, secondaryAnimation) =>
          FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            fillColor: Colors.transparent,
            child: child,
          ),
      child: KeyedSubtree(key: ValueKey(chave), child: child),
    );
  }
}

/// Tom do elemento: claro escurece no hover, escuro clareia.
enum TomHover { claro, escuro }

/// Hover padrão do app: tinta por cima (ease) + aumento opcional
class HoverAnimado extends StatefulWidget {
  final Widget child;
  final TomHover tom;
  final double raio;
  final double escala; // 1.0 = não cresce
  final bool ativo;
  final MouseCursor cursor;
  final Color? corHover;

  const HoverAnimado({
    super.key,
    required this.child,
    this.tom = TomHover.claro,
    this.raio = 12,
    this.escala = 1.0,
    this.ativo = true,
    this.cursor = SystemMouseCursors.click,
    this.corHover,
  });

  @override
  State<HoverAnimado> createState() => _HoverAnimadoState();
}

class _HoverAnimadoState extends State<HoverAnimado> {
  bool _hover = false;

  void _definir(bool valor) {
    if (_hover == valor) return;
    setState(() => _hover = valor);
  }

  @override
  Widget build(BuildContext context) {
    final cor =
        widget.corHover ??
        (widget.tom == TomHover.escuro
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.05));
    final hover = _hover && widget.ativo;

    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => _definir(true),
      onExit: (_) => _definir(false),
      child: AnimatedScale(
        scale: hover ? widget.escala : 1.0,
        duration: AppMotion.hover,
        curve: Curves.ease,
        child: AnimatedContainer(
          duration: AppMotion.hover,
          curve: Curves.ease,
          foregroundDecoration: BoxDecoration(
            color: hover ? cor : cor.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(widget.raio),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Fade normal (cross-fade) quando [chave] muda.
class TrocaFade extends StatelessWidget {
  final Object chave;
  final Widget child;
  final bool ativo;
  final bool expandir;
  final AlignmentGeometry alinhamento;
  final Duration duracao;

  const TrocaFade({
    super.key,
    required this.chave,
    required this.child,
    this.ativo = true,
    this.expandir = false,
    this.alinhamento = Alignment.centerLeft,
    this.duracao = AppMotion.fade,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: ativo ? duracao : Duration.zero,
      layoutBuilder: (atual, anteriores) => Stack(
        alignment: alinhamento,
        fit: expandir ? StackFit.expand : StackFit.loose,
        children: [...anteriores, if (atual != null) atual],
      ),
      child: KeyedSubtree(key: ValueKey(chave), child: child),
    );
  }
}
