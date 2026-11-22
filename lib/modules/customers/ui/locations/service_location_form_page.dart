// Formulário de local de atendimento (UC-02.02).
//
// SRP: renderizar formulário e delegar ao controller.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/ui/app_touch_target.dart';
import 'service_location_form_controller.dart';

final class ServiceLocationFormPage extends StatefulWidget {
  const ServiceLocationFormPage({super.key, this.onSaved});
  final VoidCallback? onSaved;

  @override
  State<ServiceLocationFormPage> createState() => _ServiceLocationFormPageState();
}

class _ServiceLocationFormPageState extends State<ServiceLocationFormPage> {
  bool _savedHandled = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.readKortex<ServiceLocationFormController>();
    controller.ensureLoaded();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('Local de Atendimento')),
      body: SafeArea(
        child: KortexWatch(
          builder: (context, _) {
            if (controller.saved.value && !_savedHandled) {
              _savedHandled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) widget.onSaved?.call();
              });
            }
            controller.error.value; controller.saving.value; controller.label.value;
            controller.street.value; controller.number.value; controller.neighborhood.value;
            controller.city.value; controller.state.value; controller.cep.value; controller.reference.value;
            return _Form(controller: controller);
          },
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.controller});
  final ServiceLocationFormController controller;
  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController label;
  late final TextEditingController street;
  late final TextEditingController number;
  late final TextEditingController neighborhood;
  late final TextEditingController city;
  late final TextEditingController state;
  late final TextEditingController cep;
  late final TextEditingController reference;
  bool _synced = false;

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    label = TextEditingController(text: c.label.value);
    street = TextEditingController(text: c.street.value);
    number = TextEditingController(text: c.number.value);
    neighborhood = TextEditingController(text: c.neighborhood.value);
    city = TextEditingController(text: c.city.value);
    state = TextEditingController(text: c.state.value);
    cep = TextEditingController(text: c.cep.value);
    reference = TextEditingController(text: c.reference.value);
  }

  @override
  void dispose() {
    for (final c in [label, street, number, neighborhood, city, state, cep, reference]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (!_synced && (c.label.value.isNotEmpty || c.street.value.isNotEmpty)) {
      label.text = c.label.value; street.text = c.street.value; number.text = c.number.value;
      neighborhood.text = c.neighborhood.value; city.text = c.city.value; state.text = c.state.value;
      cep.text = c.cep.value; reference.text = c.reference.value;
      _synced = true;
    }
    InputDecoration dec(String l, {String? hint}) => InputDecoration(
      labelText: l, hintText: hint, filled: true, fillColor: AppColors.surfaceCard,
      constraints: const BoxConstraints(minHeight: 48), border: const OutlineInputBorder(),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(key: const Key('location-label'), controller: label, onChanged: (v) => c.label.value = v, decoration: dec('Rótulo (ex.: Casa)')),
        const SizedBox(height: 12),
        TextField(key: const Key('location-street'), controller: street, onChanged: (v) => c.street.value = v, decoration: dec('Logradouro')),
        const SizedBox(height: 12),
        TextField(key: const Key('location-number'), controller: number, onChanged: (v) => c.number.value = v, decoration: dec('Número')),
        const SizedBox(height: 12),
        TextField(key: const Key('location-neighborhood'), controller: neighborhood, onChanged: (v) => c.neighborhood.value = v, decoration: dec('Bairro')),
        const SizedBox(height: 12),
        TextField(key: const Key('location-city'), controller: city, onChanged: (v) => c.city.value = v, decoration: dec('Cidade')),
        const SizedBox(height: 12),
        TextField(key: const Key('location-state'), controller: state, onChanged: (v) => c.state.value = v, decoration: dec('UF')),
        const SizedBox(height: 12),
        TextField(key: const Key('location-cep'), controller: cep, onChanged: (v) => c.cep.value = v, keyboardType: TextInputType.number, decoration: dec('CEP', hint: '00000-000')),
        const SizedBox(height: 12),
        TextField(key: const Key('location-reference'), controller: reference, onChanged: (v) => c.reference.value = v, decoration: dec('Ponto de referência (opcional)')),
        if (c.error.value != null) ...[const SizedBox(height: 12), Text(c.error.value!, style: const TextStyle(color: AppColors.error))],
        const SizedBox(height: 20),
        SizedBox(height: 52, child: FilledButton(
          key: const Key('location-save'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryAction, foregroundColor: Colors.white, minimumSize: kMinTouchTargetHeight),
          onPressed: c.saving.value ? null : c.save,
          child: c.saving.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Salvar local'),
        )),
      ]),
    );
  }
}
