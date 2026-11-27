/// Códigos de falha tipados do serviço de Backup e Restauração Segura (UC-08.02, RF-13).
abstract final class BackupFailureCodes {
  /// Senha fraca ou com tamanho inferior a 6 caracteres.
  static const weakPassword = 'ERR_BACKUP_SENHA_FRACA';

  /// Senha incorreta ao tentar decifrar o backup (fail-closed).
  static const invalidPassword = 'ERR_BACKUP_SENHA_INVALIDA';

  /// Dados cifrados corrompidos ou com checksum inválido.
  static const corruptedData = 'ERR_BACKUP_DADOS_CORROMPIDOS';

  /// Versão do schema do backup incompatível com o app atual.
  static const incompatibleSchema = 'ERR_BACKUP_SCHEMA_INCOMPATIVEL';

  /// Falha na leitura ou escrita no banco de dados SQLite.
  static const databaseError = 'ERR_BACKUP_ERRO_BANCO';

  /// Falha de I/O de arquivo ou compartilhamento do sistema operacional.
  static const ioError = 'ERR_BACKUP_ERRO_IO';
}
