# Épico 07: Configurações & Políticas Locais

## Metadados

| Atributo | Valor |
| :--- | :--- |
| **Identificador** | `EPIC07` |
| **Dependências Diretas** | `EPIC00` (fundação), `EPIC01` (perfil/auth local) |
| **Prioridade** | Média (habilita políticas transversais; D2/ADR-001) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Planejado` |
| **Referências** | [ADR-001](../../architecture/adr-001-assinatura-digital-canonica.md) \| [SPEC](../../architecture/SPEC.md) \| [DESIGN](../../architecture/DESIGN.md) |

---

## 1. Objetivo de Negócio & Escopo

Centralizar configurações e políticas locais do app em módulo dedicado, evitando flags espalhadas em `profile`, `auth` ou regras hardcoded em fluxos de negócio.

- **Incluso**:
  - `UC-07.01`: Fundação do módulo de configurações (persistência local tipada, porta, UI de configurações).
  - `UC-07.02`: Política de documento do recebedor na assinatura (D2/ADR-001): obrigatório por política/configuração, default seguro/minimização.
  - `UC-07.03`: Preferências operacionais locais (base para futuros toggles: backup/export, compliance), com catálogo extensível.
- **Não Incluso**:
  - Sincronização remota de configurações.
  - Gestão de credenciais/cofre (EPIC-01).
  - Dados comerciais do técnico (EPIC-01/Profile).

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| :--- | :--- | :--- | :---: |
| **UC-07.01** | Fundação do Módulo de Configurações Locais | Nenhuma | `Pendente` |
| **UC-07.02** | Política de Documento do Recebedor (D2) | UC-07.01 | `Pendente` |
| **UC-07.03** | Catálogo Extensível de Preferências Locais | UC-07.01 | `Pendente` |

---

## 3. Definição de Pronto (DoD) do Épico

- [ ] Configurações persistidas localmente com tipagem/validação (sem strings mágicas de chave fora de catálogo).
- [ ] UI acessível (>=48dp, #115E59, Stateless/Kortex).
- [ ] Consumidores acessam políticas por porta/use case, não por storage direto.
- [ ] D2 implementado com default seguro (minimização) e comportamento fail-closed quando política exigir documento.
- [ ] `flutter analyze --fatal-infos` e `flutter test` com exit code 0.
- [ ] Gates 2.5/3/4 conforme sensibilidade (D2 toca PII/LGPD).

---

## 4. Casos de Uso Atômicos

### Caso de Uso UC-07.01 — Fundação do Módulo de Configurações Locais

* **Identificador**: `UC-07.01`
* **Status**: `Pendente`

#### Narrativa
- **Como** técnico autônomo
- **Eu quero** acessar configurações do app em um local único
- **Para que** ajustar políticas/comportamentos sem depender de suporte ou código.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Cenário: Carregar configurações padrão no primeiro acesso
  Dado que o app não possui configurações persistidas
  Quando o módulo de configurações é inicializado
  Então retorna Result.Ok com defaults tipados
  E não expõe chaves mágicas na UI
```

#### Tarefas Técnicas
1. `TASK-01`: Criar `lib/modules/settings/` (domain/data/features/ui) com `ISettingsRepositoryPort`.
2. `TASK-02`: Persistência SQLite (`dnolib/sqlite`) ou storage local tipado; migration.
3. `TASK-03`: UI Kortex com lista de configurações e acessibilidade.

---

### Caso de Uso UC-07.02 — Política de Documento do Recebedor (D2)

* **Identificador**: `UC-07.02`
* **Status**: `Pendente`
* **Dependência**: UC-07.01, ADR-001

#### Narrativa
- **Como** responsável pelo uso do app
- **Eu quero** configurar se o documento do recebedor é obrigatório na assinatura
- **Para que** adequar a coleta de PII à política do meu contexto.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Esquema do Cenário: Exigência de documento por política
  Dado que a política "require_receiver_document" está <estado>
  Quando o técnico conclui assinatura com documento <doc>
  Então o resultado deve ser <resultado>

  Exemplos:
    | estado | doc | resultado |
    | "DESABILITADA" | "" | "Result.Ok (documento opcional)" |
    | "HABILITADA" | "" | "Result.Fail(ERR_ASSINANTE_DOCUMENTO_OBRIGATORIO)" |
    | "HABILITADA" | "12345678909" | "Result.Ok" |
```

#### NFRs / Segurança
- Gate 2.5 obrigatório (PII/LGPD): default seguro/minimização, redaction, sem log de documento.
- Alinhar com C-01..C-07/C-11 da ADR-001.

---

### Caso de Uso UC-07.03 — Catálogo Extensível de Preferências Locais

* **Identificador**: `UC-07.03`
* **Status**: `Pendente`
* **Dependência**: UC-07.01

#### Narrativa
- **Como** mantenedor
- **Eu quero** um catálogo tipado de preferências
- **Para que** adicionar novas políticas sem espalhar chaves/booleans mágicos.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Cenário: Preferência desconhecida falha de forma segura
  Dado que uma chave de configuração não está no catálogo
  Quando o sistema tenta lê-la
  Então retorna Result.Fail tipado ou default explícito documentado
  E não usa string mágica fora do catálogo
```

## 5. Riscos & Dependências

| Risco | Prob. | Impacto | Mitigação |
| :--- | :--- | :--- | :--- |
| Configuração virar “god module” | Média | Médio | Catálogo tipado, UCs pequenos, ports claros. |
| PII em política de documento (D2) | Alta | Alto | Gate 2.5, minimização, redaction, default seguro. |
| Colisão com profile/auth | Baixa | Médio | Separar claramente: credenciais (auth), perfil comercial (profile), políticas (settings). |
