# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `OPS-EPIC04-E2E-DEVICE` — E2E de device do EPIC-04
- **UC**: `UC-04.09` — UC-04.09 (Modelos de checklist alcançáveis)
- **Status**: CONCLUÍDO em código+testes; **E2E device pendente** (install bloqueado MIUI intermitente, sonda e fluxo escritos)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-04`
- **Gate 2.5 (Segurança)**: PULADO — artefato de teste (`integration_test/`) + chaves de widget; sem nova superfície sensível (nenhuma coleta/transmissão de PII, nenhuma dependência nova de rede).
- **Última Atualização**: `2026-11-22`

## Contexto Atual
- **Sonda medida em device real** (`integration_test/epic04_probe.dart`, executada com sucesso): rota inicial = **onboarding** (`[PROBE] tela inicial: [Crie seu acesso, ...]`) e **GPS OK em 2558 ms** (`lat=-16.7318355, lon=-43.8568404`). Conclusão de OS exige fix de GPS e **não tem bypass**, então a sonda era pré-requisito real do E2E — e foi medida, não presumida.
- **E2E escrito**: `integration_test/epic04_flow.dart` cobre `onboarding → cliente → OS (cliente + modelo) → check-in → checklist → conclusão`, com asserção computada em cada elo. Fica fora do glob de `flutter test` (sem sufixo `_test`) para o gate headless não tentar rodar E2E sem plugin nativo.
- **Asserções que provam o contrato**: `IN_PROGRESS` só aparece se o check-in **sem bypass** deu certo (GPS real); `selectedStatus == conforme` é relido do controller após persistir cada item (prova escrita no banco, não só cor do botão); `COMPLETED` só sai com assinatura desenhada + GPS de check-out.
- **Testabilidade**: os quatro `_Field` do onboarding não tinham `key` — adicionadas `onboarding-name|email|password|pin` + `onboarding-submit` para o E2E nao depender de índice de campo.
- **Armadilha do ambiente de teste**: `adb shell pm clear` **revoga permissão de runtime**. Sem reconceder `ACCESS_FINE/COARSE_LOCATION` após o `pm clear`, o check-in abre diálogo nativo (que o Dart não toca) e falharia por motivo errado.
- **Bloqueio medido (install)**: `adb -s 192.168.67.65:5555 install -r -t app-debug.apk` → `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`. Na mesma sessão esse **mesmo comando retornou `Success` uma vez**, sem alteração de configuração no aparelho — logo não é bloqueio permanente. `settings put secure adb_install_need_confirm 0` **não** resolveu (a chave estava `null` e continua recusando). Causa ainda **não determinada**; atribuição anterior ("falta Instalar via USB, exige conta Mi") foi refutada e corrigida no `LEARNINGS.md`.
- **Consequência de método**: `epic04_probe.dart` **foi executado** (evidência acima); `epic04_flow.dart` **não foi** — e não é reportado como validado.

## [EVIDENCIA]
- Leitura: `integration_test/epic04_flow.dart` → 6 etapas com `esperarPor`/asserticao por etapa; `lib/modules/auth/ui/onboarding/onboarding_page.dart` → `_Field(fieldKey:)` + `onboarding-submit`; `lib/modules/work_orders/ui/list/work_order_list_page.dart` → menu `Iniciar atendimento`/`Checklist`/`Concluir OS` exigindo `IN_PROGRESS` para os dois últimos.
- Verificação: `adb devices` → `192.168.67.65:5555 device`; `flutter test integration_test/epic04_probe.dart -d 192.168.67.65:5555` → `[PROBE] GPS OK em 2558ms`; `flutter test integration_test/epic04_flow.dart -d ...` → **falhou no install**, antes de executar o teste (`Failed to load ...: Unable to start the app on the device`).
- Confirmação: `flutter analyze --fatal-infos` → `No issues found!`; `flutter test` → `+221 All tests passed!`; `flutter test integration_test/epic04_flow.dart -d ...` → **falhou no install**, antes de executar o teste (`Failed to load ...: Unable to start the app on the device`).

## Próximo passo
1. Determinar a causa do `INSTALL_FAILED_USER_RESTRICTED` por evidência (logcat da sessão de instalação / `pm install` via push), não por nova suposição.
2. Com install OK: `adb shell pm clear com.servicetrack.service_track`, reconceder as duas permissões de localização e rodar `flutter test integration_test/epic04_flow.dart -d 192.168.67.65:5555`.
3. **Push**: pendente de autorização explícita do PO + 3 evidências.
4. **D-01/C-01**: persiste bloqueando persistência de documento do recebedor por design (fail-closed).

## Travas Vivas
- **Claims**: `OPS-EPIC04-E2E-DEVICE` (`opc01@e03ff640`); `claims status` antes de mutar.
- **Push**: somente com autorização explícita do PO + 3 evidências.
- **D-01/C-01**: persiste bloqueando documento do recebedor por design (fail-closed).
- **Greenfield Lock**: **DESTRAVADO**.