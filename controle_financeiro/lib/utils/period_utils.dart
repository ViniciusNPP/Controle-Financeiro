import '../models/categoria.dart';
import '../models/transacao.dart';

/// Representa um intervalo de tempo já resolvido (independente de como o
/// usuário chegou nele — mês, bimestre, ano personalizado etc) e se os
/// gráficos devem agrupar os dados por mês ou por ano dentro dele.
class FiltroPeriodo {
  final DateTime inicio;
  final DateTime fimExclusivo;
  final bool agruparPorAno;
  final String rotulo;

  const FiltroPeriodo({
    required this.inicio,
    required this.fimExclusivo,
    required this.agruparPorAno,
    required this.rotulo,
  });

  bool contem(DateTime data) => !data.isBefore(inicio) && data.isBefore(fimExclusivo);
}

class PeriodoUtils {
  PeriodoUtils._();

  static DateTime primeiroDiaDoMes(DateTime d) => DateTime(d.year, d.month);

  static DateTime primeiroDiaDoMesSeguinte(DateTime d) =>
      d.month == 12 ? DateTime(d.year + 1, 1) : DateTime(d.year, d.month + 1);

  static FiltroPeriodo mes(DateTime referencia) {
    final inicio = primeiroDiaDoMes(referencia);
    return FiltroPeriodo(
      inicio: inicio,
      fimExclusivo: primeiroDiaDoMesSeguinte(inicio),
      agruparPorAno: false,
      rotulo: _rotuloMes(inicio),
    );
  }

  /// Janela "rolante" de N meses terminando no mês de referência — usada
  /// pra bimestre (2), trimestre (3) e semestre (6).
  static FiltroPeriodo janelaMeses(DateTime referenciaFim, int quantidadeMeses) {
    final fimBase = primeiroDiaDoMes(referenciaFim);
    var inicio = fimBase;
    for (var i = 1; i < quantidadeMeses; i++) {
      inicio = inicio.month == 1 ? DateTime(inicio.year - 1, 12) : DateTime(inicio.year, inicio.month - 1);
    }
    return FiltroPeriodo(
      inicio: inicio,
      fimExclusivo: primeiroDiaDoMesSeguinte(fimBase),
      agruparPorAno: false,
      rotulo: '${_rotuloMes(inicio)} – ${_rotuloMes(fimBase)}',
    );
  }

  static FiltroPeriodo mesesPersonalizado(DateTime de, DateTime ate) {
    final inicio = primeiroDiaDoMes(de.isBefore(ate) ? de : ate);
    final fimRef = primeiroDiaDoMes(de.isBefore(ate) ? ate : de);
    return FiltroPeriodo(
      inicio: inicio,
      fimExclusivo: primeiroDiaDoMesSeguinte(fimRef),
      agruparPorAno: false,
      rotulo: '${_rotuloMes(inicio)} – ${_rotuloMes(fimRef)}',
    );
  }

  static FiltroPeriodo todoPeriodoMensal(List<DateTime> todasAsDatas) {
    if (todasAsDatas.isEmpty) return mes(DateTime.now());
    final ordenadas = [...todasAsDatas]..sort();
    final inicio = primeiroDiaDoMes(ordenadas.first);
    final fim = primeiroDiaDoMes(ordenadas.last);
    return FiltroPeriodo(
      inicio: inicio,
      fimExclusivo: primeiroDiaDoMesSeguinte(fim),
      agruparPorAno: false,
      rotulo: 'Todo o período',
    );
  }

  static FiltroPeriodo ano(int ano) => FiltroPeriodo(
        inicio: DateTime(ano),
        fimExclusivo: DateTime(ano + 1),
        agruparPorAno: true,
        rotulo: '$ano',
      );

  static FiltroPeriodo anosPersonalizado(int de, int ate) {
    final inicio = de < ate ? de : ate;
    final fim = de < ate ? ate : de;
    return FiltroPeriodo(
      inicio: DateTime(inicio),
      fimExclusivo: DateTime(fim + 1),
      agruparPorAno: true,
      rotulo: '$inicio – $fim',
    );
  }

  static FiltroPeriodo todoPeriodoAnual(List<DateTime> todasAsDatas) {
    if (todasAsDatas.isEmpty) return ano(DateTime.now().year);
    final anos = todasAsDatas.map((d) => d.year).toList()..sort();
    return anosPersonalizado(anos.first, anos.last);
  }

  static String _rotuloMes(DateTime d) {
    const nomes = ['', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${nomes[d.month]}/${d.year}';
  }

  /// Gera os "baldes" (meses ou anos) dentro do filtro — usados como eixo X.
  static List<DateTime> baldes(FiltroPeriodo filtro) {
    final lista = <DateTime>[];
    if (filtro.agruparPorAno) {
      var atual = DateTime(filtro.inicio.year);
      while (atual.isBefore(filtro.fimExclusivo)) {
        lista.add(atual);
        atual = DateTime(atual.year + 1);
      }
    } else {
      var atual = primeiroDiaDoMes(filtro.inicio);
      while (atual.isBefore(filtro.fimExclusivo)) {
        lista.add(atual);
        atual = primeiroDiaDoMesSeguinte(atual);
      }
    }
    return lista;
  }

  static String rotuloBalde(DateTime balde, bool agruparPorAno) {
    if (agruparPorAno) return '${balde.year}';
    const nomes = ['', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return nomes[balde.month];
  }
}

/// Funções que somam as transações filtradas em "baldes" (mês/ano) ou por
/// categoria, prontas para alimentar os gráficos.
class Agregador {
  Agregador._();

  static Map<DateTime, double> porBalde(
    List<Transacao> transacoes,
    FiltroPeriodo filtro,
    TipoLancamento tipo,
  ) {
    final baldes = PeriodoUtils.baldes(filtro);
    final mapa = {for (final b in baldes) b: 0.0};
    for (final t in transacoes) {
      if (t.tipo != tipo) continue;
      if (!filtro.contem(t.data)) continue;
      final chave =
          filtro.agruparPorAno ? DateTime(t.data.year) : PeriodoUtils.primeiroDiaDoMes(t.data);
      if (mapa.containsKey(chave)) {
        mapa[chave] = mapa[chave]! + t.valor;
      }
    }
    return mapa;
  }

  static Map<DateTime, double> saldoPorBalde(List<Transacao> transacoes, FiltroPeriodo filtro) {
    final entradas = porBalde(transacoes, filtro, TipoLancamento.entrada);
    final saidas = porBalde(transacoes, filtro, TipoLancamento.saida);
    return {
      for (final chave in entradas.keys) chave: (entradas[chave] ?? 0) - (saidas[chave] ?? 0),
    };
  }

  static Map<String, double> porCategoria(
    List<Transacao> transacoes,
    FiltroPeriodo filtro,
    TipoLancamento tipo,
  ) {
    final mapa = <String, double>{};
    for (final t in transacoes) {
      if (t.tipo != tipo) continue;
      if (!filtro.contem(t.data)) continue;
      mapa[t.categoriaNome] = (mapa[t.categoriaNome] ?? 0) + t.valor;
    }
    return mapa;
  }
}
