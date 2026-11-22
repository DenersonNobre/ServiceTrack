# ADR-001 — Contrato Canônico de Assinatura Digital

> **Status**: Proposto (aguardando aprovação PO/Arch + Gate 2.5)  
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

## Gate 2.5 (a executar)

Checklist mínimo:
- PII: `signerName`, `documentNumber`, imagem de assinatura — redigidos em logs/toString/erros.
- Armazenamento: SQLite local; avaliar criptografia em repouso (risco já registrado).
- Retenção/minimização: documento obrigatório? se não, não coletar.
- Validação: tamanho máximo, formato PNG/base64 válido, normalização.
- Imutabilidade: assinatura de OS concluída não pode ser alterada (INV-06/INV-SEC-23).

## Aprovação

- [ ] PO: decisão D2 (documento obrigatório/opcional).
- [ ] Arch: decisão D1/D3.
- [ ] Security: Gate 2.5 com condicionantes.
- [ ] QA: plano de testes de migração.