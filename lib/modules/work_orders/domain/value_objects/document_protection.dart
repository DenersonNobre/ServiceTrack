// Capacidade única de proteção em repouso do documento do recebedor.
//
// SRP: declarar se o SQLite/campo já possui proteção em repouso suficiente
// para persistir `documentNumber` (D-01/C-01). A UI e os consumidores devem
// consultar esta constante antes de coletar/exigir o documento.

/// `true` com D-01/C-01 mitigado: documento cifrado em repouso via
/// `IDocumentAtRestCipher` (AES-GCM, chave no Keystore/Keychain).
/// Consumidores devem falhar fail-closed se o cifrador não estiver disponível.
const bool kDocumentAtRestProtectionAvailable = true;

/// Mensagem canônica da falha de proteção em repouso (evita divergência UI/controller).
const String kDocumentProtectionUnavailableMessage =
    'Documento do recebedor não pode ser coletado/persistido sem proteção em repouso (D-01/C-01).';
