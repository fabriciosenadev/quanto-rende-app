import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/investment_result.dart';
import 'models/investment_type.dart';
import 'services/investment_calculator.dart';

void main() {
  runApp(const QuantoRendeApp());
}

class QuantoRendeApp extends StatelessWidget {
  const QuantoRendeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quanto Rende?',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _calculator = const InvestmentCalculator();
  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _percentFormatter = NumberFormat.percentPattern('pt_BR')..minimumFractionDigits = 2;

  final _initialAmountController = TextEditingController();
  final _monthsController = TextEditingController();
  final _cdiAnnualRateController = TextEditingController(text: '10');
  final _fixedAnnualRateController = TextEditingController(text: '12');
  final _ipcaAnnualRateController = TextEditingController(text: '4');
  final _realAnnualRateController = TextEditingController(text: '6');

  InvestmentType _selectedType = InvestmentType.savings;
  InvestmentResult? _result;

  @override
  void dispose() {
    _initialAmountController.dispose();
    _monthsController.dispose();
    _cdiAnnualRateController.dispose();
    _fixedAnnualRateController.dispose();
    _ipcaAnnualRateController.dispose();
    _realAnnualRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quanto Rende?')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Simule seu investimento',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Informe os dados abaixo para calcular o valor final bruto.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _initialAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Valor inicial investido',
                            prefixText: 'R\$ ',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) => _validateRequiredPositive(value, 'Informe o valor inicial.'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _monthsController,
                          decoration: const InputDecoration(labelText: 'Prazo em meses'),
                          keyboardType: TextInputType.number,
                          validator: (value) => _validateRequiredPositive(value, 'Informe o prazo.'),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<InvestmentType>(
                          value: _selectedType,
                          decoration: const InputDecoration(labelText: 'Tipo de investimento'),
                          items: InvestmentType.values
                              .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
                              .toList(),
                          onChanged: (type) {
                            if (type != null) {
                              setState(() {
                                _selectedType = type;
                                _result = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        ..._rateFields(),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _calculate,
                          icon: const Icon(Icons.calculate_outlined),
                          label: const Text('Calcular'),
                        ),
                        if (_result != null) ...[
                          const SizedBox(height: 24),
                          _ResultCard(
                            result: _result!,
                            currencyFormatter: _currencyFormatter,
                            percentFormatter: _percentFormatter,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _rateFields() {
    Widget rateField(TextEditingController controller, String label) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label, suffixText: '% a.a.'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) => _validateRequiredPositive(value, 'Informe a taxa anual.'),
        ),
      );
    }

    return switch (_selectedType) {
      InvestmentType.savings => const [
          Text('Poupança: rendimento fixo de 0,5% ao mês.'),
        ],
      InvestmentType.cdi => [rateField(_cdiAnnualRateController, 'Percentual anual do CDI')],
      InvestmentType.fixedRate => [rateField(_fixedAnnualRateController, 'Taxa prefixada anual')],
      InvestmentType.ipcaPlus => [
          rateField(_ipcaAnnualRateController, 'IPCA anual estimado'),
          rateField(_realAnnualRateController, 'Taxa real anual'),
        ],
    };
  }

  String? _validateRequiredPositive(String? value, String emptyMessage) {
    if (value == null || value.trim().isEmpty) {
      return emptyMessage;
    }
    final number = _parseNumber(value);
    if (number == null) {
      return 'Informe um número válido.';
    }
    if (number < 0) {
      return 'Não informe valores negativos.';
    }
    return null;
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = _calculator.calculate(
      initialAmount: _parseNumber(_initialAmountController.text)!,
      months: _parseNumber(_monthsController.text)!.round(),
      type: _selectedType,
      cdiAnnualRate: _parseNumber(_cdiAnnualRateController.text) ?? 0,
      fixedAnnualRate: _parseNumber(_fixedAnnualRateController.text) ?? 0,
      ipcaAnnualRate: _parseNumber(_ipcaAnnualRateController.text) ?? 0,
      realAnnualRate: _parseNumber(_realAnnualRateController.text) ?? 0,
    );

    setState(() => _result = result);
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll('.', '').replaceAll(',', '.'));
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.currencyFormatter,
    required this.percentFormatter,
  });

  final InvestmentResult result;
  final NumberFormat currencyFormatter;
  final NumberFormat percentFormatter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resultado', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _ResultLine(label: 'Valor final bruto', value: currencyFormatter.format(result.finalAmount)),
            _ResultLine(label: 'Lucro bruto', value: currencyFormatter.format(result.grossProfit)),
            _ResultLine(label: 'Rentabilidade acumulada', value: percentFormatter.format(result.accumulatedReturn)),
          ],
        ),
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label)),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
