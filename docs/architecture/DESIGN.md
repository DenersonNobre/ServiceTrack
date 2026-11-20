# ServiceTrack — Especificação de Design & Contratos Visuais (Mobile Standalone)

> **Autor (PO ou Arquiteto)**: Denerson Nobre  
> **Status**: `Aprovado` | **Versão**: `2.0.0` (Mobile Flutter 100% Nativo) | **Data**: `2026-11-20`  
> **Documentos de Referência**: [docs/product/PRD.md](../product/PRD.md) | [docs/architecture/SPEC.md](SPEC.md)

---

## 1. Princípios de Design & Identidade

- **Filosofia Visual**: Inspirada diretamente no **Product UI Styleguide v2.1** (*Clean SaaS Monochrome & Deep Petrol Green*).
- **Adequação para Uso em Campo**:
  - Superfícies claras e neutras quentes (`#FBF9F5`) com legibilidade máxima sob a luz do sol.
  - Ação primária forte em **Verde-Petróleo Profundo** (`#115E59`).
  - Alvos de toque grandes (mínimo de `48px`) para operação confortável com uma única mão ou uso com luvas de trabalho.
  - Feedback háptico sutil a cada confirmação de checklist ou botão de início/fim de OS.

---

## 2. Design Tokens Canônicos (Styleguide v2.1)

### 2.1 Cores Semânticas

| Token | Hex | Uso no Flutter | Contraste |
| :--- | :--- | :--- | :---: |
| `--color-primary-action` | `#115E59` | Botões principais, CTAs ("Iniciar", "Concluir", "Gerar PDF") | 7:1 (AAA) |
| `--color-primary-hover` | `#0F4C47` | Efeito splash/pressed | — |
| `--color-surface` | `#FBF9F5` | Fundo principal dos cards e telas | — |
| `--color-surface-card` | `#FFFFFF` | Cards elevados e itens de checklist | — |
| `--color-border` | `#E2DDD5` | Contornos sutis de cards e divisores | — |
| `--color-gray-900` | `#18181B` | Títulos e textos de alta ênfase | 12:1 (AAA) |
| `--color-gray-700` | `#3F3F46` | Textos de leitura e dados do cliente | 7:1 (AAA) |
| `--color-gray-500` | `#71717A` | Rótulos secundários e coordenadas GPS | 4.5:1 |
| `--color-gray-100` | `#F4F4F5` | Chips neutros e fundos inativos | — |

#### Badges de Status (Soft Borders)
- **Success** (`#EBF8F0` / borda `#A3E6BA` / texto `#166534`): Concluído, Conforme.
- **Info** (`#EBF5FF` / borda `#A5D0FF` / texto `#1E40AF`): Agendada.
- **Warning** (`#FEF8E7` / borda `#FDE08B` / texto `#854D0E`): Em Atendimento, Não se Aplica.
- **Error** (`#FEEFEF` / borda `#FCA5A5` / texto `#991B1B`): Não Conforme, Cancelada.

### 2.2 Tipografia & Alvos Táteis
- **Títulos**: `Inter Display` / `Plus Jakarta Sans` Bold.
- **Corpo & Rótulos**: `Inter` Medium / Regular.
- **Dados Técnicos / GPS**: `JetBrains Mono` / Monospace nativo.
- **Alvo Mínimo de Toque**: `48dp` x `48dp` em qualquer botão ou seletor.

### 2.3 Raios de Borda & Elevações
- Botões e Cards de OS: `12px` de raio com sombra suave Level 1 (`0 2px 4px -1px rgba(0,0,0,0.06)`).
- Chips e Filtros: `24px` (Full Pill).
- Modais e BottomSheets: `16px` de raio superior com sombra Level 3.

---

## 3. Telas & Fluxos Centrais do Aplicativo

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        MAPA DE TELAS DO FLUTTER                        │
├─────────────────────┬────────────────────┬─────────────────────────────┤
│  1. Início / Lista  │ 2. Execução da OS  │  3. Laudo & Compartilhar    │
│  - Próximas Visitas │ - Dados do Cliente │  - Preview do PDF           │
│  - Histórico de OSs │ - Checklist Tátil  │  - Assinatura na tela       │
│  - Botão Nova OS    │ - Câmera & Fotos   │  - Enviar via WhatsApp      │
└─────────────────────┴────────────────────┴─────────────────────────────┘
```

---

## 4. Contrato Visual do Laudo Técnico em PDF (Gerado no Celular)

O documento PDF gerado pelo pacote `package:pdf` no celular segue estritamente a identidade do Styleguide:

1. **Cabeçalho Corporativo**:
   - Barra superior com a cor sólida `--color-primary-action` (`#115E59`).
   - Logotipo ou Nome Fantasia do Técnico / Contato (WhatsApp e E-mail).
   - Número único da OS (ex: `OS-202611-0012`) e Data/Hora de emissão.
2. **Dados do Cliente & Localização**:
   - Tabela limpa com Nome, Telefone, Endereço e Coordenadas do GPS validadas.
3. **Resumo do Serviço Executado & Checklist**:
   - Grade com os itens inspecionados com tags estilizadas `[ Conforme ]`, `[ Não Conforme ]` e observações do técnico.
4. **Galeria de Evidências Fotográficas**:
   - Grade organizada de até 6 fotos com bordas sutis e legenda inferior com carimbo de data/hora UTC e coordenadas de captura.
5. **Termo de Encerramento & Assinatura Digital**:
   - Texto de garantia do serviço prestado.
   - Quadro com a imagem da assinatura colhida na tela do celular + Nome e Documento legível do cliente.

---

## 5. Diretrizes de Responsividade, Dispositivos & Orientação

- **Matriz de Dispositivos & Regra de Orientação (Invariante de UI)**:
  - **Smartphones (`largura < 600dp`)**:
    - **Orientação Estritamente Retrato (`Portrait-Only`)**: O app bloqueia a rotação em smartphones (`SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])`).
    - **Motivo de Campo**: Impede rotações acidentais e layouts comprimidos enquanto o técnico manuseia o aparelho com uma única mão ou sob escadas/andaimes.
  - **Tablets (`largura >= 600dp` — iPad / Galaxy Tab)**:
    - **Orientação Híbrida (`Portrait` & `Landscape`)**: Apenas em tablets a rotação para paisagem é liberada.
    - **Layout Master-Detail Dinâmico (Landscape)**:
      - *Painel Esquerdo (Master - 380dp fixo)*: Agenda de visitas do dia, filtros rápidos por chip e status da OS.
      - *Painel Direito (Detail - Flexível)*: Execução do checklist, anexo de fotos e preview instantâneo do laudo PDF lado a lado.
- **Acessibilidade Tátil de Campo (WCAG AA)**:
  - Alvos de toque nunca inferiores a `48dp` x `48dp`.
  - Contraste superior a 4.5:1 sob forte incidência solar.
  - Feedback háptico tátil a cada confirmação de checklist ou check-in.

---

## 6. ADRs — Decisões de Arquitetura (Standalone)

| ADR | Decisão | Alternativa | Trade-off / Justificativa |
| :--- | :--- | :--- | :--- |
| `ADR-01` | **App 100% Standalone no Aparelho** | Backend em Nuvem (NestJS/Postgres) | Elimina 100% do custo de servidor, zero complexidade de autenticação remota e entrega imediata de valor para técnicos autônomos. |
| `ADR-02` | **Banco Local SQLite com Drift** | SharedPreferences / Hive | Drift garante schema relacional forte, tipagem estrita em Dart e consultas rápidas para histórico e clientes. |
| `ADR-03` | **Geração de PDF On-Device via Isolate** | Webview HTML-to-PDF ou API externa | Funciona sem internet em menos de 1 segundo e não consome dados móveis nem servidores. Execução em Isolate impede travamento da tela. |
| `ADR-04` | **Compartilhamento via Share Nativo do SO** | Envio direto por SMTP/Servidor | Aproveita os apps já instalados no celular do técnico (WhatsApp, Gmail, Telegram), garantindo entrega instantânea na conversa do cliente. |
| `ADR-05` | **Smartphones Portrait-Only vs Tablets Híbridos (Landscape)** | Rotação livre em todos os aparelhos | Rotação em celular durante serviços de campo gera toques acidentais e perda de contexto. No tablet, a paisagem destrava produtividade Master-Detail de alta densidade. |
