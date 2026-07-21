import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  AuthService._();

  static String hashSenha(String senha) {
    final bytes = utf8.encode(senha);
    return sha256.convert(bytes).toString();
  }

  /// Validação de formato (RFC 5322 simplificada). Como o app não tem
  /// backend, não é possível confirmar se a caixa de email existe de fato
  /// — só que o formato digitado é válido.
  static bool emailValido(String email) {
    final regex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
    );
    return regex.hasMatch(email.trim());
  }

  static bool senhaValida(String senha) => senha.length >= 6;
}
