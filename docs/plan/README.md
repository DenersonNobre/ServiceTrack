# Plano Mestre de Implementação — ServiceTrack (Mobile Standalone)

> **Responsável do Plano (DevOps / Arch)**: Denerson Nobre  
> **Status Geral**: `Em Execução (EPIC-00/01/02/03 Concluídos; EPIC-04 implementado/E2E device pendente; EPIC-06 em andamento; EPIC-07 fatiado)`
>
> **Arquitetura**: Flutter 100% Autocontido (Zero Backend / Zero Infraestrutura de Nuvem)  
> **Referências**: [PRD](../product/PRD.md) \| [SPEC](../architecture/SPEC.md) \| [DESIGN](../architecture/DESIGN.md)

---

## 1. Relação de Épicos Fatiados & Matriz de Status

| Épico | Arquivo | Dependências | Prioridade | Status |
| :--- | :--- | :--- | :---: | :---: |
| **00 — Fundação Flutter** | [epic-00-fundacao.md](epics/epic-00-fundacao.md) | Nenhuma (Alicerce Técnico) | Crítica | `Concluído` |
| **01 — Onboarding, Auth Local & Perfil** | [epic-01-auth-perfil.md](epics/epic-01-auth-perfil.md) | EPIC00 | Alta | `Concluído` |
| **02 — Gestão Local de Clientes** | [epic-02-clientes.md](epics/epic-02-clientes.md) | EPIC00, EPIC01 | Alta | `Concluído` |
| **03 — Ordens de Serviço & Ciclo de Vida** | [epic-03-ordens-servico.md](epics/epic-03-ordens-servico.md) | EPIC00, EPIC02 | Alta | `Concluído` |
| **04 — Checklists, Câmera & Evidências GPS** | [epic-04-checklists-evidencias.md](epics/epic-04-checklists-evidencias.md) | EPIC00, EPIC03, EPIC07 (D2/política/defaults) | Alta | `Implementado (E2E device pendente)` |
| **05 — Motor de Laudo PDF & Compartilhamento** | [epic-05-laudo-pdf-share.md](epics/epic-05-laudo-pdf-share.md) | EPIC00, EPIC03, EPIC04 | Crítica (Core) | `Bloqueado` |
| **06 — Hardening Técnico & Qualidade Transversal** | [epic-06-hardening-qualidade.md](epics/epic-06-hardening-qualidade.md) | EPIC00, EPIC03 | Média | `Em Andamento` |
| **07 — Configurações & Políticas Locais** | [epic-07-configuracoes-politicas.md](epics/epic-07-configuracoes-politicas.md) | EPIC00, EPIC01 | Média | `Planejado (fatiado)` |

---

## 2. DAG de Precedência (Mermaid)

```mermaid
graph TD
    classDef foundation fill:#115E59,stroke:#0D524D,color:#fff;
    classDef core fill:#0284C7,stroke:#0369A1,color:#fff;
    classDef ready fill:#D97706,stroke:#B45309,color:#fff;
    classDef blocked fill:#F4F4F5,stroke:#D4D4D8,color:#71717A;

    EPIC00["EPIC-00: Fundação Flutter & Toolchain"]:::foundation
    EPIC01["EPIC-01: Onboarding, Auth Local & Perfil"]:::foundation
    EPIC02["EPIC-02: Gestão Local de Clientes (SQLite/dnolib)"]:::foundation
    EPIC03["EPIC-03: Ordens de Serviço & Ciclo de Estados"]:::ready
    EPIC04["EPIC-04: Checklists Rápidos & Evidências com GPS"]:::ready
    EPIC05["EPIC-05: Geração On-Device de Laudo PDF & Envio WhatsApp"]:::core
    EPIC06["EPIC-06: Hardening Técnico & Qualidade Transversal"]:::ready
    EPIC07["EPIC-07: Configurações & Políticas Locais"]:::blocked

    EPIC00 --> EPIC01
    EPIC01 --> EPIC02
    EPIC02 --> EPIC03
    EPIC03 --> EPIC04
    EPIC03 --> EPIC05
    EPIC04 --> EPIC05
    EPIC03 --> EPIC06
    EPIC01 --> EPIC07
    EPIC07 --> EPIC04
```

---

## 3. Ordem Canônica de Execução (Core-First & Risk-First)

1. **EPIC00 (Fundação Flutter)**: Configurar projeto Flutter, design tokens do Styleguide v2.1, scripts de teste headless e shims de claim.
2. **EPIC01 (Onboarding & Auth Local)**: Primeiro acesso do técnico, cadastro de perfil e cofre seguro de Biometria/PIN.
3. **EPIC02 (Clientes)**: Estrutura cadastral local com SQLite via `dnolib/sqlite` e validações `brlib`.
4. **EPIC03 (Ordens de Serviço)**: Motor da máquina de estados (`SCHEDULED` -> `IN_PROGRESS` -> `COMPLETED`).
5. **EPIC07 (Configurações & Políticas Locais)**: Módulo dedicado para políticas/configurações tipadas (inclui D2 documento do recebedor por política/configuração).
6. **EPIC04 (Checklists & Fotos + Reconciliação D-05)**: Implementado em código/testes (UC-04.01–04.08, D-05 mitigado, assinatura canônica). Pendência: validação E2E em device/emulador.
7. **EPIC06 (Hardening Técnico & Qualidade)**: Em andamento — FailureCodes/AppFeedback parciais e `UC-06.05` (AppDependencies + `*Routes` + `appScopedRoute`, shell enxuto) com T1 Auth/T2 WorkOrders em paralelo e T3 integração serial.
8. **EPIC05 (Laudo PDF & WhatsApp)**: Núcleo de maior valor perceptível (laudo executivo on-device e compartilhamento com 1 toque), consumindo dados reais consolidados.
