# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-04.05` (Contrato Canônico de Assinatura & Decisão de Domínio)
- **Status**: EM ANDAMENTO (ADR proposta; Gate 2.5 pendente)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-04`
- **Última Atualização**: `2026-11-22`

## Contexto Atual
- **O que foi feito**: Auditoria EPIC-04; criada EPIC-06; proposta de mitigação; ADR-001 rascunhada para unificar `DigitalSignature` (work_orders vs evidences), cobrir PII/LGPD e destravar D-05/M-04/M-05.
- **Gate 2.5 (Segurança)**: Gate 2.5: INVOKED — em execução para `docs/architecture/adr-001-assinatura-digital-canonica.md` (PII: nome/documento/assinatura; LGPD; armazenamento local; redaction; migração).
- **Gates 3/4**: não aplicável ainda (decisão/ADR, sem implementação de código).

## [EVIDENCIA]
- Leitura: `lib/modules/work_orders/domain/value_objects/digital_signature.dart`, `lib/modules/evidences/domain/entities/digital_signature.dart`, `docs/architecture/SPEC.md` RN-03/INV-03, `docs/plan/epics/epic-04-checklists-evidencias.md` §6, `docs/DEBITOS.md` D-05.
- Verifica: `flutter test test/modules/checklists test/modules/evidences` => `+19 All tests passed` (evidência prévia de módulo; sem mudança de código neste slice).
- Confirma: ADR-001 criada com opções D1-D5 e pendências de aprovação PO/Arch/Security.

## Próximo passo
1. Concluir Gate 2.5 da ADR-001.
2. Obter decisão PO sobre D2 (documento obrigatório/opcional).
3. Após aprovação, iniciar UC-04.06/04.08 implementação com TDD.