String formatCurrencyBr(double value) {
  final sign = value < 0 ? '-' : '';
  final cents = (value.abs() * 100).round();
  final whole = cents ~/ 100;
  final fraction = (cents % 100).toString().padLeft(2, '0');
  return '${sign}R\$ ${_formatThousands(whole)},$fraction';
}

String formatPercentBr(double value) {
  final percent = value * 100;
  final sign = percent < 0 ? '-' : '';
  final scaled = (percent.abs() * 100).round();
  final whole = scaled ~/ 100;
  final fraction = (scaled % 100).toString().padLeft(2, '0');
  return '$sign${_formatThousands(whole)},$fraction%';
}

String _formatThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[index]);
  }

  return buffer.toString();
}
