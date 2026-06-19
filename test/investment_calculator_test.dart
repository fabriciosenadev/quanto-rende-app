import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_rende_app/models/investment_type.dart';
import 'package:quanto_rende_app/services/investment_calculator.dart';

void main() {
  const calculator = InvestmentCalculator();

  test('calcula poupança com 0,5% ao mês', () {
    final result = calculator.calculate(
      initialAmount: 1000,
      months: 12,
      type: InvestmentType.savings,
    );

    expect(result.finalAmount, closeTo(1061.68, 0.01));
    expect(result.grossProfit, closeTo(61.68, 0.01));
    expect(result.accumulatedReturn, closeTo(0.06168, 0.0001));
  });

  test('converte taxa anual prefixada para taxa mensal aproximada', () {
    final monthlyRate = calculator.monthlyRateFor(
      type: InvestmentType.fixedRate,
      fixedAnnualRate: 12,
    );

    expect(monthlyRate, closeTo(0.009489, 0.000001));
  });

  test('soma IPCA e taxa real antes da conversão mensal simplificada', () {
    final monthlyRate = calculator.monthlyRateFor(
      type: InvestmentType.ipcaPlus,
      ipcaAnnualRate: 4,
      realAnnualRate: 6,
    );

    expect(monthlyRate, closeTo(0.007974, 0.000001));
  });

  test('rejeita valores negativos', () {
    expect(
      () => calculator.calculate(
        initialAmount: -1,
        months: 12,
        type: InvestmentType.savings,
      ),
      throwsArgumentError,
    );
  });
}
