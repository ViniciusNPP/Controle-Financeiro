import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;
  bool _importando = false;
  String? _mensagemImportacao;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final finance = context.watch<FinanceProvider>();
    final temConta = finance.dados.conta != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.savings_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 24),
                Text('Meu Financeiro', style: Theme.of(context).textTheme.displayMedium, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  temConta ? 'Entre com sua conta' : 'Crie sua conta para começar',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', hintText: 'seuemail@exemplo.com'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _senhaController,
                  obscureText: !_senhaVisivel,
                  onSubmitted: (_) => _entrar(finance),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    suffixIcon: IconButton(
                      icon: Icon(_senhaVisivel ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                      onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                    ),
                  ),
                ),
                if (auth.erro != null) ...[
                  const SizedBox(height: 10),
                  Text(auth.erro!, style: const TextStyle(color: AppColors.saida, fontSize: 13)),
                ],
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: auth.carregando ? null : () => _entrar(finance),
                  child: auth.carregando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(temConta ? 'Entrar' : 'Criar conta e entrar'),
                ),
                if (!temConta) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Primeiro acesso: sua conta é criada automaticamente com esse email e senha.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: _importando ? null : () => _importarDeOutroAparelho(finance),
                    child: Text(
                      _importando ? 'Importando...' : 'Já uso o app em outro aparelho? Importar dados',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                if (_mensagemImportacao != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _mensagemImportacao!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _entrar(FinanceProvider finance) async {
    await context.read<AuthProvider>().entrar(
          email: _emailController.text,
          senha: _senhaController.text,
          financeProvider: finance,
        );
  }

  Future<void> _importarDeOutroAparelho(FinanceProvider finance) async {
    setState(() {
      _importando = true;
      _mensagemImportacao = null;
    });

    bool sucesso;
    if (Platform.isAndroid) {
      sucesso = await finance.importarDeArquivo();
    } else {
      final pasta = await finance.escolherPastaSincronizacao();
      sucesso = pasta != null;
      if (sucesso) await finance.iniciar();
    }

    if (!mounted) return;
    setState(() {
      _importando = false;
      _mensagemImportacao = sucesso
          ? 'Dados importados! Use seu email e senha de sempre para entrar.'
          : 'Não consegui importar. Tente novamente.';
    });
  }
}
