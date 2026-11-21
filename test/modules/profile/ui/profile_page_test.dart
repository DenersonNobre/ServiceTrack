import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/modules/profile/data/memory_technician_profile_repository.dart';
import 'package:service_track/modules/profile/ui/profile/profile_controller.dart';
import 'package:service_track/modules/profile/ui/profile/profile_page.dart';

void main() {
  testWidgets('UC-01.05 - edita e salva perfil comercial', (tester) async {
    final repo = MemoryTechnicianProfileRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: KortexScope(
          providers: [
            KortexProvider<ProfileController>(
              create: (_) => ProfileController(repository: repo),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: const ProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('profile-name')), 'Rodrigo Serviços');
    await tester.enterText(find.byKey(const Key('profile-whatsapp')), '11999998888');
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(find.text('Perfil atualizado com sucesso.'), findsOneWidget);
    final loaded = await repo.load();
    expect(loaded.getOrNull()!.commercialName.value, 'Rodrigo Serviços');
    expect(loaded.getOrNull()!.whatsapp.digits, '11999998888');
  });
}
