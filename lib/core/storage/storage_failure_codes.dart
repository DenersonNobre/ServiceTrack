// Catálogo canônico de códigos de falha do módulo de storage/limpeza temporária (UC-08.03).
//
// SRP: concentrar constantes tipadas para falhas de arquivos temporários,
// evitando strings mágicas e garantindo aderência ao gate M-08.

abstract final class StorageFailureCodes {
  static const cleanupFailed = 'ERR_STORAGE_CLEANUP_FAILED';
}
