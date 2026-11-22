# Relatório de Auditoria de Release: v0.21.0

## 1. Metadados
| Campo | Informação |
| :--- | :--- |
| **Versão Auditada** | `v0.21.0` (EPIC-07 — UC-07.01/02/03) |
| **Commit de referência** | `225a29a` + correções do Gate 4 (`HEAD` desta consolidação) |
| **Data** | `2026-11-22` |
| **Auditor** | QA / Release Reviewer (subagente, isolamento epistêmico) |
| **Veredito** | **APROVADO COM RESSALVAS** |
| **Confiança** | Alta (conformidade funcional/invariantes); Média (rastreabilidade de processo) |

## 2. Evidência Empírica
- `flutter analyze --fatal-infos` → `No issues found!` — exit 0.
- `flutter test` → `+204 All tests passed!` — exit 0.
- Testes direcionados (settings + work_orders/ui + repo SQLite) → `+34 All tests passed!` — exit 0.
- `gate-uc-schema.ps1 -Path docs/plan/state/uc-current.md` → `OK`, exit 0.
- GitHub Actions: run `45081277660` (`origin/main` `7eed9ca`) **success**; HEAD local com correções de G3/G4 pendente de push.

## 3. Conformidade
- **INV-01..06**: conformes; INV-03 preservada via `ChecklistCompletionProof` + assinatura obrigatória por tipo; INV-06 guard inalterado.
- **SEC-01..08**: conformes — fonte única `GetSettings`, leitura por operação, fail-closed, não-coleta sem D-01, guard duplo, sem PII, prova de ausência com estado recarregado, INV-03 não relaxada.
- **Gherkin UC-07.01/02**: coberto. **UC-07.03**: linhas 1–3 cobertas; linha 4 (`D-01 DISPONÍVEL`) permanece inalcançável enquanto `kDocumentAtRestProtectionAvailable=false` (D-01/C-01), registrada no épico.

## 4. Achados e tratamento
| ID | Achado | Tratamento |
| :--- | :--- | :--- |
| **M1** | Deferidos M-03/M-05/B-01 sem ledger | **Resolvido**: M-03 reset de settings, M-05 extração de `_policyError`, B-01 `settingsRepository` obrigatório |
| **M2** | ADR-003/EPIC-07 afirmavam G3/G4 pendentes | **Resolvido**: docs atualizados |
| **A1** | `load()` tolera chave desconhecida vs ADR | **Resolvido**: ADR-003 documenta forward-compat |
| **A2** | Mensagem D-01 duplicada | **Resolvido**: `kDocumentProtectionUnavailableMessage` única |
| **A3** | Contagem de testes stale | **Resolvido**: 7 testes de UI/controller |
| **A4** | Falta teste do adapter com template vinculado + `requireTemplate=false` | **Resolvido**: teste adicionado |
| **A5** | Linha 4 da matriz D2 sem cobertura | **Resolvido**: nota de bloqueio por D-01 no épico |
| **A6/A7** | Redação ambígua de CI no hand-off | **Resolvido**: `origin/main` verde + HEAD pendente de push |

## 5. Ressalva de processo
- **Red-Before-Green sem prova temporal**: os commits do épico não registram `[RED]` no corpo. A limitação fica registrada; o próximo UC deve incluir a linha do teste falhando no corpo do commit.

## 6. Parecer Final
**APROVADO COM RESSALVAS.** Nenhum bloqueador de release. Código conforme à SPEC e aos SEC-01..08, com análise e suíte completas verdes, sem PII em log/erro e sem arquivos fora do escopo. Push permanece condicionado à autorização explícita do PO e às 3 evidências.
