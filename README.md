# Quanto Rende?

Aplicativo Flutter Android simples para simular quanto um valor investido pode render ao longo do tempo.

## Funcionalidades da primeira versão

- Formulário com valor inicial, prazo em meses e tipo de investimento.
- Tipos disponíveis: Poupança, CDI, Prefixado e IPCA+ simplificado.
- Cálculo local sem login, backend, banco de dados, AdMob ou APIs externas.
- Resultado com valor final bruto, lucro bruto e rentabilidade acumulada.
- Validações para campos obrigatórios, números válidos e valores não negativos.

## Regras de cálculo

- Poupança: rendimento fixo de 0,5% ao mês.
- CDI: percentual anual informado convertido para taxa mensal aproximada.
- Prefixado: taxa anual informada convertida para taxa mensal aproximada.
- IPCA+ simplificado: IPCA anual estimado + taxa real anual, convertidos para taxa mensal aproximada.

Fórmula base:

```text
valorFinal = valorInicial * pow(1 + taxaMensal, prazoMeses)
```

## Como executar

1. Instale o Flutter e configure um dispositivo ou emulador Android.
2. Baixe as dependências:

```bash
flutter pub get
```

3. Rode os testes:

```bash
flutter test
```

4. Execute no Android:

```bash
flutter run
```

## Estrutura principal

- `lib/main.dart`: interface do aplicativo e validações do formulário.
- `lib/models/`: tipos e resultado de investimento.
- `lib/services/investment_calculator.dart`: regras de cálculo.
- `test/investment_calculator_test.dart`: testes unitários dos cálculos.
