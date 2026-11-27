# Épico 08: Hardening Residual, Backup & Compliance Operacional

## Metadados

| Atributo | Valor |
| :--- | :--- |
| **Identificador** | `EPIC08` |
| **Dependências Diretas** | `EPIC00`, `EPIC01`, `EPIC05`, `EPIC07` (conforme fatia) |
| **Prioridade** | Média |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Concluído (UC-08.01, UC-08.02, UC-08.03 e UC-08.04 homologados com CI verde)` |
| **Referências** | [PRD](../../product/PRD.md) \| [SPEC](../../architecture/SPEC.md) \| [ADR-001](../../architecture/adr-001-assinatura-digital-canonica.md) \| [DEBITOS](../../DEBITOS.md) |

---

## 1. Objetivo de Negócio & Escopo

Consolidar pendências residuais de segurança/compliance, operação offline e qualidade que não bloqueiam o fluxo principal atual, mas são necessárias para endurecimento de release e evolução do produto.

- **Incluso (concluído)**:
  - `UC-08.01`: Residual D-01 — proteção em repouso de PII com AES-GCM 256, blindagem de backup do SO (`allowBackup="false"`), prova atômica de diagnóstico do cofre seguro do SO (`SecurityVaultProbe`) e mitigação homologada de D-01.
  - `UC-08.02`: Backup/Exportação segura local (RF-13) — container cifrado com AES-GCM 256, derivação PBKDF2/SHA-256 e restauração atômica no SQLite fail-closed.
  - `UC-08.03`: Compliance LGPD operacional para documento do recebedor — formalização de base legal/minimização, redaction universal (`DocumentRedactor`), zero PII em texto de PDF/logs e higienização de temporários (`TemporaryFileCleaner`).
  - `UC-08.04`: Hardening de credenciais e auditoria de dependências — rate-limit/backoff para senha mestre (D-03) e rotina de auditoria CVE (`osv-scanner` / D-02).
- **Não Incluso**:
  - Backend/nuvem/sincronização multi-dispositivo.
  - Novas features de negócio fora de hardening/backup/compliance.

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Gate 2.5 | Status |
| :--- | :--- | :--- | :--- :---: | :---: |
| **UC-08.01** | Hardening Residual D-01 (Keystore/Vault Probe & Débitos) | EPIC00/EPIC01 | INVOKED (armazenamento em repouso, segredos, plataforma) | `Concluído` |
| **UC-08.02** | Backup/Exportação Segura Local (RF-13) | EPIC00/EPIC03/EPIC05 | INVOKED (PII/exportação/backup) | `Concluído` |
| **UC-08.03** | Compliance LGPD do Documento do Recebedor | EPIC04/EPIC07 | INVOKED (PII/LGPD) | `Concluído` |
| **UC-08.04** | Rate-limit de Credencial & Auditoria CVE | EPIC01 | INVOKED (auth/dependências) | `Concluído` |

---

## 3. Definição de Pronto (DoD) do Épico

- [ ] Decisões de segurança/privacidade registradas (ADR/DEBITOS) antes de implementação.
- [ ] Gate 2.5 INVOKED por UC com superfície sensível; condicionantes tratadas.
- [ ] Backup/exportação sem PII em claro por padrão; criptografia e chave sob controle do usuário.
- [ ] Evidência de validação em device alvo para fluxos sensíveis.
- [ ] `flutter analyze --fatal-infos` e `flutter test` verdes; CI verde.

---

## 4. Casos de Uso Atômicos

### Caso de Uso UC-08.01 — Hardening Residual D-01

* **Identificador**: `UC-08.01`
* **Status**: `Proposto`
* **Gate 2.5**: `INVOKED (armazenamento em repouso, segredos, plataforma).`

#### Narrativa
- **Como** técnico autônomo
- **Eu quero** que dados locais sensíveis tenham proteção em repouso robusta e verificável na plataforma
- **Para que** perda/extração do dispositivo tenha risco reduzido.

#### Escopo técnico proposto
- Avaliar SQLCipher/full-db encryption vs. cifragem por campo para PII restante.
- Validar Keystore/Keychain por fabricante/device alvo.
- Criar runner iOS e validar políticas de backup/arquivo excluído.
- Manter fail-closed quando proteção não estiver disponível.

### Caso de Uso UC-08.02 — Backup/Exportação Segura Local (RF-13)

* **Identificador**: `UC-08.02`
* **Status**: `Proposto`
* **Gate 2.5**: `INVOKED (PII, exportação, backup).`

#### Narrativa
- **Como** técnico autônomo
- **Eu quero** exportar backup local dos meus dados
- **Para que** eu possa recuperar informações em troca de aparelho sem depender de nuvem do app.

#### Critérios iniciais
- Exportação explícita do usuário; arquivo cifrado; chave/senha sob controle do usuário.
- Backup automático do SO não inclui DB/artefatos sensíveis em claro.
- Restore com validação de integridade e compatibilidade de schema.

### Caso de Uso UC-08.03 — Compliance LGPD do Documento do Recebedor

* **Identificador**: `UC-08.03`
* **Status**: `Proposto`
* **Gate 2.5**: `INVOKED (PII/LGPD).`

#### Narrativa
- **Como** responsável pelo produto
- **Eu quero** política clara de coleta/uso/retenção do documento do recebedor
- **Para que** a captura de PII tenha base legal, minimização e proteção operacional.

#### Critérios iniciais
- Formalizar base legal/finalidade/retenção/minimização (residual C-01).
- Definir mascaramento/exibição no PDF/share (C-11) e limpeza de temporários.
- Testes de redaction em logs/toString/erros/DTOs (C-07).

### Caso de Uso UC-08.04 — Rate-limit de Credencial & Auditoria CVE

* **Identificador**: `UC-08.04`
* **Status**: `Concluído (local; CI security-audit pendente no push)`
* **Gate 2.5**: `INVOKED (auth/dependências) — sem nova superfície de auth; adicionada dependência CI (osv-scanner install script/action de workflow) com escopo restrito a leitura de pubspec.lock; sem segredos.`

#### Narrativa
- **Como** mantenedor do produto
- **Eu quero** reduzir risco de brute force local e de dependências vulneráveis
- **Para que** o hardening de segurança seja contínuo.

#### Evidência
- **D-03 (fechado por evidência, código já existente)**: `SecureCredentialStore.verifyPassword` já aplica lockout/backoff exponencial (`passwordFailCountKey`, `passwordLockedUntilKey`, `maxAttempts`, `baseLockout`, `maxLockout`), limpa contadores em sucesso. Evidência: `lib/modules/auth/data/credential_store/secure_credential_store.dart`, `test/modules/auth/data/credential_recovery_test.dart` ("verifyPassword aplica rate-limit/backoff (A1)", "lockout de senha expira (A1)"). DEBITOS atualizado para Mitigado.
- **D-02 (rotina reproduzível)**: `scripts/ci/security-audit.sh` (falha em advisory atual via `flutter pub outdated --json`; roda `osv-scanner` sobre `pubspec.lock` quando disponível; `REQUIRE_OSV_SCANNER=1` no CI). Workflow `.github/workflows/security-audit.yml` executa em push/PR/schedule/dispatch.
- **Verificação local 2026-11-25**: `flutter analyze --fatal-infos` limpo; `flutter test` **314/314 passed**; `flutter pub outdated --json` sem `isCurrentAffectedByAdvisory=true`.
