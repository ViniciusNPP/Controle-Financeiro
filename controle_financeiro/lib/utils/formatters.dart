import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _moeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  static final NumberFormat _moedaInt = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 0,
  );

  static String moeda(double valor) => _moeda.format(valor);

  static String moedaInt(double valor) {
    final formato = valor == valor.roundToDouble() ? _moedaInt : _moeda;
    return formato.format(valor);
  }

  static String moedaIntSemSimbolo(double valor) {
    return moedaInt(valor).replaceFirst('R\$', '').trim();
  }

  static final DateFormat _dataCurta = DateFormat('dd/MM/yyyy', 'pt_BR');
  static String data(DateTime d) => _dataCurta.format(d);

  static const List<String> nomesMesesAbrev = [
    '',
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  static const List<String> nomesMesesCompleto = [
    '',
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
}
