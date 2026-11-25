# ADR-001 — Contrato Canônico de Assinatura Digital

> **Status**: Aceito para implementação com condicionantes — Gate 2.5 APROVADO COM CONDICIONANTES (Média, 2026-11-22); PO D2 decidido; Arch D1/D3/D4/D5 aprovados 
> **Data**: 2026-11-22  
> **Autores**: `opc01@e03ff640`  
> **Relacionado**: UC-04.04, UC-04.05, UC-04.08, UC-03.05, D-05, INV-03, INV-SEC-24/25/26/27, LGPD

## Contexto

Existem dois contratos de assinatura no código [FATO]:

| Local | Campos | Formato imagem | Documento | Limite | Erros |
|---|---|---|---|---:|---|
| `lib/modules/work_orders/domain/value_objects/digital_signature.dart` | `signerName`, `imageBase64` | base64 string | não | 200KB base64 | `ERR_ASSINATURA_INVALIDA` |
| `lib/modules/evidences/domain/entities/digital_signature.dart` | `signatureBytes`, `signerName`, `documentNumber`, `signedAtUtc` | Uint8List PNG | CPF/RG (obrigatório) | 150KB | `ERR_ASSINATURA_AUSENTE`, `ERR_ASSINATURA_TAMANHO_EXCEDIDO`, `ERR_ASSINANTE_NOME_OBRIGATORIO`, `ERR_ASSINANTE_DOCUMENTO_OBRIGATORIO` |

Conflitos adicionais [FATO]:
- `SPEC.md` RN-03 cita `assinaturaBase64`, `recebedorNome`.
- `epic-04` UC-04.04 exige nome + CPF/RG.
- `work_order_list_page.dart` coleta assinatura/nome sem documento e cria `work_orders.DigitalSignature`.
- D-05 bloqueia integração real de checklist na conclusão.

## Decisão Proposta

### D1 — Contrato canônico único
Adotar **um único VO** `DigitalSignature` (nome final a confirmar) com:

- `signatureBytes: Uint8List` (canônico; PNG rasterizado)
- `signerName: String` (normalizado, 1..120)
- `documentNumber: String?` (opcional no modelo; exigido por política D2 quando habilitada)
- `signedAtUtc: DateTime`
- `toBase64()`/codec apenas na borda de persistência/serialização, não como campo de domínio primário.

**Aprovação Arch (2026-11-22)**: D1 aprovado com condicionantes C-05/C-06/C-08/C-09.

### D2 — Documento do recebedor (PII/LGPD) — decisão PO
Opções:
1. **Obrigatório** (alinha UC-04.04): fortalece comprovação; aumenta coleta PII/LGPD e fricção em campo.
2. **Opcional** (compatível com UC-03.05 atual): menor fricção; menor força probatória.
3. **Obrigatório quando política/configuração exigir**: flexível, mas adiciona complexidade.

**Decisão PO (2026-11-22): Opção 3 — obrigatório por política/configuração.**  
Implementação deve definir default seguro (minimização: não coletar/exigir por padrão até política habilitar), validar/normalizar quando informado, redigir/criptografar conforme C-01/C-06/C-07 e registrar finalidade/retenção (C-03).

### D3 — Local canônico
- **Dono canônico**: `lib/modules/evidences/domain/` (assinatura é evidência). 
- `work_orders` consome o contrato canônico (import/port/DTO conforme fronteira) e **não** mantém segundo VO semântico.
- Evitar mover para `core` até haver 2+ consumidores reais com mesmo contrato; se necessário, promover com ADR de atualização.

**Aprovação Arch (2026-11-22)**: D3 aprovado.

### D4 — Persistência
- Persistir imagem como BLOB (preferido) ou base64 em coluna dedicada, mas nunca logar. 
- `documentNumber` é PII: redigir em `toString`, logs, erros; armazenamento cifrado/mascarado conforme C-01 (dependência D-01/INV-SEC-26/27).
- `signedAtUtc` persistido como ISO-8601 UTC; legado sem timestamp não fabrica valor original (C-04).

**Aprovação Arch (2026-11-22)**: D4 aprovado com condicionantes C-01/C-04/C-05/C-10.

### D5 — Erros
Padronizar catálogo de erros de assinatura (mapeando legados):
- `ERR_ASSINATURA_AUSENTE`
- `ERR_ASSINATURA_TAMANHO_EXCEDIDO`
- `ERR_ASSINANTE_NOME_OBRIGATORIO`
- `ERR_ASSINANTE_DOCUMENTO_OBRIGATORIO` (quando política exige e está ausente)
- `ERR_ASSINANTE_DOCUMENTO_INVALIDO` (quando informado/inválido)
- `ERR_ASSINATURA_INVALIDA` (formato/base64/corrompida/PNG inválido)

**Aprovação Arch (2026-11-22)**: D5 aprovado; mapear `ERR_ASSINATURA_INVALIDA` legado sem perder semântica onde necessário.

## Consequências

Positivas:
- Remove duplicação N-01.
- Habilita integração UC-04.07/D-05 com contrato claro.
- Melhora rastreabilidade LGPD.

Negativas/riscos:
- Migração de dados SQLite existentes (UC-03.05 já persiste assinatura base64/nome).
- Mudança em UI de conclusão e testes.
- PII adicional se documento obrigatório.

## Plano de Migração

1. **Gate 2.5** sobre ADR (PII/LGPD, armazenamento, redaction).
2. Introduzir VO canônico + adapters de compatibilidade (ler base64 legado).
3. Atualizar repositórios/migrations com coluna de documento/data UTC (nullable se opcional).
4. Atualizar UI/controller de conclusão para usar contrato canônico.
5. Remover VO duplicado após migração verde.

## Gate 2.5 — Veredito (2026-11-22)

**Gate 2.5: INVOKED — Aprovado com condicionantes (Confiança Média, `ses_dfc96c088ffePqylwAxJpMhMTK`)**. Não pronto para implementação antes de C-01..C-12.

| ID | Sev. | Condicionante | Status |
|---|---|---|---|
| C-01 | Alta | Antes de persistir `documentNumber`, definir base legal/finalidade/minimização/retenção (LGPD) e proteção em repouso (cifra DB/campo, chave Keystore/Keychain; segredos fora do SQLite). | Parcial — proteção técnica em repouso implementada (AES-GCM 256 campo, chave Keystore/Keychain, fail-closed; `enc:v1:`); pendente base legal/finalidade/retenção LGPD e política de produto |
| C-02 | Alta | Endurecer backup: Android `allowBackup="false"` enquanto sem backup cifrado controlado; excluir DB/artefatos sensíveis; tratar iOS equivalente. (D-01) | Parcial — Android `allowBackup="false"` e `fullBackupContent="false"` aplicados; pendente iOS e exclusões granulares de backup cifrado controlado |
| C-03 | Alta | Decisão PO D2 com justificativa documentada; recomendação segurança: não coletar documento por padrão (minimização). | **Decidido PO 2026-11-22**: obrigatório por política/configuração; default seguro/minimização |
| C-04 | Média | Migração bidirecional na leitura/unidirecional na escrita; não fabricar `signedAtUtc`/documento ausente; semântica explícita (`nullable`/`migratedAtUtc`). | Aberto |
| C-05 | Média | Limite por bytes reais decodificados (não comprimento base64); política para legado acima do limite: preservar imutável ou marcar, nunca truncar. | Aberto |
| C-06 | Média | Proibir `toJson` com PII/imagem crus; DTOs de borda explícitos; `toString` redigido só com metadados não sensíveis. | Aberto |
| C-07 | Média | Testes de redaction em toString/erros/logs/DTOs/debug; gate/grep sem PII em logs. | Aberto |
| C-08 | Média | PNG canônico válido (magic bytes), limite único em bytes pós-decodificação, validação na entrada/reidratação. | Aberto |
| C-09 | Média | Validar antes de persistir/renderizar/exportar; erros tipados sem ecoar payload. | Aberto |
| C-10 | Média | Preservar INV-SEC-23 em novo schema/migração; testes update/insert bloqueado, migração não altera OS concluída, status nulo fail-closed. | Aberto |
| C-11 | Média | Antes de EPIC-05/RF-13, definir política de dados em PDF/share; mínimo necessário, mascaramento documento se exibido, limpar temporários. | Aberto |
| C-12 | Média | Backup/exportação com PII sensível só cifrado, chave sob controle do usuário, escopo documentado; excluir DB/assinaturas de backup automático por padrão. | Aberto |

**Invariantes propostas (Gate 2.5)**: INV-SEC-SIG-01..06 (repouso/backup, minimização, migração sem fabricação, redaction, formato/tamanho, imutabilidade pós-conclusão).

**Risco dominante**: Information Disclosure de PII sensível (assinatura, nome, eventual CPF/RG) em SQLite plain e superfícies de backup/exportação.

## Aprovação

- [x] PO: decisão D2 — **obrigatório por política/configuração** (2026-11-22); default seguro/minimização.
- [x] Arch: D1/D3/D4/D5 aprovados (2026-11-22), condicionados a C-01..C-12 na implementação.
- [x] Security: Gate 2.5 com condicionantes (C-01..C-12 abertos; C-03 decidido).
- [ ] QA: plano de testes de migração (na implementação UC-04.06/07/08).