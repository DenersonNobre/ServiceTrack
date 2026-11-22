# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-04.08` (Unificação de DigitalSignature e Migração / M-05)
- **Status**: EM ANDAMENTO (Gate 2.5 em execução)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-04`
- **Última Atualização**: `2026-11-22`

## Contexto Atual
- **O que foi feito**: UC-04.07 concluído/consolidado (D-05 mitigado). Iniciado UC-04.08 (unificação DigitalSignature/M-05, ADR-001).
- **Gate 2.5 (Segurança)**: Gate 2.5: INVOKED — APROVADO COM CONDICIONANTES (Média, `ses_dfbc73e7affeMHohJlFfenufxo`). C-01/N1: não persistir `documentNumber` em claro (D-01); default minimização. C-03/N2: `documentNumber?` opcional por política/config, default sem coleta. C-10: migration additiva, sem UPDATE em COMPLETED + testes INV-SEC-23. C-04..C-09 obrigatórios no slice. C-02/C-11/C-12 deferidos (D-01/EPIC-05/EPIC-07).
- **Gates 3/4**: pendentes (implementação condicionada ao Gate 2.5).

## [EVIDENCIA]
- Leitura: `lib/modules/work_orders/ui/list/work_order_list_controller.dart`, `lib/modules/checklists/ui/execution/checklist_execution_controller.dart`, `lib/app/adapters/checklist_proof_adapter.dart`, `lib/app/app_entry.dart`, `lib/modules/work_orders/domain/ports/checklist_proof_port.dart`.
- Verifica: `flutter analyze --fatal-infos` (escopo tocado) => `No issues found!` (2026-11-22).
- Confirma: `flutter test test/modules/checklists/ui/checklist_execution_controller_test.dart test/app/adapters/checklist_proof_adapter_test.dart test/modules/work_orders/ui/work_order_list_controller_test.dart` => `+10 All tests passed`. Full: `flutter analyze --fatal-infos` limpo; `flutter test` 157 pass / 3 fail (flaky auth A1, fora do slice; rerun direcionado 3 pass / 1 fail no mesmo flake).

## Próximo passo
1. **UC-04.08** (unificação `DigitalSignature` conforme ADR-001, M-05): Gate 2.5 obrigatório antes do coder; C-01..C-12 abertos; D2 decidido (documento do receptor obrigatório por política/config, secure-by-default).
2. **UC-04.06**: fechar binding/execução ponta-a-ponta remanescente se houver lacunas fora do UC-04.07 (validação E2E device pendente).
3. Consolidar release EPIC-04 após UC-04.08/Gates.