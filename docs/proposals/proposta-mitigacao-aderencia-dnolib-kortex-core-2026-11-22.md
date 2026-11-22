# Proposta de Mitigação — Aderência dnolib/kortex, Core e Débitos

> **Data**: 2026-11-22  
> **Autor**: `opc01@e03ff640` (auditoria estática/read-only; sem mutação de código de produção)  
> **Escopo**: `lib/`, `pubspec.yaml`, `docs/DEBITOS.md`, convenções `AGENTS.md`/`architecture-guidelines.md`  
> **Método**: inspeção estática (`git grep`, leitura de arquivos, contagem de padrões). Itens não executados em runtime são marcados como [INFERÊNCIA].

## 1. Resumo Executivo

| Área | Situação | Confiança | Risco |
|---|---|---|---|
| **Kortex** | Boa adoção em telas/controllers principais (`IKortexController`, `KortexSignal`, `KortexWatch`, `KortexScope`, `IKortexPage`). Há exceções pontuais com `setState` local. | Alta | Médio |
| **dnolib** | Boa adoção de `Result/ValidationError/Money/sqlite` e `brlib` (CPF/CNPJ). Não foram achados imports de `dnolib` em alguns pontos esperados? [FATO] há uso amplo; [INFERÊNCIA] pode haver utilitários dnolib subutilizados. | Média | Médio |
| **Core** | `lib/core` pequeno (3 widgets + orientation guard). Há boilerplate repetido fora do core (snackbar de erro, alvo 48dp, códigos de falha, padrões de persistência). | Alta | Médio |
| **Strings mágicas** | Códigos `ERR_*` estão espalhados inline em vários módulos; `AuthFailureCodes` já é o padrão bom. Labels de UI são esperados, mas códigos/keys/status de domínio devem ser nominais. | Alta | Médio |
| **Débitos** | D-01..D-05 abertos. Débitos adicionais identificados: duplicação de `DigitalSignature`, respostas de checklist só em memória, integração D-05 incompleta, `setState` em forms/widgets, snackbar boilerplate, tamanho inicial de assets (já mitigado). | Média | Alto (D-05/integração) |

## 2. Evidências Principais

### 2.1 Kortex (aderência)
**Positivo [FATO]**
- `pubspec.yaml`: `kortex: path: ../kortex`.
- Uso amplo de `KortexScope`, `IKortexSignal/Signal`, `IKortexController`, `KortexWatch`, `IKortexPage` em `lib/app/app_entry.dart`, auth, customers, work_orders, profile, checklists.

**Desvios/atenção [FATO]**
- `setState` em: `lib/app/app_entry.dart:51` (`_AppEntryState` com `WidgetsBindingObserver`), `customer_form_page.dart`, `service_location_form_page.dart`, `signature_pad_widget.dart`, `profile_page.dart`, `work_order_form_page.dart`.
- Classificação [INFERÊNCIA]: forms com estado efêmero local podem ser aceitáveis; `AppEntryState` é shell de lifecycle; `SignaturePadWidget` tem estado local de captura/salvamento. Avaliar caso a caso contra a regra “Toda gerência de estado de tela deve utilizar kortex”.

### 2.2 dnolib (aderência)
**Positivo [FATO]**
- `pubspec.yaml`: `dnolib: path: ../.dnolib`.
- Uso de `dnolib/core/patterns/result.dart`, `validation_error.dart`, `core/models/money.dart`, `sqlite/sqlite.dart`, `brlib/brlib.dart` (CPF/CNPJ em customers).

**Lacunas potenciais [INFERÊNCIA, confiança Média]**
- Verificar se há utilitários dnolib para validações/formatação/mascaramento já usados de forma inconsistente (telefone, email, CEP, moeda BRL). Ex.: há `ValidationError` manual em vários locais com códigos repetidos.
- Confirmar se `dnolib` oferece base de repositório SQLite/erros padronizados que evite `try/catch` repetido em repos.
- Duplicação de conceito: `DigitalSignature` existe em `lib/modules/work_orders/domain/value_objects/digital_signature.dart` e `lib/modules/evidences/domain/entities/digital_signature.dart` com contratos diferentes. Decisão de contrato canônico necessária.

### 2.3 Core — candidatos a promoção

| Candidato | Evidência | Destino sugerido | Prioridade |
|---|---|---|---|
| **Snackbar/feedback de erro** | `ScaffoldMessenger.of(...).showSnackBar(...)` repetido 9x em `work_order_list_page.dart` e padrão similar em outros fluxos [INFERÊNCIA] | `lib/core/ui/app_feedback.dart` ou extension `BuildContext.showError/showSuccess` | Alta |
| **Token de alvo tátil** | `minimumSize: const Size(48, 48)` repetido em múltiplas páginas/widgets | `lib/core/ui/touch_targets.dart` (`kMinTouchTarget = 48`, `kMinTouchSize`) + helpers de estilo | Média |
| **Códigos de falha nominais** | `AuthFailureCodes` é bom; demais módulos usam `ERR_*` inline | `lib/core/errors/` ou por módulo `domain/..._failure_codes.dart`; padronizar convenção | Alta |
| **Mapeamento Result->UI** | Controllers/pages fazem switch/case repetido | helper `result.fold`/extension já existe em dnolib? avaliar; se não, `lib/core/patterns/result_ui.dart` | Média |
| **Persistência SQLite boilerplate** | Repos repetem `try/catch`, `ValidationError(code: ERR_*_PERSISTENCIA, ...)` | base/adapter em `lib/core/data/sqlite_repository_base.dart` ou utilitário local usando dnolib/sqlite | Média |
| **Formatação de data/hora/Money** | Labels e formatação espalhados [INFERÊNCIA] | `lib/core/formatters/` se repetição for confirmada | Baixa |
| **Status badge/label mapping** | `WorkOrderStatus` tem label na UI? verificar; badges de OS existem | `core/ui`/mapper por módulo; evitar strings soltas | Média |
| **Diálogos de confirmação/justificativa** | Diálogos de pausa/cancelamento com estrutura repetida | `lib/core/ui/app_confirm_dialog.dart` / `app_reason_dialog.dart` | Média |

### 2.4 Strings mágicas / códigos

**Códigos de erro `ERR_*` (alto valor de limpeza) [FATO]**
- Espalhados inline em auth VOs, recovery, checklists, customers, evidences, profile, work_orders, data repos.
- Bom padrão existente: `lib/modules/auth/domain/ports/auth_failure_codes.dart`.
- Risco: typo, divergência de contrato, difícil refactor/rastreabilidade.

**Chaves de persistência / nomes de coluna [INFERÊNCIA]**
- Colunas SQLite são strings em migrations/repos; aceitável na borda de persistência, mas devem ser centralizadas por tabela/migration (já parcialmente). Verificar duplicação.

**Labels de UI [INFERÊNCIA, baixo risco]**
- Textos PT-BR em UI são esperados. Não tratar como “mágica” indevida se forem copy local; considerar l10n somente se houver requisito futuro.

### 2.5 Débitos (registrados + encontrados)

| ID/Tipo | Débito | Evidência | Severidade | Mitigação proposta |
|---|---|---|---:|---|
| D-01 | Sem runners nativos; `allowBackup`/Keystore pendentes | `docs/DEBITOS.md` | Média | Scaffolding plataforma + checklist de hardening Android/iOS |
| D-02 | CVE audit indisponível offline | `docs/DEBITOS.md` | Média | Rodar `osv-scanner`/pub audit quando online; CI periódico |
| D-03 | `verifyPassword` sem rate-limit | `docs/DEBITOS.md` | Média | Avaliar rate-limit/backoff na UC-01.04/credencial |
| D-04 | Casa sem `docs/mitigations/` | `docs/DEBITOS.md` | Baixa | Criar ao abrir débito multi-passo; esta proposta pode originar MITs |
| D-05 | `ChecklistCompletionProof(0,0)` hardcoded na conclusão | `docs/DEBITOS.md`, `work_order_list_page.dart` | **Alta** | Integrar prova real por OS/template antes de EPIC-04 integração; fail-closed |
| N-01 | Duplicação `DigitalSignature` (work_orders vs evidences) | dois arquivos com contratos distintos | **Alta** | Definir contrato canônico (SPEC/INV-03), adapter/migração, único VO |
| N-02 | Respostas checklist só em memória | `MemoryChecklistAnswerRepository` | Alta | Repo SQLite por OS/template, migração, binding com UC-04.02/INV-03 |
| N-03 | EPIC-04 desatualizado no plano/gates | epic/README/uc-current sem reconciliação | Média | Auditoria por UC, gates 2.5/3/4, qa-reviews v0.18+ |
| N-04 | `setState` em forms/shell/widget | 11 ocorrências achadas | Média | Classificar: efêmero local aceitável vs estado de tela; migrar onde houver regra de negócio/UI complexa |
| N-05 | SnackBar boilerplate repetido | 9 ocorrências no work order list page | Baixa | helper `core/ui/app_feedback.dart` |
| N-06 | Códigos `ERR_*` inline | ampla ocorrência | Média | `*FailureCodes` por módulo ou catálogo central por contexto |
| N-07 | Repetição `Size(48,48)` | ampla ocorrência | Baixa | token/constante de acessibilidade + theme/button styles |

## 3. Proposta de Mitigação (fases)

### Fase 0 — Decisões (sem código)
1. **ADR curta**: contrato canônico de assinatura (INV-03) e modelo de prova de checklist por OS.
2. **ADR curta**: política de `setState` local efêmero vs Kortex em forms.
3. **Convenção**: catálogo de códigos de falha por módulo (`<Module>FailureCodes`), proibindo literal `ERR_*` fora do catálogo.

### Fase 1 — Baixo risco / alto reuso (quick wins)
1. Criar `lib/core/ui/app_feedback.dart` (`showAppError`, `showAppSuccess`) e substituir usos repetidos.
2. Criar `lib/core/ui/touch_target.dart` (`kMinTouchTargetSize`, `kMinTouchTargetEdge`).
3. Inventariar `ERR_*` e gerar catálogos por módulo (começar por work_orders/customers/checklists/evidences/profile).
4. Adicionar lint/check de CI simples (grep gate) para novos `ERR_` literais fora de `*_failure_codes.dart` [INFERÊNCIA].

### Fase 2 — Integridade de domínio (D-05/N-01/N-02)
1. Modelar persistência de respostas de checklist por OS (SQLite) e binding template↔OS.
2. Substituir `ChecklistCompletionProof(0,0)` por prova calculada de fonte real; manter fail-closed.
3. Unificar `DigitalSignature` canônico; adaptar UI de conclusão e evidences.
4. Cobrir com TDD + Gate 2.5 (PII/LGPD, imutabilidade, validação).

### Fase 3 — Reconciliação EPIC-04
1. Auditar UC-04.01–04.04 com evidência real.
2. Atualizar `epic-04`, `README`, `uc-current`, gerar qa-reviews.
3. Fechar D-05 no mesmo ciclo da integração.

### Fase 4 — Hardening
1. Tratar D-01/D-02/D-03 conforme ambiente/plataforma.
2. Criar `docs/mitigations/` quando houver plano multi-passo (D-04).

## 4. Backlog Proposto (rastreável)

| ID | Item | Tipo | Prioridade | Esforço | Dependência | Critério de aceite |
|---|---|---|---:|---:|---|---|
| M-01 | Catálogo `FailureCodes` por módulo | Refactor | Alta | M | nenhum | zero `ERR_*` literal fora catálogos; testes verdes |
| M-02 | `AppFeedback` + `TouchTarget` core | Core/UI | Média | P | nenhum | usos duplicados reduzidos; >=48dp preservado |
| M-03 | ADR assinatura canônica | Arquitetura | Alta | P | nenhum | decisão registrada em docs/architecture/ADR ou proposal aceita |
| M-04 | Persistência checklist por OS | Domínio/Dados | Alta | G | M-03 | respostas SQLite, prova real, fail-closed, D-05 fechado |
| M-05 | Unificar `DigitalSignature` | Domínio | Alta | M | M-03 | um contrato canônico; migração/adapters; testes |
| M-06 | Reconciliação EPIC-04 | Governança | Alta | M | M-04/M-05 | épico/status/laudos coerentes com evidência |
| M-07 | Política setState local | Arquitetura | Média | P | nenhum | guideline + refactors pontuais onde necessário |
| M-08 | Gate anti-string-mágica ERR | Qualidade | Média | P | M-01 | script/gate falha em literal novo fora catálogo |

## 5. Riscos e Cuidados

- **Não fazer big-bang**: migrar por módulo/UC, com testes verdes.
- **D-05 é sensível**: qualquer integração com checklist toca INV-03/INV-06/INV-SEC-23; exigir Gate 2.5 e 3/4.
- **Duplicação de assinatura**: cuidado com PII/LGPD (documento do recebedor) e com persistência/redação.
- **Core só recebe o que é transversal**: evitar “core dump”; promover apenas após 2+ usos reais ou contrato claro.

## 6. Próximo passo recomendado

Aprovar Fase 0 (decisões) e executar Fase 1 M-01/M-02 em fatias pequenas com TDD/verify, sem tocar na integração sensível de D-05 antes do desenho M-03/M-04.
