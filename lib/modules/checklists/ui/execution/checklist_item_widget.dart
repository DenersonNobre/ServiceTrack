// Widget tátil tri-estado de item de checklist (UC-04.02 / DESIGN.md §4.2).
//
// SRP: renderizar pergunta + 3 botões >= 48dp (Conforme, Não Conforme, N/A)
// e campo de observação expandido em Não Conforme.

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/ui/app_touch_target.dart';
import '../../domain/entities/checklist_answer.dart';

/// Item tátil de execução de checklist em campo (alvos >= 48dp).
final class ChecklistItemWidget extends StatelessWidget {
  /// Cria o widget de item de checklist.
  const ChecklistItemWidget({
    super.key,
    required this.title,
    required this.selectedStatus,
    required this.onStatusChanged,
    this.notes = '',
    this.onNotesChanged,
    this.enabled = true,
  });

  /// Pergunta/verificação técnica.
  final String title;

  /// Status atualmente selecionado (null = não respondido).
  final ChecklistAnswerStatus? selectedStatus;

  /// Callback de mudança de status.
  final void Function(ChecklistAnswerStatus status) onStatusChanged;

  /// Texto atual da observação.
  final String notes;

  /// Callback de alteração de observação.
  final void Function(String value)? onNotesChanged;

  /// Controla se edição está habilitada (false em OS imutável).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final showNotes =
        selectedStatus == ChecklistAnswerStatus.naoConforme || notes.isNotEmpty;
    return Card(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.gray900,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ChoiceButton(
                    key: const Key('checklist-btn-conforme'),
                    label: 'Conforme',
                    selected: selectedStatus == ChecklistAnswerStatus.conforme,
                    activeColor: const Color(0xFF166534),
                    activeBg: const Color(0xFFEBF8F0),
                    onPressed: enabled
                        ? () => onStatusChanged(ChecklistAnswerStatus.conforme)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ChoiceButton(
                    key: const Key('checklist-btn-nao-conforme'),
                    label: 'Não Conf.',
                    selected:
                        selectedStatus == ChecklistAnswerStatus.naoConforme,
                    activeColor: const Color(0xFF991B1B),
                    activeBg: const Color(0xFFFEEFEF),
                    onPressed: enabled
                        ? () =>
                            onStatusChanged(ChecklistAnswerStatus.naoConforme)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ChoiceButton(
                    key: const Key('checklist-btn-nao-aplica'),
                    label: 'N/A',
                    selected: selectedStatus == ChecklistAnswerStatus.naoAplica,
                    activeColor: AppColors.gray700,
                    activeBg: const Color(0xFFF4F4F5),
                    onPressed: enabled
                        ? () => onStatusChanged(ChecklistAnswerStatus.naoAplica)
                        : null,
                  ),
                ),
              ],
            ),
            if (showNotes) ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('checklist-notes-field'),
                initialValue: notes,
                enabled: enabled,
                maxLines: 2,
                onChanged: onNotesChanged,
                decoration: InputDecoration(
                  labelText: 'Observação',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    super.key,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.activeBg,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final Color activeBg;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: kMinTouchTargetSize,
          backgroundColor: selected ? activeBg : AppColors.surfaceCard,
          foregroundColor: selected ? activeColor : AppColors.gray700,
          side: BorderSide(
            color: selected ? activeColor : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
