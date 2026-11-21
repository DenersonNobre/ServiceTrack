# Laudo de Auditoria de Código — `EPIC-01` (Auth & Perfil)

> **Governança**: Auditoria independente de código da `EPIC-01` (`lib/modules/auth/`, `lib/modules/profile/` e wiring em `lib/main.dart`) frente a [SPEC.md](../../architecture/SPEC.md), [PRD.md](../../product/PRD.md), [DESIGN.md](../../architecture/DESIGN.md) e [AGENTS.md](../../../AGENTS.md).

---

## 1. Metadados da Auditoria

| Campo | Informação |
| :--- | :--- |
| **Escopo Auditado** | `EPIC-01` (`UC-01.01` a `UC-01.05`) — `lib/modules/auth/`, `lib/modules/profile/`, `lib/main.dart` |
| **Data / Hora** | `2026-11-21 13:07:45` |
| **Auditor** | Antigravity (`agy01@59993bf1`) |
| **Veredito Geral** | **APROVADO COM RESSALVAS** |

---

## 2. Evidência Empírica de Execução (Gates Automatizados)

### 2.1 Análise Estática (Linter Estrito)
```text
Comando: flutter analyze --fatal-infos
Erros: 0
Avisos: 0
Tempo de Execução: 21.6s
Exit Code: 0
Status: PASS
```

### 2.2 Suíte de Testes (Unitários & Widgets)
```text
Comando: flutter test
Total de Testes: 88
Passaram: 88
Falharam: 0
Tempo de Execução: 02:50
Exit Code: 0
Status: PASS
```

### 2.3 Varredura de Padrões Proibidos (`AGENTS.md` §1)
```text
Padrões verificados em lib/**/*.dart: synapx | GetX | ChangeNotifier | Provider | print( | throw 
Ocorrências: 0
Status: PASS
```

---

## 3. Matriz de Conformidade com a Especificação & Diretivas

| Requisito / Diretiva | Status | Evidência |
| :--- | :---: | :--- |
| **Motor reativo `kortex` exclusivo** | Conforme | `IKortexController`, `KortexSignal`, `KortexScope` em todo `auth/` e `profile/`; zero GetX/ChangeNotifier |
| **Uso de `dnolib` sem `synapx`** | Conforme | `IResult`, `ValidationError` usados; zero imports de `synapx` |
| **Criptografia segura de credenciais (RF-02)** | Conforme | `Pbkdf2Sha256` (RFC 8018, 210k iterações, salt 16 bytes CSPRNG, `constantTimeEquals`, `toString()` redigido) |
| **Rate-limit / Lockout exponencial (PIN e Senha)** | Conforme | `SecureCredentialStore` aplica backoff exponencial (30s..15m) após 3 falhas, coberto por testes |
| **Persistência de Nome e E-mail no Onboarding (RF-01)** | **Não Conforme** | `OnboardingController.submit()` valida `name` e `email`, mas descarta ambos ao salvar (ver **M1**) |
| **Orientação `Portrait-Only` em Smartphones (RNF-05)** | **Não Conforme** | `lib/main.dart` não configura `SystemChrome.setPreferredOrientations` (ver **M3**) |
| **Responsividade / Não congelar UI (NFR)** | **Ressalva** | PBKDF2 210k iterações roda síncrono na Main Isolate (ver **M2**) |

---

## 4. Tabela de Apontamentos por Severidade

### 4.1 Bloqueadores (Blockers — B1..Bn)

| ID | Descrição do Problema | Impacto | Ação Corretiva Exigida |
| :--- | :--- | :--- | :--- |
| *Nenhum* | Build, análise estática e 88/88 testes passam; segurança criptográfica e rate-limit estão sólidos. | — | — |

### 4.2 Maiores (Majors — M1..Mn)

| ID | Descrição do Problema | Impacto | Ação Recomendada |
| :--- | :--- | :--- | :--- |
| **M1** | **Descarte silencioso de `name` e `email` no Onboarding** (`lib/modules/auth/ui/onboarding/onboarding_controller.dart:51-74`): `submit()` valida `TechnicianName` e `ContactEmail`, mas chama apenas `repository.saveCredentials(password, pin)`, sem persistir nome nem e-mail no perfil comercial. | Quebra o contrato do `PRD.md` (RF-01): o técnico cadastra nome e e-mail no onboarding, mas os dados somem ao abrir o perfil/laudo PDF. | Persistir `TechnicianProfile` inicial com `name` e `email` ao concluir o onboarding. |
| **M2** | **PBKDF2 síncrono na Main UI Isolate** (`lib/modules/auth/data/credential_store/secure_credential_store.dart:95-102,141,203`): 210.000 iterações (420.000 no `saveCredentials`) rodam sincronamente na thread de UI. Evidência empírica: `flutter test` levou **02:50** com o grosso do tempo em `credential_recovery_test.dart`. | Congelamento perceptível da UI (*jank* / risco de ANR) em celulares Android de entrada ao cadastrar ou validar PIN/senha. | Executar `CredentialHash.create` e `hash.matches` via `Isolate.run(...)`. |
| **M3** | **Ausência de trava `Portrait-Only` para smartphones (`< 600dp`)** (`lib/main.dart:26-37`): `AGENTS.md` §1, `PRD.md` (RNF-05) e `DESIGN.md` §5 exigem bloqueio de rotação em smartphones e liberação apenas em tablets (`>= 600dp`). | Descumprimento de invariante não-negociável de ergonomia de campo. | Aplicar controle de orientação (`SystemChrome.setPreferredOrientations`) no boot/layout baseado no `shortestSide < 600`. |

### 4.3 Menores / Informativos (Advisory — A1..An)

| ID | Descrição do Problema | Sugestão |
| :--- | :--- | :--- |
| **A1** | **Encapsulamento de `KortexSignal`** (`LockController`, `OnboardingController`): sinais mutáveis `final KortexSignal<T>` são expostos diretamente como públicos na API do controller. | Manter `_signal` privado e expor `IKortexReadonlySignal<T>` (padrão oficial do `kortex`). |
| **A2** | **Future não aguardado em `main.dart:354`**: `widget.repo.markUnlocked();` retorna `Future` sem `await`/`unawaited`. | Aguardar ou marcar explicitamente com `unawaited(...)`. |
| **A3** | **Efeito colateral em `build()` (`main.dart:343-346`)**: `_AppEntryState.build()` muta `_isLockVisible` durante a construção da árvore. | Mover atualização de `_isLockVisible` para o callback da resolução da rota ou listener fora de `build()`. |
| **A4** | **Duplicação de lockout em `SecureCredentialStore`** (`_registerPinFailure` / `_registerPasswordFailure`, `_isLockedOut` / `_isPasswordLockedOut`). | Extrair helper privado parametrizado por `(failCountKey, lockedUntilKey)` (DRY). |

---

## 5. Parecer Final

A implementação da **`EPIC-01`** apresenta excelente qualidade de engenharia em segurança criptográfica (`PBKDF2-HMAC-SHA-256`, comparação em tempo constante, redação de logs, backoff exponencial), aderência estrita a `kortex`/`dnolib` sem padrões proibidos e suíte verde (**88/88 testes**, **0 issues** no `flutter analyze --fatal-infos`). O veredito é **APROVADO COM RESSALVAS**, com 3 apontamentos **Majors** (`M1` persistência de nome/e-mail no onboarding, `M2` PBKDF2 em `Isolate.run`, `M3` trava de orientação `Portrait-Only` em smartphones) recomendados para correção antes do fechamento do MVP.
