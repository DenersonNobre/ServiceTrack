// Tela de perfil comercial (UC-01.05).
//
// SRP: renderizar edição de perfil comercial e delegar ações ao controller.
// Não valida regra de negócio; não persiste diretamente.
//
// Pattern: IKortexPage + KortexWatch.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/ui/app_touch_target.dart';
import 'profile_controller.dart';

/// Página de edição de perfil comercial.
final class ProfilePage extends IKortexPage<ProfileController> {
  /// Cria a página.
  const ProfilePage({super.key});

  Future<void> _pickImage(BuildContext context, ProfileController controller) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await controller.importLogo(bytes);
  }

  @override
  Widget buildPage(BuildContext context, ProfileController controller) {
    controller.ensureLoaded();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Perfil Comercial'),
      ),
      body: SafeArea(
        child: KortexWatch(
          builder: (context, _) {
            if (controller.loading.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryAction),
              );
            }
            // Subscribe to signals used by the form.
            controller.error.value;
            controller.success.value;
            controller.saving.value;
            controller.logoPath.value;
            controller.commercialName.value;
            controller.whatsapp.value;
            return _ProfileForm(controller: controller, onPickImage: () => _pickImage(context, controller));
          },
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection({required this.logoPath, required this.onPick, required this.onRemove});
  final String? logoPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final path = logoPath;
    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: AppColors.surfaceCard,
          backgroundImage: path != null && File(path).existsSync() ? FileImage(File(path)) : null,
          child: path == null ? const Icon(Icons.storefront, color: AppColors.primaryAction, size: 36) : null,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              key: const Key('profile-pick-logo'),
              style: OutlinedButton.styleFrom(minimumSize: kMinTouchTargetSize),
              onPressed: onPick,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Selecionar logo'),
            ),
            if (path != null)
              TextButton.icon(
                key: const Key('profile-remove-logo'),
                style: TextButton.styleFrom(minimumSize: kMinTouchTargetSize),
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover'),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.controller, required this.onPickImage});
  final ProfileController controller;
  final VoidCallback onPickImage;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final TextEditingController _name;
  late final TextEditingController _whatsapp;
  bool _synced = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.controller.commercialName.value);
    _whatsapp = TextEditingController(text: widget.controller.whatsapp.value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFromController();
  }

  void _syncFromController() {
    final c = widget.controller;
    if (_synced) return;
    if (c.commercialName.value.isNotEmpty || c.whatsapp.value.isNotEmpty) {
      _name.text = c.commercialName.value;
      _whatsapp.text = c.whatsapp.value;
      _synced = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    // sync once when loaded with data
    if (!_synced && (controller.commercialName.value.isNotEmpty || controller.whatsapp.value.isNotEmpty)) {
      _name.text = controller.commercialName.value;
      _whatsapp.text = controller.whatsapp.value;
      _synced = true;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LogoSection(
                logoPath: controller.logoPath.value,
                onPick: widget.onPickImage,
                onRemove: controller.removeLogo,
              ),
              const SizedBox(height: 24),
              TextField(
                key: const Key('profile-name'),
                controller: _name,
                onChanged: (v) => controller.commercialName.value = v,
                decoration: const InputDecoration(
                  labelText: 'Nome comercial',
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  constraints: BoxConstraints(minHeight: 48),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('profile-whatsapp'),
                controller: _whatsapp,
                keyboardType: TextInputType.phone,
                onChanged: (v) => controller.whatsapp.value = v,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp',
                  hintText: '(11) 99999-8888',
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  constraints: BoxConstraints(minHeight: 48),
                  border: OutlineInputBorder(),
                ),
              ),
              if (controller.error.value != null) ...[
                const SizedBox(height: 12),
                Text(controller.error.value!, style: const TextStyle(color: AppColors.error)),
              ],
              if (controller.success.value != null) ...[
                const SizedBox(height: 12),
                Text(controller.success.value!, style: const TextStyle(color: AppColors.primaryAction)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('profile-save'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryAction,
                    foregroundColor: Colors.white,
                    minimumSize: kMinTouchTargetHeight,
                  ),
                  onPressed: controller.saving.value ? null : controller.save,
                  child: controller.saving.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Salvar perfil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
