// Códigos de falha do módulo de clientes e locais (UC-02.01 / UC-02.02 / UC-06.01).
//
// SRP: concentra os códigos ERR_CLIENTE_* e ERR_LOCAL_* de validação e persistência.
// NÃO valida, NÃO persiste, NÃO toca em UI.
// Pattern: constantes nominais (elimina strings mágicas).
//
// Dependências: nenhuma.

/// Códigos de falha do domínio e repositórios de clientes e locais de atendimento.
abstract final class CustomerFailureCodes {
  /// Falha de persistência SQLite para cliente.
  static const customerPersistence = 'ERR_CLIENTE_PERSISTENCIA';

  /// Nome de cliente vazio ou acima do limite permitido.
  static const invalidCustomerName = 'ERR_CLIENTE_NOME_INVALIDO';

  /// CPF ou CNPJ do cliente inválido.
  static const invalidDocument = 'ERR_CLIENTE_DOCUMENTO_INVALIDO';

  /// WhatsApp do cliente inválido.
  static const invalidWhatsapp = 'ERR_CLIENTE_WHATSAPP_INVALIDO';

  /// E-mail do cliente inválido.
  static const invalidEmail = 'ERR_CLIENTE_EMAIL_INVALIDO';

  /// Identificador de cliente inválido.
  static const invalidCustomerId = 'ERR_CLIENTE_ID_INVALIDO';

  /// Falha de persistência SQLite para local de atendimento.
  static const locationPersistence = 'ERR_LOCAL_PERSISTENCIA';

  /// Rótulo do local vazio ou acima do limite permitido.
  static const invalidLocationLabel = 'ERR_LOCAL_ROTULO_INVALIDO';

  /// CEP do local inválido.
  static const invalidCep = 'ERR_LOCAL_CEP_INVALIDO';

  /// Identificador do local inválido.
  static const invalidLocationId = 'ERR_LOCAL_ID_INVALIDO';

  /// Endereço do local incompleto (sem logradouro ou cidade).
  static const invalidAddress = 'ERR_LOCAL_ENDERECO_INVALIDO';
}
