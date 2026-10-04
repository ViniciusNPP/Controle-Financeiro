import '../models/recorrencia.dart';

DateTime proximaDataRecorrencia(DateTime atual, PeriodoRecorrencia periodo) {
  switch (periodo) {
    case PeriodoRecorrencia.diariamente:
      return atual.add(const Duration(days: 1));
    case PeriodoRecorrencia.semanalmente:
      return atual.add(const Duration(days: 7));
    case PeriodoRecorrencia.mensalmente:
      return _navegarMeses(atual, 1);
    case PeriodoRecorrencia.anualmente:
      return _navegarMeses(atual, 12);
  }
}

DateTime _navegarMeses(DateTime atual, int meses) {
  final anoDestino = atual.year + ((atual.month - 1 + meses) ~/ 12);
  final mesDestino = ((atual.month - 1 + meses) % 12) + 1;
  final ultimoDiaDoMesDestino = _ultimoDiaDoMes(anoDestino, mesDestino);
  final dia = atual.day > ultimoDiaDoMesDestino ? ultimoDiaDoMesDestino : atual.day;
  return DateTime(anoDestino, mesDestino, dia);
}

int _ultimoDiaDoMes(int ano, int mes) {
  // Dia 0 do mês seguinte é o último dia do mês atual.
  return DateTime(ano, mes + 1, 0).day;
}