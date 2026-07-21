import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/form_fields.dart';
import '../widgets/category_selector.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _valorKey = GlobalKey<CurrencyInputState>();

  DateTime _data = DateTime.now();
  TipoLancamento? _tipo;
  Categoria? _categoria;
  double _valor = 0;
  bool _salvando = false;

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
      _data = DateTime.now();
      _tipo = null;
      _categoria = null;
      _valor = 0;
      _salvando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lançamento adicionado!'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Novo lançamento', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              _rotulo('Data'),
              DatePickerField(valor: _data, onChanged: (d) => setState(() => _data = d)),
              const SizedBox(height: 20),
              _rotulo('Tipo'),
              Row(
                children: [
                  Expanded(child: _botaoTipo('Entrada', TipoLancamento.entrada, AppColors.entrada)),
                  const SizedBox(width: 12),
                  Expanded(child: _botaoTipo('Saída', TipoLancamento.saida, AppColors.saida)),
                ],
              ),
              const SizedBox(height: 20),
              _rotulo('Categoria'),
              CategorySelector(
                tipo: _tipo,
                categoriaSelecionada: _categoria,
                onSelecionar: (c) => setState(() => _categoria = c),
              ),
              const SizedBox(height: 20),
              _rotulo('Valor'),
              CurrencyInput(key: _valorKey, onChanged: (v) => setState(() => _valor = v)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _valido && !_salvando ? _salvar : null,
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
    );
  }

  Widget _rotulo(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      );

  Widget _botaoTipo(String label, TipoLancamento tipo, Color cor) {
    final selecionado = _tipo == tipo;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() {
          _tipo = tipo;
          _categoria = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selecionado ? cor.withOpacity(0.12) : AppColors.disabledFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selecionado ? cor : Colors.transparent, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: selecionado ? cor : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
