import 'package:intl/intl.dart';

/// Currency formatting utilities
class CurrencyFormatter {
  static final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _compact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  /// Format: Rp 1.000.000
  static String format(double amount) => _fmt.format(amount);

  /// Format compact: Rp 1,0jt
  static String compact(double amount) => _compact.format(amount);

  /// Format dengan tanda +/-
  static String signed(double amount, {bool isIncome = false}) {
    final prefix = isIncome ? '+' : '-';
    return '$prefix${format(amount.abs())}';
  }

  /// Parse dari string ke double
  static double parse(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}
