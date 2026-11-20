# ServiceTrack - Product Requirements Document (PRD)

> **Status**: `Aprovado`  
> **Versão**: `2.0.0` (Pivô Estratégico: Mobile Standalone Autocontido) | **Data**: `2026-11-20`  
> **Product Owner**: Denerson Nobre  
> **Arquitetura Base**: Flutter 100% Local (Zero Backend / Zero Infraestrutura de Nuvem Inicial)

---

## 1. Visão Geral & Proposta de Valor

### 1.1 Declaração do Problema (Problem Statement)
- **Cenário Atual**: Técnicos autônomos, prestadores de serviços de ar-condicionado, eletricistas, encanadores, instaladores e pequenos empreiteiros dependem de blocos de papel, pranchetas ou blocos de notas no celular.
- **Pontos de Fricção (Pain Points)**:
  - *Fricção 1 (Sistemas corporativos caros e complexos)*: Softwares de FSM (Field Service Management) existentes no mercado são caros, exigem mensalidades pesadas, servidores em nuvem e painéis web pensados para grandes corporações, sendo inviáveis para quem trabalha sozinho ou em dupla.
  - *Fricção 2 (Amadorismo e Contestação)*: Ao terminar o serviço, o técnico manda uma foto no WhatsApp ou anota num papel sem valor jurídico, gerando contestação de clientes sobre o que foi executado, garantia e peças trocadas.
  - *Fricção 3 (Dependência de Internet e Perda de Tempo à Noite)*: O técnico chega em casa cansado e precisa redigir propostas e laudos no computador para enviar aos clientes por e-mail.

### 1.2 Proposta de Valor & Diferencial Competitivo
- **Para**: Técnicos autônomos, instaladores, vistoriadores e pequenos prestadores de serviços em campo.
- **Que buscam**: Emitir ordens de serviço (OS) e laudos técnicos com padrão profissional em menos de 2 minutos diretamente pelo celular.
- **O ServiceTrack é**: Um aplicativo móvel (Android & iOS) **100% autocontido (Standalone)**, que opera offline sem necessidade de criar conta, sem servidores na nuvem e sem mensalidade de infraestrutura.
- **Que entrega**: Cadastro ágil de clientes/serviços, checklist tátil rápido, fotos com carimbo de auditoria (data/hora UTC e coordenadas GPS), assinatura digital coletada no vidro do celular e **geração instantânea do Laudo Técnico em PDF profissional no próprio aparelho**, pronto para envio imediato via WhatsApp ou E-mail.
- **Diferente de**: Sistemas pesados com retaguarda web ou formulários estáticos sem validade de comprovação.
- **Nosso produto**: O técnico baixa da loja e começa a faturar e emitir laudos em 30 segundos, sem setup, com total soberania sobre seus dados locais.

---

## 2. Personas & Jornadas de Usuário

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        PERSONA CENTRAL DO PRODUTO                      │
├────────────────────────────────────────────────────────────────────────┤
│  Rodrigo Silva                                                         │
│  Papel: Técnico Instalador Autônomo (Refrigeração & Climatização)      │
│  Contexto: Trabalha sozinho ou com 1 ajudante; atende 3 a 6 locais/dia │
│  Foco: Agilidade no celular, receber na hora e passar profissionalismo │
└────────────────────────────────────────────────────────────────────────┘
```

### 2.1 Jornada de Sucesso (Happy Path de Rodrigo)
1. **Cadastro Rápido**: Rodrigo recebe um chamado no WhatsApp, abre o app e cria a OS em 20 segundos (digita o nome do cliente e endereço).
2. **Chegada e Execução**: No local (mesmo em subsolo ou galpão sem sinal), clica em "Iniciar Atendimento" (o app captura o GPS e o relógio local).
3. **Comprovação**: Executa o serviço, marca o checklist rápido com polegar, tira até 6 fotos pelo app (antes e depois).
4. **Assinatura e Laudo**: Mostra o resumo na tela do celular para o cliente assinar com o dedo, insere o nome do cliente.
5. **Fechamento**: Clica em "Gerar Laudo PDF". Em 1 segundo o app gera um laudo com design editorial de alto padrão (Styleguide Deep Petrol Green) e abre a bandeja nativa de compartilhamento direto para o WhatsApp do cliente.

---

## 3. Requisitos Funcionais (RF) — Mobile 100% Local

### 3.1 Módulo: Identidade Local, Segurança & Acesso

- **RF-01 (Cadastro Inicial Obrigatório do Técnico)**:
  - Na primeira abertura (Onboarding), o técnico deve cadastrar obrigatoriamente: **Nome/Razão Social, E-mail, Senha Mestre e PIN numérico (4 a 6 dígitos)**.
  - Esses dados alimentam simultaneamente a credencial de segurança local e o cabeçalho comercial dos laudos técnicos em PDF.
- **RF-02 (Armazenamento Seguro de Credenciais)**:
  - A senha deve ser armazenada com hash criptográfico seguro (Argon2 ou PBKDF2/SHA-256 com salt) e o PIN no cofre seguro nativo do SO (`flutter_secure_storage` via Keystore no Android e Keychain no iOS).
- **RF-03 (Política de Entrada e Biometria)**:
  - **Com Hardware de Biometria**: Opção "Entrar com Biometria" (Face ID / Digital via `local_auth`). Estando ativa, o app abre sem pedir senha/PIN.
  - **Sem Hardware de Biometria**: Opção "Lembrar de Mim" (mantém a sessão desbloqueada localmente).
  - **Acesso Rápido de Campo**: Se a sessão expirar ou a biometria falhar temporariamente (mão suja de graxa/óleo), o técnico pode desbloquear rapidamente digitando apenas o **PIN numérico**.
- **RF-04 (Recuperação de Acesso Local)**:
  - Caso o técnico esqueça o PIN: pode desbloquear usando a **Senha Mestre**.
  - Caso o técnico esqueça a Senha Mestre: pode recuperar o acesso autenticando-se com a **Credencial/Senha de Bloqueio do próprio smartphone** (fallback do sistema operacional) ou via pergunta/chave de emergência gerada no cadastro inicial.

### 3.2 Módulo: Gestão Local de Clientes & Histórico
- **RF-01**: O aplicativo deve permitir o cadastro direto de clientes (Nome/Razão Social, Telefone/WhatsApp, CPF/CNPJ, E-mail e Endereço).
- **RF-02**: O aplicativo deve exibir o histórico de atendimentos e laudos já emitidos para cada cliente no próprio aparelho.

### 3.2 Módulo: Ordens de Serviço & Ciclo de Vida
- **RF-03**: O técnico deve poder criar uma nova OS selecionando um cliente existente ou cadastrando um novo na hora.
- **RF-04**: O aplicativo deve conduzir a OS pelos estados: `Agendada` ➔ `Em Atendimento` (Check-in com GPS) ➔ `Concluída` (Check-out com GPS e Assinatura) ou `Cancelada`.
- **RF-05**: O aplicativo deve registrar automaticamente coordenadas de geolocalização e carimbo de data/hora no início e término do atendimento.

### 3.3 Módulo: Checklists & Evidências de Campo
- **RF-06**: O técnico deve poder cadastrar modelos de checklist reutilizáveis (ex: "Instalação de Ar Split", "Manutenção Preventiva").
- **RF-07**: Cada item do checklist deve permitir resposta tátil rápida: `[Conforme]`, `[Não Conforme]`, `[Não se Aplica]` e observação opcional.
- **RF-08**: O aplicativo deve permitir capturar fotos da câmera ou galeria (máximo de 6 fotos por OS), compactando e gravando marca d'água de data/hora e coordenadas.
- **RF-09**: O aplicativo deve colher a assinatura digital do cliente na tela do celular, com campo para nome completo e documento (CPF/RG).

### 3.4 Módulo: Motor de Geração de Laudo em PDF (On-Device)
- **RF-10**: O aplicativo deve compilar o Laudo Técnico em PDF no próprio smartphone (usando pacote nativo Dart `pdf`), sem depender de internet.
- **RF-11**: O PDF deve conter cabeçalho personalizável (com logo do técnico/empresa e dados de contato), sumário do serviço, checklist estruturado, galeria de evidências com fotos nítidas e as assinaturas digitais.
- **RF-12**: O aplicativo deve disparar a folha de compartilhamento nativa do sistema operacional (Android/iOS) para envio via WhatsApp, E-mail ou impressão Bluetooth/Wi-Fi.

### 3.5 Módulo: Backup & Exportação
- **RF-13**: O técnico deve poder fazer backup de segurança de todo o banco de dados local em arquivo ZIP/JSON no Google Drive/iCloud ou armazenamento do aparelho.

---

## 4. Requisitos Não Funcionais (RNF)

- **RNF-01 (Zero Dependência de Backend)**: 100% das funcionalidades de cadastro, captura de evidências e geração de PDF devem operar de forma autônoma sem sinal de celular.
- **RNF-02 (Performance de Geração de PDF)**: Compilação do PDF completo (com até 6 fotos compactadas e assinaturas) em menos de 2.0 segundos em dispositivos intermediários.
- **RNF-03 (Consumo de Armazenamento Local)**: Compressão automática de imagens no dispositivo para JPEG de qualidade otimizada (máximo 400KB por foto salva), garantindo que centenas de OSs ocupem menos de 150 MB no aparelho.
- **RNF-04 (Privacidade e LGPD)**: Dados pertencem exclusivamente ao técnico no seu dispositivo local. Nenhuma informação de clientes ou fotos trafega para servidores de terceiros.
- **RNF-05 (Design, Dispositivos & Orientação)**:
  - Implementação fiel do Styleguide v2.1 (superfícies limpas, Deep Petrol Green `#115E59`, alvos de toque >= 48px).
  - **Smartphones (`< 600dp`)**: Orientação estritamente Retrato (`Portrait-Only`), travada contra rotações acidentais em campo.
  - **Tablets (`>= 600dp`)**: Suporte híbrido com modo Paisagem (`Landscape`) ativando layout Master-Detail (agenda à esquerda, detalhes e execução da OS à direita).

---

## 5. Limites do Produto (Explicit Non-Goals do MVP Standalone)

1. **Painel Web / Retaguarda em Nuvem**: Não há backend centralizado, Next.js nem servidor NestJS no escopo inicial.
2. **Sincronização em Tempo Real Multi-Dispositivo**: Cada técnico possui seu app isolado em seu próprio aparelho (backup via exportação de arquivo).
3. **Cobrança / Gateway de Pagamento Integrado**: O técnico combina e recebe seus valores diretamente via Pix/maquininha física habitual.
4. **Telemetria de Trajeto Contínuo**: Apenas coordenadas pontuais de início e fim da OS para preservar 100% da bateria do aparelho.

---

## 6. Métricas de Sucesso do Produto (KPIs)

| Métrica / Indicador | Sem o App (Papel / WhatsApp) | Com o ServiceTrack Standalone |
| :--- | :--- | :--- |
| **Tempo para Emitir um Laudo Formal** | 2 a 4 horas (à noite no PC) | **< 90 segundos no próprio local** |
| **Custo de Infraestrutura / Servidor** | Variável / Risco de mensalidade | **R$ 0,00 (Zero custo de nuvem)** |
| **Taxa de Fechamento de OS sem Sinal** | 0% (se depender de nuvem) | **100% autônomo offline** |
| **Percepção de Valor / Profissionalismo** | Informal (recibo de papel) | **PDF com padrão corporativo e fotos** |
