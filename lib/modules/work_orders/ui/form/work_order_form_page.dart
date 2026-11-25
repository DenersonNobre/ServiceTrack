// Formulário de criação de OS (UC-03.01).
//
// SRP: renderizar formulário e delegar ao controller.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/brlib/brlib.dart';

import '../../../../app/theme/app_colors.dart';
import 'work_order_form_controller.dart';

final class WorkOrderFormPage extends StatefulWidget {
  const WorkOrderFormPage({super.key, this.onSaved});
  final VoidCallback? onSaved;

  @override
  State<WorkOrderFormPage> createState() => _WorkOrderFormPageState();
}

class _WorkOrderFormPageState extends State<WorkOrderFormPage> {
  bool _savedHandled = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.readKortex<WorkOrderFormController>();
    controller.ensureLoaded();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('Nova Ordem de Serviço')),
      body: SafeArea(
        child: KortexWatch(
          builder: (context, _) {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryAction));
            }
            if (controller.saved.value && !_savedHandled) {
              _savedHandled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) widget.onSaved?.call(); });
            }
            controller.error.value;
            controller.saving.value;
            controller.customerId.value;
            controller.description.value;
            controller.estimatedValue.value;
            controller.scheduledAt.value;
            controller.scheduledDate.value;
            controller.scheduledTime.value;
            controller.templates.value;
            controller.checklistTemplateId.value;
            return _Form(controller: controller);
          },
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.controller});
  final WorkOrderFormController controller;
  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController description;
  late final TextEditingController value;
  late final TextEditingController date;
  bool _synced = false;

  @override
  void initState() {
    super.initState();
    description = TextEditingController(text: widget.controller.description.value);
    value = TextEditingController(text: widget.controller.estimatedValue.value);
    date = TextEditingController(text: widget.controller.scheduledDate.value);
  }

  @override
  void dispose() {
    description.dispose();
    value.dispose();
    date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (!_synced && c.description.value.isNotEmpty) {
      description.text = c.description.value;
      value.text = c.estimatedValue.value;
      date.text = c.scheduledDate.value;
      _synced = true;
    }
    InputDecoration dec(String label, {String? hint}) => InputDecoration(
      labelText: label, hintText: hint, filled: true, fillColor: AppColors.surfaceCard,
      constraints: const BoxConstraints(minHeight: 48), border: const OutlineInputBorder(),
    );
    final customers = c.customers.value;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DropdownButtonFormField<String>(
          key: const Key('wo-customer'),
          // ignore: deprecated_member_use
          value: c.customerId.value,
          decoration: dec('Cliente'),
          items: customers.map((cu) => DropdownMenuItem<String>(value: cu.id, child: Text(cu.name.value))).toList(),
          onChanged: (v) => c.customerId.value = v,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          key: const Key('wo-checklist-template'),
          // ignore: deprecated_member_use
          value: c.checklistTemplateId.value,
          decoration: dec('Checklist (opcional)'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Sem checklist')),
            ...c.templates.value.map(
              (t) => DropdownMenuItem<String?>(value: t.id, child: Text(t.title)),
            ),
          ],
          onChanged: (v) => c.checklistTemplateId.value = v,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('wo-description'),
          controller: description,
          onChanged: (v) => c.description.value = v,
          decoration: dec('Descrição do serviço'),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('wo-value'),
          controller: value,
          onChanged: (v) => c.estimatedValue.value = v,
          inputFormatters: [CurrencyInputFormatter()],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: dec('Valor estimado (R\$)', hint: '150,00'),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                key: const Key('wo-date'),
                controller: date,
                onChanged: (v) => c.updateScheduledDate(v),
                inputFormatters: [DateInputFormatter(format: 'dd/MM/yyyy')],
                keyboardType: TextInputType.datetime,
                decoration: dec('Data', hint: 'DD/MM/AAAA'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                key: const Key('wo-time'),
                // ignore: deprecated_member_use
                value: c.scheduledTime.value,
                decoration: dec('Horário'),
                items: WorkOrderFormController.availableTimeSlots
                    .map(
                      (t) => DropdownMenuItem<String>(
                        value: t,
                        child: Text(t),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) c.updateScheduledTime(v);
                },
              ),
            ),
          ],
        ),
        if (c.error.value != null) ...[const SizedBox(height: 12), Text(c.error.value!, style: const TextStyle(color: AppColors.error))],
        const SizedBox(height: 20),
        SizedBox(height: 52, child: FilledButton(
          key: const Key('wo-save'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryAction, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
          onPressed: c.saving.value ? null : c.save,
          child: c.saving.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Criar OS'),
        )),
      ]),
    );
  }
}
