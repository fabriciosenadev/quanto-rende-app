enum InvestmentType {
  savings('Poupança'),
  cdi('CDI'),
  fixedRate('Prefixado'),
  ipcaPlus('IPCA+ simplificado');

  const InvestmentType(this.label);

  final String label;
}
