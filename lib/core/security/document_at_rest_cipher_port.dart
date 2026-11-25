// Porta de cifragem em repouso para campos sensíveis (D-01/C-01).
//
// SRP: definir o contrato de cifra/decifra para PII persistida localmente.
// NÃO conhece SQLite, Keystore diretamente ou regras de negócio.

import 'package:kortex_lib/kortex_lib.dart';

/// Contrato de proteção em repouso para valores sensíveis antes de persistir.
abstract interface class IDocumentAtRestCipher {
  /// Cifra um valor sensível para armazenamento em repouso.
  Future<IResult<String, ValidationError>> encrypt(String plainText);

  /// Decifra um valor previamente cifrado pelo mesmo contrato.
  Future<IResult<String, ValidationError>> decrypt(String cipherText);
}
