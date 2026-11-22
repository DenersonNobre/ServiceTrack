// Formulário de cliente (UC-02.01).
//
// SRP: renderizar formulário e delegar ao controller.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/ui/app_touch_target.dart';
import 'customer_form_controller.dart';

final class CustomerFormPage extends StatefulWidget {
  const CustomerFormPage({super.key, this.onSaved});
  final VoidCallback? onSaved;

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  bool _savedHandled = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.readKortex<CustomerFormController>();
    controller.ensureLoaded();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('Cliente')),
      body: SafeArea(
        child: KortexWatch(
          builder: (context, _) {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryAction));
            }
            if (controller.saved.value && !_savedHandled) {
              _savedHandled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) widget.onSaved?.call();
              });
            }
            controller.error.value;
            controller.saving.value;
            controller.name.value;
            controller.document.value;
            controller.whatsapp.value;
            controller.email.value;
            controller.notes.value;
            return _Form(controller: controller);
          },
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.controller});
  final CustomerFormController controller;
  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController name;
  late final TextEditingController document;
  late final TextEditingController whatsapp;
  late final TextEditingController email;
  late final TextEditingController notes;
  bool _synced = false;

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    name = TextEditingController(text: c.name.value);
    document = TextEditingController(text: c.document.value);
    whatsapp = TextEditingController(text: c.whatsapp.value);
    email = TextEditingController(text: c.email.value);
    notes = TextEditingController(text: c.notes.value);
  }

  @override
  void dispose() {
    name.dispose();
    document.dispose();
    whatsapp.dispose();
    email.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (!_synced && (c.name.value.isNotEmpty || c.whatsapp.value.isNotEmpty)) {
      name.text = c.name.value; document.text = c.document.value; whatsapp.text = c.whatsapp.value; email.text = c.email.value; notes.text = c.notes.value;
      _synced = true;
    }
    InputDecoration dec(String label, {String? hint}) => InputDecoration(
      labelText: label, hintText: hint, filled: true, fillColor: AppColors.surfaceCard,
      constraints: const BoxConstraints(minHeight: 48), border: const OutlineInputBorder(),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(key: const Key('customer-name'), controller: name, onChanged: (v) => c.name.value = v, decoration: dec('Nome / Razão Social')),
        const SizedBox(height: 12),
        TextField(key: const Key('customer-document'), controller: document, onChanged: (v) => c.document.value = v, decoration: dec('CPF/CNPJ (opcional)')),
        const SizedBox(height: 12),
        TextField(key: const Key('customer-whatsapp'), controller: whatsapp, onChanged: (v) => c.whatsapp.value = v, keyboardType: TextInputType.phone, decoration: dec('WhatsApp', hint: '(11) 99999-8888')),
        const SizedBox(height: 12),
        TextField(key: const Key('customer-email'), controller: email, onChanged: (v) => c.email.value = v, keyboardType: TextInputType.emailAddress, decoration: dec('E-mail (opcional)')),
        const SizedBox(height: 12),
        TextField(key: const Key('customer-notes'), controller: notes, onChanged: (v) => c.notes.value = v, decoration: dec('Observações (opcional)'), maxLines: 3),
        if (c.error.value != null) ...[const SizedBox(height: 12), Text(c.error.value!, style: const TextStyle(color: AppColors.error))],
        const SizedBox(height: 20),
        SizedBox(height: 52, child: FilledButton(
          key: const Key('customer-save'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryAction, foregroundColor: Colors.white, minimumSize: kMinTouchTargetHeight),
          onPressed: c.saving.value ? null : c.save,
          child: c.saving.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Salvar cliente'),
        )),
      ]),
    );
  }
}
