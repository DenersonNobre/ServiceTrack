# Relatório de Auditoria de Release: v0.19.0

## 1. Metadados da Auditoria

| Campo | Informação |
| :--- | :--- |
| **Versão Auditada** | `v0.19.0` (UC-04.08 / EPIC-04 / M-05) |
| **Commit SHA (HEAD auditado)** | `d4b32b77887eb32d81a8e29f30d6614214179e64` |
| **Intervalo auditado** | `5543ee3..d4b32b7` (5 commits) |
| **Data / Hora** | `2026-11-22` (auditoria executada nesta sessão) |
| **Auditor** | QA Subagent (Gate 4, isolamento epistêmico; evidência empírica local) |
| **Veredito Geral** | **APROVADO COM RESSALVAS** |

---

## 2. Evidência Empírica de Execução (Gates Automatizados)

*Comandos executados localmente nesta auditoria; saídas reais capturadas.*

### 2.1 Análise Estática / Lint

```text
Comando: flutter analyze --fatal-infos
Saída: Analyzing service_track...
       No issues found! (ran in 19.8s)
Exit Code: 0
Status: PASS
```

### 2.2 Suíte de Testes Alvo (UC-04.08)

```text
Comando: flutter test test/modules/evidences/domain/digital_signature_test.dart test/modules/work_orders/data/work_order_sqlite_repository_test.dart test/modules/work_orders/domain/work_order_complete_test.dart test/modules/work_orders/domain/work_order_pause_test.dart test/modules/work_orders/ui/work_order_list_controller_test.dart
Resultado: 00:03 +32: All tests passed!
Exit Code: 0
Status: PASS
```

### 2.3 Suíte de Testes Completa

```text
Comando: flutter test
Resultado: 01:28 +171: All tests passed!
Exit Code: 0
Status: PASS
```

### 2.4 Evidência Informada (pós A1-A3, coerente com 2.1-2.3)

```text
flutter analyze --fatal-infos (arquivos tocados após d4b32b7) => No issues found
flutter test test/modules/work_orders/data/work_order_sqlite_repository_test.dart => 10 passed
```

---

## 3. Matriz de Conformidade com a Especificação (`SPEC.md` / ADR-001)

| Invariante / Requisito | Status | Evidência |
| :--- | :---: | :--- |
| **INV-03**: Completude de fechamento (assinatura coletada) | Conforme | `DigitalSignature.tryCreate` valida PNG/nome/doc por política (`lib/modules/evidences/domain/entities/digital_signature.dart:39-182`); UI conclusão cria assinatura canônica e falha tipada (`lib/modules/work_orders/ui/list/work_order_list_page.dart:318-339`); testes domínio/controller/repo passam. |
| **INV-06**: Imutabilidade pós-conclusão | Conforme | Migration v10 aditiva, sem `UPDATE` em `COMPLETED` (`lib/modules/work_orders/data/work_order_migration.dart:65-71`); repo bloqueia insert fabricado/update em `COMPLETED` (`lib/modules/work_orders/data/work_order_sqlite_repository.dart:103-120`); testes INV-SEC-23 passam. |
| **ADR-001 D1**: Contrato canônico único | Conforme | VO canônico em `evidences.domain.entities.DigitalSignature`; `work_orders.domain.value_objects.digital_signature` re-exporta canônico (`lib/modules/work_orders/domain/value_objects/digital_signature.dart:1-4`). |
| **ADR-001 D2 / C-03**: Documento por política, default minimização | Conforme | `requireDocumentByPolicy=false` default; `ERR_ASSINANTE_DOCUMENTO_OBRIGATORIO` quando exigido/ausente. `SignaturePadWidget.requireDocumentByPolicy` oculta campo por default (A1, `lib/modules/evidences/ui/signature/signature_pad_widget.dart:22-33,117-129`). Wiring `requireReceiverDocument` em controller/app/app_entry/UI. Testes C-03 passam. |
| **ADR-001 D4 / C-04**: Sem fabricação de `signedAtUtc` | Conforme | `restore` preserva `signedAtUtc` nulo (`digital_signature.dart:72-108`); repo parseia somente quando presente (`work_order_sqlite_repository.dart:263-273`); teste C-04 passa. |
| **C-01 / D-01**: Documento PII sem proteção em repouso | Mitigado (fail-closed) | Save bloqueia `documentNumber != null` com `ERR_ASSINATURA_DOCUMENTO_PROTECAO_INDISPONIVEL` (`work_order_sqlite_repository.dart:77-86`); teste UC-04.08/C-01 passa. Coluna v10 existe mas não é escrita por este caminho. |
| **C-05**: Limite por bytes decodificados | Conforme | `bytes.length` sobre `Uint8List` decodificado; limite 150KB (`digital_signature.dart:13,110-139`); teste tamanho excedido passa. |
| **C-06/C-07**: Redaction PII/imagem | Conforme | `toString` redigido, sem nome/doc/base64 (`digital_signature.dart:184-188`); sem `toJson/fromJson`; teste C-06/C-07 passa. A3: reidratação corrompida falha `ERR_OS_DADOS_INVALIDOS` sem ecoar PII/payload (`work_order_sqlite_repository_test.dart:274-298`). |
| **C-08**: PNG magic bytes / validação | Conforme | `_hasPngMagic` em create/restore (`digital_signature.dart:15,127-144`); teste C-08 passa. |
| **C-09**: Validar antes de persistir/reidratar | Conforme no slice | Validação em create/restore e fail-closed no repo; render/export PDF/share fora do escopo (EPIC-05/C-11). |
| **C-10**: Preservar INV-SEC-23 em migration/schema | Conforme | Migration v10 apenas `ALTER TABLE ADD COLUMN`; sem UPDATE em COMPLETED; testes de imutabilidade passam. |

### 3.1 Condicionantes Gate 2.5 (C-01..C-12)

| ID | Sev. | Status | Observação |
| :--- | :---: | :---: | :--- |
| C-01 | Alta | Mitigado (fail-closed) | Persistência de `documentNumber` bloqueada até D-01/criptografia em repouso. |
| C-02 | Alta | Aberto (deferido) | `allowBackup`/exclusões de backup dependem de runners nativos (D-01). |
| C-03 | Alta | Atendido | Decisão PO D2 implementada com default minimização; A1 tratado. |
| C-04 | Média | Atendido | Sem fabricação `signedAtUtc` em restore/migration. |
| C-05 | Média | Atendido | Limite por bytes decodificados. |
| C-06 | Média | Atendido | Sem `toJson` PII/imagem; codec de borda explícito `toBase64`; redaction. |
| C-07 | Média | Atendido parcialmente | Testes de redaction presentes; falta gate automatizado de grep/log em CI. |
| C-08 | Média | Atendido | PNG magic bytes + validação create/restore. |
| C-09 | Média | Atendido no slice | Validação antes de persistir/reidratar; export/render fora de escopo. |
| C-10 | Média | Atendido | Migration aditiva; INV-SEC-23 preservada. |
| C-11 | Média | Aberto (deferido) | Política PDF/share/PII depende de EPIC-05. |
| C-12 | Média | Aberto (deferido) | Backup/exportação cifrada depende de D-01/EPIC-07. |

---

## 4. Tabela de Apontamentos por Severidade

### 4.1 Bloqueadores (Blockers — B1..Bn)

*Impedem terminantemente o release. Causam falha em build, violação de invariante, regressão funcional ou brecha de segurança.*

| ID | Descrição do Problema | Impacto | Ação Corretiva Exigida |
| :--- | :--- | :--- | :--- |
| *Nenhum* | — | — | — |

### 4.2 Maiores (Majors — M1..Mn)

*Débitos técnicos relevantes, quebra parcial de contrato não-crítico ou ausência de cobertura em caso de contorno.*

| ID | Descrição do Problema | Impacto | Ação Recomendada |
| :--- | :--- | :--- | :--- |
| **M1** | Ativar `requireReceiverDocument=true` antes de D-01/criptografia em repouso fará `WorkOrderSqliteRepository.save` falhar com `ERR_ASSINATURA_DOCUMENTO_PROTECAO_INDISPONIVEL` ao concluir OS com documento. | Bloqueio operacional da política C-03 quando habilitada; comportamento é fail-closed por design (C-01/D-01). | Antes de habilitar política em EPIC-07/produção, resolver D-01: criptografia em repouso para PII sensível, escrita segura de `signature_document_number`, e testes de migração/restore. |
| **M2** | Condicionantes C-02/C-11/C-12 permanecem abertos (backup/allowBackup, PDF/share, exportação cifrada). | Risco residual de exposição de PII em superfícies de plataforma/exportação fora do slice atual. | Tratar em D-01 (C-02/C-12) e EPIC-05 (C-11) com gate 2.5 específico antes de habilitar backup/export/share. |

### 4.3 Menores / Informativos (Advisory — A1..An)

*Sugestões de melhoria cosmética, nomenclatura ou refatoração estilística.*

| ID | Descrição | Sugestão |
| :--- | :--- | :--- |
| **A1** | Gate 3 A1-A3 tratados em `d4b32b7` (SignaturePadWidget C-03, D-01 documentado, teste A3 reidratação corrompida). | Manter evidência no hand-off/release; sem ação adicional. |
| **A2** | `signature_document_number` existe no schema v10 mas não é populada pelo caminho atual (C-01 fail-closed). | Ao resolver D-01, implementar escrita cifrada/redigida, migração segura e testes de round-trip; não popular antes. |
| **A3** | C-07 tem testes de redaction, mas não há gate automatizado de grep/log para PII em CI. | Considerar gate estático simples (grep/denylist) no pipeline quando CI estiver ativo, sem substituir revisão. |

---

## 5. Parecer Final de Liberação

**Aprovado com ressalvas.** O slice UC-04.08 cumpre o objetivo de unificação canônica de `DigitalSignature` (ADR-001 D1/D2/D4) com evidência empírica verde: `flutter analyze --fatal-infos` sem issues e `flutter test` completo `+171 All tests passed` (exit 0) nesta auditoria. INV-03, INV-06 e INV-SEC-23 permanecem preservadas; C-03/C-04/C-05/C-06/C-07/C-08/C-09/C-10 foram atendidos no slice, com C-01 mitigado por fail-closed devido a D-01. Não há bloqueadores no código do slice. As ressalvas M1/M2 são riscos/residuais já rastreados (D-01/EPIC-05/EPIC-07) e não devem impedir a consolidação do UC-04.08, desde que `requireReceiverDocument` permaneça `false` até a resolução de D-01 e que C-02/C-11/C-12 sejam tratados antes de backup/export/share com PII.