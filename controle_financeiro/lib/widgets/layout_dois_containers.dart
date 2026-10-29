import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/sidebar_utils.dart';

/// Descreve o conteúdo de um dos dois containers.
class ConfigBloco {
  final String titulo;
  final Color cor;
  final int quantidade;
  final IndexedWidgetBuilder itemBuilder;
  final String mensagemVazia;
  final Widget? cabecalhoTabela;  /// Aparece acima da lista, só quando há itens
  final Widget? rodape;  /// Fixo abaixo da lista

  const ConfigBloco({
    required this.titulo,
    required this.cor,
    required this.quantidade,
    required this.itemBuilder,
    required this.mensagemVazia,
    this.cabecalhoTabela,
    this.rodape,
  });
}

/// Layout de aba com dois containers flexiveis e quando compacto se torna um trocando entre uma variante e outra
class TelaDuasListas extends StatefulWidget {
  final String titulo;
  final ConfigBloco primeiro;
  final ConfigBloco segundo;

  const TelaDuasListas({
    super.key,
    required this.titulo,
    required this.primeiro,
    required this.segundo,
  });

  @override
  State<TelaDuasListas> createState() => _TelaDuasListasState();
}

class _TelaDuasListasState extends State<TelaDuasListas> {
  bool _mostrarSegundoCompacto = false;
  static const _minWidth = 500.0; /// Largura abaixo da qual passa para o modo compacto
  static const _larguraMaximaBloco = double.infinity; /// Largura máxima de cada container
  static const _alturaMaximaBloco = double.infinity; /// Altura máxima de cada container
  static const _espacoEntreBlocos = 48.0; /// Espaço entre os dois containers

  Widget _limitar(Widget bloco) => ConstrainedBox(
    constraints: const BoxConstraints(
      maxWidth: _larguraMaximaBloco,
      maxHeight: _alturaMaximaBloco,
    ),
    child: bloco,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sidebarVisivel(context)) ...[
          Text(widget.titulo, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= _minWidth) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: _limitar(_bloco(context, widget.primeiro))),
                    const SizedBox(width: _espacoEntreBlocos),
                    Flexible(child: _limitar(_bloco(context, widget.segundo))),
                  ],
                );
              }

              final atual = _mostrarSegundoCompacto
                  ? widget.segundo
                  : widget.primeiro;
              return Align(
                alignment: Alignment.topCenter,
                child: _limitar(
                  _bloco(
                    context,
                    atual,
                    onTrocar: () => setState(
                      () => _mostrarSegundoCompacto = !_mostrarSegundoCompacto,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bloco(
    BuildContext context,
    ConfigBloco c, {
    VoidCallback? onTrocar, // se não-nulo, usa o layout "compacto" do cabeçalho
  }) {
    final vazio = c.quantidade == 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: onTrocar != null
                      ? [
                          Text(
                            '${c.quantidade}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: c.cor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            c.titulo,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ]
                      : [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: c.cor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            c.titulo,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                ),
                if (onTrocar != null)
                  InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(20),
                    onTap: onTrocar,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.sync_alt_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  Text(
                    '${c.quantidade}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!vazio && c.cabecalhoTabela != null) c.cabecalhoTabela!,
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: vazio ? 1 : c.quantidade,
              itemBuilder: (context, i) {
                if (vazio) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      c.mensagemVazia,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return c.itemBuilder(context, i);
              },
            ),
          ),
          if (c.rodape != null) ...[const SizedBox(height: 8), c.rodape!],
        ],
      ),
    );
  }
}