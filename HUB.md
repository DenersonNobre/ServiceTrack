---
tags:
  - hub
  - servicetrack
  - arquitetura
---

# 🛠️ ServiceTrack — Hub de Controle & Conhecimento

> **Visão**: Aplicativo Flutter 100% Standalone (Local-First) para técnicos de campo e prestadores autônomos.  
> **Status**: `Fundação Concluída (EPIC-00)` | **Próximo**: `EPIC-01: Onboarding & Auth`

---

## 🧭 Mapa de Navegação (Quarteto Canônico)

```
                     ┌───────────────────────┐
                     │      PRD (Produto)    │
                     └──────────┬────────────┘
                                │
        ┌───────────────────────┴───────────────────────┐
        ▼                                               ▼
┌───────────────────────┐                       ┌───────────────────────┐
│     SPEC (Domínio)    │                       │     DESIGN (Visual)   │
└──────────┬────────────┘                       └───────────┬───────────┘
           │                                                │
           └────────────────────┬───────────────────────────┘
                                ▼
                     ┌───────────────────────┐
                     │   README (Plano/DAG)  │
                     └───────────────────────┘
```

- 🎯 [[docs/product/PRD|PRD — Requisitos de Produto (v2.0.0)]]: Personas, jornada do técnico Rodrigo, RNF-05 (Portrait-only para celulares, Landscape Master-Detail para tablets).
- 📐 [[docs/architecture/SPEC|SPEC — Especificação de Domínio]]: Regras executáveis (`RN-01..06`), Invariantes `INV-01..06`, entidades `WorkOrder`, `GeoPoint`, `kortex` e `dnolib`.
- 🎨 [[docs/architecture/DESIGN|DESIGN — Styleguide & Tokens]]: Identidade *Deep Petrol Green* (`#115E59`), matriz de elevação (Shadow 1..4), botões táteis (>=48dp) e contrato do Laudo PDF.
- 🗺️ [[docs/plan/README|Plano Mestre & Backlog]]: Grafo de precedência (DAG), DoR, DoD e matriz de épicos.

---

## ⚡ Épicos de Implementação

- ✅ [[docs/plan/epics/epic-00-fundacao|EPIC-00: Fundação Flutter & Toolchain]] `(Concluído - Commit c65dbc9)`
- ⏳ [[docs/plan/epics/epic-01-auth-perfil|EPIC-01: Onboarding, Autenticação Local & Perfil]] `(Pronto para Iniciar)`
  - [[docs/plan/epics/epic-01-auth-perfil#caso-de-uso-uc-0101--onboarding-inicial--registro-de-credenciais|UC-01.01: Onboarding Inicial & Credenciais]]
  - [[docs/plan/epics/epic-01-auth-perfil#caso-de-uso-uc-0102--autenticacao-por-biometria--lembrar-de-mim|UC-01.02: Biometria & "Lembrar de Mim"]]
  - [[docs/plan/epics/epic-01-auth-perfil#caso-de-uso-uc-0103--desbloqueio-rapido-via-teclado-de-pin-numerico|UC-01.03: Teclado de PIN Numérico de Campo]]
  - [[docs/plan/epics/epic-01-auth-perfil#caso-de-uso-uc-0104--recuperacao-de-acesso-local--fallback-do-so|UC-01.04: Recuperação de Acesso Local]]
  - [[docs/plan/epics/epic-01-auth-perfil#caso-de-uso-uc-0105--edicao-de-perfil-comercial-do-tecnico|UC-01.05: Perfil Comercial do Técnico]]

---

## 📊 Governança em Tempo Real

- 📌 [[CHECKPOINT|CHECKPOINT Atual]]: Estado verificado, travas ativas e próximo passo.
- 📓 [[LEARNINGS|LEARNINGS (Diário Técnico)]]: Lições aprendidas da stack, Puro (`v3-47-6`), SQLite e Kortex.
- 🤖 [[AGENTS|AGENTS.md]]: Contexto para agentes de IA com mandatos e regras de conduta.

---

## 💡 Dicas para o Obsidian
- Pressione `Ctrl + G` (ou abra a aba **Graph View**) para ver todos os documentos conectados como uma teia interativa!
- Utilize o modo **Reading View** para renderização impecável das tabelas, diagramas Mermaid e alertas semânticos.
