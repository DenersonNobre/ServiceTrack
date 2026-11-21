// Porta de armazenamento chave-valor seguro (UC-01.01, TASK-02).
//
// SRP: abstrai leitura/escrita do segredo em repouso.
// NÃO conhece credencial, hash ou regra de negócio.
// Pattern: Port do Hexagonal (DIP: domínio não importa infraestrutura).
//
// Dependências: nenhuma.

/// Backend genérico de armazenamento seguro.
abstract class ISecureKeyValue {
  /// Lê o valor de [key] ou `null` quando ausente.
  Future<String?> read(String key);

  /// Grava [value] em [key] (sobrescreve).
  Future<void> write(String key, String value);

  /// Remove [key] quando existir.
  Future<void> delete(String key);

  /// Remove todas as entradas do backend.
  Future<void> deleteAll();
}
