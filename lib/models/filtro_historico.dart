import 'categoria.dart';
import 'transacao.dart';

enum CampoFiltro { data, tipo, categoria, valor }

extension CampoFiltroLabel on CampoFiltro {
  String get rotulo {
    switch (this) {
      case CampoFiltro.data:
        return 'Data';
      case CampoFiltro.tipo:
        return 'Tipo';
      case CampoFiltro.categoria:
        return 'Categoria';
      case CampoFiltro.valor:
        return 'Valor';
    }
  }
}

enum Operador { igual, maior, maiorIgual, menor, menorIgual }

extension OperadorLabel on Operador {
  String get simbolo {
    switch (this) {
      case Operador.igual:
        return '=';
      case Operador.maior:
        return '>';
      case Operador.maiorIgual:
        return '≥';
      case Operador.menor:
        return '<';
      case Operador.menorIgual:
        return '≤';
    }
  }

  String get rotulo {
    switch (this) {
      case Operador.igual:
        return 'Igual';
      case Operador.maior:
        return 'Maior';
      case Operador.maiorIgual:
        return 'Maior ou igual';
      case Operador.menor:
        return 'Menor';
      case Operador.menorIgual:
        return 'Menor ou igual';
    }
  }
}

/// Um filtro ativo no histórico. Para Tipo/Categoria usa [texto] (busca por
/// conter o termo). Para Data/Valor usa dois campos + operador: quando o
/// segundo campo está preenchido, ele manda (aplica o operador); quando só
/// o primeiro está preenchido, busca por igualdade.
class FiltroHistorico {
  final String id;
  final CampoFiltro campo;

  final String? texto;

  final DateTime? data1;
  final DateTime? data2;
  final double? numero1;
  final double? numero2;
  final Operador operador;

  const FiltroHistorico({
    required this.id,
    required this.campo,
    this.texto,
    this.data1,
    this.data2,
    this.numero1,
    this.numero2,
    this.operador = Operador.igual,
  });

  bool aplica(Transacao t) {
    switch (campo) {
      case CampoFiltro.tipo:
        if (texto == null || texto!.trim().isEmpty) return true;
        final alvo = texto!.trim().toLowerCase();
        if (t.tipo == TipoLancamento.entrada) return 'entrada'.contains(alvo);
        return 'saída'.contains(alvo) || 'saida'.contains(alvo);

      case CampoFiltro.categoria:
        if (texto == null || texto!.trim().isEmpty) return true;
        return t.categoriaNome.toLowerCase().contains(texto!.trim().toLowerCase());

      case CampoFiltro.data:
        final d = DateTime(t.data.year, t.data.month, t.data.day);
        final d1 = data1 != null ? DateTime(data1!.year, data1!.month, data1!.day) : null;
        final d2 = data2 != null ? DateTime(data2!.year, data2!.month, data2!.day) : null;
        return _aplicaIntervalo<DateTime>(valor: d, v1: d1, v2: d2, comparar: (a, b) => a.compareTo(b));

      case CampoFiltro.valor:
        return _aplicaIntervalo<double>(valor: t.valor, v1: numero1, v2: numero2, comparar: (a, b) => a.compareTo(b));
    }
  }

  /// - Os dois campos preenchidos: filtra por intervalo (entre v1 e v2,
  ///   independente de qual é o menor), o operador é ignorado.
  /// - Só o campo 2 preenchido: aplica o operador sobre v2.
  /// - Só o campo 1 preenchido: busca por igualdade a v1.
  /// - Nenhum preenchido: filtro inativo (sempre passa).
  bool _aplicaIntervalo<T>({
    required T valor,
    required T? v1,
    required T? v2,
    required int Function(T, T) comparar,
  }) {
    if (v1 != null && v2 != null) {
      final v1EhMenor = comparar(v1, v2) <= 0;
      final menor = v1EhMenor ? v1 : v2;
      final maior = v1EhMenor ? v2 : v1;
      return comparar(valor, menor) >= 0 && comparar(valor, maior) <= 0;
    }
    if (v2 != null) {
      final cmp = comparar(valor, v2);
      switch (operador) {
        case Operador.igual:
          return cmp == 0;
        case Operador.maior:
          return cmp > 0;
        case Operador.maiorIgual:
          return cmp >= 0;
        case Operador.menor:
          return cmp < 0;
        case Operador.menorIgual:
          return cmp <= 0;
      }
    }
    if (v1 != null) return comparar(valor, v1) == 0;
    return true;
  }
}
