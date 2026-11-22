# Épico 07: Configurações & Políticas Locais

## Metadados

| Atributo | Valor |
| :--- | :--- |
| **Identificador** | `EPIC07` |
| **Dependências Diretas** | `EPIC00` (fundação), `EPIC01` (perfil/auth local) |
| **Prioridade** | Média (habilita políticas transversais; D2/ADR-001) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Em Andamento (UC-07.01/02/03 concluídos em código; Gates 3/4 pendentes)` |
| **Referências** | [ADR-001](../../architecture/adr-001-assinatura-digital-canonica.md) \| [SPEC](../../architecture/SPEC.md) \| [DESIGN](../../architecture/DESIGN.md) \| [DEBITOS](../../DEBITOS.md) |

---

## 1. Objetivo de Negócio & Escopo

Centralizar configurações e políticas locais do app em módulo dedicado, evitando flags espalhadas em `app_entry`, controllers ou regras hardcoded em fluxos de negócio.

- **Incluso**:
  - `UC-07.01`: Fundação do módulo `settings` (catálogo tipado, ports, persistência SQLite, defaults seguros, get/update use cases).
  - `UC-07.02`: UI de Configurações (tela acessível, Kortex, leitura/edição por use case).
  - `UC-07.03`: Integração de políticas existentes (`require_checklist_template`, `require_receiver_document`) nos consumidores, substituindo bools hardcoded por leitura do settings; respeitando D-01/C-01.
- **Não Incluso**:
  - Sincronização remota de configurações.
  - Gestão de credenciais/cofre (EPIC-01).
  - Dados comerciais do técnico (EPIC-01/Profile).
  - Criptografia em repouso do SQLite (D-01) — pré-requisito para habilitar persistência de documento do recebedor.
  - Backup/export seguro com PII (C-11/C-12, EPIC-05/EPIC-07 futuro).

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Gate 2.5 | Status |
| :--- | :--- | :--- | :---: | :---: |
| **UC-07.01** | Fundação do Módulo de Configurações Locais | Nenhuma | PULADO (sem superfície sensível nova; sem PII, sem nova dependência) | `Concluído (código+testes)` |
| **UC-07.02** | UI de Configurações Locais | UC-07.01 | PULADO (UI lê/escreve por use case; sem PII nova; D2 já decidido) | `Concluído (código+testes)` |
| **UC-07.03** | Integração de Políticas de Conclusão/Evidência | UC-07.01, UC-07.02 | INVOKED (D2/PII: documento do recebedor; respeitar C-01/D-01, minimização, fail-closed) | `Concluído (código+testes; G2.5 c/ condicionantes)` |

---

## 3. Definição de Pronto (DoD) do Épico

- [x] Catálogo tipado de configurações com defaults explícitos (sem string mágica de chave fora do catálogo).
- [x] Persistência local SQLite via `dnolib/sqlite` com migration versionada e idempotente (`SettingsMigration.v11`, `dbVersion: 11`).
- [x] Consumidores acessam políticas por use case, não por storage direto nem bool hardcoded em `app_entry`.
- [x] UI acessível (>=48dp, `#115E59`, `StatelessWidget` por padrão, estado reativo Kortex).
- [x] D2 implementado: `require_receiver_document` default `false` (minimização); quando habilitado, o fluxo falha fail-closed enquanto D-01 não protege o documento.
- [x] `require_checklist_template` default `true` (política C, D-05) configurável.
- [x] `flutter analyze --fatal-infos` e `flutter test` com exit code 0 (`202 passed`).
- [ ] Gate 4 formal do épico (G2.5 aprovado com condicionantes; G3 aprovado com ressalvas; ressalvas de follow-up registradas).

### 3.1 Status de Execução (2026-11-22)

- **UC-07.01 (concluído)**: `SettingKey`, `SettingsSnapshot`, `ISettingsRepositoryPort`, `SettingsSqliteRepository`, `MemorySettingsRepository`, `GetSettings`, `UpdateSetting` e `SettingsMigration.v11` entregues; `app_database` em `dbVersion: 11`; 10 testes do módulo verdes. Decisão em [ADR-003](../../architecture/adr-003-settings-locais-tipadas.md).
- **UC-07.02 (concluído)**: `SettingsController` (Kortex), `SettingsPage` (`SwitchListTile` >=48dp, `KortexListener` + `AppFeedback`), `SettingsRoutes` e entrada na Home; `AppDependencies`/`ServiceTrackApp`/`main.dart` injetam `ISettingsRepositoryPort` (SQLite no app real, memória no fallback). 4 testes de UI/controller verdes.
- **UC-07.03 (concluído)**: `GetSettings` é a fonte única no `WorkOrderListController`; políticas lidas por operação; `require_checklist_template` alimenta a prova real; `require_receiver_document` valida documento e falha fail-closed com `ERR_ASSINATURA_DOCUMENTO_PROTECAO_INDISPONIVEL` enquanto D-01 estiver aberto; UI não coleta documento nesse estado. Gate 2.5 **INVOKED — aprovado com condicionantes (Média)**, SEC-01..SEC-08; invariantes INV-SEC-28..32. 4 testes nomeados de política/segurança + 1 widget test de não-coleta; suíte **202 verdes**. Gate 3 aprovado com ressalvas; Gate 4 pendente.

---

## 4. Casos de Uso Atômicos

### Caso de Uso UC-07.01 — Fundação do Módulo de Configurações Locais

* **Identificador**: `UC-07.01`
* **Status**: `Concluído (código+testes)`
* **Gate 2.5**: `PULADO — sem superfície sensível nova, sem PII, sem nova dependência; persistência local SQLite padrão do projeto`.
* **Gate DoR**: `tools/bin/claims claim -path . -slice UC-07.01 -owner <agente> -paths lib/modules/settings,...`
* **Gate DoD**: `tools/bin/claims release -path . -slice UC-07.01`

#### Narrativa
- **Como** técnico autônomo
- **Eu quero** que o app tenha configurações locais tipadas com defaults seguros
- **Para que** políticas de operação sejam consistentes e evoluam sem espalhar flags hardcoded.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Cenário: Carregar configurações padrão no primeiro acesso
  Dado que o app não possui configurações persistidas
  Quando o módulo de configurações é inicializado
  Então retorna Result.Ok com defaults tipados
  E require_checklist_template = true
  E require_receiver_document = false

Esquema do Cenário: Atualizar política tipada
  Dado que o catálogo contém a chave <chave>
  Quando o técnico atualiza o valor para <valor>
  Então o sistema persiste e retorna <resultado>

  Exemplos:
    | chave | valor | resultado |
    | "require_checklist_template" | false | "Result.Ok(SettingsSnapshot)" |
    | "require_receiver_document" | true | "Result.Ok(SettingsSnapshot)" |
    | "chave_inexistente" | true | "Result.Fail(ERR_CONFIGURACAO_CHAVE_INVALIDA)" |
```

#### NFRs Mensuráveis
| NFR | Métrica | Target | Medição |
| :--- | :--- | :--- | :--- |
| Leitura local | Tempo de leitura SQLite | `< 50 ms` | Teste de repositório SQLite em memória |
| Tipagem | Chaves fora do catálogo | `0` uso em UI/consumidor | Revisão/gate + teste de chave inválida |

#### Tarefas Técnicas
1. `TASK-01`: Criar `lib/modules/settings/domain/` com catálogo tipado (`SettingKey`/enum ou VO), `SettingsSnapshot`, falhas tipadas e porta `ISettingsRepositoryPort`.
2. `TASK-02`: Criar `lib/modules/settings/data/` com `SettingsSqliteRepository` + migration versionada (tabela key/value tipada ou colunas explícitas; decisão no slice com justificativa).
3. `TASK-03`: Criar `lib/modules/settings/features/` com `GetSettings`/`UpdateSetting` (ou equivalente) retornando `Result<T>`.
4. `TASK-04`: Testes unitários domínio + integração SQLite (defaults, update, chave inválida, idempotência migration).

#### Impacto & Arquivos Alvo
- `lib/modules/settings/**` [NEW]
- `test/modules/settings/**` [NEW]
- `docs/plan/epics/epic-07-configuracoes-politicas.md` [MODIFY]

---

### Caso de Uso UC-07.02 — UI de Configurações Locais

* **Identificador**: `UC-07.02`
* **Status**: `Concluído (código+testes)`
* **Dependência**: UC-07.01
* **Gate 2.5**: `PULADO — UI consome use cases; não coleta PII nova; exibe/edita flags de política já definidas (D2 decidido)`.
* **Gate DoR**: `tools/bin/claims claim -path . -slice UC-07.02 -owner <agente> -paths lib/modules/settings/ui,...`
* **Gate DoD**: `tools/bin/claims release -path . -slice UC-07.02`

#### Narrativa
- **Como** técnico autônomo
- **Eu quero** acessar e ajustar configurações do app em um local único
- **Para que** configurar políticas operacionais sem depender de suporte ou código.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Cenário: Exibir configurações com defaults
  Dado que o técnico abre a tela de Configurações
  Quando o módulo carrega o snapshot
  Então exibe toggles com estado atual
  E alvos táteis possuem >= 48dp
  E a tela usa Kortex/StatelessWidget por padrão

Cenário: Alterar política pela UI
  Dado que o técnico altera "Exigir checklist na conclusão"
  Quando confirma a alteração
  Então o sistema persiste via use case
  E exibe feedback de sucesso/falha com AppFeedback
```

#### NFRs / Acessibilidade
- Alvos táteis `>= 48dp`; contraste/tema `#115E59`.
- Sem `setState` para estado de tela; Kortex.
- Sem string mágica de chave na UI (usa catálogo/tipos).

#### Tarefas Técnicas
1. `TASK-01`: Criar `lib/modules/settings/ui/` (controller Kortex, page StatelessWidget, widgets).
2. `TASK-02`: Integrar navegação/entrada em configurações (ponto de acesso a definir no slice, sem espalhar regra).
3. `TASK-03`: Testes de widget/controller para renderização, toggle e feedback.

#### Impacto & Arquivos Alvo
- `lib/modules/settings/ui/**` [NEW]
- `lib/app/app_entry.dart` [MODIFY] (injeção/navegação, se necessário)
- `test/modules/settings/ui/**` [NEW]

---

### Caso de Uso UC-07.03 — Integração de Políticas de Conclusão/Evidência

* **Identificador**: `UC-07.03`
* **Status**: `Concluído (código+testes; G2.5 aprovado com condicionantes; G3/G4 pendentes)`
* **Dependência**: UC-07.01, UC-07.02, ADR-001 D2
* **Gate 2.5**: `INVOKED — D2 toca PII/LGPD (documento do recebedor). Respeitar C-01/D-01 (sem persistência de documento em claro; fail-closed se habilitado sem proteção), minimização (default false), redaction, sem log de documento. Checklist policy não é PII.`

#### Narrativa
- **Como** responsável pelo uso do app
- **Eu quero** que as políticas de checklist e documento do recebedor sejam lidas de configurações
- **Para que** o comportamento de conclusão da OS reflita a política configurada, com segurança por padrão.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Esquema do Cenário: Exigência de documento por política configurada
  Dado que a política "require_receiver_document" está <estado>
  E a proteção de repouso D-01 está <d01>
  Quando o técnico conclui OS com assinatura e documento <doc>
  Então o resultado deve ser <resultado>

  Exemplos:
    | estado | d01 | doc | resultado |
    | "DESABILITADA" | "NAO_APLICA" | "" | "Result.Ok (documento opcional)" |
    | "HABILITADA" | "INDISPONIVEL" | "12345678909" | "Result.Fail(ERR_ASSINATURA_DOCUMENTO_PROTECAO_INDISPONIVEL)" |
    | "HABILITADA" | "DISPONIVEL" | "" | "Result.Fail(ERR_ASSINANTE_DOCUMENTO_OBRIGATORIO)" |
    | "HABILITADA" | "DISPONIVEL" | "12345678909" | "Result.Ok" |

Esquema do Cenário: Exigência de checklist por política configurada
  Dado que a política "require_checklist_template" está <estado>
  Quando o técnico conclui OS sem template/checklist exigido
  Então o resultado deve ser <resultado>

  Exemplos:
    | estado | resultado |
    | "HABILITADA" | "Result.Fail(ERR_CHECKLIST_TEMPLATE_OBRIGATORIO)" |
    | "DESABILITADA" | "Result.Ok (se demais invariantes ok)" |
```

#### NFRs / Segurança
- Gate 2.5 obrigatório antes do coder (PII/LGPD/D2).
- Não persistir `documentNumber` em claro (C-01/D-01); guard fail-closed existente deve permanecer.
- Sem log/telemetria de documento; `toString` redigido (já coberto em VO canônico).
- Remover bools hardcoded de `app_entry/service_track_app/work_order_list_controller` em favor de leitura por porta/use case (ou provider de settings injetado).

#### Tarefas Técnicas
1. `TASK-01`: Usar `GetSettings` como fonte única de política no consumidor (menor acoplamento que porta dedicada; SEC-01).
2. `TASK-02`: Adaptar `app_entry.dart`, `service_track_app.dart`, `work_order_list_controller/page` para consumir política configurada; manter defaults seguros.
3. `TASK-03`: Garantir comportamento D-01 fail-closed quando `require_receiver_document=true` e proteção indisponível.
4. `TASK-04`: Testes de integração/controle cobrindo matriz D2 + checklist policy + D-01 guard; regressão dos testes existentes.

#### Impacto & Arquivos Alvo
- `lib/modules/settings/**` [MODIFY]
- `lib/modules/work_orders/domain/value_objects/document_protection.dart` [NEW]
- `lib/app/app_entry.dart` [MODIFY]
- `lib/app/service_track_app.dart` [MODIFY]
- `lib/app/app_dependencies.dart` [MODIFY]
- `lib/app/home_page.dart` [MODIFY]
- `lib/app/database/app_database.dart` [MODIFY]
- `lib/main.dart` [MODIFY]
- `lib/modules/work_orders/ui/list/work_order_list_controller.dart` [MODIFY]
- `lib/modules/work_orders/ui/list/work_order_list_page.dart` [MODIFY]
- `lib/modules/work_orders/ui/work_orders_routes.dart` [MODIFY]
- `test/modules/settings/**` [MODIFY/NEW]
- `test/modules/work_orders/**` [MODIFY]

---

## 5. Riscos & Dependências

| Risco | Prob. | Impacto | Mitigação |
| :--- | :--- | :--- | :--- |
| Configuração virar “god module” | Média | Médio | Catálogo tipado, UCs pequenos, ports claros, sem storage direto no consumidor. |
| PII em política de documento (D2) | Alta | Alto | Gate 2.5 no UC-07.03; minimização default false; C-01/D-01 fail-closed; redaction. |
| Colisão com profile/auth | Baixa | Médio | Separar: credenciais (auth), perfil comercial (profile), políticas (settings). |
| Habilitar documento sem D-01 | Média | Alto | Guard fail-closed já existente; UI deve sinalizar restrição; teste de regressão. |
| Mudança em wiring quebrar fluxo de conclusão | Média | Médio | Testes existentes de work order/checklist como rede de segurança; integração por slice. |

## 6. Observações de Planejamento

- **Defaults canônicos**: `require_checklist_template=true` (D-05/política C), `require_receiver_document=false` (D2/minimização).
- **D-01**: enquanto aberto, persistir `documentNumber` em claro é proibido; política pode ser configurada, mas a efetivação com persistência depende de proteção em repouso.
- **Ordem sugerida**: UC-07.01 → UC-07.02 → G2.5 UC-07.03 → UC-07.03.
- **Claim paths**: definir paths por UC no DoR (não pré-reivindicar `lib/app/**` inteiro; expandir por arquivos existentes).
