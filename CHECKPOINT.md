# CHECKPOINT — ServiceTrack (Mobile Standalone)

> Protocolo de Continuidade Canônico (Budget: <= 60 linhas).
> Ponteiro da verdade viva; sem duplicação de backlog ou código.

## Contexto
App Flutter 100% standalone para técnicos autônomos com kortex, kortex_lib (pub.dev), SQLite local, biometria/PIN e geração de laudos em PDF no aparelho.

## Estado Real (Verificado em 2026-11-25)
- **Git local**: `main`; HEAD `0f34808` (checagem local; não confirma CI). Árvore com alterações locais não commitadas desta fatia (EPIC-05 integração).
- **Arquitetura & Shell**: `AppServices` composition root puro de infraestrutura/hardware; rotas em `lib/app/routes/app_pages.dart` com bindings por módulo (`*Routes.fromDatabase`).
- **Evolução Recente Concluída**:
  - `Settings`: persistência SQLite com `ConflictAlgorithm.replace`; jornada (`schedule_day_start/end/slot_interval`).
  - `Formulários & Máscaras`: `kortex_lib/brlib` em clientes (CPF/CNPJ, WhatsApp), locais (CEP) e OS (moeda R$, data dd/MM/yyyy, horários 30 min).
  - `Agenda (Schedule)`: calendário mensal 2D + agenda diária com timeline/ocupação e navegação para detalhe/novo agendamento.
- **EPIC-04 E2E (device M2010J19CG, Android 10, 2026-11-25)**: **verde** (`01:52 +1: All tests passed`) — onboarding→cliente→OS→check-in IN_PROGRESS→checklist 3/3 conforme→conclusão COMPLETED. Fixes: nav drawer keys, `esperarConforme` wall-clock, `INSERT OR REPLACE` (SQLite 3.22/Android 10), `AlertDialog` content com `SizedBox(width: double.maxFinite)`.
- **EPIC-05 (2026-11-25)**: concluído em evidência local/device. Preview/share/cache/histórico dedicados, `ReportDataAssembler`, códigos de falha padronizados, asserções de conteúdo do PDF e INV-05 <2s validado no M2010J19CG (Android 10, 3/3 on-device). Ver [status](docs/plan/epics/epic-05-laudo-pdf-share.md).
- **D-01/C-01 (parcial, 2026-11-25)**: `documentNumber` protegido em repouso por cifragem de campo AES-GCM 256 (`IDocumentAtRestCipher` + `AesGcmDocumentAtRestCipher`, chave Keystore/Keychain via `flutter_secure_storage`); `WorkOrderSqliteRepository` cifra/decifra `signature_document_number` (`enc:v1:`), fail-closed sem cifrador; `kDocumentAtRestProtectionAvailable=true`. Residual: LGPD base legal/finalidade/retenção, full-db/sqlcipher, iOS, validação Keystore por fabricante.
- **EPIC-08 (proposto)**: `docs/plan/epics/epic-08-hardening-residual-backup-compliance.md` criado; README/DAG atualizados.
- **Suíte & Qualidade (2026-11-25, evidência local)**: `flutter analyze --fatal-infos` limpo (0 issues). `flutter test` completo **314/314 passed**.
- **Travas Vivas & Governança**: claim ativo `OPS-D01-C01-EPIC08` (coder-agent) para commit/push final; push autorizado pelo PO, acompanhar CI até verde.

## Próximo Passo Acionável
1. Commit atômico D-01+C-01 técnico + EPIC-08 backlog + release claim.
2. Push com autorização já concedida pelo PO + acompanhar CI até verde.
3. Priorização PO do EPIC-08 (UC-08.01..04) e residual LGPD formal C-01.
