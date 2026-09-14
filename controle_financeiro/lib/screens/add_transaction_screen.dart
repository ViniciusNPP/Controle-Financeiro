import 'package:controle_financeiro/widgets/others_widgets.dart';
import 'package:flutter/material.dart';
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
  final _descricaoController = TextEditingController();

  DateTime _data = DateTime.now();
  TipoLancamento? _tipo;
  Categoria? _categoria;
  double _valor = 0;

  bool _erroTipo = false;
  bool _erroCategoria = false;
  bool _erroValor = false;

  bool get _valido => _tipo != null && _categoria != null && _valor > 0;

  @override
  void dispose() {
    setState(() {
      _erroTipo = false;
      _erroCategoria = false;
      _erroValor = false;
    });
    _descricaoController.dispose();
    super.dispose();
  }

  Future<bool> _salvar() async {
    if (!_valido) {
      setState(() {
        _erroTipo = _tipo == null;
        _erroCategoria = _categoria == null;
        _erroValor = _valor <= 0;
      });
      return false;
    }

    try {
      final descricao = _descricaoController.text.trim();
      await context.read<FinanceProvider>().adicionarTransacao(
        data: _data,
        tipo: _tipo!,
        categoriaId: _categoria!.id,
        categoriaNome: _categoria!.nome,
        valor: _valor,
        descricao: descricao.isEmpty ? null : descricao,
      );

      if (!mounted) return true;
      _valorKey.currentState?.limpar();
      _descricaoController.clear();
      setState(() {
        _tipo = null;
        _categoria = null;
        _valor = 0;
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Novo lançamento',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _rotulo('Data'),
                              DatePickerField(
                                valor: _data,
                                onChanged: (d) {
                                  setState(() => _data = d);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Tipo',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _erroTipo
                                          ? Colors.red
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.swap_horiz,
                                      size: 20,
                                    ),
                                    tooltip: 'Trocar tipo',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    mouseCursor: SystemMouseCursors.click,
                                    onPressed: () => setState(() {
                                      _tipo = _tipo == TipoLancamento.entrada
                                          ? TipoLancamento.saida
                                          : TipoLancamento.entrada;
                                      _categoria = null;
                                      _erroTipo = false;
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              BordaComErro(
                                erro: _erroTipo,
                                raioBorda: 16,
                                child: botaoSelecionavel(
                                  label: _tipo == TipoLancamento.saida
                                      ? 'Saída'
                                      : 'Entrada',
                                  selecionado: _tipo != null,
                                  cor: _tipo == TipoLancamento.saida
                                      ? AppColors.saida
                                      : AppColors.entrada,
                                  onTap: () => setState(() {
                                    _tipo = _tipo == TipoLancamento.entrada
                                        ? TipoLancamento.saida
                                        : TipoLancamento.entrada;
                                    _categoria = null;
                                    _erroTipo = false;
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 20),
                    CampoComErro(
                      rotulo: 'Categoria',
                      erro: _erroCategoria,
                      raioBorda: 16,
                      child: CategorySelector(
                        tipo: _tipo,
                        categoriaSelecionada: _categoria,
                        onSelecionar: (c) {
                          setState(() {
                            _categoria = c;
                            _erroCategoria = false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _rotulo('Descrição (opcional)'),
                    TextField(
                      controller: _descricaoController,
                      maxLength: 250,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Observação...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    CampoComErro(
                      rotulo: 'Valor',
                      erro: _erroValor,
                      child: CurrencyInput(
                        key: _valorKey,
                        onChanged: (v) => setState(() {
                          _valor = v;
                          _erroValor = false;
                        }),
                      ),
                    ),
                    const SizedBox(height: 28),
                    BotaoSalvarAnimado(
                      label: 'Salvar lançamento',
                      corIdle: const Color(0xFF3e3b79),
                      aoPressionar: _salvar,
                    ),
                  ],
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
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    ),
  );
}
