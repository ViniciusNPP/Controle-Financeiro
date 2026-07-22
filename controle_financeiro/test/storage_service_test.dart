import 'package:controle_financeiro/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DadosApp.fromJson', () {
    test('ignora a estrutura antiga de conta e carrega categorias e transações', () {
      final dados = DadosApp.fromJson({
        'conta': {},
        'categorias': [
          {
            'id': 'cat-1',
            'nome': 'Alimentação',
            'tipo': 'saida',
          }
        ],
        'transacoes': <Map<String, Object>>[],
      });

      expect(dados.categorias, hasLength(1));
      expect(dados.categorias.first.nome, 'Alimentação');
      expect(dados.transacoes, isEmpty);
    });
  });
}
