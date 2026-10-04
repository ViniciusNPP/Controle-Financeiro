import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/categoria.dart';
import '../models/recorrencia.dart';
import '../models/transacao.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../utils/recorrencia_calculator.dart';

class FinanceProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final SyncService _sync = SyncService();
  final _uuid = const Uuid();

  DadosApp _dados = DadosApp.vazio();
  DateTime? _ultimaSincronizacao;
  bool _carregado = false;

  DadosApp get dados => _dados;
  List<Categoria> get categorias => _dados.categorias;
  List<Transacao> get transacoes => _dados.transacoes;
  DateTime? get ultimaSincronizacao => _ultimaSincronizacao;
  bool get carregado => _carregado;

  /// Carrega os dados locais
  Future<void> iniciar() async {
    _dados = await _storage.carregar();

    final daPasta = await _sync.lerDaPasta();
    if (daPasta != null) {
      _dados = _mesclar(_dados, daPasta);
      await _storage.salvar(_dados);
    }

    await _gerarTransacoesPendentes();

    _carregado = true;
    notifyListeners();
  }

  /// Percorre os moldes de recorrência e gera as Transacoes pendentes em sequência
  Future<void> _gerarTransacoesPendentes() async {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);

    final novasTransacoes = <Transacao>[];
    final recorrentesAtualizados = <LancamentoRecorrente>[];
    var categoriasAtualizadas = _dados.categorias;
    var houveMudanca = false;

    for (final molde in _dados.recorrentes) {
      var proxima = molde.dataRecorrencia;

      while (!proxima.isAfter(hojeSemHora) &&
          (molde.dataTermino == null || !proxima.isAfter(molde.dataTermino!))) {
        novasTransacoes.add(
          Transacao(
            id: _uuid.v4(),
            data: proxima,
            tipo: molde.tipo,
            categoriaId: molde.categoriaId,
            categoriaNome: molde.categoriaNome,
            valor: molde.valor,
            descricao: molde.descricao,
          ),
        );
        categoriasAtualizadas = [
          for (final c in categoriasAtualizadas)
            if (c.id == molde.categoriaId)
              c.copyWith(vezesUsada: c.vezesUsada + 1)
            else
              c,
        ];
        houveMudanca = true;
        proxima = proximaDataRecorrencia(proxima, molde.periodo);
      }

      recorrentesAtualizados.add(molde.copyWith(dataRecorrencia: proxima));
    }

    if (!houveMudanca) return;

    _dados = _dados.copyWith(
      transacoes: [..._dados.transacoes, ...novasTransacoes],
      categorias: categoriasAtualizadas,
      recorrentes: recorrentesAtualizados,
    );
    await _storage.salvar(_dados);
  }

  /// Mescla dois conjuntos de dados por ID, sem duplicar e sem perder nada.
  DadosApp _mesclar(DadosApp local, DadosApp remoto) {
    final idsTransacoesLocal = local.transacoes.map((t) => t.id).toSet();
    final transacoesMescladas = [...local.transacoes];
    for (final t in remoto.transacoes) {
      if (!idsTransacoesLocal.contains(t.id)) transacoesMescladas.add(t);
    }

    final idsCategoriasLocal = local.categorias.map((c) => c.id).toSet();
    final categoriasMescladas = [...local.categorias];
    for (final c in remoto.categorias) {
      if (!idsCategoriasLocal.contains(c.id)) categoriasMescladas.add(c);
    }

    final idsRecorrentesLocal = local.recorrentes.map((r) => r.id).toSet();
    final recorrentesMesclados = [...local.recorrentes];
    for (final r in remoto.recorrentes) {
      if (!idsRecorrentesLocal.contains(r.id)) recorrentesMesclados.add(r);
    }

    return DadosApp(
      categorias: categoriasMescladas,
      transacoes: transacoesMescladas,
      recorrentes: recorrentesMesclados,
    );
  }

  Future<void> _persistirETentarSincronizar() async {
    await _storage.salvar(_dados);
    await _sync.escreverNaPasta(_dados);
    _ultimaSincronizacao = DateTime.now();
    notifyListeners();
  }

  Future<void> adicionarTransacao({
    required DateTime data,
    required TipoLancamento tipo,
    required String categoriaId,
    required String categoriaNome,
    required double valor,
    String? descricao,
  }) async {
    final nova = Transacao(
      id: _uuid.v4(),
      data: data,
      tipo: tipo,
      categoriaId: categoriaId,
      categoriaNome: categoriaNome,
      valor: valor,
      descricao: descricao,
    );

    _dados = _dados.copyWith(
      transacoes: [..._dados.transacoes, nova],
      categorias: [
        for (final c in _dados.categorias)
          if (c.id == categoriaId)
            c.copyWith(vezesUsada: c.vezesUsada + 1)
          else
            c,
      ],
    );
    await _persistirETentarSincronizar();
  }

  Future<void> adicionarTransacaoRecorrente({
    required DateTime data,
    required TipoLancamento tipo,
    required String categoriaId,
    required String categoriaNome,
    required double valor,
    String? descricao,
    required PeriodoRecorrencia periodo,
    required DateTime dataInicioRecorrencia,
    DateTime? dataTermino,
  }) async {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final inicioSemHora = DateTime(
      dataInicioRecorrencia.year,
      dataInicioRecorrencia.month,
      dataInicioRecorrencia.day,
    );
    final ehHoje = !inicioSemHora.isAfter(hojeSemHora);

    var transacoes = _dados.transacoes;
    var categorias = _dados.categorias;

    if (ehHoje) {
      final novaTransacao = Transacao(
        id: _uuid.v4(),
        data: data,
        tipo: tipo,
        categoriaId: categoriaId,
        categoriaNome: categoriaNome,
        valor: valor,
        descricao: descricao,
      );
      transacoes = [...transacoes, novaTransacao];
      categorias = [
        for (final c in categorias)
          if (c.id == categoriaId)
            c.copyWith(vezesUsada: c.vezesUsada + 1)
          else
            c,
      ];
    }

    final dataRecorrenciaInicial = ehHoje
        ? proximaDataRecorrencia(inicioSemHora, periodo)
        : inicioSemHora;

    final molde = LancamentoRecorrente(
      id: _uuid.v4(),
      tipo: tipo,
      categoriaId: categoriaId,
      categoriaNome: categoriaNome,
      valor: valor,
      descricao: descricao,
      periodo: periodo,
      dataInicio: inicioSemHora,
      dataRecorrencia: dataRecorrenciaInicial,
      dataTermino: dataTermino,
    );

    _dados = _dados.copyWith(
      transacoes: transacoes,
      categorias: categorias,
      recorrentes: [..._dados.recorrentes, molde],
    );
    await _persistirETentarSincronizar();
  }

  Future<Categoria> adicionarCategoria(String nome, TipoLancamento tipo) async {
    final nova = Categoria(id: _uuid.v4(), nome: nome.trim(), tipo: tipo);
    _dados = _dados.copyWith(categorias: [..._dados.categorias, nova]);
    await _persistirETentarSincronizar();
    return nova;
  }

  Future<void> editarTransacao(Transacao atualizada) async {
    _dados = _dados.copyWith(
      transacoes: [
        for (final t in _dados.transacoes)
          if (t.id == atualizada.id) atualizada else t,
      ],
    );
    await _persistirETentarSincronizar();
  }

  Future<void> excluirTransacao(String id, String categoriaId) async {
    _dados = _dados.copyWith(
      transacoes: _dados.transacoes.where((t) => t.id != id).toList(),
      categorias: [
        for (final c in _dados.categorias)
          if (c.id == categoriaId)
            c.copyWith(vezesUsada: c.vezesUsada - 1)
          else
            c,
      ],
    );
    await _persistirETentarSincronizar();
  }

  Future<void> editarRecorrente(LancamentoRecorrente atualizado) async {
    _dados = _dados.copyWith(
      recorrentes: [
        for (final r in _dados.recorrentes)
          if (r.id == atualizado.id) atualizado else r,
      ],
    );
    await _persistirETentarSincronizar();
  }

  Future<void> excluirRecorrente(String id) async {
    _dados = _dados.copyWith(
      recorrentes: _dados.recorrentes.where((r) => r.id != id).toList(),
    );
    await _persistirETentarSincronizar();
  }

  Future<void> editarCategoria(Categoria atualizada) async {
    _dados = _dados.copyWith(
      categorias: [
        for (final c in _dados.categorias)
          if (c.id == atualizada.id) atualizada else c,
      ],
    );
    await _persistirETentarSincronizar();
  }

  Future<void> excluirCategoria(String id) async {
    _dados = _dados.copyWith(
      categorias: _dados.categorias.where((c) => c.id != id).toList(),
    );
    await _persistirETentarSincronizar();
  }

  List<Categoria> categoriasPorTipo(TipoLancamento tipo) {
    final lista = _dados.categorias.where((c) => c.tipo == tipo).toList();
    lista.sort((a, b) {
      final porUso = b.vezesUsada.compareTo(a.vezesUsada);
      if (porUso != 0) return porUso;
      return a.nome.toLowerCase().compareTo(
        b.nome.toLowerCase(),
      ); // desempate alfabético
    });
    return lista;
  }

  // --- Sincronização ---

  Future<String?> escolherPastaSincronizacao() => _sync.escolherPasta();

  Future<String?> pastaSincronizacaoAtual() => _sync.pastaConfigurada();

  Future<void> sincronizarAgora() => _persistirETentarSincronizar();

  Future<bool> exportarParaArquivo() async {
    final ok = await _sync.exportarArquivo(_dados);
    if (ok) {
      _ultimaSincronizacao = DateTime.now();
      notifyListeners();
    }
    return ok;
  }

  Future<bool> importarDeArquivo() async {
    final importado = await _sync.importarArquivo();
    if (importado == null) return false;
    _dados = importado; // substitui completamente os dados atuais
    await _storage.salvar(_dados);
    _ultimaSincronizacao = DateTime.now();
    notifyListeners();
    return true;
  }
}
