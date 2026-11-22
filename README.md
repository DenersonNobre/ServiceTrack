# ServiceTrack

> **Gestão Inteligente e Confiável de Visitas Técnicas (Mobile Standalone)**  
> **Status**: `Fase de Fundação Concluída (EPIC-00)` | **Versão**: `0.1.0+1`

Aplicativo Flutter 100% local e autocontido (sem backend / zero custos de nuvem) desenhado para técnicos autônomos e pequenos prestadores de serviços. Permite cadastrar clientes, preencher checklists com o polegar, capturar fotos auditáveis com GPS e gerar laudos técnicos em PDF de padrão executivo prontos para envio instantâneo via WhatsApp.

---

## 1. Stack & Fundações Canônicas

- **Framework**: Flutter 3.47.6+ (Dart 3.13.5+)
- **Shared Kernel & Reatividade**:
  - `kortex`: Gerenciamento de estado fino por Signals (`KortexSignal`, `KortexWatch`) e injeção com escopo determinístico (`KortexScope`).
  - `dnolib`: Utilitários e infraestrutura compartilhada (validação de CPF/CNPJ, formatação de telefone, sqlite, widgets; exceto synapx).
- **Composição & Navegação**: `AppDependencies` (composition root) + `*Routes` por módulo usando `appScopedRoute`; `AppEntry` só gate/lifecycle/dispatch. Ver [ADR-002](docs/architecture/adr-002-app-shell-di-route-bindings.md).
- **Persistência Local**: SQLite tipado via `sqflite` / `sqflite_common_ffi`.
- **Cofre Seguro**: `flutter_secure_storage` & `local_auth` (Biometria / PIN).
- **Mídia & Laudos**: `image`, `geolocator`, `signature`, `pdf` e `share_plus`.

---

## 2. Comandos de 1 Linha (Build & Test)

```powershell
# Executar análise estática e testes unificados
pwsh build-all.ps1

# Apenas análise de código (Linter estrito)
flutter analyze

# Executar suite completa de testes
flutter test
```

---

## 3. Governança & Arquitetura

- **Requisitos de Produto**: [docs/product/PRD.md](docs/product/PRD.md)
- **Especificação de Domínio**: [docs/architecture/SPEC.md](docs/architecture/SPEC.md)
- **Contratos Visuais & Tokens**: [docs/architecture/DESIGN.md](docs/architecture/DESIGN.md)
- **Plano Mestre & Backlog**: [docs/plan/README.md](docs/plan/README.md)
