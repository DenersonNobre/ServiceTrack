// Gate arquitetural anti-string-mágica para códigos ERR_* (M-08 / UC-06.01/06.04).
//
// SRP: falhar o build/teste caso qualquer literal 'ERR_*' ou "ERR_*" seja
// introduzido em lib/ fora dos catálogos canônicos *_failure_codes.dart.
// A prova negativa garante que o gate não é vacuidade: uma fixture com literal
// novo tem de reprovar.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _errLiteralPattern = RegExp(r'''['"]ERR_[A-Z0-9_]+['"]''');

/// Varre [root] e devolve as violações (`arquivo:linha: literal`) encontradas.
({List<String> violations, int filesScanned}) scanErrLiterals(Directory root) {
  final violations = <String>[];
  var filesScanned = 0;

  final files = root
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('_failure_codes.dart'));

  for (final file in files) {
    filesScanned++;
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final codeOnly = lines[i].split('//').first;
      final match = _errLiteralPattern.firstMatch(codeOnly);
      if (match != null) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        violations.add('$normalizedPath:${i + 1}: ${match.group(0)}');
      }
    }
  }

  return (violations: violations, filesScanned: filesScanned);
}

void main() {
  test('M-08: nenhum literal ERR_* fora de *_failure_codes.dart em lib/', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    final result = scanErrLiterals(libDir);
    expect(
      result.filesScanned,
      greaterThan(0),
      reason: 'O gate deve varrer arquivos; zero arquivos é vacuidade.',
    );
    expect(
      result.violations,
      isEmpty,
      reason:
          'Use constantes de *_failure_codes.dart em vez de literais ERR_*:\n'
          '${result.violations.join('\n')}',
    );
  });

  test(
    'UC-06.04: prova negativa — literal ERR_* em fixture reprova o gate',
    () {
      final fixture = Directory.systemTemp.createTempSync('gate-err-fixture-');
      try {
        File('${fixture.path}/servico_com_literal.dart')
            .writeAsStringSync("const codigo = 'ERR_NOVO_CODIGO';\n");

        final result = scanErrLiterals(fixture);

        expect(result.filesScanned, 1);
        expect(result.violations, hasLength(1));
        expect(result.violations.single, contains('ERR_NOVO_CODIGO'));
      } finally {
        fixture.deleteSync(recursive: true);
      }
    },
  );

  test('UC-06.04: catálogo *_failure_codes.dart é allowlist', () {
    final fixture = Directory.systemTemp.createTempSync('gate-err-catalog-');
    try {
      File('${fixture.path}/exemplo_failure_codes.dart')
          .writeAsStringSync("const codigo = 'ERR_PERMITIDO_NO_CATALOGO';\n");

      final result = scanErrLiterals(fixture);

      expect(result.filesScanned, 0);
      expect(result.violations, isEmpty);
    } finally {
      fixture.deleteSync(recursive: true);
    }
  });
}
