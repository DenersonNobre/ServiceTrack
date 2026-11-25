// Widget de exclusão por swipe com confirmação visual padronizada.
//
// SRP: encapsular o comportamento de Dismissible com fundo destrutivo e
// diálogo de confirmação padronizado no Design System.

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Item de lista com swipe para exclusão e confirmação.
class DismissibleTile extends StatelessWidget {
  /// Cria um [DismissibleTile].
  const DismissibleTile({
    required this.itemKey,
    required this.child,
    required this.onDismissed,
    super.key,
    this.onConfirmDismiss,
    this.confirmTitle,
    this.confirmMessage,
    this.background,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  /// Chave única do item para o [Dismissible].
  final Key itemKey;

  /// Conteúdo principal a ser exibido.
  final Widget child;

  /// Ação executada após o dismiss ser confirmado e finalizado.
  final VoidCallback onDismissed;

  /// Callback opcional de confirmação customizada.
  /// Se não fornecido ou retornar `true`, valida com o diálogo se fornecido.
  final Future<bool> Function()? onConfirmDismiss;

  /// Título do diálogo padrão de confirmação.
  final String? confirmTitle;

  /// Mensagem do diálogo padrão de confirmação.
  final String? confirmMessage;

  /// Background customizado ao arrastar.
  final Widget? background;

  /// Raio da borda para o background padrão (padrão: 12dp).
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: itemKey,
      direction: DismissDirection.endToStart,
      background: background ?? _buildDefaultBackground(),
      confirmDismiss: (direction) async {
        if (onConfirmDismiss != null) {
          final customResult = await onConfirmDismiss!();
          if (!customResult) return false;
        }

        if (confirmTitle != null || confirmMessage != null) {
          if (!context.mounted) return false;
          final dialogResult = await _showConfirmDialog(context);
          return dialogResult ?? false;
        }

        return true;
      },
      onDismissed: (_) => onDismissed(),
      child: child,
    );
  }

  Widget _buildDefaultBackground() {
    return Card(
      color: AppColors.error,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
      child: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Excluir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(confirmTitle ?? 'Confirmar exclusão'),
        content: confirmMessage != null ? Text(confirmMessage!) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
