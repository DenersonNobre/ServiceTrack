# Épico 04: Checklists Rápidos, Fotos & Evidências Georreferenciadas

## Metadados

| Atributo | Valor |
| :--- | :--- |
| **Identificador** | `EPIC04` |
| **Dependências Diretas** | `EPIC00`, `EPIC03`, `EPIC07` (política D2) |
| **Prioridade** | Alta (Comprovação Técnica & Auditabilidade) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Implementado em código (UC-04.01–04.09); E2E device bloqueado pelo ambiente` |
| **Referências da SPEC** | [docs/architecture/SPEC.md](../../architecture/SPEC.md) \| [docs/architecture/DESIGN.md](../../architecture/DESIGN.md) |

---

## 1. Objetivo de Negócio & Escopo

Permitir o preenchimento de itens de checklist de forma ágil em campo com o polegar, captura de fotos com compressão local compulsória (máx. 6 fotos, < 400KB cada), gravação de metadados de auditoria (data/hora UTC e coordenadas) e coleta de assinatura digital na tela.

- **Incluso**:
  - `UC-04.01`: Templates de Checklists Reutilizáveis (Instalação, Manutenção, Vistoria).
  - `UC-04.02`: Execução de Checklist Tri-Estado (`[Conforme]`, `[Não Conforme]`, `[Não se Aplica]`) com alvos táteis de 48dp.
  - `UC-04.03`: Captura e Compressão Local de Fotos com marca d'água de auditoria (`INV-04`).
  - `UC-04.04`: Coleta de Assinatura Digital do Cliente em Canvas (`SignaturePadWidget`) com Nome e CPF/RG (`INV-03`).
- **Não Incluso**:
  - Gravação de vídeo, upload em nuvem ou lógica condicional aninhada (*branching rules*).

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| :--- | :--- | :--- | :---: |
| **UC-04.01** | Modelos de Checklists Rápidos | Nenhuma | `Concluído (fechado em UC-04.09)` |
| **UC-04.02** | Preenchimento Tátil do Checklist na OS | UC-04.01 | `Concluído` |
| **UC-04.03** | Captura & Compressão de Fotos com Metadados | Nenhuma | `Concluído` |
| **UC-04.04** | Assinatura Digital na Tela do Smartphone | Nenhuma | `Concluído` |
| **UC-04.09** | Modelos Alcançáveis: Seed + Cadastro | UC-04.01 | `Concluído` |

---

## 3. Definição de Pronto (DoD) do Épico

- [x] Invariantes `INV-03` (completude obrigatória) e `INV-04` (cota de 6 fotos) cobertos por testes unitários.
- [x] Compressão de imagem executando em `Isolate.run(...)` sem travar a UI.
- [x] Coleta de assinatura rasterizada e vinculada à OS.
- [x] `flutter analyze --fatal-infos` e `flutter test` com exit code 0 (E2E device pendente).

---

## 4. Casos de Uso Atômicos

---

### Caso de Uso UC-04.01 — Modelos de Checklists Rápidos

* **Identificador**: `UC-04.01`
* **Status**: `Concluído (código+testes; TASK-02 fechado em UC-04.09; E2E device pendente)`
* **Gate DoR**: `tools/bin/claims claim -path . -slice UC-04.01 -owner <agente> -paths lib/modules/checklists/`
* **Gate DoD**: `tools/bin/claims release -path . -slice UC-04.01`

#### Narrativa
- **Como** Técnico autônomo
- **Eu quero** criar e reutilizar modelos de checklist por tipo de serviço (ex.: Instalação Split, Manutenção Preventiva)
- **Para que** eu não precise redigitar as mesmas verificações em toda Ordem de Serviço.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Esquema do Cenário: Criação e validação de modelo de checklist
  Dado que o técnico solicita salvar um template de checklist
  Quando informar <titulo> e <qtd_itens>
  Então o domínio deve retornar <resultado>

  Exemplos:
    | titulo | qtd_itens | resultado |
    | "Instalação Split" | 3 | "Result.Ok(ChecklistTemplate)" |
    | "" | 2 | "Result.Fail(ERR_CHECKLIST_TITULO_INVALIDO)" |
    | "Vistoria Rápida" | 0 | "Result.Fail(ERR_CHECKLIST_SEM_ITENS)" |
```
* **Fixture**: `docs/plan/fixtures/uc-04-checklists-evidencias.json`

#### NFRs Mensuráveis
| UC | NFR | Métrica | Target | Medição |
| :--- | :--- | :--- | :--- | :--- |
| `UC-04.01` | Listagem local de templates | Tempo de leitura SQLite | `< 50 ms` | Teste de repositório com 50 templates |

#### Tarefas Técnicas
1. `TASK-01`: Criar entidades `ChecklistTemplate` e `ChecklistItem` + migration SQLite + testes unitários.
2. `TASK-02`: Implementar `ChecklistTemplateSqliteRepository` e UI Kortex de cadastro/listagem.

---

### Caso de Uso UC-04.02 — Preenchimento Tátil do Checklist na OS

* **Identificador**: `UC-04.02`
* **Status**: `Concluído (código+testes; E2E device pendente)`
* **Gate DoR**: `tools/bin/claims claim -path . -slice UC-04.02 -owner <agente> -paths lib/modules/checklists/`
* **Gate DoD**: `tools/bin/claims release -path . -slice UC-04.02`

#### Narrativa
- **Como** Técnico executando uma OS em andamento (`IN_PROGRESS`)
- **Eu quero** responder cada item com toques rápidos (`Conforme`, `Não Conforme`, `Não se Aplica`) e observação opcional
- **Para que** o laudo técnico documente cada verificação com rapidez em campo.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Esquema do Cenário: Resposta de item de checklist na OS
  Dado que a OS está no status <status_os>
  Quando o técnico responder o item obrigatório com <resposta> e <observacao>
  Então o sistema deve retornar <resultado>

  Exemplos:
    | status_os | resposta | observacao | resultado |
    | "IN_PROGRESS" | "CONFORME" | "" | "Result.Ok(ChecklistAnswer)" |
    | "COMPLETED" | "CONFORME" | "" | "Result.Fail(ERR_OS_IMUTAVEL)" |
    | "IN_PROGRESS" | "NAO_CONFORME" | "Dreno obstruído" | "Result.Ok(ChecklistAnswer)" |
```
* **Fixture**: `docs/plan/fixtures/uc-04-checklists-evidencias.json`

#### NFRs Mensuráveis
| UC | NFR | Métrica | Target | Medição |
| :--- | :--- | :--- | :--- | :--- |
| `UC-04.02` | Ergonomia tátil | Altura mínima dos botões | `>= 48 dp` | Widget test verificando `getSize` >= 48x48 |

#### Tarefas Técnicas
1. `TASK-01`: Criar `ChecklistAnswer` + regra de completude (`INV-03`) e imutabilidade (`INV-06`).
2. `TASK-02`: Implementar `ChecklistItemWidget` tri-estado com botões `>= 48dp` e controller Kortex.

---

### Caso de Uso UC-04.03 — Captura & Compressão de Fotos com Metadados

* **Identificador**: `UC-04.03`
* **Status**: `Concluído (código+testes; E2E device pendente)`
* **Gate DoR**: `tools/bin/claims claim -path . -slice UC-04.03 -owner <agente> -paths lib/modules/evidences/`
* **Gate DoD**: `tools/bin/claims release -path . -slice UC-04.03`

#### Narrativa
- **Como** Técnico em campo
- **Eu quero** fotografar o serviço antes/depois (até 6 fotos por OS) com compressão automática e carimbo de data/hora UTC + GPS
- **Para que** as evidências ocupem pouco espaço no aparelho e tenham valor de comprovação.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Esquema do Cenário: Anexo e limite de evidências fotográficas (INV-04)
  Dado que a OS já possui <fotos_existentes> evidências
  Quando o técnico anexar uma nova foto de <tamanho_kb> KB
  Então o sistema deve retornar <resultado>

  Exemplos:
    | fotos_existentes | tamanho_kb | resultado |
    | 0 | 320 | "Result.Ok(PhotoEvidence)" |
    | 6 | 250 | "Result.Fail(ERR_EVIDENCIA_LIMITE_EXCEDIDO)" |
    | 5 | 399 | "Result.Ok(PhotoEvidence)" |
```
* **Fixture**: `docs/plan/fixtures/uc-04-checklists-evidencias.json`

#### NFRs Mensuráveis
| UC | NFR | Métrica | Target | Medição |
| :--- | :--- | :--- | :--- | :--- |
| `UC-04.03` | Tamanho de foto comprimida | Bytes salvos no disco | `<= 400 KB` | Teste unitário do `ImageCompressorAdapter` em `Isolate.run` |

#### Tarefas Técnicas
1. `TASK-01`: Criar `PhotoEvidence`, porta `IImageCompressorPort` e adaptador com `package:image` em `Isolate.run`.
2. `TASK-02`: Persistir arquivos exclusivamente em `getApplicationSupportDirectory()` (isolamento LGPD) + UI de galeria da OS.

---

### Caso de Uso UC-04.04 — Assinatura Digital na Tela do Smartphone

* **Identificador**: `UC-04.04`
* **Status**: `Concluído (código+testes; C-03/D2 policy-driven doc; E2E device pendente)`
* **Gate DoR**: `tools/bin/claims claim -path . -slice UC-04.04 -owner <agente> -paths lib/modules/evidences/`
* **Gate DoD**: `tools/bin/claims release -path . -slice UC-04.04`

#### Narrativa
- **Como** Técnico finalizando o atendimento
- **Eu quero** colher a assinatura do cliente na tela junto com o nome completo e documento (CPF/RG)
- **Para que** o cliente confirme formalmente o recebimento do serviço no laudo.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Esquema do Cenário: Validação de assinatura digital (INV-03)
  Dado que o técnico está na etapa de encerramento da OS
  Quando submeter <assinatura_bytes>, <nome_recebedor> e <documento>
  Então o domínio deve retornar <resultado>

  Exemplos:
    | assinatura_bytes | nome_recebedor | documento | resultado |
    | "png-bytes-validos" | "Carlos Eduardo" | "12345678909" | "Result.Ok(DigitalSignature)" |
    | "" | "Carlos Eduardo" | "12345678909" | "Result.Fail(ERR_ASSINATURA_AUSENTE)" |
    | "png-bytes-validos" | "" | "12345678909" | "Result.Fail(ERR_ASSINANTE_NOME_OBRIGATORIO)" |
```
* **Fixture**: `docs/plan/fixtures/uc-04-checklists-evidencias.json`

#### NFRs Mensuráveis
| UC | NFR | Métrica | Target | Medição |
| :--- | :--- | :--- | :--- | :--- |
| `UC-04.04` | Rasterização do traço | Tamanho do PNG gerado | `<= 150 KB` | Teste unitário de exportação do canvas |

---

## 5. Dados e Configuração

### 5.1 Migrations SQLite (`dnolib/sqlite`)
| Arquivo | Conteúdo | UCs dependentes |
| :--- | :--- | :--- |
| `lib/modules/checklists/data/checklist_migration.dart` | Tabelas `checklist_templates`, `checklist_items`, `checklist_answers` (v8); seed dos 3 modelos embutidos + 8 itens (v12, `INSERT OR IGNORE`) | `UC-04.01`, `UC-04.02`, `UC-04.09` |
| `lib/modules/evidences/data/evidence_migration.dart` | Tabelas `photo_evidences`, `digital_signatures` | `UC-04.03`, `UC-04.04` |

### 5.2 Seeds
- `ChecklistMigration.v12()` (registrada em `createAppDatabase`, `dbVersion: 12`) semeia 3 modelos com itens:
  `Instalação Split` (3 itens), `Manutenção Preventiva` (3 itens) e `Vistoria Rápida` (2 itens).
- `INSERT OR IGNORE`: reabrir o banco na mesma versão **não** re-semeia nem duplica itens.

### 5.3 Config Schema
- Sem variáveis de ambiente externas (armazenamento 100% local em `getApplicationSupportDirectory()/evidences/`).

---

## 6. Reconciliação, Lacunas & Integração D-05

> Atualização 2026-11-22 (auditoria `opc01@e03ff640` + adendos `agy01@59993bf1`).

### 6.1 Evidência existente [FATO]
- Commits: `b85c967` (UC-04.01), `451a2ac` (UC-04.02), `b37befc` (UC-04.03), `7495877` (UC-04.04).
- Testes de módulo: `flutter test test/modules/checklists test/modules/evidences` => `+19 All tests passed`.
- Ausentes: laudos QA v0.18+ para UC-04.x, atualização de status/gates, integração com conclusão de OS.

### 6.2 Lacunas bloqueantes
1. **D-05**: mitigado em UC-04.07 — prova real via porta/adapter, binding template↔OS, execução/persistência de respostas, guard INV-06, política C (`requireChecklistTemplate` default true, decisão PO 2026-11-22). G2.5 INVOKED, G3 APROVADO (Alta), G4 APROVADO (Alta, `qa-review-v0.18.0.md`). Validação E2E device permanece pendente.
2. **Persistência de respostas por OS**: `ChecklistAnswerSqliteRepository` + migration v8 criados; binding template↔OS e integração no fluxo de execução/conclusão entregues no UC-04.07. E2E device pendente.
3. **Contrato de assinatura duplicado (M-03/M-05)**: resolvido em UC-04.08 — VO canônico em `evidences.domain.entities.DigitalSignature`, `work_orders` re-exporta, migration v10 aditiva.
4. **Governança**: matriz UC-04.01–04.08 atualizada; laudos `qa-review-v0.18.0.md` e `qa-review-v0.19.0.md` emitidos. Pendências: E2E device e atualização do `docs/plan/README.md` conforme consolidação final.

### 6.3 UCs/Tracks de Reconciliação (propostos)

| ID | Título | Dependência | Status |
|---|---|---|---|
| **UC-04.05** | Contrato Canônico de Assinatura & Decisão de Domínio (ADR/M-03) | UC-04.04 | `Pendente` |
| **UC-04.06** | Persistência SQLite de Respostas de Checklist por OS (M-04) | UC-04.01, UC-04.02 | `Concluído` |
| **UC-04.07** | Integração Prova Real de Checklist na Conclusão OS (fecha D-05) | UC-04.06, UC-03.05 | `Concluído` |
| **UC-04.08** | Unificação de DigitalSignature e Migração (M-05) | UC-04.05 | `Concluído` |
| **UC-04.09** | Modelos Alcançáveis: Seed Embutido + Cadastro pela UI | UC-04.01 | `Concluído` |

> Gate 2.5 obrigatório em UC-04.05/07/08 (PII/LGPD, imutabilidade, validação). Gate 4 deve incluir evidência de `flutter analyze --fatal-infos` e `flutter test` completo.

### 6.4 UC-04.09 — correção de entrega declarada (2026-11-22)

`UC-04.01` figurava `Concluído`, mas o `TASK-02` ("UI Kortex de cadastro/listagem") não estava entregue: a página de listagem existia como **código morto** (nenhuma rota a montava), não havia formulário de cadastro e nenhuma migration semeava templates. Efeito medido: em instalação limpa o seletor `wo-checklist-template` nascia vazio, `checklistTemplateId` só podia ser `null` e o fluxo `template→OS→checklist→conclusão` era inalcançável pela UI.

Entregue nesta fatia:

| Item | Arquivo | Prova |
| :--- | :--- | :--- |
| Seed de 3 modelos + 8 itens | `checklist_migration.dart` (`v12`) | `checklist_seed_migration_test.dart` (RED antes: `Expected: length 3 / Actual: []`) |
| Cadastro com validação de domínio | `checklist_template_form_controller.dart` | `checklist_template_form_controller_test.dart` (RED antes: `Method not found`) |
| Tela stateless com identidade por item | `checklist_template_form_page.dart` | `checklist_template_form_page_test.dart` (RED por mutação: `ValueKey(index)` herda texto do vizinho removido) |
| Rota acessível a partir da OS | `checklists_routes.dart` + ação `wo-templates` | `checklist_templates_reachable_test.dart` (RED por mutação: `+0 -2` sem a ação) |

**Pendente**: validação E2E em device — bloqueada por `INSTALL_FAILED_USER_RESTRICTED` (MIUI recusando instalação por USB), não pelo código.
