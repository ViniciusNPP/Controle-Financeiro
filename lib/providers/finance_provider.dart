import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/categoria.dart';
import '../models/transacao.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

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

  /// Carrega os dados locais e, se houver uma pasta de sincronização
  /// configurada (fluxo automático do desktop), mescla com o que estiver lá.
  Future<void> iniciar() async {
    _dados = await _storage.carregar();

    final daPasta = await _sync.lerDaPasta();
    if (daPasta != null) {
      _dados = _mesclar(_dados, daPasta);
      await _storage.salvar(_dados);
    }

    _carregado = true;
    notifyListeners();
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

    return DadosApp(
      conta: local.conta ?? remoto.conta,
      categorias: categoriasMescladas,
      transacoes: transacoesMescladas,
    );
  }

  Future<void> _persistirETentarSincronizar() async {
    await _storage.salvar(_dados);
    await _sync.escreverNaPasta(_dados);
    _ultimaSincronizacao = DateTime.now();
    notifyListeners();
  }

  Future<void> definirConta(String email, String senhaHash) async {
    _dados = _dados.copyWith(conta: ContaLocal(email: email, senhaHash: senhaHash));
    await _persistirETentarSincronizar();
  }

  Future<void> adicionarTransacao({
    required DateTime data,
    required TipoLancamento tipo,
    required String categoriaId,
    required String categoriaNome,
    required double valor,
  }) async {
    final nova = Transacao(
      id: _uuid.v4(),
      data: data,
      tipo: tipo,
      categoriaId: categoriaId,
      categoriaNome: categoriaNome,
      valor: valor,
    );
    _dados = _dados.copyWith(transacoes: [..._dados.transacoes, nova]);
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

  Future<void> excluirTransacao(String id) async {
    _dados = _dados.copyWith(
      transacoes: _dados.transacoes.where((t) => t.id != id).toList(),
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

  List<Categoria> categoriasPorTipo(TipoLancamento tipo) =>
      _dados.categorias.where((c) => c.tipo == tipo).toList();

  // --- Sincronização ---

  Future<String?> escolherPastaSincronizacao() => _sync.escolherPasta();

  Future<String?> pastaSincronizacaoAtual() => _sync.pastaConfigurada();

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
    _dados = _mesclar(_dados, importado);
    await _storage.salvar(_dados);
    _ultimaSincronizacao = DateTime.now();
    notifyListeners();
    return true;
  }
}
