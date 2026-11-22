// Gate arquitetural anti-string-mágica para códigos ERR_* (M-08 / UC-06.01).
//
// SRP: falhar o build/teste caso qualquer literal 'ERR_*' ou "ERR_*" seja
// introduzido em lib/ fora dos catálogos canônicos *_failure_codes.dart.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'M-08: nenhum literal ERR_* fora de *_failure_codes.dart em lib/',
    () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final errLiteralPattern = RegExp(r'''['"]ERR_[A-Z0-9_]+['"]''');
      final violations = <String>[];

      final files = libDir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('_failure_codes.dart'));

      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final codeOnly = lines[i].split('//').first;
          final match = errLiteralPattern.firstMatch(codeOnly);
          if (match != null) {
            final normalizedPath = file.path.replaceAll('\\', '/');
            violations.add('$normalizedPath:${i + 1}: ${match.group(0)}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Use constantes de *_failure_codes.dart em vez de literais ERR_*:\n'
            '${violations.join('\n')}',
      );
    },
  );
}
