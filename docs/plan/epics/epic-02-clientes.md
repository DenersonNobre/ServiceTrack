# Épico 02: Gestão Local de Clientes & Locais (SQLite / dnolib)

## Metadados

| Atributo | Valor |
| :--- | :--- |
| **Identificador** | `EPIC02` |
| **Dependências Diretas** | `EPIC00`, `EPIC01` |
| **Prioridade** | Alta (Base Cadastral para OSs) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Concluído` |
| **Referências da SPEC** | [docs/architecture/SPEC.md](../../architecture/SPEC.md) \| [docs/product/PRD.md](../../product/PRD.md) |

---

## 1. Objetivo de Negócio & Escopo

Permitir que o técnico cadastre, consulte, edite e organize sua carteira de clientes e locais de atendimento diretamente no smartphone, com armazenamento SQLite local via `dnolib/sqlite` e validações brasileiras com `dnolib/brlib` (CPF/CNPJ, CEP e WhatsApp).

- **Incluso**:
  - `UC-02.01`: Cadastro e Edição de Cliente (Nome/Razão Social, CPF/CNPJ com validação `brlib`, WhatsApp/Telefone, E-mail e Observações).
  - `UC-02.02`: Cadastro de Locais de Atendimento / Endereços vinculados ao cliente (Logradouro, Bairro, Cidade, CEP e Ponto de Referência).
  - `UC-02.03`: Listagem e Busca Rápida de Clientes com filtro em tempo real (`KortexSignal`).
  - `UC-02.04`: Visualização de Detalhes do Cliente com Histórico de Ordens de Serviço emitidas.
- **Não Incluso**:
  - Sincronização multi-dispositivo ou importação via planilhas remotas no MVP.

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| :--- | :--- | :--- | :---: |
| **UC-02.01** | Cadastro e Edição de Cliente com Validação `brlib` | Nenhuma | `Concluído` |
| **UC-02.02** | Gestão de Endereços e Locais de Atendimento | UC-02.01 | `Concluído` |
| **UC-02.03** | Busca Rápida Tátil de Clientes | UC-02.01 | `Concluído` |
| **UC-02.04** | Histórico e Detalhes do Cliente | UC-02.01, UC-02.03 | `Concluído` |

---

## 3. Definição de Pronto (DoD) do Épico

- [x] Entidades de domínio `Customer` e `ServiceLocation` puras com testes unitários.
- [x] Validação de CPF/CNPJ via `dnolib/brlib` sem exceções.
- [x] Tabela SQLite criada com índices para busca por nome e documento.
- [x] Controllers reativos implementados com `kortex` (`KortexSignal`, `IKortexPage`).
- [x] Suíte de testes unitários e de widgets 100% verde com exit code 0.
