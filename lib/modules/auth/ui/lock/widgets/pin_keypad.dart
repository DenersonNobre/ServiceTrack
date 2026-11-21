// Teclado numérico de PIN (UC-01.03).
//
// SRP: renderiza teclado numérico com alvos táteis >=48dp para entrada de PIN.
// Não valida PIN, não acessa storage, não navega.
//
// Pattern: Widget puro controlado por callbacks.

import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';

/// Teclado numérico grande para desbloqueio por PIN.
final class PinKeypad extends StatelessWidget {
  /// Cria o teclado.
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
  });

  /// Chamado ao tocar um dígito.
  final ValueChanged<String> onDigit;

  /// Chamado ao tocar backspace.
  final VoidCallback onBackspace;

  /// Chamado ao tocar OK/submit.
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['⌫', '0', 'OK'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _KeyButton(
                        label: key,
                        onTap: () => _handle(key),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _handle(String key) {
    if (key == '⌫') return onBackspace();
    if (key == 'OK') return onSubmit();
    onDigit(key);
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOk = label == 'OK';
    final isBack = label == '⌫';
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isOk ? AppColors.primaryAction : AppColors.surfaceCard,
            foregroundColor: isOk ? Colors.white : AppColors.gray900,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isOk ? AppColors.primaryAction : AppColors.border,
              ),
            ),
            padding: const EdgeInsets.all(8),
          ),
          onPressed: onTap,
          child: isBack
              ? const Icon(Icons.backspace_outlined, size: 24)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isOk ? Colors.white : AppColors.gray900,
                  ),
                ),
        ),
      ),
    );
  }
}
