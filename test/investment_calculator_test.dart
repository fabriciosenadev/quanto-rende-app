import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quanto_rende_app/models/investment_type.dart';
import 'package:quanto_rende_app/services/investment_calculator.dart';

void main() {
  const calculator = InvestmentCalculator();

  group('InvestmentCalculator.calculate', () {
    test('calcula poupança com rendimento fixo de 0,5% ao mês', () {
      final result = calculator.calculate(
        initialAmount: 1000,
        months: 12,
        type: InvestmentType.savings,
      );

      final expectedFinalAmount = 1000 * pow(1.005, 12);

      expect(result.finalAmount, closeTo(expectedFinalAmount, 0.000001));
      expect(result.grossProfit, closeTo(expectedFinalAmount - 1000, 0.000001));
      expect(result.accumulatedReturn, closeTo((expectedFinalAmount - 1000) / 1000, 0.000001));
    });

    test('calcula CDI convertendo a taxa anual informada para taxa mensal', () {
      final result = calculator.calculate(
        initialAmount: 2500,
        months: 18,
        type: InvestmentType.cdi,
        cdiAnnualRate: 10,
      );

      final monthlyRate = pow(1.10, 1 / 12).toDouble() - 1;
      final expectedFinalAmount = 2500 * pow(1 + monthlyRate, 18);

      expect(result.finalAmount, closeTo(expectedFinalAmount, 0.000001));
      expect(result.grossProfit, closeTo(expectedFinalAmount - 2500, 0.000001));
    });

    test('calcula prefixado convertendo a taxa anual para taxa mensal', () {
      final result = calculator.calculate(
        initialAmount: 5000,
        months: 24,
        type: InvestmentType.fixedRate,
        fixedAnnualRate: 12,
      );

      final monthlyRate = pow(1.12, 1 / 12).toDouble() - 1;
      final expectedFinalAmount = 5000 * pow(1 + monthlyRate, 24);

      expect(result.finalAmount, closeTo(expectedFinalAmount, 0.000001));
      expect(result.accumulatedReturn, closeTo((expectedFinalAmount - 5000) / 5000, 0.000001));
    });

    test('calcula IPCA+ somando IPCA anual e taxa real anual de forma simplificada', () {
      final result = calculator.calculate(
        initialAmount: 3000,
        months: 36,
        type: InvestmentType.ipcaPlus,
        ipcaAnnualRate: 4,
        realAnnualRate: 6,
      );

      final monthlyRate = pow(1.10, 1 / 12).toDouble() - 1;
      final expectedFinalAmount = 3000 * pow(1 + monthlyRate, 36);

      expect(result.finalAmount, closeTo(expectedFinalAmount, 0.000001));
      expect(result.grossProfit, closeTo(expectedFinalAmount - 3000, 0.000001));
    });

    test('mantém valor inicial quando o prazo é zero', () {
      final result = calculator.calculate(
        initialAmount: 1500,
        months: 0,
        type: InvestmentType.savings,
      );

      expect(result.finalAmount, 1500);
      expect(result.grossProfit, 0);
      expect(result.accumulatedReturn, 0);
    });

    test('retorna rentabilidade zero quando o valor inicial é zero', () {
      final result = calculator.calculate(
        initialAmount: 0,
        months: 12,
        type: InvestmentType.fixedRate,
        fixedAnnualRate: 12,
      );

      expect(result.finalAmount, 0);
      expect(result.grossProfit, 0);
      expect(result.accumulatedReturn, 0);
    });

    test('rejeita valor inicial negativo', () {
      expect(
        () => calculator.calculate(
          initialAmount: -1,
          months: 12,
          type: InvestmentType.savings,
        ),
        throwsArgumentError,
      );
    });

    test('rejeita prazo negativo', () {
      expect(
        () => calculator.calculate(
          initialAmount: 1000,
          months: -1,
          type: InvestmentType.savings,
        ),
        throwsArgumentError,
      );
    });

    test('rejeita taxa anual negativa', () {
      expect(
        () => calculator.calculate(
          initialAmount: 1000,
          months: 12,
          type: InvestmentType.cdi,
          cdiAnnualRate: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('InvestmentCalculator.monthlyRateFor', () {
    test('retorna 0,5% ao mês para poupança', () {
      expect(
        calculator.monthlyRateFor(type: InvestmentType.savings),
        closeTo(0.005, 0.000001),
      );
    });

    test('converte taxa anual prefixada para taxa mensal aproximada', () {
      final monthlyRate = calculator.monthlyRateFor(
        type: InvestmentType.fixedRate,
        fixedAnnualRate: 12,
      );

      expect(monthlyRate, closeTo(pow(1.12, 1 / 12).toDouble() - 1, 0.000001));
    });

    test('soma IPCA e taxa real antes da conversão mensal simplificada', () {
      final monthlyRate = calculator.monthlyRateFor(
        type: InvestmentType.ipcaPlus,
        ipcaAnnualRate: 4,
        realAnnualRate: 6,
      );

      expect(monthlyRate, closeTo(pow(1.10, 1 / 12).toDouble() - 1, 0.000001));
    });
  });
}
