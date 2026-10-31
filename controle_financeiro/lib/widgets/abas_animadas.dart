import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Substitui o IndexedStack: mantém todas as abas vivas (estado preservado)
/// e anima a troca com SharedAxisTransition horizontal.
///
/// [posicoes] guarda a posição visual de cada aba na sidebar
/// (posicoes[indiceDaAba] = posição). A direção segue essa posição:
/// indo para uma aba abaixo, a tela entra da direita para a esquerda;
/// indo para uma aba acima, entra da esquerda para a direita.
class AbasAnimadas extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final List<int> posicoes;
  final Duration duration;

  const AbasAnimadas({
    super.key,
    required this.index,
    required this.children,
    required this.posicoes,
    this.duration = AppMotion.transicaoAba,
  });

  @override
  State<AbasAnimadas> createState() => _AbasAnimadasState();
}

class _AbasAnimadasState extends State<AbasAnimadas> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _inversa;
  late int _atual;
  int? _anterior; // só preenchido enquanto a transição acontece
  bool _reverso = false;

  @override
  void initState() {
    super.initState();
    _atual = widget.index;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _anterior = null);
        }
      });
    _inversa = ReverseAnimation(_controller);
  }

  @override
  void didUpdateWidget(covariant AbasAnimadas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _atual) {
      _anterior = _atual;
      _atual = widget.index;
      _reverso = widget.posicoes[_atual] < widget.posicoes[_anterior!];
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// (animation, secondaryAnimation) de cada aba conforme o papel dela.
  (Animation<double>, Animation<double>) _animacoesDe(int i) {
    if (_anterior == null) {
      return i == _atual
          ? (kAlwaysCompleteAnimation, kAlwaysDismissedAnimation)
          : (kAlwaysDismissedAnimation, kAlwaysDismissedAnimation);
    }
    if (!_reverso) {
      if (i == _atual) return (_controller, kAlwaysDismissedAnimation); // entra
      if (i == _anterior) return (kAlwaysCompleteAnimation, _controller); // sai
    } else {
      if (i == _atual) return (kAlwaysCompleteAnimation, _inversa); // entra
      if (i == _anterior) return (_inversa, kAlwaysDismissedAnimation); // sai
    }
    return (kAlwaysDismissedAnimation, kAlwaysDismissedAnimation);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _anterior != null, // sem cliques durante a transição
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (int i = 0; i < widget.children.length; i++) _construirAba(i),
        ],
      ),
    );
  }

  Widget _construirAba(int i) {
    final (entrada, saida) = _animacoesDe(i);
    final visivel = i == _atual || i == _anterior;

    // A estrutura é sempre a mesma para cada aba; assim o State dela
    // nunca é recriado, só muda a animação.
    return Offstage(
      key: ValueKey(i),
      offstage: !visivel,
      child: TickerMode(
        enabled: visivel,
        child: SharedAxisTransition(
          animation: entrada,
          secondaryAnimation: saida,
          transitionType: SharedAxisTransitionType.horizontal,
          fillColor: Colors.transparent,
          child: widget.children[i],
        ),
      ),
    );
  }
}