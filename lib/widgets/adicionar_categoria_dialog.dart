import 'package:controle_financeiro/widgets/botoes_personalizados.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';

/// Popup de adicionar categoria usado na aba Categorias. Diferente do
/// "+ nova categoria" do formulário de lançamento, este NÃO fecha ao
/// adicionar: mostra uma confirmação rápida e limpa o campo, para o usuário
/// poder adicionar várias categorias seguidas sem reabrir o popup.
class AdicionarCategoriaDialog extends StatefulWidget {
  final TipoLancamento tipo;

  const AdicionarCategoriaDialog({super.key, required this.tipo});

  @override
  State<AdicionarCategoriaDialog> createState() => _AdicionarCategoriaDialogState();
}

class _AdicionarCategoriaDialogState extends State<AdicionarCategoriaDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _salvando = false;
  String? _mensagem;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _adicionar() async {
    final nome = _controller.text.trim();
    if (nome.isEmpty || _salvando) return;

    setState(() => _salvando = true);
    await context.read<FinanceProvider>().adicionarCategoria(nome, widget.tipo);
    if (!mounted) return;

    setState(() {
      _salvando = false;
      _mensagem = '"$nome" adicionada!';
      _controller.clear();
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cor = widget.tipo == TipoLancamento.entrada ? AppColors.entrada : AppColors.saida;
    final tipoLabel = widget.tipo == TipoLancamento.entrada ? 'entrada' : 'saída';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Nova categoria de $tipoLabel'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Nome da categoria'),
              onSubmitted: (_) => _adicionar(),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _mensagem == null
                  ? const SizedBox(height: 0)
                  : Padding(
                      key: ValueKey(_mensagem),
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 16, color: cor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _mensagem!,
                              style: TextStyle(color: cor, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: estiloBotao(corForeGround: Color(0xFF3e3b79)),
          child: const Text('Fechar'),
        ),
        ElevatedButton.icon(
          onPressed: _salvando ? null : _adicionar,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Adicionar'),
          style: estiloBotao(corBackGround: Color(0xFF3e3b79), isSide: true),
        ),
      ],
    );
  }
}
