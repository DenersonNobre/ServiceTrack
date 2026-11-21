// Derivação de chave PBKDF2-HMAC-SHA-256 para o cofre local (UC-01.01).
//
// SRP: deriva, serializa (formato versionado v1$...), interpreta e compara
// hashes de credenciais com salt único e custo calibrável.
// NÃO persiste, NÃO conhece PIN/senha como conceito, NÃO loga segredo.
// Pattern: Value Object criptográfico + funções puras.
//
// Decisão (Gate 2.5 INVOKED, PO aprovou): PBKDF2-HMAC-SHA-256 para senha E
// PIN — SHA-256 de 1 iteração é força-brutável para PIN de 4-6 dígitos.
// Formato: `v1$pbkdf2-sha256$<iter>$<saltB64>$<hashB64>`.
//
// Dependências: package:crypto (direta pinada), dart:convert, dart:math,
// dart:typed_data.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Perfil de custo da derivação (iterações por credencial).
final class KdfProfile {
  /// Cria o perfil com [iterations] iterações.
  const KdfProfile({required this.iterations}) : assert(iterations > 0);

  /// Iterações do PBKDF2.
  final int iterations;

  /// Perfil de produção com custo fixo revisável.
  static const standard = KdfProfile(iterations: 210000);

  /// Calibra o custo para o alvo de tempo neste aparelho.
  factory KdfProfile.calibrated({
    Duration target = const Duration(milliseconds: 250),
  }) {
    final iterations = Pbkdf2Sha256.calibrateIterations(target: target);
    return KdfProfile(iterations: iterations);
  }
}

/// PBKDF2 com PRF HMAC-SHA-256 (RFC 8018 §5.2), saída de 32 bytes.
abstract final class Pbkdf2Sha256 {
  /// Comprimento do derivado em bytes.
  static const digestLength = 32;

  /// Tamanho do salt em bytes (≥128 bits, INV-SEC-01).
  static const saltLength = 16;

  /// Deriva a chave de [password] com [salt] e [iterations].
  static List<int> derive({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    int dkLen = digestLength,
  }) {
    final hmac = Hmac(sha256, password);
    final blocks = (dkLen + sha256.blockSize - 1) ~/ sha256.blockSize;
    final output = BytesBuilder();
    for (var block = 1; block <= blocks; block++) {
      final counter = ByteData(4)..setUint32(0, block, Endian.big);
      var previous = hmac.convert([...salt, ...counter.buffer.asUint8List()]);
      var mixed = Uint8List.fromList(previous.bytes);
      for (var round = 1; round < iterations; round++) {
        previous = hmac.convert(previous.bytes);
        final current = previous.bytes;
        for (var i = 0; i < mixed.length; i++) {
          mixed[i] ^= current[i];
        }
      }
      output.add(mixed);
    }
    return output.takeBytes().sublist(0, dkLen);
  }

  /// Estima iterações para atingir [target] neste aparelho.
  static int calibrateIterations({
    required Duration target,
    int minIterations = 20000,
    int maxIterations = 300000,
  }) {
    const probeOps = 2000;
    final probe = List<int>.filled(64, 7);
    final key = List<int>.filled(32, 3);
    final hmac = Hmac(sha256, key);
    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < probeOps; i++) {
      hmac.convert(probe);
    }
    stopwatch.stop();
    final perOpMicros = stopwatch.elapsedMicroseconds / probeOps;
    if (perOpMicros <= 0) {
      return minIterations;
    }
    final estimated = target.inMicroseconds ~/ (2 * perOpMicros);
    return estimated.clamp(minIterations, maxIterations);
  }
}

/// Hash de credencial no formato `v1$pbkdf2-sha256$iter$salt$hash`.
final class CredentialHash {
  const CredentialHash._({
    required this.salt,
    required this.iterations,
    required this.digest,
  });

  /// Salt aleatório usado na derivação.
  final List<int> salt;

  /// Iterações usadas na derivação.
  final int iterations;

  /// Derivado de 32 bytes.
  final List<int> digest;

  /// Cria o hash de [password] com salt CSPRNG único.
  factory CredentialHash.create({
    required List<int> password,
    required int iterations,
    Random? random,
  }) {
    final source = random ?? Random.secure();
    final salt = List<int>.generate(
      Pbkdf2Sha256.saltLength,
      (_) => source.nextInt(256),
    );
    final digest = Pbkdf2Sha256.derive(
      password: password,
      salt: salt,
      iterations: iterations,
    );
    return CredentialHash._(
      salt: salt,
      iterations: iterations,
      digest: digest,
    );
  }

  /// Serializa no formato versionado.
  String encode() {
    final saltB64 = base64.encode(salt);
    final hashB64 = base64.encode(digest);
    return 'v1\$pbkdf2-sha256\$$iterations\$$saltB64\$$hashB64';
  }

  /// Interpreta o formato; lança [FormatException] se corrompido.
  /// Corrupção de disco é falha catastrófica (exceção, não Result).
  factory CredentialHash.parse(String encoded) {
    final parts = encoded.split('\$');
    if (parts.length != 5 || parts[0] != 'v1') {
      throw const FormatException('Formato de hash de credencial inválido.');
    }
    if (parts[1] != 'pbkdf2-sha256') {
      throw const FormatException('Algoritmo de hash não suportado.');
    }
    final iterations = int.tryParse(parts[2]);
    if (iterations == null || iterations <= 0) {
      throw const FormatException('Iterações de hash inválidas.');
    }
    late final List<int> salt;
    late final List<int> digest;
    try {
      salt = base64.decode(parts[3]);
      digest = base64.decode(parts[4]);
    } on FormatException {
      throw const FormatException('Hash de credencial corrompido.');
    }
    if (salt.length != Pbkdf2Sha256.saltLength ||
        digest.length != Pbkdf2Sha256.digestLength) {
      throw const FormatException('Hash de credencial corrompido.');
    }
    return CredentialHash._(
      salt: salt,
      iterations: iterations,
      digest: digest,
    );
  }

  /// Confere [password] contra este hash em tempo constante.
  bool matches(List<int> password) {
    final candidate = Pbkdf2Sha256.derive(
      password: password,
      salt: salt,
      iterations: iterations,
    );
    return constantTimeEquals(candidate, digest);
  }

  /// Redigido de propósito: hash jamais aparece em log (INV-SEC-06).
  @override
  String toString() => 'CredentialHash(redacted)';
}

/// Igualdade em tempo constante sobre bytes (INV-SEC-04).
///
/// Proibido `==`, `Contains` ou `startsWith` em material secreto.
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  var mixed = 0;
  for (var i = 0; i < a.length; i++) {
    mixed |= a[i] ^ b[i];
  }
  return mixed == 0;
}
