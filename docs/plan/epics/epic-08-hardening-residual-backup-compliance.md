# Épico 08: Hardening Residual, Backup & Compliance Operacional

## Metadados

| Atributo | Valor |
| :--- | :--- |
| **Identificador** | `EPIC08` |
| **Dependências Diretas** | `EPIC00`, `EPIC01`, `EPIC05`, `EPIC07` (conforme fatia) |
| **Prioridade** | Média (proposta — aguarda priorização PO) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Proposto (backlog PO; sem claim ativo)` |
| **Referências** | [PRD](../../product/PRD.md) \| [SPEC](../../architecture/SPEC.md) \| [ADR-001](../../architecture/adr-001-assinatura-digital-canonica.md) \| [DEBITOS](../../DEBITOS.md) |

---

## 1. Objetivo de Negócio & Escopo

Consolidar pendências residuais de segurança/compliance, operação offline e qualidade que não bloqueiam o fluxo principal atual, mas são necessárias para endurecimento de release e evolução do produto.

- **Incluso (proposta)**:
  - `UC-08.01`: Residual D-01 — avaliação/implementação de criptografia full-db (SQLCipher) ou reforço equivalente; validação de Keystore/Keychain por fabricante; runner iOS.
  - `UC-08.02`: Backup/Exportação segura local (RF-13) — ZIP/JSON cifrado, mínimo necessário, sem PII em claro em backups automáticos (C-11/C-12).
  - `UC-08.03`: Compliance LGPD operacional para documento do recebedor — formalizar base legal/finalidade/retenção/minimização (residual C-01), política de exibição/mascaramento em PDF/share e limpeza de temporários (C-11).
  - `UC-08.04`: Hardening de credenciais e auditoria de dependências — rate-limit/backoff para senha mestre (D-03) e rotina de auditoria CVE (`pub audit`/OSV, D-02).
- **Não Incluso**:
  - Backend/nuvem/sincronização multi-dispositivo.
  - Novas features de negócio fora de hardening/backup/compliance.

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Gate 2.5 | Status |
| :--- | :--- | :--- | :---: | :---: |
| **UC-08.01** | Hardening Residual D-01 (full-db/iOS/Keystore) | EPIC00/EPIC01 | INVOKED (superfície sensível: armazenamento/segredos) | `Proposto` |
| **UC-08.02** | Backup/Exportação Segura Local (RF-13) | EPIC00/EPIC03/EPIC05 | INVOKED (PII/exportação/backup) | `Proposto` |
| **UC-08.03** | Compliance LGPD do Documento do Recebedor | EPIC04/EPIC07 | INVOKED (PII/LGPD) | `Proposto` |
| **UC-08.04** | Rate-limit de Credencial & Auditoria CVE | EPIC01 | INVOKED (auth/dependências) | `Proposto` |

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
* **Status**: `Proposto`
* **Gate 2.5**: `INVOKED (auth/dependências).`

#### Narrativa
- **Como** mantenedor do produto
- **Eu quero** reduzir risco de brute force local e de dependências vulneráveis
- **Para que** o hardening de segurança seja contínuo.

#### Critérios iniciais
- Rate-limit/backoff para verificação de senha mestre (D-03), sem UX degradante.
- Rotina de auditoria CVE/dependências (D-02) com evidência reproduzível.
