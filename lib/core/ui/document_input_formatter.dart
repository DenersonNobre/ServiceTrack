import 'package:flutter/services.dart';
import 'package:kortex_lib/brlib/brlib.dart';

/// [TextInputFormatter] para CPF (11 dígitos) ou CNPJ (14 dígitos).
final class DocumentInputFormatter extends TextInputFormatter {
  DocumentInputFormatter();

  final CpfInputFormatter _cpf = CpfInputFormatter();
  final CnpjInputFormatter _cnpj = CnpjInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    if (digits.length > 11) {
      return _cnpj.formatEditUpdate(oldValue, newValue);
    }
    return _cpf.formatEditUpdate(oldValue, newValue);
  }
}
