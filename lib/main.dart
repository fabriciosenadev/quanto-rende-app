import 'package:flutter/material.dart';

import 'models/investment_result.dart';
import 'models/investment_type.dart';
import 'services/br_formatters.dart';
import 'services/investment_calculator.dart';

void main() {
  runApp(const QuantoRendeApp());
}

class QuantoRendeApp extends StatelessWidget {
  const QuantoRendeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF0F766E);

    return MaterialApp(
      title: 'Quanto Rende?',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF102A43),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE5EAF0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD9E2EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: seedColor, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFB42318)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380 ? 12.0 : 16.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Quanto Rende?')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HeroHeader(),
                  const SizedBox(height: 16),
                  _FormCard(
                    formKey: _formKey,
                    initialAmountController: _initialAmountController,
                    monthsController: _monthsController,
                    selectedType: _selectedType,
                    rateFields: _rateFields(),
                    onTypeChanged: (type) {
                      if (type == null) {
                        return;
                      }
                      setState(() {
                        _selectedType = type;
                        _result = null;
                      });
                    },
                    onCalculate: _calculate,
                    validateAmount: (value) => _validateRequiredPositive(
                      value,
                      'Informe o valor inicial para calcular.',
                    ),
                    validateMonths: _validateRequiredPositiveInteger,
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _result == null
                        ? const _EmptyResultCard()
                        : _ResultCard(result: _result!),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _rateFields() {
    Widget rateField({
      required TextEditingController controller,
      required String label,
      required String helper,
    }) {
      return TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          suffixText: '% a.a.',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) => _validateRequiredPositive(
          value,
          'Informe a taxa anual para este investimento.',
        ),
      );
    }

    return switch (_selectedType) {
      InvestmentType.savings => const [
          _InfoBanner(
            text: 'Poupança usa rendimento fixo de 0,5% ao mês nesta versão.',
          ),
        ],
      InvestmentType.cdi => [
          rateField(
            controller: _cdiAnnualRateController,
            label: 'Percentual anual do CDI',
            helper: 'Exemplo: 10 para 10% ao ano.',
          ),
        ],
      InvestmentType.fixedRate => [
          rateField(
            controller: _fixedAnnualRateController,
            label: 'Taxa prefixada anual',
            helper: 'Informe a taxa bruta anual combinada.',
          ),
        ],
      InvestmentType.ipcaPlus => [
          rateField(
            controller: _ipcaAnnualRateController,
            label: 'IPCA anual estimado',
            helper: 'Estimativa anual de inflação.',
          ),
          const SizedBox(height: 12),
          rateField(
            controller: _realAnnualRateController,
            label: 'Taxa real anual',
            helper: 'Taxa adicional acima do IPCA.',
          ),
        ],
    };
  }

  String? _validateRequiredPositive(String? value, String emptyMessage) {
    if (value == null || value.trim().isEmpty) {
      return emptyMessage;
    }
    final number = _parseDecimal(value);
    if (number == null) {
      return 'Use apenas números. Exemplo: 1000,00.';
    }
    if (number < 0) {
      return 'Digite um valor igual ou maior que zero.';
    }
    return null;
  }

  String? _validateRequiredPositiveInteger(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o prazo em meses.';
    }
    final number = int.tryParse(value.trim());
    if (number == null) {
      return 'Digite um número inteiro de meses. Exemplo: 12.';
    }
    if (number < 0) {
      return 'Digite um prazo igual ou maior que zero.';
    }
    return null;
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final result = _calculator.calculate(
      initialAmount: _parseDecimal(_initialAmountController.text)!,
      months: int.parse(_monthsController.text.trim()),
      type: _selectedType,
      cdiAnnualRate: _parseDecimal(_cdiAnnualRateController.text) ?? 0,
      fixedAnnualRate: _parseDecimal(_fixedAnnualRateController.text) ?? 0,
      ipcaAnnualRate: _parseDecimal(_ipcaAnnualRateController.text) ?? 0,
      realAnnualRate: _parseDecimal(_realAnnualRateController.text) ?? 0,
    );

    setState(() => _result = result);
  }

  double? _parseDecimal(String value) {
    final trimmed = value.trim();
    final hasComma = trimmed.contains(',');
    final hasDot = trimmed.contains('.');

    final normalized = hasComma && hasDot
        ? trimmed.replaceAll('.', '').replaceAll(',', '.')
        : trimmed.replaceAll(',', '.');

    return double.tryParse(normalized);
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.savings_outlined, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(
            'Simule seus rendimentos com clareza',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Preencha os dados do investimento e veja uma estimativa bruta em poucos segundos.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.88),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.formKey,
    required this.initialAmountController,
    required this.monthsController,
    required this.selectedType,
    required this.rateFields,
    required this.onTypeChanged,
    required this.onCalculate,
    required this.validateAmount,
    required this.validateMonths,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController initialAmountController;
  final TextEditingController monthsController;
  final InvestmentType selectedType;
  final List<Widget> rateFields;
  final ValueChanged<InvestmentType?> onTypeChanged;
  final VoidCallback onCalculate;
  final String? Function(String?) validateAmount;
  final String? Function(String?) validateMonths;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(
              icon: Icons.edit_note_outlined,
              title: 'Dados da simulação',
              subtitle: 'Informe valores brutos. Nenhum dado sai do seu aparelho.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: initialAmountController,
              decoration: const InputDecoration(
                labelText: 'Valor inicial investido',
                hintText: 'Exemplo: 1.000,00',
                prefixText: 'R\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: validateAmount,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: monthsController,
              decoration: const InputDecoration(
                labelText: 'Prazo em meses',
                hintText: 'Exemplo: 12',
                suffixText: 'meses',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: validateMonths,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<InvestmentType>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo de investimento',
                helperText: 'Escolha uma opção para ajustar os campos de taxa.',
              ),
              items: InvestmentType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: onTypeChanged,
            ),
            const SizedBox(height: 14),
            ...rateFields,
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: onCalculate,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Calcular rendimento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final InvestmentResult result;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      key: const ValueKey('result-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            icon: Icons.trending_up_outlined,
            title: 'Resultado estimado',
            subtitle: 'Valores brutos, sem impostos ou taxas operacionais.',
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFCF6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Valor final bruto',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF246B49),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatCurrencyBr(result.finalAmount),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: const Color(0xFF0B4F34),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ResultLine(
            label: 'Lucro bruto',
            value: formatCurrencyBr(result.grossProfit),
          ),
          const Divider(height: 24),
          _ResultLine(
            label: 'Rentabilidade acumulada',
            value: formatPercentBr(result.accumulatedReturn),
          ),
        ],
      ),
    );
  }
}

class _EmptyResultCard extends StatelessWidget {
  const _EmptyResultCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      key: const ValueKey('empty-result-card'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.insights_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu resultado aparecerá aqui',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Depois do cálculo, você verá valor final, lucro e rentabilidade acumulada.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF62748E),
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF62748E),
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF0369A1), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF075985),
                    height: 1.35,
                  ),
            ),
          ),
        ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF52606D),
                ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}
