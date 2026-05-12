/// Form validation utilities
class AppValidator {
  AppValidator._();

  /// Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email wajib diisi';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Format email tidak valid';
    return null;
  }

  /// Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 8) return 'Password minimal 8 karakter';
    return null;
  }

  /// Name validation
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nama wajib diisi';
    if (value.trim().length < 2) return 'Nama minimal 2 karakter';
    if (value.trim().length > 100) return 'Nama maksimal 100 karakter';
    return null;
  }

  /// Required field
  static String? required(String? value, {String field = 'Field'}) {
    if (value == null || value.trim().isEmpty) return '$field wajib diisi';
    return null;
  }

  /// Amount validation (keuangan)
  static String? amount(String? value) {
    if (value == null || value.isEmpty) return 'Jumlah wajib diisi';
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    final num = double.tryParse(cleaned) ?? 0;
    if (num <= 0) return 'Jumlah harus lebih dari 0';
    return null;
  }

  /// OTP validation
  static String? otp(String? value) {
    if (value == null || value.length != 6) return 'OTP harus 6 digit';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'OTP harus berupa angka';
    return null;
  }
}
