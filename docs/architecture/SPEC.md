# ServiceTrack — Especificação Técnica de Domínio (Standalone Mobile)

> **Arquiteto (responsável)**: Denerson Nobre  
> **Status**: `Aprovado` | **Versão**: `2.0.0` (Arquitetura 100% Flutter Local) | **Data**: `2026-11-20`  
> **Documento de Referência**: [docs/product/PRD.md](../product/PRD.md)

---

## Regras de Negócio Executáveis (Obrigatório)

| ID | Regra | Entrada | Saída | Exceções | Rastreabilidade |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `RN-01` | Transição de Estado da OS | `{"statusAtual": "SCHEDULED", "novoStatus": "IN_PROGRESS", "hasCheckInGeo": true}` | `{"sucesso": true, "status": "IN_PROGRESS"}` | Transição ilegal (ex: SCHEDULED -> COMPLETED direto) | `INV-01, UC-OS.01` |
| `RN-02` | Captura de Georreferenciamento Local | `{"lat": -23.55052, "lng": -46.633308, "timestampUtc": "2026-11-20T20:00:00Z"}` | `{"valido": true}` | Coordenadas fora dos limites (-90..90, -180..180) | `INV-02, UC-OS.02` |
| `RN-03` | Conclusão Obrigatória de Checklist e Assinatura | `{"osId": "uuid", "respostasChecklist": [...], "assinaturaBase64": "...", "recebedorNome": "Carlos"}` | `{"sucesso": true, "status": "COMPLETED"}` | Item mandatório pendente ou assinatura ausente | `INV-03, UC-OS.03` |
| `RN-04` | Autenticação Local Segura (Biometria / PIN) | `{"authType": "BIOMETRIC", "pinAttempt": "1234"}` | `{"autenticado": true}` | PIN incorreto ou biometria recusada | `INV-04, UC-AUTH.01` |
| `RN-05` | Compressão e Limite de Evidências Fotográficas | `{"fotosCount": 7}` | `{"valido": false, "erro": "ERR_EVIDENCIA_LIMITE_EXCEDIDO"}` | Mais de 6 fotos por OS | `INV-05, UC-EV.01` |
| `RN-06` | Compilação de PDF On-Device | `{"os": WorkOrderCompleta}` | `{"pdfBytes": Uint8List, "tamanhoKb": 450}` | Erro de layout ou estouro de memória | `INV-06, UC-PDF.01` |

---

## 1. Visão Geral & Bounded Context

- **Propósito do Sistema**: O ServiceTrack é um aplicativo Flutter para smartphones que transforma o trabalho do técnico de campo autônomo, permitindo gerenciar ordens de serviço, preencher checklists, tirar fotos auditáveis, colher assinaturas e **gerar laudos em PDF no próprio aparelho** sem nenhuma dependência de infraestrutura em nuvem ou internet.
- **Fronteiras & Limites**:
  - **DENTRO do escopo**: CRUD local de clientes, ciclo de vida da OS, checklist rápido, fotos com metadados/timestamp, assinatura em canvas, geração nativa de PDF com `package:pdf` e compartilhamento via `package:share_plus` (WhatsApp/E-mail/Impressão).
  - **FORA do escopo**: Servidor remoto/backend, contas de usuário/login em nuvem, sync bidirecional entre aparelhos e painel web administrativo.
- **Atores & Personas**:
  - `Técnico Autônomo`: Operador único e dono do aparelho.

---

## 2. Linguagem Ubíqua (Glossário Canônico)

| Termo em Português | Termo Técnico no Código | Definição Rígida de Negócio |
| :--- | :--- | :--- |
| **Cliente** | `Customer` | Contato contratante do serviço (Nome, Telefone/WhatsApp, Endereço). |
| **Ordem de Serviço** | `WorkOrder` | Agregado raiz da visita técnica e execução do serviço. |
| **Status da OS** | `WorkOrderStatus` | Máquina de estados: `SCHEDULED`, `IN_PROGRESS`, `PAUSED`, `COMPLETED`, `CANCELLED`. |
| **Ponto Georreferenciado** | `GeoPoint` | Value Object com latitude, longitude e timestamp da captura. |
| **Modelo de Checklist** | `ChecklistTemplate` | Lista padrão de verificações reutilizáveis por tipo de trabalho. |
| **Resposta de Checklist** | `ChecklistAnswer` | Registro com `CONFORME`, `NAO_CONFORME`, `NAO_APLICA` e observação. |
| **Evidência Fotográfica** | `PhotoEvidence` | Imagem compactada salva no armazenamento local do aparelho com data e GPS. |
| **Assinatura Digital** | `DigitalSignature` | Imagem rasterizada da assinatura na tela + nome do cliente e documento. |
| **Laudo Técnico em PDF** | `TechnicalReportPdf` | Documento binário gerado on-device pronto para compartilhamento. |

---

## 3. Invariantes de Domínio (Regras Inegociáveis)

- **INV-01 (Fluxo Estrito de Estados)**: Nenhuma `WorkOrder` pode ser finalizada (`COMPLETED`) sem ter sido iniciada (`IN_PROGRESS`). `PAUSED` é estado intermediário válido apenas a partir de `IN_PROGRESS`, e a retomada retorna a `IN_PROGRESS` antes de qualquer conclusão. |
- **INV-02 (Auditabilidade Georreferenciada)**: O Check-in e o Check-out exigem a coleta de um `GeoPoint` com precisão do GPS nativo (ou indicação de GPS desligado com autorização expressa).
- **INV-03 (Completude de Fechamento)**: Uma `WorkOrder` só pode ser concluída se todos os itens obrigatórios de checklist tiverem sido respondidos e a assinatura digital do cliente tiver sido coletada.
- **INV-04 (Cota Máxima de Evidências)**: Cada `WorkOrder` armazena no máximo 6 fotos compactadas localmente.
- **INV-05 (Autocontenção da Geração de PDF)**: O gerador de laudo técnico em PDF deve ser executado 100% no dispositivo (Isolate em background do Dart para não congelar a UI), sem requisição a nenhuma API externa.
- **INV-06 (Imutabilidade Pós-Conclusão)**: Uma `WorkOrder` com status `COMPLETED` é travada para edições no banco local, assegurando a integridade do laudo emitido.

---

## 4. Modelos de Domínio & Agregados

### 4.1 Agregado Raiz: WorkOrder
```text
Entidade Raiz: WorkOrder (Identificador: WorkOrderId [UUID v4])
├── Propriedades:
│   ├── customer: Customer (embutido ou referenciado por CustomerId)
│   ├── serviceDescription: String
│   ├── scheduledAt: DateTime
│   ├── status: WorkOrderStatus
│   ├── checkIn: GeoPoint? (Registrado ao iniciar)
│   ├── checkOut: GeoPoint? (Registrado ao concluir)
│   ├── checklistAnswers: List<ChecklistAnswer>
│   ├── evidences: List<PhotoEvidence> (0..6)
│   ├── signature: DigitalSignature?
│   ├── notes: String?
│   └── cancellationReason: String?
├── Métodos de Negócio:
│   ├── startService(geo: GeoPoint): Result<void>
│   ├── pause(reason: String): Result<void>
│   ├── resume(): Result<void>
│   ├── answerItem(itemId: String, answer: ChecklistAnswer): Result<void>
│   ├── addEvidence(evidence: PhotoEvidence): Result<void>
│   ├── complete(signature: DigitalSignature, checkOutGeo: GeoPoint): Result<void>
│   └── cancel(reason: String): Result<void>
└── Invariantes Aplicados: INV-01, INV-02, INV-03, INV-04, INV-06
```

---

## 5. Portas de Comunicação & Frameworks Base

O ServiceTrack utiliza rigorosamente o stack e bibliotecas canônicas do autor:
- **`kortex`**: Motor reativo de granularidade fina baseado em Signals (`KortexSignal`, `KortexWatch`, `IKortexPage`), injeção com escopo explícito na árvore de widgets (`KortexScope`, `KortexProvider`) e ciclo de vida determinístico sem dependências externas.
- **`kortex_lib`** (pub.dev): Utilitários universais, `Result`/`ValidationError`, Value Objects monetários/BR (`Money`, `brlib` com validação de CPF/CNPJ, formatação de telefone), persistência SQLite e widgets reutilizáveis. (Substitui `dnolib`, aposentada na Fase B.)

```dart
// Exemplo de Controller usando Kortex
abstract class IWorkOrderRepositoryPort {
  Future<Result<List<WorkOrder>>> listAll();
  Future<Result<WorkOrder?>> getById(String id);
  Future<Result<void>> save(WorkOrder order);
  Future<Result<void>> delete(String id);
}

// Contrato de Captura de GPS Nativo
abstract class ILocationServicePort {
  Future<Result<GeoPoint>> getCurrentLocation();
}

// Contrato de Compressão de Imagens
abstract class IImageCompressorPort {
  Future<Result<String>> compressAndSave(String sourcePath, {int quality, int maxWidth});
}

// Contrato de Geração de Laudo Técnico On-Device
abstract class IPdfReportGeneratorPort {
  Future<Result<Uint8List>> generatePdf(WorkOrder workOrder);
}

// Contrato de Compartilhamento Nativo do SO (WhatsApp, E-mail, Arquivos)
abstract class IShareServicePort {
  Future<Result<void>> sharePdfFile(Uint8List pdfBytes, String fileName, {String? textMessage});
}

// Contrato de Credenciais Locais (Onboarding & Desbloqueio)
abstract class IAuthCredentialRepositoryPort {
  Future<Result<String>> saveCredentials({required MasterPassword password, required SecurityPin pin});
  Future<Result<bool>> verifyPin(String attempt);
  Future<Result<bool>> verifyPassword(String attempt);
  Future<Result<bool>> clearAll();
}
```

### 5.1 Composition Root & Route Bindings

- **`AppDependencies`** (`lib/app/app_dependencies.dart`) é o composition root: agrega portas/adaptadores e políticas e é injetado no `AppEntry`. Não é um service locator; dependências continuam explícitas por construtor.
- **Cada módulo expõe `*Routes`** em `lib/modules/<modulo>/ui/` (ex.: `CustomersRoutes`, `ProfileRoutes`), recebendo apenas as portas que usa.
- **`appScopedRoute<T, R>`** (`lib/core/ui/app_scoped_route.dart`) é o binding canônico para rota com um controller: encapsula `MaterialPageRoute`, `KortexScope`, `KortexProvider`, `readKortex` e auto-dispose.
- **`KortexScope` manual** é exceção justificada para rotas com múltiplos providers; não é o padrão.
- **`AppEntry`** mantém gate de rota inicial, lifecycle/relock e dispatch; não compõe controllers de módulo nem contém regra de negócio.
- **GetX/service locator** permanecem proibidos (`AGENTS.md`).

Decisão completa e plano de migração: [ADR-002](adr-002-app-shell-di-route-bindings.md).

### 5.2 Configurações Locais Tipadas

- **Catálogo**: `SettingKey` (`lib/modules/settings/domain/value_objects`) mapeia chave persistida, tipo e default seguro (`require_checklist_template=true`, `require_receiver_document=false`).
- **Snapshot**: `SettingsSnapshot` imutável, preenche defaults para chaves ausentes e expõe getters tipados.
- **Porta/use cases**: `ISettingsRepositoryPort.load()/update()`, `GetSettings` e `UpdateSetting` (chave validada contra o catálogo).
- **Persistência**: tabela `app_settings (key, value, updated_at_utc)` na migration `v11`; `app_database` em `dbVersion: 11`.
- **Falhas tipadas**: `ERR_CONFIGURACAO_CHAVE_INVALIDA`, `ERR_CONFIGURACAO_VALOR_INVALIDO`, `ERR_CONFIGURACAO_PERSISTENCIA`.
- **Consumidores**: devem usar os use cases/porta; nunca acessar a tabela ou strings de chave diretamente. A política é relida **por operação** de conclusão (SEC-02) e falha fail-closed se o settings não puder ser lido (SEC-03).
- **Documento do recebedor**: `require_receiver_document` default `false`. Com D-01/C-01 mitigado por cifragem de campo AES-GCM 256 (`IDocumentAtRestCipher`, chave Keystore/Keychain), `kDocumentAtRestProtectionAvailable=true`; `signature_document_number` é persistido cifrado (`enc:v1:`). Sem cifrador disponível o fluxo falha fail-closed com `ERR_ASSINATURA_DOCUMENTO_PROTECAO_INDISPONIVEL` (SEC-04/SEC-05).
- **Checklist**: `require_checklist_template=false` remove apenas a exigência de template; completude de itens obrigatórios (INV-03) permanece obrigatória (SEC-08).

Decisão completa: [ADR-003](adr-003-settings-locais-tipadas.md).

---

## 6. Taxonomia de Falhas & Padrão Result

| Código de Erro | Severidade | Motivo de Negócio | Ação do Sistema |
| :--- | :---: | :--- | :--- |
| `ERR_OS_TRANSICAO_INVALIDA` | Esperada | Tentar concluir OS que não foi iniciada. | Retornar `Result.Fail(ERR_OS_TRANSICAO_INVALIDA)` |
| `ERR_CHECKLIST_INCOMPLETO` | Esperada | Itens de verificação mandatórios pendentes. | Retornar `Result.Fail(ERR_CHECKLIST_INCOMPLETO)` |
| `ERR_ASSINATURA_AUSENTE` | Esperada | Fechamento sem assinatura do cliente. | Retornar `Result.Fail(ERR_ASSINATURA_AUSENTE)` |
| `ERR_EVIDENCIA_LIMITE_EXCEDIDO` | Esperada | Tentativa de adicionar mais de 6 fotos. | Retornar `Result.Fail(ERR_EVIDENCIA_LIMITE_EXCEDIDO)` |
| `ERR_GERACAO_PDF_FALHOU` | Esperada | Memória insuficiente para rasterizar imagens no PDF. | Retornar `Result.Fail(ERR_GERACAO_PDF_FALHOU)` |
| `ERR_PIN_INCORRETO_TENTATIVAS_RESTANTES` | Esperada | PIN incorreto com tentativas restantes. | Retornar `Result.Fail(ERR_PIN_INCORRETO_TENTATIVAS_RESTANTES)` e incrementar contador |
| `ERR_PIN_BLOQUEADO_TEMPORARIAMENTE` | Esperada | 3+ falhas de PIN (rate-limit). | Retornar `Result.Fail(ERR_PIN_BLOQUEADO_TEMPORARIAMENTE)` até expirar o bloqueio |
| `ERR_SENHA_INCORRETA` | Esperada | Senha mestre incorreta na verificação/recuperação. | Retornar `Result.Fail(ERR_SENHA_INCORRETA)` |
| `ERR_CREDENCIAIS_NAO_CADASTRADAS` | Esperada | Verificação sem onboarding concluído. | Retornar `Result.Fail(ERR_CREDENCIAIS_NAO_CADASTRADAS)` |
| `ERR_COFRE_INDISPONIVEL` | Esperada | I/O do Keychain/Keystore falhou. | Retornar `Result.Fail(ERR_COFRE_INDISPONIVEL)` (exceção só neste ponto de fronteira) |
| `ERR_LAUDO_DADOS_CARREGAMENTO_FALHOU` | Esperada | Falha ao carregar dados necessários para montar o laudo (banco indisponível, OS/dados inconsistentes ou erro de leitura). | Retornar `Result.Fail(ERR_LAUDO_DADOS_CARREGAMENTO_FALHOU)` |
| `ERR_LAUDO_HISTORICO_CARREGAMENTO_FALHOU` | Esperada | Falha ao carregar histórico de laudos concluídos. | Retornar `Result.Fail(ERR_LAUDO_HISTORICO_CARREGAMENTO_FALHOU)` |
