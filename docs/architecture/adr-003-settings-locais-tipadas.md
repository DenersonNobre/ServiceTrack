# ADR-003 — Configurações Locais Tipadas

> **Status**: Aceito (UC-07.01/02/03 implementados; G3 aprovado com ressalvas; G4 pendente)
>
> **Data**: 2026-11-22  
> **Autor**: `opc01@e03ff640`  
> **Relacionado**: `EPIC-07`, `UC-07.01`, `SettingKey`, `SettingsSnapshot`, `ISettingsRepositoryPort`, `SettingsMigration.v11`, `ADR-001` D2.

## Contexto

[FATO] Políticas de conclusão estavam distribuídas como bools em `app_entry`, `service_track_app` e `work_order_list_controller` (`requireChecklistTemplate`, `requireReceiverDocument`), sem catálogo único, default explícito ou persistência local.

[FATO] O app usa SQLite via `kortex_lib/sqlite` para dados locais; não há backend. A decisão D2 (ADR-001) exige política configurável com default seguro/minimização.

## Decisão

1. **Persistência key/value**: tabela `app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL, updated_at_utc TEXT NOT NULL)`, migration `v11` em `SettingsMigration`.
2. **Catálogo tipado**: `SettingKey` enum mapeia chave persistida ↔ default seguro:
   - `require_checklist_template` → `true`;
   - `require_receiver_document` → `false`.
3. **Snapshot imutável**: `SettingsSnapshot` preenche defaults para chaves ausentes e expõe getters tipados.
4. **Porta + use cases**: `ISettingsRepositoryPort.load()/update()`, `GetSettings` e `UpdateSetting` (valida chave contra o catálogo).
5. **Fail-closed**:
   - chave fora do catálogo → `ERR_CONFIGURACAO_CHAVE_INVALIDA`;
   - valor persistido inválido → `ERR_CONFIGURACAO_VALOR_INVALIDO`;
   - falha de I/O → `ERR_CONFIGURACAO_PERSISTENCIA`.
6. **Sem storage direto no consumidor**: UI/controllers devem usar os use cases/porta, nunca acessar `app_settings` diretamente.

## Alternativas consideradas

| Alternativa | Por que não |
| :--- | :--- |
| `SharedPreferences` | Introduz outro storage e perde o schema/migração já usado no app. |
| Colunas explícitas por política | Menos extensível; cada nova política exige migration e alteração de DTO. |
| Configuração remota | Fora do escopo standalone (zero backend). |
| Bools hardcoded no shell/controller | Viola SRP, espalha política e impede configuração pelo técnico. |

## Consequências

**Positivas**
- Catálogo único e tipado; defaults explícitos e testáveis.
- Extensível para novas políticas sem alterar consumidores.
- Persistência local consistente com o restante do app.
- Base para UC-07.02 (UI) e UC-07.03 (integração de políticas).

**Negativas / custos**
- Tabela key/value exige parse/validação de valor na borda.
- Tipos futuros (int/text) exigem extensão do catálogo/Snapshot.
- Ainda depende de D-01 para persistir documento do recebedor com proteção em repouso.

## Estado da implementação

| Item | Estado |
| :--- | :--- |
| `SettingKey` + `SettingsSnapshot` + port | Concluído |
| `SettingsMigration.v11` + `app_database` dbVersion 11 | Concluído |
| `SettingsSqliteRepository` + `MemorySettingsRepository` | Concluído |
| `GetSettings` + `UpdateSetting` | Concluído |
| Testes de domínio/repositório/use cases | Concluído (10 testes) |
| UI de configurações (UC-07.02) | Concluído |
| Integração das políticas nos consumidores (UC-07.03) | Concluído (G2.5 com condicionantes; G3 aprovado com ressalvas; G4 pendente) |

## Regras de evolução

1. Nova política entra primeiro em `SettingKey` com default seguro e teste.
2. Consumidor lê por `GetSettings`/porta; não usa string de chave solta.
3. Valor inválido no storage falha de forma tipada; nunca assume default silencioso para dado corrompido.
4. Migrations são aditivas e idempotentes; nunca reescrevem configuração existente.
5. `load()` é forward-compatible: **tolera** chave desconhecida (ignora) para não quebrar rollback; a rejeição `ERR_CONFIGURACAO_CHAVE_INVALIDA` ocorre no `UpdateSetting`/escrita.
