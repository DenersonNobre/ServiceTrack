# Épico 03: Ordens de Serviço & Ciclo de Vida da Visita Técnica

## Metadados

| Atributo | Valor |
| :--- | :--- |
| **Identificador** | `EPIC03` |
| **Dependências Diretas** | `EPIC00`, `EPIC01`, `EPIC02` |
| **Prioridade** | Alta (Agregado Central de Negócio) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Concluído` |
| **Referências da SPEC** | [docs/architecture/SPEC.md](../../architecture/SPEC.md) \| [docs/product/PRD.md](../../product/PRD.md) |

---

## 1. Objetivo de Negócio & Escopo

Governar a criação, agendamento e transições da Ordem de Serviço (`WorkOrder`), aplicando a máquina de estados estrita (`SCHEDULED` -> `IN_PROGRESS` -> `COMPLETED`/`CANCELLED`) com registro pontual de Check-in/Check-out e cálculo de duração do atendimento.

- **Incluso**:
  - `UC-03.01`: Criação Rápida de Ordem de Serviço (Seleção de Cliente, Descrição do Serviço, Data/Hora e Valor Estimado com `kortex_lib` Money).
  - `UC-03.02`: Agenda & Lista de Visitas (Filtros por chip: Hoje, Agendadas, Em Andamento, Concluídas).
  - `UC-03.03`: Início do Atendimento (Check-in pontual com captura de geolocalização `GeoPoint` e transição para `IN_PROGRESS`).
  - `UC-03.04`: Pausa e Cancelamento com Justificativa Obrigatória (pausa/retomada sem GPS, por ora; motivo obrigatório na pausa/cancelamento).
  - `UC-03.05`: Trava de Imutabilidade e Conclusão (`INV-01`, `INV-06`).
- **Não Incluso**:
  - Telemetria de rastreamento contínuo de rota em background.

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| :--- | :--- | :--- | :---: |
| **UC-03.01** | Criação Rápida de Ordem de Serviço | Nenhuma | `Concluído` |
| **UC-03.02** | Painel de Visitas & Filtros Rápidos | UC-03.01 | `Concluído` |
| **UC-03.03** | Check-in de Atendimento & Georreferenciamento | UC-03.01, UC-03.02 | `Concluído` |
| **UC-03.04** | Pausa e Cancelamento com Justificativa | UC-03.01 | `Concluído` |
| **UC-03.05** | Fechamento e Travamento Imutável da OS | UC-03.03 | `Concluído` |

---

## 3. Definição de Pronto (DoD) do Épico

- [ ] Agregado `WorkOrder` aplicando invariantes `INV-01` e `INV-06`.
- [ ] Transições ilegais rejeitadas via `Result.Fail(ERR_OS_TRANSICAO_INVALIDA)`.
- [ ] Telas construídas com `kortex` e cards com tokens do Styleguide v2.1.
- [ ] Testes unitários de máquina de estados 100% verdes.
