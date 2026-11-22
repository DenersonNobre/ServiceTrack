import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UC-06.05 - AppEntry não compõe controllers de módulo', () {
    final source = File('lib/app/app_entry.dart').readAsStringSync();

    expect(source, isNot(contains('KortexProvider<')));
    expect(source, isNot(contains('KortexScope(')));
  });
}
