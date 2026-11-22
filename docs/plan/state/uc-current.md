# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-04.05` (Contrato Canônico de Assinatura & Decisão de Domínio)
- **Status**: EM ANDAMENTO (ADR proposta; Gate 2.5 concluído com condicionantes; decisão PO pendente)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-04`
- **Última Atualização**: `2026-11-22`

## Contexto Atual
- **O que foi feito**: Auditoria EPIC-04; criada EPIC-06; proposta de mitigação; ADR-001 rascunhada para unificar `DigitalSignature` (work_orders vs evidences), cobrir PII/LGPD e destravar D-05/M-04/M-05. Gate 2.5 executado.
- **Gate 2.5 (Segurança)**: Gate 2.5: INVOKED — APROVADO COM CONDICIONANTES (Confiança Média, `ses_dfc96c088ffePqylwAxJpMhMTK`). C-01..C-12 abertos (PII/LGPD minimização D2, proteção em repouso/backup D-01/C5, migração sem fabricação, redaction/DTO, PNG/tamanho canônico, INV-SEC-23 em migração, política PDF/share/export). INV-SEC-SIG-01..06 propostas.
- **Gates 3/4**: não aplicável ainda (decisão/ADR, sem implementação de código).

## [EVIDENCIA]
- Leitura: `lib/modules/work_orders/domain/value_objects/digital_signature.dart`, `lib/modules/evidences/domain/entities/digital_signature.dart`, `docs/architecture/SPEC.md` RN-03/INV-03, `docs/plan/epics/epic-04-checklists-evidencias.md` §6, `docs/DEBITOS.md` D-05/D-01.
- Verifica: `flutter test test/modules/checklists test/modules/evidences` => `+19 All tests passed` (baseline módulo, sem mudança de código neste slice).
- Confirma: ADR-001 atualizada com veredito Gate 2.5 e condicionantes C-01..C-12.

## Próximo passo
1. Obter decisão PO sobre D2 (documento obrigatório/opcional; recomendação segurança: opcional por padrão/minimização).
2. Obter aprovação Arch para D1/D3/D4/D5.
3. Após aprovação, iniciar UC-04.06/04.08 com TDD e condicionantes Gate 2.5 embutidos.