# Débitos Técnicos — ServiceTrack (casa do projeto)

> Ledger D-XX desta casa (fonte única). Cada débito aponta para a mitigação/decisão
> registrada; status aberto exige dono. Convenção: `docs/DEBITOS.md` ↔ hand-off e laudos.

| ID | Débito | Decisão / Mitigação | Status | Dono |
| :--- | :--- | :--- | :---: | :--- |
| D-01 | Proteção em repouso parcial: runner Android existe com `allowBackup="false"`; iOS ausente. DB SQLite ainda sem criptografia full-db (sqlcipher); `documentNumber` (PII, C-01/UC-04.08) agora protegido por cifragem de campo AES-GCM 256 com chave no Keystore/Keychain (`AesGcmDocumentAtRestCipher`, `IDocumentAtRestCipher`), fail-closed sem cifrador. | `kDocumentAtRestProtectionAvailable=true`; repo cifra/decifra `signature_document_number` (prefixo `enc:v1:`). Pendências residuais: criptografia full-db, runner iOS, validação Keystore por fabricante. | Parcial | PO |
| D-02 | Auditoria de CVE indisponível (`pub audit` inexistente no Dart 3.13.5, ambiente offline, sem osv-scanner) | Repetir quando houver toolchain/rede; pacotes de segurança pinados (`crypto 3.0.8`, `flutter_secure_storage 9.2.4`) | Aberto | PO |
| D-03 | `verifyPassword` sem rate-limit (só o PIN tem bloqueio) | Risco consciente (Gate 3): entropia de 8+ chars vs PIN 4–6 dígitos; reavaliar na UC-01.04 (recuperação) | Aberto | PO |
| D-04 | Casa sem `docs/mitigations/` (ledger MIT-XX) | Criar quando o primeiro débito exigir plano de ação multi-passo; até lá, decisões vivem no hand-off e laudos | Aberto | PO |
| D-05 | UC-03.05 concluía com `ChecklistCompletionProof(0,0)` hardcoded; risco de bypass silencioso | UC-04.07: prova real via `IChecklistProofPort` + `ChecklistProofAdapter`, binding template na OS, execução/persistência de checklist, guard INV-06, política C `requireChecklistTemplate` (default true). Gate 2.5 INVOKED, Gate 3 APROVADO (Alta), Gate 4 APROVADO (Alta, `qa-review-v0.18.0.md`). Validação E2E device pendente. | Mitigado | PO |
