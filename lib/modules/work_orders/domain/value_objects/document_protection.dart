// Capacidade única de proteção em repouso do documento do recebedor.
//
// SRP: declarar se o SQLite/campo já possui proteção em repouso suficiente
// para persistir `documentNumber` (D-01/C-01). A UI e os consumidores devem
// consultar esta constante antes de coletar/exigir o documento.

/// `false` enquanto D-01/C-01 estiver aberto: o documento não pode ser
/// persistido em claro (INV-SEC-30).
const bool kDocumentAtRestProtectionAvailable = false;
