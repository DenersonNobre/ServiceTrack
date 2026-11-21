# Épico 01: Onboarding, Autenticação Local & Perfil do Técnico

## Metadados

| Atributo | Valor |
| :--- | :--- |
| **Identificador** | `EPIC01` |
| **Dependências Diretas** | `EPIC00` (Fundação Flutter) |
| **Prioridade** | Alta (Portão de Entrada do App) |
| **Responsável (Arquiteto)** | Denerson Nobre |
| **Status Atual** | `Em Andamento` (UC-01.01 concluído; UC-01.02..05 pendentes) |
| **Referências da SPEC** | [docs/architecture/SPEC.md](../../architecture/SPEC.md) \| [docs/product/PRD.md](../../product/PRD.md) |

---

## 1. Objetivo de Negócio & Escopo

Garantir o portão de entrada seguro e a identidade comercial do técnico no **ServiceTrack Standalone**. No primeiro acesso, o aplicativo realiza o onboarding obrigatório para registrar os dados do profissional (Nome, E-mail, Telefone, Senha e PIN). Nas sessões subsequentes, oferece autenticação veloz e ergonômica via Biometria (Face ID / Digital) ou PIN tátil, com fallback em Senha Mestre e tolerância à operação com mãos sujas ou sem internet.

- **Incluso**:
  - `UC-01.01`: Fluxo de Onboarding inicial (Cadastro de Nome, E-mail, Senha Mestre e PIN numérico).
  - `UC-01.02`: Mecanismo de Entrada Rápida com Biometria (`local_auth`) e opção "Lembrar de Mim" para aparelhos sem leitor biométrico.
  - `UC-01.03`: Desbloqueio alternativo por PIN numérico de 4 a 6 dígitos em cofre seguro (`flutter_secure_storage`).
  - `UC-01.04`: Recuperação de Acesso Local via Senha Mestre e Autenticação do Sistema Operacional.
  - `UC-01.05`: Gestão de Perfil Comercial (edição de dados que alimentam o cabeçalho dos laudos técnicos).
- **Não Incluso / Fora do Escopo**:
  - Envio de e-mail de recuperação por servidor remoto ou login em nuvem (escopo 100% local no MVP).

---

## 2. Matriz de Casos de Uso (Feature Matrix)

| ID do Caso de Uso | Título do Caso de Uso | Dependências Internas | Status |
| :--- | :--- | :--- | :---: |
| **UC-01.01** | Onboarding Inicial & Registro de Credenciais | Nenhuma | `Concluído` |
| **UC-01.02** | Autenticação por Biometria / "Lembrar de Mim" | UC-01.01 | `Concluído` |
| **UC-01.03** | Desbloqueio Rápido via Teclado de PIN Numérico | UC-01.01 | `Pendente` |
| **UC-01.04** | Recuperação de Acesso Local & Fallback do SO | UC-01.01, UC-01.03 | `Pendente` |
| **UC-01.05** | Edição de Perfil Comercial do Técnico | UC-01.01 | `Pendente` |

---

## 3. Definição de Pronto (DoD) do Épico

- [ ] Todos os Casos de Uso (`UC-01.01..05`) implementados com TDD Red-Before-Green.
- [ ] Credenciais sensíveis (PIN e Senha) armazenadas exclusivamente no `flutter_secure_storage`.
- [ ] 100% dos testes unitários e de widget cobrindo sucesso, PIN incorreto e ausência de hardware biométrico.
- [ ] Build e `flutter analyze` retornando zero warnings e zero erros.
- [ ] `docs/plan/README.md` atualizado com o progresso do épico.

---

## 4. Casos de Uso Atômicos

---

### Caso de Uso UC-01.01 — Onboarding Inicial & Registro de Credenciais

* **Identificador**: `UC-01.01`
* **Status**: `Concluído`
* **Gate DoR**: `tools/bin/claims claim -path . -slice UC-01.01 -owner <agente> -paths lib/modules/auth/`
* **Gate DoD**: `tools/bin/claims release -path . -slice UC-01.01`
* **Evidência**: TASK-01/02/03 verdes (33/33, analyze limpo). Gates 2.5/3/4 aprovados (Alta). Laudos `qa-review-v0.1.0`, `qa-review-v0.2.0`, `qa-review-v0.3.0`. Desvio PBKDF2 PIN autorizado pelo PO (2026-11-21). Obs. QA: B1-B3 registradas no laudo v0.3.0.

#### Narrativa
- **Como** Técnico autônomo abrindo o ServiceTrack pela primeira vez
- **Eu quero** cadastrar meus dados profissionais (Nome, E-mail, Telefone), minha Senha Mestre e um PIN numérico
- **Para que** meu aplicativo seja protegido contra terceiros e meus laudos técnicos já nasçam com meu cabeçalho personalizado.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Esquema do Cenário: Validação do cadastro de credenciais no primeiro acesso
  Dado que o usuário está na tela de boas-vindas do onboarding
  Quando informar <nome>, <email>, <senha> e <pin>
  Então o sistema deve validar os campos e retornar <status>

  Exemplos:
    | nome | email | senha | pin | status |
    | "Rodrigo Silva" | "rodrigo@clima.com" | "Segura@2026" | "1234" | "SUCESSO_CADASTRADO" |
    | "" | "rodrigo@clima.com" | "Segura@2026" | "1234" | "ERR_NOME_OBRIGATORIO" |
    | "Rodrigo Silva" | "invalido" | "Segura@2026" | "1234" | "ERR_EMAIL_INVALIDO" |
    | "Rodrigo Silva" | "rodrigo@clima.com" | "123" | "1234" | "ERR_SENHA_CURTA" |
    | "Rodrigo Silva" | "rodrigo@clima.com" | "Segura@2026" | "12" | "ERR_PIN_INVALIDO" |
```
* **Fixture**: `docs/plan/fixtures/uc-01-01-onboarding.json`

#### Tarefas Técnicas (Tasks)
1. `TASK-01`: Criar Value Objects `TechnicianName`, `Email`, `MasterPassword` e `SecurityPin` com testes unitários.  
   ➔ **Commit**: `feat(auth): criar value objects de credenciais locais`
2. `TASK-02`: Implementar repositório seguro com `flutter_secure_storage` para guardar hash e PIN.  
   ➔ **Commit**: `feat(auth): implementar persistencia segura no cofre local`
3. `TASK-03`: Criar tela de Onboarding com os Design Tokens do Styleguide (Deep Petrol Green).  
   ➔ **Commit**: `feat(auth): criar tela de onboarding inicial do tecnico`

---

### Caso de Uso UC-01.02 — Autenticação por Biometria / "Lembrar de Mim"

* **Identificador**: `UC-01.02`
* **Status**: `Concluído`
* **Evidência**: 51/51 testes, analyze limpo. Gate 2.5 INVOKED/APROVADO Média (A1-A5 aplicados). Gate 3 APROVADO Média. Gate 4 APROVADO Alta (`qa-review-v0.4.0.md`). Refatoração pós-QA: barrels `.index.dart` (`9186d4c`) reverificada.

#### Narrativa
- **Como** Técnico autônomo com o app configurado
- **Eu quero** entrar no app usando minha impressão digital / Face ID ou deixar a opção "Lembrar de mim" ativada
- **Para que** eu não perca tempo digitando credenciais a cada abertura de chamado.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Esquema do Cenário: Autenticação biométrica na abertura do app
  Dado que o técnico possui biometria configurada
  Quando abrir o aplicativo e o sensor biométrico retornar <resultado_sensor>
  Então o app deve apresentar <comportamento>

  Exemplos:
    | resultado_sensor | comportamento |
    | "SUCESSO" | "ENTRADA_DIRETA_HOME" |
    | "FALHA_LEITURA" | "SOLICITAR_PIN_MANUAL" |
    | "CANCELADO_PELO_USUARIO" | "PERMANECER_TELA_PIN" |
```
* **Fixture**: `docs/plan/fixtures/uc-01-02-biometrics.json`

---

### Caso de Uso UC-01.03 — Desbloqueio Rápido via Teclado de PIN Numérico

* **Identificador**: `UC-01.03`
* **Status**: `Pendente`

#### Narrativa
- **Como** Técnico com as mãos sujas de trabalho ou luvas em campo
- **Eu quero** um teclado numérico com botões grandes de pelo menos 48dp para digitar meu PIN
- **Para que** eu consiga desbloquear o app de primeira sem erros tácteis.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Esquema do Cenário: Validação de PIN na tela de bloqueio
  Dado que o app está bloqueado aguardando PIN
  Quando o técnico digitar a sequência <pin_digitado>
  Então o sistema deve responder com <resultado>

  Exemplos:
    | pin_digitado | resultado |
    | "1234" (correto) | "ACESSO_LIBERADO" |
    | "9999" (incorreto) | "ERR_PIN_INCORRETO_TENTATIVAS_RESTANTES" |
    | "0000" (3x erro) | "BLOQUEIO_TEMPORARIO_OU_PEDIR_SENHA" |
```
* **Fixture**: `docs/plan/fixtures/uc-01-03-pin.json`

---

### Caso de Uso UC-01.04 — Recuperação de Acesso Local & Fallback do SO

* **Identificador**: `UC-01.04`
* **Status**: `Pendente`

#### Narrativa
- **Como** Técnico que esqueceu seu PIN numérico
- **Eu quero** redefinir meu PIN usando minha Senha Mestre ou a autenticação de segurança do próprio celular
- **Para que** eu nunca perca meus dados ou fique sem trabalhar.

#### Critérios de Aceitação (Gherkin Executável)
```gherkin
Esquema do Cenário: Recuperação de PIN esquecido
  Dado que o técnico clicou em "Esqueci meu PIN"
  Quando autenticar com sucesso usando <metodo_recuperacao>
  Então o app deve permitir recadastrar um novo PIN sem apagar o histórico de OSs

  Exemplos:
    | metodo_recuperacao |
    | "SENHA_MESTRE_VALIDA" |
    | "BIOMETRIA_OU_PADRAO_DO_SISTEMA_OPERACIONAL" |
```
* **Fixture**: `docs/plan/fixtures/uc-01-04-recovery.json`

---

### Caso de Uso UC-01.05 — Edição de Perfil Comercial do Técnico

* **Identificador**: `UC-01.05`
* **Status**: `Pendente`

#### Narrativa
- **Como** Técnico autônomo
- **Eu quero** editar meus dados de contato (WhatsApp, logotipo/foto, nome comercial)
- **Para que** as alterações reflitam imediatamente nos próximos laudos técnicos em PDF que eu gerar.

---

## 5. Dados e Configuração

### Cofre Seguro Local (`flutter_secure_storage`)
| Chave | Descrição | Formato |
| :--- | :--- | :--- |
| `sec_user_id` | Identificador único do técnico | UUID v4 |
| `sec_master_password_hash` | Hash da Senha Mestre | Salt + PBKDF2-HMAC-SHA-256, formato `v1$pbkdf2-sha256$iter$salt$hash` |
| `sec_pin_hash` | Hash do PIN numérico | Salt + PBKDF2-HMAC-SHA-256, formato `v1$pbkdf2-sha256$iter$salt$hash` (decisão Gate 2.5/PO 2026-11-21: SHA-256 de 1 iteração é força-brutável para 10⁴–10⁶ candidatos) |
| `sec_pin_fail_count` / `sec_pin_locked_until` | Rate-limit do PIN (estado de segurança) | Contador + epoch-ms UTC do bloqueio; 3 falhas → bloqueio base 30s com backoff, teto 15min |
| `sec_biometrics_enabled` | Flag de biometria ativa | Booleano ("true"/"false") |
| `sec_remember_me` | Flag de lembrar sessão | Booleano ("true"/"false") |
