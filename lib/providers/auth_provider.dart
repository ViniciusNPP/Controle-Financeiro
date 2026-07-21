import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import 'finance_provider.dart';

class AuthProvider extends ChangeNotifier {
  bool _autenticado = false;
  String? _erro;
  bool _carregando = false;

  bool get autenticado => _autenticado;
  String? get erro => _erro;
  bool get carregando => _carregando;

  /// Login local: se ainda não existe conta salva nos dados (nem local, nem
  /// importada de outro aparelho), o primeiro email/senha digitado cria a
  /// conta. Se já existe, valida contra ela.
  Future<bool> entrar({
    required String email,
    required String senha,
    required FinanceProvider financeProvider,
  }) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    if (!AuthService.emailValido(email)) {
      _erro = 'Digite um email válido.';
      _carregando = false;
      _autenticado = false;
      notifyListeners();
      return false;
    }
    if (!AuthService.senhaValida(senha)) {
      _erro = 'A senha precisa ter pelo menos 6 caracteres.';
      _carregando = false;
      _autenticado = false;
      notifyListeners();
      return false;
    }

    final conta = financeProvider.dados.conta;
    final hash = AuthService.hashSenha(senha);

    if (conta == null) {
      await financeProvider.definirConta(email.trim(), hash);
      _autenticado = true;
      _erro = null;
    } else if (conta.email.toLowerCase() == email.trim().toLowerCase() && conta.senhaHash == hash) {
      _autenticado = true;
      _erro = null;
    } else {
      _erro = 'Email ou senha incorretos.';
      _autenticado = false;
    }

    _carregando = false;
    notifyListeners();
    return _autenticado;
  }

  void sair() {
    _autenticado = false;
    notifyListeners();
  }
}
