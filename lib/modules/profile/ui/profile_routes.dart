// Rotas e bindings Kortex do módulo de perfil.
//
// SRP: compor a rota escopada do perfil comercial.
// Não implementa regra de negócio nem conhece o shell do app.

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/ui/app_scoped_route.dart';
import '../data/file_technician_profile_repository.dart';
import '../domain/ports/technician_profile_repository_port.dart';
import 'profile/profile_controller.dart';
import 'profile/profile_page.dart';

/// Bindings de navegação do módulo de perfil comercial.
final class ProfileRoutes {
  const ProfileRoutes({required this.profileRepository});

  factory ProfileRoutes.standard() {
    return ProfileRoutes(
      profileRepository: FileTechnicianProfileRepository(
        baseDir: getApplicationSupportDirectory,
      ),
    );
  }

  final ITechnicianProfileRepositoryPort profileRepository;

  /// Tela de edição do perfil comercial.
  Route<void> edit() {
    return appScopedRoute<ProfileController, void>(
      create: (_) => ProfileController(repository: profileRepository),
      builder: (_, _) => const ProfilePage(),
    );
  }
}
