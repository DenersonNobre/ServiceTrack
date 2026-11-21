# Épico 05: Geração On-Device de Laudo Técnico em PDF & Compartilhamento

## Metadados

| Atributo | Valor |
| :--- | :--- |
| **Identificador** | `EPIC05` |
| **Dependências Diretas** | `EPIC00`, `EPIC03`, `EPIC04` |
| **Prioridade** | Crítica (Core de Valor do Produto Standalone) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Não Iniciado` |
| **Referências da SPEC** | [docs/architecture/SPEC.md](../../architecture/SPEC.md) \| [docs/architecture/DESIGN.md](../../architecture/DESIGN.md) |

---

## 1. Objetivo de Negócio & Escopo

Compilar o Laudo Técnico em PDF no próprio smartphone em menos de 2 segundos utilizando o pacote nativo `pdf` (sem internet e sem servidores), aplicando rigorosamente o Styleguide v2.1 (*Deep Petrol Green* `#115E59`, dados do técnico no cabeçalho, checklist estruturado, fotos nítidas e assinaturas digitais), com compartilhamento imediato via WhatsApp, E-mail ou impressão.

- **Incluso**:
  - `UC-05.01`: Motor de Renderização de PDF On-Device via Isolate (Layout executivo profissional).
  - `UC-05.02`: Preview / Visualizador de PDF integrado ao aplicativo.
  - `UC-05.03`: Disparo da Folha de Compartilhamento Nativa do SO (`package:share_plus`) direto para o WhatsApp do cliente com mensagem pré-formatada.
  - `UC-05.04`: Exportação e Armazenamento Local do Laudo no histórico da visita.
- **Não Incluso**:
  - Envio por servidor de e-mail SMTP em nuvem no MVP.

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| :--- | :--- | :--- | :---: |
| **UC-05.01** | Motor de Compilação do PDF On-Device | Nenhuma | `Pendente` |
| **UC-05.02** | Visualização & Preview do Laudo no App | UC-05.01 | `Pendente` |
| **UC-05.03** | Compartilhamento Nativo com 1 Toque (WhatsApp) | UC-05.01, UC-05.02 | `Pendente` |
| **UC-05.04** | Histórico e Reemissão de Laudos Salvos | UC-05.01 | `Pendente` |

---

## 3. Definição de Pronto (DoD) do Épico

- [ ] PDF gerado em menos de 2.0s sem travar a interface (Isolate validado).
- [ ] Teste automatizado gerando o binário do PDF e confirmando integridade binária.
- [ ] Integração com `share_plus` testada com sucesso.
