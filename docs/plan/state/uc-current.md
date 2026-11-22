# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-04.08` (Unificação de DigitalSignature e Migração / M-05)
- **Status**: CONCLUÍDO (G2.5 APROVADO COM CONDICIONANTES, G3 APROVADO COM RESSALVAS, G4 APROVADO COM RESSALVAS — `qa-review-v0.19.0.md`)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-04`
- **Última Atualização**: `2026-11-22`

## Contexto Atual
- **O que foi feito**: VO canônico unificado em `evidences.domain.entities.DigitalSignature` (bytes PNG, `documentNumber?` por política, `signedAtUtc?` sem fabricação, PNG magic bytes, limite por bytes decodificados, toString redigido). `work_orders` VO re-exporta canônico. Migration v10 additiva, sem UPDATE COMPLETED. Repo: restore legado sem fabricação, save fail-closed C-01 se `documentNumber` presente (D-01). UI conclusão usa bytes canônicos; policy `requireReceiverDocument` wired. Gate 3 A1: `SignaturePadWidget` minimização C-03. A3: teste reidratação corrompida fail-closed. A2: D-01 documentado.
- **Gate 2.5 (Segurança)**: Gate 2.5: INVOKED — APROVADO COM CONDICIONANTES (Média, `ses_dfbc73e7affeMHohJlFfenufxo`). C-01/N1: não persistir `documentNumber` em claro (D-01); default minimização. C-03/N2: `documentNumber?` opcional por política/config, default sem coleta. C-10: migration additiva, sem UPDATE em COMPLETED + testes INV-SEC-23. C-04..C-09 obrigatórios no slice. C-02/C-11/C-12 deferidos (D-01/EPIC-05/EPIC-07).
- **Gates 3/4**: Gate 3 APROVADO COM RESSALVAS (Média, `ses_dfba5efb7ffec0ObBpwnLSY0Nx`); A1-A3 tratados. Gate 4 APROVADO COM RESSALVAS (Alta, `ses_dfba01a35ffesmZKHEjmpjHY4A`, `docs/plan/reviews/qa-review-v0.19.0.md`). Full suite: 171 passed, 0 failed.

## [EVIDENCIA]
- Leitura: `docs/architecture/adr-001-assinatura-digital-canonica.md`, `lib/modules/evidences/domain/entities/digital_signature.dart`, `lib/modules/work_orders/domain/value_objects/digital_signature.dart`, `lib/modules/work_orders/data/work_order_sqlite_repository.dart`, `lib/modules/work_orders/data/work_order_migration.dart`.
- Verifica: `flutter analyze --fatal-infos lib/modules/work_orders lib/modules/evidences lib/app test/modules/work_orders test/modules/evidences/domain/digital_signature_test.dart` => `No issues found!`
- Confirma: `flutter test test/modules/work_orders test/modules/evidences/domain test/modules/checklists test/app/adapters/checklist_proof_adapter_test.dart` => `+63 All tests passed`. Inclui C-01/C-03/C-04/C-06/C-07/C-08.

## Próximo passo
1. **E2E device (EPIC-04)**: validar fluxo ponta-a-ponta em device/emulador (template->OS->checklist->conclusão) — pendência de ambiente, não de código.
2. **EPIC-07**: plugar políticas/config (checklist obrigatório, documento recebedor) e tratar C-01/D-01 antes de habilitar persistência de documento.
3. **Consolidação EPIC-04**: README/épico reconciliados (UC-04.01–04.08 concluídos em código/testes; D-05 mitigado). Fechar E2E device e emitir consolidação/laudo final do épico quando validado.