# Épico 04: Checklists Rápidos, Fotos & Evidências Georreferenciadas

## Metadados

| Atributo | Valor |
| :--- | :--- |
| **Identificador** | `EPIC04` |
| **Dependências Diretas** | `EPIC00`, `EPIC03` |
| **Prioridade** | Alta (Comprovação Técnica & Auditabilidade) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Não Iniciado` |
| **Referências da SPEC** | [docs/architecture/SPEC.md](../../architecture/SPEC.md) \| [docs/architecture/DESIGN.md](../../architecture/DESIGN.md) |

---

## 1. Objetivo de Negócio & Escopo

Permitir o preenchimento de itens de checklist de forma ágil em campo com o polegar, captura de fotos com compressão local compulsória (máx. 6 fotos, < 400KB cada), gravação de metadados de auditoria (data/hora e coordenadas) e coleta de assinatura digital na tela.

- **Incluso**:
  - `UC-04.01`: Templates de Checklists Reutilizáveis (Instalação, Manutenção, Vistoria).
  - `UC-04.02`: Execução de Checklist Tri-Estado (`[Conforme]`, `[Não Conforme]`, `[Não se Aplica]`) com alvos táteis de 48dp.
  - `UC-04.03`: Captura e Compressão Local de Fotos com marca d'água de auditoria (`INV-04`).
  - `UC-04.04`: Coleta de Assinatura Digital do Cliente em Canvas (`SignaturePadWidget`) com Nome e CPF/RG.
- **Não Incluso**:
  - Gravação de vídeo ou upload em nuvem.

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| :--- | :--- | :--- | :---: |
| **UC-04.01** | Modelos de Checklists Rápidos | Nenhuma | `Pendente` |
| **UC-04.02** | Preenchimento Tátil do Checklist na OS | UC-04.01 | `Pendente` |
| **UC-04.03** | Captura & Compressão de Fotos com Metadados | Nenhuma | `Pendente` |
| **UC-04.04** | Assinatura Digital na Tela do Smartphone | Nenhuma | `Pendente` |

---

## 3. Definição de Pronto (DoD) do Épico

- [ ] Invariantes `INV-03` (completude obrigatória) e `INV-04` (cota de 6 fotos) cobertos por testes.
- [ ] Compressão de imagem executando em Isolate em segundo plano.
- [ ] Coleta de assinatura rasterizada e vinculada à OS.
