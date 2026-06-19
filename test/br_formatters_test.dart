import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_rende_app/services/br_formatters.dart';

void main() {
  test('formata valores monetários em reais sem depender de pacote externo', () {
    expect(formatCurrencyBr(1234.5), 'R\$ 1.234,50');
    expect(formatCurrencyBr(0), 'R\$ 0,00');
  });

  test('formata rentabilidade acumulada em percentual brasileiro', () {
    expect(formatPercentBr(0.1234), '12,34%');
    expect(formatPercentBr(1), '100,00%');
  });
}
