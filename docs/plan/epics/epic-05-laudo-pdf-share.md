# Épico 05: Geração On-Device de Laudo Técnico em PDF & Compartilhamento

## Metadados

| Atributo | Valor |
| :--- | :--- |
| **Identificador** | `EPIC05` |
| **Dependências Diretas** | `EPIC00`, `EPIC03`, `EPIC04` |
| **Prioridade** | Crítica (Core de Valor do Produto Standalone) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Concluído (evidência local/device 2026-11-25) — integração app/preview/share/reabertura/histórico dedicado implementados; INV-05 validado no M2010J19CG (Android 10); ausência de congelamento de UI segue como observação qualitativa` |
| **Referências da SPEC** | [docs/architecture/SPEC.md](../../architecture/SPEC.md) \| [docs/architecture/DESIGN.md](../../architecture/DESIGN.md) |

---

## 1. Objetivo de Negócio & Escopo

Compilar o Laudo Técnico em PDF no próprio smartphone em menos de 2 segundos utilizando o pacote nativo `pdf` (sem internet e sem servidores), aplicando rigorosamente o Styleguide v2.1 (*Deep Petrol Green* `#115E59`, dados do técnico no cabeçalho, checklist estruturado, fotos nítidas e assinaturas digitais), com compartilhamento imediato via WhatsApp, E-mail ou impressão.

- **Incluso**:
  - `UC-05.01`: Motor de Renderização de PDF On-Device via `Isolate.run(...)` (Layout executivo profissional).
  - `UC-05.02`: Visualização & Preview do Laudo no aplicativo.
  - `UC-05.03`: Disparo da Folha de Compartilhamento Nativa do SO (`package:share_plus`) direto para o WhatsApp do cliente.
  - `UC-05.04`: Histórico e Reemissão de Laudos Salvos localmente.
- **Não Incluso**:
  - Envio por servidor de e-mail SMTP em nuvem ou armazenamento remoto no MVP.

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| :--- | :--- | :--- | :---: |
| **UC-05.01** | Motor de Compilação do PDF On-Device | Nenhuma | `Implementado; desempenho em aparelho alvo pendente` |
| **UC-05.02** | Visualização & Preview do Laudo no App | UC-05.01 | `Implementado e integrado no app` |
| **UC-05.03** | Compartilhamento Nativo com 1 Toque (WhatsApp) | UC-05.01, UC-05.02 | `Implementado e integrado no app` |
| **UC-05.04** | Histórico e Reemissão de Laudos Salvos | UC-05.01 | `Implementado e integrado (cache/regeneração, reabertura por OS e histórico visual dedicado); INV-05 validado em device alvo` |

---

## 3. Definição de Pronto (DoD) do Épico

- [x] Desempenho abaixo de 2.0s confirmado em aparelho alvo (`INV-05`) — `flutter test -d 192.168.67.65:5555 test/modules/reports/data/pdf_report_generator_adapter_test.dart` (M2010J19CG, Android 10 / API 29, 2026-11-25): **3/3 passed**, incluindo caso com 6 fotos e asserção `elapsedMilliseconds < 2000`. Ausência de congelamento de UI permanece observação qualitativa em uso real.
- [x] Teste automatizado valida cabeçalho `%PDF-` e conteúdo das seções obrigatórias (helper de extração de texto por streams zlib/latin1 + asserts de seções/conteúdo-chave em OS sem fotos e com fotos).
- [x] Adaptador de compartilhamento nativo isolado pela porta `IShareServicePort` e coberto por testes do módulo.
- [x] `flutter analyze --fatal-infos` limpo e `flutter test` completo **310/310 passed** (evidência local 2026-11-25, inclui slice UC-05.04-HISTORY).

### Estado conferido em 2026-11-25

- Os commits `3127e03`, `b1afce6` e `e531b15` adicionaram o gerador PDF, preview/compartilhamento e armazenamento/cache local, respectivamente.
- Integração no app concluída: `AppRoutes.reportPreview`, `AppPages` compõe `ReportsRoutes` com `PdfReportGeneratorAdapter`, `ShareServiceAdapter`, `ReportStorageAdapter` e `reportDataLoader` (repos SQLite/profile + `ReportDataAssembler`); `WorkOrdersRoutes.list(onReport: ...)` abre o preview por `workOrderId`.
- `ReportDataAssembler` puro mapeia OS/cliente/perfil/checklist/assinatura/GPS para `ReportData` (fotos `const []` por enquanto; logo lida na borda se existir).
- UC-05.04: cache/regeneração/reabertura por OS concluída e **tela de histórico visual dedicada implementada/integrada** (`AppRoutes.reportHistory`, `ReportsRoutes.history`, `ReportHistoryController/Page`, item no `HomeDrawer`, loader no `AppPages` com OS concluídas enriquecidas por cliente e ordenadas desc). Desempenho <2s em device alvo (INV-05) validado por teste automatizado on-device (M2010J19CG, Android 10, 2026-11-25); ausência de congelamento de UI permanece observação qualitativa.
- Validação local (fatia UC-05.04-HISTORY, 2026-11-25): `flutter analyze --fatal-infos` limpo; testes focados **39/39 passed**; `flutter test` completo **310/310 passed**.

---

## 4. Casos de Uso Atômicos

---

### Caso de Uso UC-05.01 — Motor de Compilação do PDF On-Device

* **Identificador**: `UC-05.01`
* **Status**: `Implementado (código e testes; validação de desempenho em aparelho pendente)`
* **Gate DoR**: `tools/bin/claims claim -path . -slice UC-05.01 -owner <agente> -paths lib/modules/reports/`
* **Gate DoD**: `tools/bin/claims release -path . -slice UC-05.01`

#### Narrativa
- **Como** Técnico concluindo uma Ordem de Serviço
- **Eu quero** que o aplicativo gere um PDF profissional no próprio aparelho com meu cabeçalho comercial, dados do cliente, checklist, fotos e assinatura
- **Para que** eu entregue o laudo formal ao cliente imediatamente, mesmo sem internet.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Esquema do Cenário: Compilação on-device do Laudo Técnico em PDF (INV-05)
  Dado que o técnico solicita gerar o laudo de uma OS com status <status_os> e <qtd_fotos> fotos
  Quando o motor de PDF for acionado
  Então o sistema deve retornar <resultado>

  Exemplos:
    | status_os | qtd_fotos | resultado |
    | "COMPLETED" | 6 | "Result.Ok(Uint8List %PDF- valido)" |
    | "SCHEDULED" | 0 | "Result.Fail(ERR_OS_NAO_CONCLUIDA)" |
    | "COMPLETED" | 0 | "Result.Ok(Uint8List %PDF- sem galeria)" |
```
* **Fixture**: `docs/plan/fixtures/uc-05-laudo-pdf-share.json`

#### NFRs Mensuráveis
| UC | NFR | Métrica | Target | Medição |
| :--- | :--- | :--- | :--- | :--- |
| `UC-05.01` | Tempo de geração on-device | Duração total com 6 fotos | `< 2000 ms` | Benchmark em teste unitário via `Stopwatch` |

#### Tarefas Técnicas
1. `TASK-01`: Implementar `PdfReportGeneratorAdapter` (`IPdfReportGeneratorPort`) com `package:pdf` em `Isolate.run(...)` e paleta Deep Petrol Green `#115E59`.
2. `TASK-02`: Testes unitários verificando assinatura `%PDF-`, 0 fotos, 6 fotos e rejeição de OS não concluída.

---

### Caso de Uso UC-05.02 — Visualização & Preview do Laudo no App

* **Identificador**: `UC-05.02`
* **Status**: `Implementado e integrado no app (rota `/report-preview`, acionado por OS concluída)`
* **Gate DoR**: `tools/bin/claims claim -path . -slice UC-05.02 -owner <agente> -paths lib/modules/reports/`
* **Gate DoD**: `tools/bin/claims release -path . -slice UC-05.02`

#### Narrativa
- **Como** Técnico
- **Eu quero** visualizar o resumo e o status do laudo gerado antes de enviá-lo
- **Para que** eu tenha certeza de que fotos, dados e assinatura estão corretos.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Esquema do Cenário: Carregamento do preview do laudo gerado
  Dado que o técnico abre a tela de laudo da OS
  Quando o gerador responder com <estado_geracao>
  Então a interface deve exibir <estado_ui>

  Exemplos:
    | estado_geracao | estado_ui |
    | "CARREGANDO" | "Indicador de geração em andamento" |
    | "SUCESSO" | "Resumo do laudo + botão Compartilhar PDF (>= 48dp)" |
    | "ERRO" | "Mensagem amigável + botão Tentar novamente" |
```
* **Fixture**: `docs/plan/fixtures/uc-05-laudo-pdf-share.json`

#### NFRs Mensuráveis
| UC | NFR | Métrica | Target | Medição |
| :--- | :--- | :--- | :--- | :--- |
| `UC-05.02` | Alvo tátil de compartilhamento | Altura do botão CTA | `>= 48 dp` | Widget test |

---

### Caso de Uso UC-05.03 — Compartilhamento Nativo com 1 Toque (WhatsApp)

* **Identificador**: `UC-05.03`
* **Status**: `Implementado e integrado no app (compartilhamento com 1 toque no preview)`
* **Gate DoR**: `tools/bin/claims claim -path . -slice UC-05.03 -owner <agente> -paths lib/modules/reports/`
* **Gate DoD**: `tools/bin/claims release -path . -slice UC-05.03`

#### Narrativa
- **Como** Técnico
- **Eu quero** compartilhar o PDF do laudo diretamente pelo menu nativo do celular (WhatsApp, E-mail, Impressão) com 1 toque
- **Para que** o cliente receba o documento na hora, sem retrabalho.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Esquema do Cenário: Compartilhamento do arquivo PDF via Share nativo
  Dado que o laudo PDF foi gerado em disco
  Quando o técnico clicar em Compartilhar com <nome_arquivo> e <resultado_so>
  Então o sistema deve retornar <resultado>

  Exemplos:
    | nome_arquivo | resultado_so | resultado |
    | "OS-202611-0001.pdf" | "COMPARTILHADO" | "Result.Ok(void)" |
    | "" | "COMPARTILHADO" | "Result.Fail(ERR_LAUDO_ARQUIVO_INVALIDO)" |
    | "OS-202611-0001.pdf" | "CANCELADO_PELO_USUARIO" | "Result.Ok(void)" |
```
* **Fixture**: `docs/plan/fixtures/uc-05-laudo-pdf-share.json`

#### NFRs Mensuráveis
| UC | NFR | Métrica | Target | Medição |
| :--- | :--- | :--- | :--- | :--- |
| `UC-05.03` | Desacoplamento de plataforma | Dependência do domínio | `0 imports share_plus no domain/` | Revisão de imports / analyze |

---

### Caso de Uso UC-05.04 — Histórico e Reemissão de Laudos Salvos

* **Identificador**: `UC-05.04`
* **Status**: `Implementado e integrado (cache/regeneração, reabertura por OS e tela de histórico visual dedicada)`
* **Gate DoR**: `tools/bin/claims claim -path . -slice UC-05.04 -owner <agente> -paths lib/modules/reports/`
* **Gate DoD**: `tools/bin/claims release -path . -slice UC-05.04`

#### Narrativa
- **Como** Técnico
- **Eu quero** reabrir ou reenviar qualquer laudo de OS concluída no histórico do cliente
- **Para que** eu possa fornecer uma segunda via em segundos caso o cliente perca o arquivo.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Esquema do Cenário: Reemissão de laudo no histórico
  Dado que o técnico seleciona uma OS no histórico com <pdf_em_cache>
  Quando solicitar abrir ou reenviar o laudo
  Então o sistema deve <acao>

  Exemplos:
    | pdf_em_cache | acao |
    | "EXISTE_NO_DISCO" | "Abrir/compartilhar arquivo salvo imediatamente" |
    | "REMOVIDO_DO_DISCO" | "Regenerar PDF a partir da OS imutável e salvar novamente" |
    | "OS_INEXISTENTE" | "Result.Fail(ERR_OS_NAO_ENCONTRADA)" |
```
* **Fixture**: `docs/plan/fixtures/uc-05-laudo-pdf-share.json`

#### NFRs Mensuráveis
| UC | NFR | Métrica | Target | Medição |
| :--- | :--- | :--- | :--- | :--- |
| `UC-05.04` | Reabertura em cache | Tempo de leitura do PDF salvo | `< 100 ms` | Teste de repositório de laudos |

---

## 5. Dados e Configuração

### 5.1 Armazenamento Local de Laudos
- Diretório privado: `getApplicationSupportDirectory()/reports/OS-<id>.pdf`.
- Nenhuma migration adicional obrigatória (ou tabela opcional `generated_reports` indexada por `work_order_id`).

### 5.2 Config Schema
- Sem variáveis de ambiente externas (100% on-device).
