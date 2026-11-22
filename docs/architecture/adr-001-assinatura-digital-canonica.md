# ADR-001 — Contrato Canônico de Assinatura Digital

> **Status**: Proposto — Gate 2.5 APROVADO COM CONDICIONANTES (Média, 2026-11-22); aguardando decisão PO D2 + aprovação Arch  
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
- `documentNumber: String?` ou `String` (**decisão PO necessária**; ver D2)
- `signedAtUtc: DateTime`
- `toBase64()`/codec apenas na borda de persistência/serialização, não como campo de domínio primário.

### D2 — Documento do recebedor (PII/LGPD) — decisão PO
Opções:
1. **Obrigatório** (alinha UC-04.04): fortalece comprovação; aumenta coleta PII/LGPD e fricção em campo.
2. **Opcional** (compatível com UC-03.05 atual): menor fricção; menor força probatória.
3. **Obrigatório quando política/configuração exigir**: flexível, mas adiciona complexidade.

**Recomendação [INFERÊNCIA, confiança Média]**: Opção 2 no MVP, com campo opcional normalizado/validado quando informado, e redação/criptografia conforme política; evoluir para obrigatoriedade por configuração se PO exigir. *Requer aprovação PO.*

### D3 — Local canônico
- Colocar contrato em `lib/modules/evidences/domain/` **ou** `lib/core/domain/value_objects/` se for transversal. [INFERÊNCIA] Como assinatura é evidência e também usada na conclusão de OS, preferir módulo `evidences` como dono e expor via port/uso explícito; evitar duplicação.
- `work_orders` não deve manter um segundo VO com mesmo nome semântico.

### D4 — Persistência
- Persistir bytes como BLOB ou base64 em coluna dedicada, mas nunca logar. 
- `documentNumber` é PII: redigir em `toString`, logs, erros; avaliar armazenamento cifrado/mascarado (dependência de D-01/INV-SEC-26/27).

### D5 — Erros
Padronizar catálogo de erros de assinatura (mapeando legados):
- `ERR_ASSINATURA_AUSENTE`
- `ERR_ASSINATURA_TAMANHO_EXCEDIDO`
- `ERR_ASSINANTE_NOME_OBRIGATORIO`
- `ERR_ASSINANTE_DOCUMENTO_INVALIDO` (quando informado/inválido)
- `ERR_ASSINATURA_INVALIDA` (formato/base64/corrompida)

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
| C-01 | Alta | Antes de persistir `documentNumber`, definir base legal/finalidade/minimização/retenção (LGPD) e proteção em repouso (cifra DB/campo, chave Keystore/Keychain; segredos fora do SQLite). | Aberto |
| C-02 | Alta | Endurecer backup: Android `allowBackup="false"` enquanto sem backup cifrado controlado; excluir DB/artefatos sensíveis; tratar iOS equivalente. (D-01) | Aberto |
| C-03 | Alta | Decisão PO D2 com justificativa documentada; recomendação segurança: não coletar documento por padrão (minimização). | Aberto |
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

- [ ] PO: decisão D2 (documento obrigatório/opcional).
- [ ] Arch: decisão D1/D3.
- [ ] Security: Gate 2.5 com condicionantes.
- [ ] QA: plano de testes de migração.