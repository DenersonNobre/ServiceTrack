# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-04.05` (Contrato Canônico de Assinatura & Decisão de Domínio)
- **Status**: EM ANDAMENTO (ADR proposta; Gate 2.5 condicionantes; PO decidiu D2)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-04`
- **Última Atualização**: `2026-11-22`

## Contexto Atual
- **O que foi feito**: ADR-001 rascunhada e revisada em Gate 2.5. PO decidiu D2: documento recebedor **obrigatório por política/configuração** (default seguro/minimização).
- **Gate 2.5 (Segurança)**: Gate 2.5: INVOKED — APROVADO COM CONDICIONANTES (Confiança Média, `ses_dfc96c088ffePqylwAxJpMhMTK`). C-01..C-12 abertos; **C-03 decidido PO 2026-11-22**. INV-SEC-SIG-01..06 propostas.
- **Gates 3/4**: não aplicável ainda (decisão/ADR, sem implementação de código).

## [EVIDENCIA]
- Leitura: `docs/architecture/adr-001-assinatura-digital-canonica.md`, `docs/architecture/SPEC.md` RN-03/INV-03, `docs/plan/epics/epic-04-checklists-evidencias.md` §6.
- Verifica: `flutter test test/modules/checklists test/modules/evidences` => `+19 All tests passed` (baseline módulo, sem mudança de código neste slice).
- Confirma: D2 registrado na ADR-001 e checklist de aprovação atualizado.

## Próximo passo
1. Obter aprovação Arch para D1/D3/D4/D5.
2. Planejar UC-04.06/04.08 com TDD, Gate 2.5 condicionantes embutidos e política/configuração de documento.
3. Após aprovação, iniciar implementação.