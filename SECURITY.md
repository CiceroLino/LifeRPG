# Security Policy

## Supported Versions

LifeRPG ainda não mantém múltiplas linhas de release. Correções de segurança são aplicadas na branch principal e, quando houver releases públicas, na versão mais recente.

| Branch or version | Security support |
| --- | --- |
| `main` | Supported |
| Latest public release | Supported |
| Older snapshots, forks or local builds | Best effort |

## Reporting a Vulnerability

Relate vulnerabilidades abrindo uma issue privada ou, se isso não estiver disponível, uma issue pública com o mínimo de detalhe necessário para iniciar contato. Evite publicar payloads completos, dados pessoais, arquivos de banco ou passos exploráveis em ambientes reais.

Inclua, quando possível:

- Versão, commit ou branch afetada.
- Plataforma afetada, como Android, iOS, web, Linux, Windows ou macOS.
- Resumo do impacto.
- Passos de reprodução em ambiente local ou dados anonimizados.
- Evidências relevantes, como logs sem segredos.

## Handling

O objetivo é confirmar o recebimento em até 7 dias. Se a vulnerabilidade for válida, a correção deve priorizar preservação de dados locais do usuário e compatibilidade com backups existentes.

Quando uma correção estiver disponível, o reporte público deve descrever impacto, versões afetadas e orientação de atualização sem divulgar detalhes exploráveis desnecessários.

## Dependency verification

`python3 tool/security_audit.py` queries OSV for every resolved hosted Pub package and the Gradle wrapper. After resolving the Android graph, pass `--gradle-report build/security/android-dependencies.txt` to include Maven. Network errors and incomplete inventories fail the gate. CI pins Flutter 3.44.2 and action revisions, runs isolated tests, builds the declared platforms and executes the Web startup smoke.

Gradle 8.14.6 is pinned with the official distribution SHA-256 and replaces the version affected by CVE-2026-22865/CVE-2026-22816 and the October daemon/TLS advisories. See the upstream [release notes](https://docs.gradle.org/8.14.6/release-notes.html).

Native inventory: `docs/security/native-components.json`. SQLite Dart 3.5.2 provides SQLite 3.53.4; Web uses the matching release asset, with a rebuilt sqflite worker. The generator's default still fetches an older WASM, so updating only its worker is insufficient. Compare the recorded hashes and run the Web smoke whenever changing either file.

PDFium remains revision `chromium/7811` through the compatible upstream packages. Pub scanning does not determine its CVE reachability or validate the downloaded native binary. Review upstream fixes, build flags and artifact hashes before claiming a clean native security audit. Likewise, mobile system SQLite/media frameworks require platform-specific inventory. Local validation on Linux cannot establish macOS/iOS/Windows runtime behavior or release signing.

## Scope details

Estão no escopo:

- Vazamento ou corrupção de dados locais do usuário.
- Falhas em backup, restore, importação ou exportação.
- Problemas com arquivos importados, como PDFs e áudios.
- Exposição indevida por notificações, storage local ou permissões de plataforma.

Fora de escopo:

- Problemas que exigem acesso físico completo ao dispositivo desbloqueado sem outro impacto demonstrável.
- Vulnerabilidades em dependências sem impacto reproduzível no LifeRPG.
- Relatos sem informação suficiente para reprodução ou triagem.
