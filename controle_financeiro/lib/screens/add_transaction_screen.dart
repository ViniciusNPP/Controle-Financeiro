import 'package:controle_financeiro/utils/app_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/form_fields.dart';
import '../widgets/category_selector.dart';
import '../widgets/botoes_personalizados.dart';

class AddTransactionScreen extends StatefulWidget {
  final bool ativa;
  const AddTransactionScreen({super.key, this.ativa = true});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _valorKey = GlobalKey<CurrencyInputState>();
  bool _tecladoRegistrado = false;

  DateTime _data = DateTime.now();
  TipoLancamento? _tipo;
  Categoria? _categoria;
  double _valor = 0;
  bool _salvando = false;
  bool _isCategoria = false;
  bool _isData = false;

  bool get _valido => _tipo != null && _categoria != null && _valor > 0;

  Future<void> _salvar() async {
    if (!_valido) return;
    setState(() => _salvando = true);

    await context.read<FinanceProvider>().adicionarTransacao(
          data: _data,
          tipo: _tipo!,
          categoriaId: _categoria!.id,
          categoriaNome: _categoria!.nome,
          valor: _valor,
        );

    if (!mounted) return;
    _valorKey.currentState?.limpar();
    setState(() {
      _tipo = null;
      _categoria = null;
      _valor = 0;
      _salvando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lançamento adicionado!'), behavior: SnackBarBehavior.floating),
    );
  }

  Map<LogicalKeyboardKey, bool Function()> _acoesDigitos() {
    const teclas = [
      LogicalKeyboardKey.digit0, LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4, LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6, LogicalKeyboardKey.digit7, LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    return {
      for (var i = 0; i < teclas.length; i++)
        teclas[i]: () => (!_isCategoria && !_isData)
            ? inserirDigitoInput(context: context, digito: '$i', valorKey: _valorKey)
            : false,
    };
  }
  
  late final _teclado = GlobalKeyHandler(
    obterContext: () => context,
    acoes1: {
      LogicalKeyboardKey.enter: () {
        if (_valido && !_salvando) _salvar();
      },
    },
    acoes2: {
      LogicalKeyboardKey.backspace: () => (!_isCategoria && !_isData) 
        ? removerDigitoInput(context: context, valorKey: _valorKey)
        : false,
        ... _acoesDigitos()
    }
  );
  
  void _atualizarHandler() {
    if (widget.ativa && !_tecladoRegistrado) {
      _teclado.registrar();
      _tecladoRegistrado = true;
    } else if (!widget.ativa && _tecladoRegistrado) {
      _teclado.remover();
      _tecladoRegistrado = false;
    }
  }
  
  @override
  void initState() {
    super.initState();
    _atualizarHandler();
  }

  @override
  void didUpdateWidget(covariant AddTransactionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _atualizarHandler();
  }

  @override
  void dispose() {
    if (_tecladoRegistrado) _teclado.remover();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Novo lançamento', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                _rotulo('Data'),
                GestureDetector(
                  onTap: () => _isData = true,
                  child: DatePickerField(valor: _data, onChanged: (d) {
                    setState(() => _data = d);
                    _isData = false;
                  }),
                ),
                const SizedBox(height: 20),
                _rotulo('Tipo'),
                Row(
                  children: [
                    Expanded(
                      child: botaoSelecionavel(
                        label: 'Entrada',
                        selecionado: _tipo == TipoLancamento.entrada,
                        cor: AppColors.entrada,
                        onTap: () => setState(() {
                          _tipo = TipoLancamento.entrada;
                          _categoria = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: botaoSelecionavel(
                        label: 'Saída',
                        selecionado: _tipo == TipoLancamento.saida,
                        cor: AppColors.saida,
                        onTap: () => setState(() {
                          _tipo = TipoLancamento.saida;
                          _categoria = null;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _rotulo('Categoria'),
                GestureDetector(
                  onTap: () => _isCategoria = true,
                  child: CategorySelector(
                    tipo: _tipo,
                    categoriaSelecionada: _categoria,
                    onSelecionar: (c) {
                      setState(() => _categoria = c);
                      _isCategoria = false;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _rotulo('Valor'),
                CurrencyInput(
                  key: _valorKey, 
                  onChanged: (v) => setState(() => _valor = v), 
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _valido && !_salvando ? _salvar : null,
                    style: estiloBotao(corBackGround: Color(0xFF3e3b79), isSide: true),
                    child: _salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Salvar lançamento'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rotulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      texto,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
    ),
  );
}
