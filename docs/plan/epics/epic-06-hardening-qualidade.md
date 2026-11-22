# Épico 06: Hardening Técnico, Aderência & Qualidade Transversal

## Metadados

| Atributo | Valor |
| :--- | :--- |
| **Identificador** | `EPIC06` |
| **Dependências Diretas** | `EPIC00`, `EPIC03` (base de código estável); **não bloqueia** EPIC-04/05, mas deve evitar colisão de diff |
| **Prioridade** | Média (Qualidade/Manutenibilidade; reduz dívida antes de escalar EPIC-04/05) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Pronto para Iniciar` |
| **Referências** | [Proposta de Mitigação](../../proposals/proposta-mitigacao-aderencia-dnolib-kortex-core-2026-11-22.md) \| [AGENTS.md](../../../AGENTS.md) \| [SPEC](../../architecture/SPEC.md) |

---

## 1. Objetivo de Negócio & Escopo

Reduzir dívida técnica transversal identificada na auditoria de 2026-11-22, sem mudar regra de negócio: padronizar códigos de falha, consolidar utilitários de UI/core, reforçar aderência Kortex/Stateless e criar gates simples anti-regressão.

- **Incluso**:
  - `UC-06.01`: Catálogo de `*FailureCodes` por módulo e eliminação de `ERR_*` inline.
  - `UC-06.02`: Core UI transversal (`AppFeedback`, tokens de touch target, helpers de diálogo/confirmação quando houver 2+ usos).
  - `UC-06.03`: Aderência Stateless/Kortex em widgets com `setState` injustificado (inventário da auditoria; exceções só com justificativa explícita).
  - `UC-06.04`: Gate de qualidade anti-string-mágica `ERR_*` fora de catálogos.
- **Não Incluso**:
  - Integração D-05 / prova real de checklist na conclusão de OS (fica na reconciliação EPIC-04, M-03/M-04/M-05).
  - Unificação do contrato `DigitalSignature` (EPIC-04/M-05).
  - Hardening de plataforma D-01/D-02/D-03 (débitos separados por ambiente).

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| :--- | :--- | :--- | :---: |
| **UC-06.01** | Catálogos de Falha por Módulo (`*FailureCodes`) | Nenhuma | `Pendente` |
| **UC-06.02** | Core UI Transversal (Feedback/Touch Target) | Nenhuma | `Pendente` |
| **UC-06.03** | Refator Stateless/Kortex em Widgets Justificados | UC-06.02 (opcional) | `Pendente` |
| **UC-06.04** | Gate Anti-String-Mágica `ERR_*` | UC-06.01 | `Pendente` |

---

## 3. Definição de Pronto (DoD) do Épico

- [ ] Nenhum literal `ERR_*` fora dos catálogos `*FailureCodes` aprovados (ou allowlist documentada).
- [ ] `AppFeedback`/helpers de core usados onde havia duplicação real; sem “core dump”.
- [ ] `StatefulWidget/setState` remanescentes têm justificativa técnica explícita documentada no código/proposta.
- [ ] Gate automatizado (script/test) falha em novo `ERR_*` literal fora de catálogo.
- [ ] `flutter analyze --fatal-infos` e `flutter test` com exit code 0.
- [ ] Laudo QA por UC/épico conforme governança.

---

## 4. Casos de Uso Atômicos

### Caso de Uso UC-06.01 — Catálogos de Falha por Módulo

* **Identificador**: `UC-06.01`
* **Status**: `Pendente`

#### Narrativa
- **Como** mantenedor do ServiceTrack
- **Eu quero** códigos `ERR_*` centralizados por módulo/contexto
- **Para que** evite typo, divergência de contrato e refatoração frágil.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Cenário: Nenhum código de erro literal fora de catálogo após migração
  Dado que os módulos possuem catálogos *FailureCodes
  Quando a suíte de verificação de strings mágicas é executada
  Então ela retorna exit code 0
  E não há literal "ERR_" fora dos arquivos de catálogo/allowlist
```

#### Tarefas Técnicas
1. `TASK-01`: Inventariar `ERR_*` por módulo (auth já tem padrão; replicar para customers/work_orders/checklists/evidences/profile/core onde aplicável).
2. `TASK-02`: Migrar literais com testes verdes por módulo (fatia pequena).
3. `TASK-03`: Adicionar teste/script de verificação.

---

### Caso de Uso UC-06.02 — Core UI Transversal

* **Identificador**: `UC-06.02`
* **Status**: `Pendente`

#### Narrativa
- **Como** desenvolvedor Flutter
- **Eu quero** helpers transversais para feedback e alvo tátil
- **Para que** eliminar boilerplate sem criar abstração prematura.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Cenário: Feedback de erro padronizado
  Dado que uma tela precisa exibir ValidationError ao usuário
  Quando o helper AppFeedback.showError é chamado
  Então exibe SnackBar com mensagem e sem duplicar ScaffoldMessenger boilerplate
```

#### Tarefas Técnicas
1. `TASK-01`: Criar `lib/core/ui/app_feedback.dart` e tokens `touch_target.dart` (somente se 2+ usos reais).
2. `TASK-02`: Migrar usos duplicados (começar por `work_order_list_page.dart`).
3. `TASK-03`: Testes de widget para helper/comportamento acessível.

---

### Caso de Uso UC-06.03 — Refator Stateless/Kortex

* **Identificador**: `UC-06.03`
* **Status**: `Pendente`

#### Narrativa
- **Como** time de UI
- **Eu quero** widgets sem `setState` injustificado
- **Para que** cumprir a regra canônica do AGENTS.md e manter reatividade Kortex.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Cenário: Widget com estado de tela usa Kortex
  Dado um widget que antes usava setState para estado de tela
  Quando for refatorado
  Então passa a usar KortexSignal/IKortexController/KortexWatch conforme aplicável
  E nenhum StatefulWidget permanece sem justificativa técnica explícita
```

#### Tarefas Técnicas
1. `TASK-01`: Revisar ocorrências validadas na Seção 7.1 da proposta (foco em `signature_pad_widget.dart` e lifecycle forms).
2. `TASK-02`: Refatorar somente onde houver ganho real; documentar exceções.

---

### Caso de Uso UC-06.04 — Gate Anti-String-Mágica ERR

* **Identificador**: `UC-06.04`
* **Status**: `Pendente`
* **Dependência**: UC-06.01

#### Narrativa
- **Como** mantenedor de qualidade
- **Eu quero** um gate que falhe em novos `ERR_*` literais fora de catálogo
- **Para que** a dívida N-06 não regrida.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Cenário: Gate reprova literal ERR fora de catálogo
  Dado um arquivo Dart com literal "ERR_NOVO_CODIGO" fora de *FailureCodes
  Quando o script de gate executa
  Então retorna exit code != 0 e aponta o arquivo:linha
```

#### Tarefas Técnicas
1. `TASK-01`: Criar script PowerShell/Dart em `scripts/gates/` ou `scripts/` com allowlist explícita.
2. `TASK-02`: Integrar ao `build-all.ps1`/verificação local; documentar em AGENTS/LEARNINGS.

## 5. Riscos & Dependências

| Risco | Prob. | Impacto | Mitigação |
| :--- | :--- | :--- | :--- |
| Refator amplo de `ERR_*` gerar churn | Média | Médio | Migrar por módulo, commits atômicos, testes por fatia. |
| “Core dump” de abstrações | Média | Médio | Só promover para core com 2+ usos reais. |
| Colisão com EPIC-04 em andamento | Média | Médio | Claims por path, evitar tocar `work_orders` completion até D-05 planejado. |
