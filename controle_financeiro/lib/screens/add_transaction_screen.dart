import 'package:controle_financeiro/widgets/others_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categoria.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/form_fields.dart';
import '../widgets/category_selector.dart';
import '../widgets/botoes_personalizados.dart';
import '../widgets/recorrencia_widgets.dart';
import '../models/recorrencia.dart' as model;

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

  // Estado da recorrência
  bool _recorrenciaAtiva = false;
  ConfiguracaoRecorrencia? _configRecorrencia;

  bool get _valido => _tipo != null && _categoria != null && _valor > 0;

  model.PeriodoRecorrencia _paraPeriodoModel(PeriodoRecorrencia p) => switch (p) {
        PeriodoRecorrencia.diariamente => model.PeriodoRecorrencia.diariamente,
        PeriodoRecorrencia.semanalmente => model.PeriodoRecorrencia.semanalmente,
        PeriodoRecorrencia.mensalmente => model.PeriodoRecorrencia.mensalmente,
        PeriodoRecorrencia.anualmente => model.PeriodoRecorrencia.anualmente,
      };

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AddTransactionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ativa && !widget.ativa) {
      setState(() {
        _erroTipo = false;
        _erroCategoria = false;
        _erroValor = false;
        // Saiu da aba sem salvar: desfaz a recorrência pendente.
        _recorrenciaAtiva = false;
        _configRecorrencia = null;
      });
    }
  }

  Future<void> _alternarRecorrencia(bool valor) async {
    if (!valor) {
      setState(() {
        _recorrenciaAtiva = false;
        _configRecorrencia = null;
      });
      return;
    }

    // Ativa visualmente o switch já ao ligar, e abre o dialog em seguida.
    setState(() => _recorrenciaAtiva = true);

    final resultado = await RecorrenciaDialog.show(
      context,
      configuracaoInicial: _configRecorrencia,
    );

    if (!mounted) return;

    if (resultado == null) {
      // Cancelou ou fechou no X: volta pro estado desativado.
      setState(() {
        _recorrenciaAtiva = false;
        _configRecorrencia = null;
      });
    } else {
      setState(() => _configRecorrencia = resultado);
    }
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
      final config = _configRecorrencia;

      if (config == null) {
        await context.read<FinanceProvider>().adicionarTransacao(
          data: _data,
          tipo: _tipo!,
          categoriaId: _categoria!.id,
          categoriaNome: _categoria!.nome,
          valor: _valor,
          descricao: descricao.isEmpty ? null : descricao,
        );
      } else {
        await context.read<FinanceProvider>().adicionarTransacaoRecorrente(
          data: _data,
          tipo: _tipo!,
          categoriaId: _categoria!.id,
          categoriaNome: _categoria!.nome,
          valor: _valor,
          descricao: descricao.isEmpty ? null : descricao,
          periodo: _paraPeriodoModel(config.periodo),
          dataInicioRecorrencia: config.dataInicio,
          dataTermino: config.dataTermino,
        );
      }

      if (!mounted) return true;
      _valorKey.currentState?.limpar();
      _descricaoController.clear();
      setState(() {
        _tipo = null;
        _categoria = null;
        _valor = 0;
        _recorrenciaAtiva = false;
        _configRecorrencia = null;
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
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                  SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.swap_horiz,
                                        size: 16,
                                      ),
                                      tooltip: 'Trocar tipo',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 16,
                                      mouseCursor: SystemMouseCursors.click,
                                      onPressed: () => setState(() {
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CampoComErro(
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
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _rotulo('Recorrente'),
                            SizedBox(
                              height: 52,
                              child: Center(
                                child: SwitchRecorrencia(
                                  ativo: _recorrenciaAtiva,
                                  onChanged: _alternarRecorrencia,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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