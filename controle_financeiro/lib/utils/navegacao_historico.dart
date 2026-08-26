import '../models/categoria.dart';
import '../models/filtro_historico.dart';

List<FiltroHistorico> filtrosHistoricoDoGrafico({
  required DateTime data1,
  required DateTime data2,
  required TipoLancamento tipo,
  String? categoria,
}) {
  final filtros = <FiltroHistorico>[];

  if (categoria != null && categoria.trim().isNotEmpty) {
    filtros.add(FiltroHistorico(
      id: '__grafico_categoria__',
      campo: CampoFiltro.categoria,
      texto: categoria,
    ));
  }

  filtros.add(FiltroHistorico(
    id: '__grafico_data__',
    campo: CampoFiltro.data,
    data1: data1,
    data2: data2,
  ));

  filtros.add(FiltroHistorico(
    id: '__grafico_tipo__',
    campo: CampoFiltro.tipo,
    texto: tipo == TipoLancamento.entrada ? 'Entrada' : 'Saída',
  ));

  return filtros;
}