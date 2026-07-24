import 'package:controle_financeiro/widgets/botoes_personalizados.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Campo de data: já vem preenchido com hoje, e ao tocar abre um calendário
/// que só permite escolher hoje ou datas anteriores (nunca datas futuras).
class DatePickerField extends StatelessWidget {
  final DateTime valor;
  final ValueChanged<DateTime> onChanged;

  const DatePickerField({super.key, required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final escolhida = await showDatePicker(
            context: context,
            initialDate: valor,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            helpText: 'Escolha a data',
            cancelText: 'Cancelar',
            confirmText: 'Confirmar',
            locale: const Locale('pt', 'BR'),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  textButtonTheme: TextButtonThemeData(
                    style: estiloBotao(corForeGround: Color(0xFF2e2a6e)),
                  ),
                  iconButtonTheme: IconButtonThemeData(
                    style: estiloBotao(),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (escolhida != null) onChanged(escolhida);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(Formatters.data(valor), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formata a digitação como centavos entrando pela direita, no estilo
/// "R$ 0,00" -> digita 1 -> "R$ 0,01" -> digita 2 -> "R$ 0,12" e assim por diante.
class _CentavosInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) digitos = '0';
    if (digitos.length > 12) digitos = digitos.substring(digitos.length - 12);

    final valorCentavos = int.parse(digitos);
    final valor = valorCentavos / 100;
    final texto = valor.toStringAsFixed(2).replaceAll('.', ',');
    final formatado = _comSeparadorMilhar(texto);

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }

  String _comSeparadorMilhar(String valorComVirgula) {
    final partes = valorComVirgula.split(',');
    final inteiro = partes[0];
    final decimais = partes.length > 1 ? partes[1] : '00';
    final buffer = StringBuffer();
    for (var i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) buffer.write('.');
      buffer.write(inteiro[i]);
    }
    return '${buffer.toString()},$decimais';
  }
}

/// Campo de valor com o "R$" fixo antes do número, já formatado como dinheiro.
/// [valorInicial] permite pré-preencher (usado ao editar um lançamento existente).
class CurrencyInput extends StatefulWidget {
  final ValueChanged<double> onChanged;
  final double valorInicial;

  const CurrencyInput({super.key, required this.onChanged, this.valorInicial = 0});

  @override
  State<CurrencyInput> createState() => CurrencyInputState();
}

class CurrencyInputState extends State<CurrencyInput> {
  late final TextEditingController _controller =
      TextEditingController(text: _formatar(widget.valorInicial));

  String _formatar(double v) {
    final texto = v.toStringAsFixed(2).replaceAll('.', ',');
    final partes = texto.split(',');
    final buffer = StringBuffer();
    final inteiro = partes[0];
    for (var i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) buffer.write('.');
      buffer.write(inteiro[i]);
    }
    return '${buffer.toString()},${partes[1]}';
  }

  double get valorAtual {
    final limpo = _controller.text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo) ?? 0.0;
  }

  void limpar() {
    setState(() => _controller.text = '0,00');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_CentavosInputFormatter()],
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      decoration: const InputDecoration(
        prefixText: 'R\$ ',
        prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      onChanged: (_) => widget.onChanged(valorAtual),
    );
  }
}
