import 'dart:math';

import '../models/investment_result.dart';
import '../models/investment_type.dart';

class InvestmentCalculator {
  const InvestmentCalculator();

  InvestmentResult calculate({
    required double initialAmount,
    required int months,
    required InvestmentType type,
    double cdiAnnualRate = 0,
    double fixedAnnualRate = 0,
    double ipcaAnnualRate = 0,
    double realAnnualRate = 0,
  }) {
    if (initialAmount < 0) {
      throw ArgumentError.value(initialAmount, 'initialAmount', 'Não pode ser negativo.');
    }
    if (months < 0) {
      throw ArgumentError.value(months, 'months', 'Não pode ser negativo.');
    }

    final monthlyRate = monthlyRateFor(
      type: type,
      cdiAnnualRate: cdiAnnualRate,
      fixedAnnualRate: fixedAnnualRate,
      ipcaAnnualRate: ipcaAnnualRate,
      realAnnualRate: realAnnualRate,
    );
    final finalAmount = initialAmount * pow(1 + monthlyRate, months).toDouble();
    final grossProfit = finalAmount - initialAmount;
    final accumulatedReturn = initialAmount == 0 ? 0 : grossProfit / initialAmount;

    return InvestmentResult(
      finalAmount: finalAmount,
      grossProfit: grossProfit,
      accumulatedReturn: accumulatedReturn,
    );
  }

  double monthlyRateFor({
    required InvestmentType type,
    double cdiAnnualRate = 0,
    double fixedAnnualRate = 0,
    double ipcaAnnualRate = 0,
    double realAnnualRate = 0,
  }) {
    return switch (type) {
      InvestmentType.savings => 0.005,
      InvestmentType.cdi => _annualPercentageToMonthlyRate(cdiAnnualRate),
      InvestmentType.fixedRate => _annualPercentageToMonthlyRate(fixedAnnualRate),
      InvestmentType.ipcaPlus => _annualPercentageToMonthlyRate(ipcaAnnualRate + realAnnualRate),
    };
  }

  double _annualPercentageToMonthlyRate(double annualPercentage) {
    if (annualPercentage < 0) {
      throw ArgumentError.value(annualPercentage, 'annualPercentage', 'Não pode ser negativo.');
    }
    return pow(1 + (annualPercentage / 100), 1 / 12).toDouble() - 1;
  }
}
