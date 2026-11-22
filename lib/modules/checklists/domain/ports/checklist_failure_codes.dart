// Códigos de falha do módulo de checklists (UC-04.01 / UC-04.02 / UC-06.01).
//
// SRP: concentra os códigos ERR_CHECKLIST_* e ERR_OS_IMUTAVEL do módulo.
// NÃO valida, NÃO persiste, NÃO toca em UI.
// Pattern: constantes nominais (elimina strings mágicas).
//
// Dependências: nenhuma.

/// Códigos de falha do domínio, repositórios e execução de checklists.
abstract final class ChecklistFailureCodes {
  /// Falha de persistência SQLite de template ou resposta de checklist.
  static const persistence = 'ERR_CHECKLIST_PERSISTENCIA';

  /// Tentativa de alterar resposta de checklist em OS concluída/imutável (INV-06).
  static const workOrderImmutable = 'ERR_OS_IMUTAVEL';

  /// Resposta de checklist com identificador de OS ou item inválido.
  static const invalidAnswer = 'ERR_CHECKLIST_RESPOSTA_INVALIDA';

  /// Observação da resposta excede o limite de caracteres permitido.
  static const notesTooLong = 'ERR_CHECKLIST_OBSERVACAO_LONGA';

  /// Checklist possui itens obrigatórios sem resposta (INV-03).
  static const incomplete = 'ERR_CHECKLIST_INCOMPLETO';

  /// Identificador de item de checklist inválido.
  static const invalidItemId = 'ERR_CHECKLIST_ITEM_ID_INVALIDO';

  /// Título de item de checklist vazio ou inválido.
  static const invalidItemTitle = 'ERR_CHECKLIST_ITEM_TITULO_INVALIDO';

  /// Ordem de item de checklist negativa ou inválida.
  static const invalidItemOrder = 'ERR_CHECKLIST_ITEM_ORDEM_INVALIDA';

  /// Identificador de template de checklist inválido.
  static const invalidTemplateId = 'ERR_CHECKLIST_ID_INVALIDO';

  /// Título de template de checklist vazio ou inválido.
  static const invalidTemplateTitle = 'ERR_CHECKLIST_TITULO_INVALIDO';

  /// Template de checklist sem nenhum item cadastrado.
  static const emptyItems = 'ERR_CHECKLIST_SEM_ITENS';

  /// Template de checklist contém itens com identificador duplicado.
  static const duplicateItemId = 'ERR_CHECKLIST_ITEM_ID_DUPLICADO';

  /// Política exige template de checklist vinculado à OS.
  static const templateRequired = 'ERR_CHECKLIST_TEMPLATE_OBRIGATORIO';

  /// Template de checklist não encontrado no repositório.
  static const notFound = 'ERR_CHECKLIST_NAO_ENCONTRADO';
}
