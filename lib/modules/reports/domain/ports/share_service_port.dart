// Porta desacoplada para compartilhamento de arquivo PDF on-device (UC-05.03).
//
// SRP: Contrato para compartilhamento nativo via Intent (Android) / UIActivityViewController (iOS).
// NÃO importa share_plus no domínio.

import 'package:kortex_lib/kortex_lib.dart';

/// Contrato para serviço nativo de compartilhamento de laudo PDF.
abstract interface class IShareServicePort {
  /// Compartilha o arquivo PDF localizado em [filePath] com o sistema operacional.
  ///
  /// Retorna [Success] caso a ação seja enviada para a folha nativa de compartilhamento,
  /// ou [Failure] com [ValidationError] caso o caminho seja inválido ou o compartilhamento falhe.
  Future<IResult<void, ValidationError>> sharePdfFile({
    required String filePath,
    required String title,
    String? subject,
  });
}
