import 'dart:io';
import 'package:controle_financeiro/services/sync_service.dart';
import 'package:controle_financeiro/widgets/botoes_personalizados.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sidebar.dart';
import 'add_transaction_screen.dart';
import 'categorias_screen.dart';
import 'charts_screen.dart';
import 'historico_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _aba = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>(); //Chave mobile
  final _conteudoKey = GlobalKey(); //Chave desktop

  static const _larguraSidebar = 250.0;
  static const _quebraDesktop = 900.0;

  void _abrirSincronizacao(BuildContext context) {
    final finance = context.read<FinanceProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _SincronizacaoSheet(finance: finance),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telas = [AddTransactionScreen(ativa: _aba == 0,), ChartsScreen(), HistoricoScreen(), CategoriasScreen()];
    final titulos = ['Adicionar lançamento', 'Gráficos', 'Histórico', 'Categorias'];

    final conteudo = IndexedStack(key: _conteudoKey, index: _aba, children: telas);
    final sidebar = AppSidebarContent(
      abaSelecionada: _aba,
      onSelecionar: (i) => setState(() => _aba = i),
      onSincronizar: () => _abrirSincronizacao(context),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _quebraDesktop;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                SizedBox(
                  width: _larguraSidebar,
                  child: sidebar,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: conteudo,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(titulos[_aba]),
            leading: IconButton(
              mouseCursor: SystemMouseCursors.click,
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          drawer: Drawer(
            width: 270,
            backgroundColor: AppColors.sidebarBg,
            child: sidebar,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: conteudo,
            ),
          ),
        );
      },
    );
  }
}

class _SincronizacaoSheet extends StatefulWidget {
  final FinanceProvider finance;
  const _SincronizacaoSheet({required this.finance});

  @override
  State<_SincronizacaoSheet> createState() => _SincronizacaoSheetState();
}

class _SincronizacaoSheetState extends State<_SincronizacaoSheet> {
  bool _carregando = false;
  String? _mensagem;
  String? _pasta;

  @override
  void initState() {
    super.initState();
    widget.finance.pastaSincronizacaoAtual().then((p) {
      if (mounted) setState(() => _pasta = p);
    });
  }

  Future<void> _exportar(Future<bool> Function() acao) async {
    setState(() {
      _carregando = true;
      _mensagem = null;
    });
    final ok = await acao();
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _mensagem = ok ? 'Feito!' : 'Não foi possível concluir.';
    });
  }

  Future<void> _importar() async {
    setState(() {
      _carregando = true;
      _mensagem = null;
    });
    try {
      final ok = await widget.finance.importarDeArquivo();
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _mensagem = ok ? 'Dados importados com sucesso!' : null;
      });
    } on FormatoInvalidoException catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Não foi possível importar'),
          content: Text(e.mensagem),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Entendi')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ultimaSinc = widget.finance.ultimaSincronizacao;
    final backgroundColor = Color(0xFF3e3b79);
    final foregroundColor = Color(0xFFffffff);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sincronização', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              ultimaSinc != null
                  ? 'Última sincronização: ${ultimaSinc.hour.toString().padLeft(2, '0')}:${ultimaSinc.minute.toString().padLeft(2, '0')}'
                  : 'Ainda não sincronizado nesta sessão',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            // Exportar/Importar manual — disponível em qualquer plataforma
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: const Text('Exportar dados'),
                style: estiloBotao(corBackGround: backgroundColor),
                onPressed: _carregando ? null : () => _exportar(widget.finance.exportarParaArquivo),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Importar dados'),
                style: estiloBotao(corBackGround: foregroundColor, corForeGround: backgroundColor, isSide: true),
                onPressed: _carregando ? null : _importar,
              ),
            ),
            const SizedBox(height: 16),

            // Sincronização automática por pasta — só faz sentido no desktop
            if (!Platform.isAndroid) ...[
              const Divider(),
              const SizedBox(height: 10),
              Text(_pasta ?? 'Nenhuma pasta escolhida ainda', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  style: estiloBotao(corBackGround: backgroundColor),
                  label: Text(_pasta == null ? 'Escolher pasta' : 'Trocar pasta'),
                  onPressed: _carregando
                      ? null
                      : () async {
                          setState(() => _carregando = true);
                          final p = await widget.finance.escolherPastaSincronizacao();
                          await widget.finance.iniciar();
                          if (!mounted) return;
                          setState(() {
                            _pasta = p;
                            _carregando = false;
                          });
                        },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'No computador, a sincronização com a pasta escolhida acontece automaticamente a cada alteração.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else ...[
              Text(
                'No Android, a sincronização é manual: exporte pra salvar na pasta do Drive/OneDrive, e importe pra trazer o que foi feito no outro aparelho.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (_mensagem != null) ...[
              const SizedBox(height: 12),
              Text(_mensagem!, style: const TextStyle(color: AppColors.entrada, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
