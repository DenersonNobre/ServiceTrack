# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-04.05` (Contrato Canônico de Assinatura & Decisão de Domínio)
- **Status**: CONCLUIDO (ADR aceita para implementação com condicionantes)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-04`
- **Última Atualização**: `2026-11-22`

## Contexto Atual
- **O que foi feito**: ADR-001 rascunhada, Gate 2.5 executado, D2 decidido pelo PO (obrigatório por política/configuração, default seguro/minimização), D1/D3/D4/D5 aprovados pelo Arch.
- **Gate 2.5 (Segurança)**: Gate 2.5: INVOKED — APROVADO COM CONDICIONANTES (Confiança Média, `ses_dfc96c088ffePqylwAxJpMhMTK`). C-01..C-12 abertos; **C-03 decidido PO 2026-11-22**. INV-SEC-SIG-01..06 propostas — devem ser embutidas em UC-04.06/07/08.
- **Gates 3/4**: N/A (decisão/ADR). Implementações subsequentes exigirão Gate 2.5/3/4.

## [EVIDENCIA]
- Leitura: `docs/architecture/adr-001-assinatura-digital-canonica.md`, `docs/architecture/SPEC.md` RN-03/INV-03, `docs/plan/epics/epic-04-checklists-evidencias.md` §6.
- Verifica: `flutter test test/modules/checklists test/modules/evidences` => `+19 All tests passed` (baseline, sem mudança de código).
- Confirma: ADR-001 com status Aceito para implementação com condicionantes; aprovações PO/Arch/Security registradas.

## Próximo passo
1. Iniciar **UC-04.06** (persistência SQLite de respostas de checklist por OS) com TDD.
2. Em seguida **UC-04.08** (unificação DigitalSignature) e **UC-04.07** (integração D-05), respeitando EPIC-07/D2.