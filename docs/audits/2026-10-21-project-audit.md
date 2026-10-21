# Auditoria técnica do LifeRPG — 21/10/2026

## Resultado

Foram identificados **29 achados: 7 P1, 19 P2 e 3 P3**, além de riscos e limitações separados abaixo. Os problemas mais urgentes envolvem perda de dados/progressão, inicialização em plataformas anunciadas e segurança do build Android. Não foi demonstrado comprometimento do aplicativo nem identificado problema P0.

O projeto tem uma base útil: separação entre UI/providers/repositories, conclusão de missões e compras transacionais, foreign keys habilitadas, SQL normalmente parametrizado e testes das principais regras. Entretanto, os testes atuais não exercitam vários fluxos reais de inicialização, concorrência, backup e erro de persistência.

O [plano de correção](../superpowers/plans/2026-10-21-project-remediation.md) transforma estes achados em entregas verificáveis. Esta auditoria não implementou correções.

## Escopo e estado auditado

- Branch: `feature/mvp-closeout`.
- HEAD: `1cff6d2bbad13733f1a9fd685e7e3deece12c77a`.
- Estado atual do diretório, incluindo alterações locais preexistentes em `.fvmrc`, `.vscode/settings.json`, `lib/ui/screens/main_screen.dart` e assets. Essas alterações foram preservadas.
- Inventário: 105 arquivos Dart em `lib`, com 20.392 linhas; 38 arquivos Dart de teste, com 4.514 linhas.
- Inspeção das camadas de domínio, serviços, persistência/migrações/backup, providers e fluxos principais de UI; manifests, entitlements, configuração de build/CI e dependências resolvidas.
- Ambiente: Linux, Flutter 3.44.2, Dart 3.12.2, schema SQLite 13.
- Auditoria ampla de código e verificações locais; não equivale a pentest, fuzzing dos parsers nativos ou homologação em todos os sistemas.

## Validação executada

| Verificação | Resultado |
| --- | --- |
| `.fvm/flutter_sdk/bin/flutter analyze --no-pub` | Sem problemas detectados |
| `.fvm/flutter_sdk/bin/flutter test --no-pub --reporter expanded` | 132 testes passaram |
| `.fvm/flutter_sdk/bin/flutter build web --no-pub --release` | Build concluído |
| Smoke do build Web em Chromium headless, perfil novo | Exceção de inicialização de mídia reproduzida |
| `.fvm/flutter_sdk/bin/flutter build linux --no-pub --release` | Build concluído; não comprova funcionamento das integrações nativas |
| OSV `querybatch`, nome/versão/ecossistema `Pub` | 149 pacotes hospedados consultados; zero advisories retornados |
| Busca de padrões de credenciais em arquivos rastreados | Nenhuma ocorrência dos padrões específicos de chaves privadas, AWS access key, GitHub token ou Stripe secret; não é uma varredura de todo o histórico Git |
| Probes adicionais de banco/Windows/importação, com banco em diretório temporário | Cinco cenários reproduzidos |
| Probes adicionais de domínio/concorrência, com bancos temporários | Oito cenários observados em execuções concluídas |
| Probes de widgets/áudio com dependências controladas | Perfil tardio e repeat all reproduzidos |

Houve falhas ambientais por quota de escrita em `/tmp` durante tentativas adicionais. As verificações adicionais do banco e o build Linux foram concluídos usando `TMPDIR=/home/cicero/.cache/liferpg-audit-tmp`. Essas falhas ambientais não foram classificadas como bugs do projeto.

**Incidente de isolamento identificado durante a auditoria:** a suíte existente foi executada antes da descoberta de A02. Os próprios testes apagam `liferpg.db` no caminho padrão do FFI, também utilizado pelo app desktop quando aberto a partir deste diretório. Não havia snapshot anterior que permitisse afirmar se esse caminho continha progresso de desenvolvimento. Depois da descoberta, as reproduções utilizaram bancos temporários explicitamente configurados. Não executar novamente os testes atuais contra um diretório com dados importantes antes de corrigir o isolamento.

Evidências locais desta sessão: `/tmp/liferpg-audit-analyze.log`, `/tmp/liferpg-audit-tests.log`, `/tmp/liferpg-audit-web-build.log`, `/tmp/liferpg-audit-web-smoke.log`, `/tmp/liferpg-audit-linux-build.log`, `/tmp/liferpg-osv-scan.json`, `/tmp/liferpg-database-audit-results.log`. São temporárias; resultados e passos relevantes estão registrados neste documento.

SHA-256 dos insumos para conferir se a análise ainda corresponde ao checkout:

| Arquivo | SHA-256 |
| --- | --- |
| `pubspec.lock` | `0b3b724452c5d00445b02ed6f5d977c5c78c812541a80909e167be21cf8c42bd` |
| `web/sqlite3.wasm` | `8766db025f5d5b6f24c6a51cc9dec843ab7a7720e3dfa5b47d70d33db96d506b` |
| `web/sqflite_sw.js` | `a0632c26ab24b6de3f99bccabd2ed18dad9ece6add1f47d2bd065fa71339d352` |

## Critério de prioridade e evidência

- **P1:** perda silenciosa de dados/progresso, bloqueio da inicialização ou correção prioritária de segurança.
- **P2:** funcionalidade incorreta, inconsistência persistente ou impedimento de distribuição/integração.
- **P3:** apresentação, funcionalidade secundária ou manutenção.
- **Reproduzido:** cenário executado contra o código atual; falha injetada ou simulação de plataforma são identificadas explicitamente.
- **Confirmado por código:** caminho e causa identificáveis, sem execução no sistema operacional afetado.
- Riscos que dependem de interleaving ou de mapeamento de componentes ainda não validado ficam fora da contagem de bugs confirmados.

## Achados P1

### A01 — Banco desktop em diretório de ferramentas e dependente do diretório corrente

**Evidência:** confirmado por código. `lib/core/platform/database_platform_io.dart:5-9` ativa FFI sem configurar caminho; `lib/data/database/database_helper.dart:17-19` utiliza `getDatabasesPath()`. A implementação instalada de `sqflite_common_ffi` retorna `<cwd>/.dart_tool/sqflite_common_ffi/databases` (`lib/src/sqflite_ffi_impl_io.dart:89`).

**Impacto:** iniciar o mesmo binário de outro diretório acessa outro banco; instalações podem tentar gravar em diretórios sem permissão. No desenvolvimento, `flutter clean` remove `.dart_tool` e, portanto, pode remover o progresso local. O código do SDK instalado confirma a remoção em `packages/flutter_tools/lib/src/commands/clean.dart:55`; o comando destrutivo não foi executado na auditoria.

**Correção:** diretório estável de suporte da aplicação; migração preservando o banco antigo e tratamento de conflito se o destino já contiver dados. Caminho de teste precisa ser injetado separadamente.

### A02 — Testes apagam o mesmo banco usado pelo app desktop

**Evidência:** confirmado por código. `lib/data/database/database_helper.dart:855-863` apaga `liferpg.db` no caminho padrão; pelo menos 15 arquivos de teste chamam `resetForTesting`, e `test/data/database/mission_attribute_migration_test.dart:17-19` também chama `deleteDatabase` diretamente. Nenhum teste configura `setDatabasesPath`.

**Impacto:** a suíte pode destruir dados de desenvolvimento. `dart_test.yaml` limita concorrência a 1, mas isso não protege dados persistentes nem execuções simultâneas de processos.

**Correção:** diretório temporário por suíte/processo, fechamento/limpeza explícitos e remoção ou proteção da API destrutiva do helper de produção. Priorizar antes de novos testes.

### A03 — JSON com chaves presentes e valores nulos passa pela validação e apaga dados

**Evidência:** reproduzido. `lib/services/backup_service_io.dart:105-111` e `backup_service_web.dart` só verificam presença de quatro chaves. `lib/data/database/database_helper.dart:701-735` apaga tudo e aceita ausência de linhas.

**Reprodução isolada:** inserir uma missão; importar `{"version":"unsupported-future","player":null,"missions":null,"skills":null}`. `getBackupInfo` informa `isValid=true`; `restoreData` conclui e deixa `player` e `missions` vazios. O serviço normal de importação usa a mesma validação e o mesmo restore.

**Correção:** validar versão, tipos, campos obrigatórios, domínio e referências antes de qualquer DELETE; distinguir backup válido vazio de payload inválido. Manter rollback transacional e testar preservação integral do banco rejeitado.

### A04 — Escritas integrais do player perdem XP/RP por concorrência ou cache antigo

**Evidência:** reproduzido com operações reais. `lib/data/repositories/player_repository.dart:40-60` grava o objeto inteiro e faz read-modify-write sem transação. `lib/providers/player_provider.dart:48-70` persiste snapshots de perfil/energia contendo também saldos antigos.

**Resultados observados:**

- Foco de 25 XP concorrente com missão de 100 XP/25 RP: resultado **25 XP/0 RP**, esperado **125 XP/25 RP**.
- Dois `addXP(25)` concorrentes: **25 XP**, esperado **50 XP**.
- PlayerProvider carregado com 0 XP; foco concede 25 XP; `setManualEnergy(50)` usando cache antigo faz o banco voltar a **0 XP**.

**Correção:** updates por responsabilidade; perfil e energia não escrevem XP/RP. Incrementos e recálculo de nível devem ser atômicos e reutilizáveis na transação da missão/foco.

### A05 — Build Web compila, mas a aplicação falha ao criar providers de mídia

**Evidência:** reproduzido no Chromium com o build release. Console: `LocalMediaImportException: Local media import is not supported on this platform.`

`lib/services/local_media_import_service_stub.dart:3-6` lança na factory; `lib/providers/tome_provider.dart:9-11` e `tavern_provider.dart:35-40` a chamam nos construtores. `lib/main.dart:53` registra o provider e `lib/ui/screens/main_screen.dart:62,74-88` o acessa na inicialização/IndexedStack.

**Impacto:** erro sem o usuário sequer pedir importação; build verde não significa app Web utilizável.

**Correção:** implementação Web ou serviço indisponível que só devolva erro na operação solicitada; bootstrap e UI precisam consultar capacidades sem lançar na construção.

### A06 — Inicialização Windows lança antes de `runApp`

**Evidência:** reproduzido com override de `TargetPlatform.windows`, usando o plugin instalado. `lib/main.dart:27` aguarda `MissionReminderService.initialize`; `lib/services/mission_reminder_service.dart:28-34` omite `InitializationSettings.windows`. `flutter_local_notifications` 21.0.0 lança `ArgumentError: Windows settings must be set when targeting Windows platform.` nesse caso.

**Correção:** inicializar com configuração Windows válida ou desativar explicitamente essa integração na plataforma. Falha de serviço opcional precisa permitir que o app abra com estado compreensível. Homologar também em Windows real.

### A07 — Gradle 8.14 está em faixas afetadas por advisories altos

**Evidência:** versão fixada em `android/gradle/wrapper/gradle-wrapper.properties:5`, comparada com os avisos oficiais consultados em 21/10/2026. Detalhamento e limites na seção de segurança abaixo.

**Correção:** atualizar a linha 8.14 para **8.14.6 ou patch posterior validado**, com checksum da distribuição e build Android de verificação. A versão 8.14.4 resolve os dois CVEs de janeiro, mas não os três avisos publicados em outubro.

## Achados P2

| ID | Evidência e localização | Gatilho e impacto | Correção indicada |
| --- | --- | --- | --- |
| **A08** | **Reproduzido.** `database_helper.dart:614,731-735` | Criar missão ID 1, projeto ID 2 e mover a missão para o projeto. O backup exporta a filha antes do pai; restaurá-lo viola FK. O rollback preserva o banco atual, mas o backup próprio não restaura. | Ordenar hierarquia topologicamente ou diferir a validação de FKs de forma controlada dentro da transação; rejeitar ciclos e órfãos. |
| **A09** | **Reproduzida a ausência de conversão; problema de versionamento confirmado.** `database_helper.dart:635,698`; `backup_service_io.dart:105` | Todo backup tem `version:1.0`, independentemente do schema. Payload antigo com atributos 2/3/5 é aceito como percentuais, sem a conversão 40/60/100 da migração v5. Valores baixos atuais e legados são indistinguíveis apenas pelos números. | Versionar formato e schema separadamente; migradores explícitos para origens conhecidas. Não multiplicar automaticamente valores 1–5 de backups modernos ou ambíguos. |
| **A10** | **Reproduzido com trigger rejeitando INSERT.** `focus_session_service.dart:46-47` | XP é concedido antes da gravação de `focus_sessions`; rejeição deixa 25 XP e nenhum histórico. Retry pode duplicar concessão. | Mesma transação para sessão e XP; identidade da sessão para repetição segura. |
| **A11** | **Reproduzido.** `data/models/mission.dart:202,214-232`; `missions_list_screen.dart:160-171` | `copyWith(id:null)` conserva o ID; duplicar falha por PK. O mesmo padrão impede limpar parent, vencimento, lembrete, localização e datas de conclusão através de `copyWith`. | Sentinel para distinguir omissão de null e operação explícita de copiar sem identidade; conferir chamadas existentes. |
| **A12** | **Reproduzido.** `mission_completion_service.dart:417-427` | Semanal, intervalo 2, mesmo weekday: próxima data fica em 7 dias em vez de 14. | Aplicar intervalo às semanas elegíveis com dias selecionados. |
| **A13** | **Reproduzido.** `mission_completion_service.dart:393-404` | Diária atrasada em 2.005 dias atinge limite de 1.000 avanços, permanece vencida e uma segunda conclusão imediata concede mais XP. | Salto calculado ou algoritmo com pós-condição obrigatória de data futura. |
| **A14** | **Confirmado por código; efeito persistente relacionado reproduzido em A04.** `pomodoro_provider.dart:42-45`; `pomodoro_screen.dart:189` | Conclusão pelo timer não recarrega PlayerProvider; só o botão manual recarrega. XP e nível visíveis ficam antigos. | Sincronizar player em toda conclusão bem-sucedida, independentemente da origem. |
| **A15** | **Reproduzido em widget.** `profile_screen.dart:46-56,145,297` | Perfil monta com player null; carregamento termina depois. Controllers continuam vazios e `_loadedPlayerId` null impede marcar edição/salvar. | Hidratar por mudança observada do player, preservando edição pendente e avatar. |
| **A16** | **Confirmado por código.** `mission_reminder_service.dart:22-25,39`; `settings_provider.dart:95` | Permissão inicial desativada em Apple e `requestPermissions` sem chamadas no app. Android 13+ também não recebe solicitação em runtime. | Solicitar no primeiro uso apropriado; representar autorização/recusa real na UI. |
| **A17** | **Confirmado por manifests e README da dependência instalada.** `android/app/src/main/AndroidManifest.xml` | Faltam `ScheduledNotificationReceiver` e configuração de recuperação após boot. O manifest do plugin v21 declara apenas permissões básicas; agendamento não fica funcional apenas com POST_NOTIFICATIONS. | Registrar receiver de agendamento e, para manter após reinício, receiver/permissão de boot; verificar manifest mesclado e dispositivo. Não solicitar exact alarm se continuar usando agendamento inexato. |
| **A18** | **Confirmado por código.** `settings_provider.dart:95-100`; `mission_provider.dart:258-260` | Desligar notificações só muda bool; alertas pendentes continuam. Conclusão recorrente passa `notificationsEnabled:true`, ignorando preferência. Reset também não cancela pendências. | Reconciliação central dos agendamentos com preferências e estado persistido. |
| **A19** | **Confirmado pelo código e plugin instalado.** `mission_reminder_service.dart:84`; `mission_provider.dart:223-242,300-318` | `zonedSchedule` não é implementado no Linux pela versão instalada. A gravação da missão já ocorreu, mas erro interrompe recarga e o formulário fecha. | Capacidade por plataforma; separar resultado da gravação de aviso de agendamento, sem mascarar missão já salva. |
| **A20** | **Confirmado por código.** `settings_screen.dart:545-554`; `database_helper.dart:675-695` | Factory reset só recarrega Player/Mission/Skill, embora apague recompensas/inventário/notas/PDFs/faixas. Outros providers continuam exibindo itens antigos; áudio/timer não são encerrados. Restore pede restart, mas permite continuar com caches antigos. | Coordenar pausa, cancelamento, limpeza e recarga de todos os providers; impedir callbacks antigos de regravar estado após troca de dados. |
| **A21** | **Reproduzido: colisão em 20/20 pares.** `local_media_import_service_io.dart:89-100,127-142` | Duas importações homônimas verificam inexistência antes de abrir/gravar e recebem o mesmo caminho. Um arquivo pode sobrescrever o outro; dois registros podem apontar para os mesmos bytes. | Identificador único, criação exclusiva ou reserva serializada; cópia temporária e publicação atômica. |
| **A22** | **Reproduzido com playback controlado.** `tavern_provider.dart:135-145,308-315` | Repeat all com uma faixa seleciona a própria faixa; `playTrack` considera que já toca e não faz seek/restart ao receber completion. | Tratar reinício no estado completed; verificar contrato da Future de `play` para não adiar persistência até a música terminar. |
| **A23** | **Confirmado pelas dependências/registrants atuais; sem execução do áudio nesses SOs.** `pubspec.yaml:59-60`; `tavern_audio_service.dart:96` | `just_audio` resolvido oferece Android/iOS/macOS/Web; não há backend adicional Linux/Windows no projeto. Tavern chama `setFilePath` nessas plataformas. `audio_service` usa NoOp em Linux/Windows e não fornece o backend de reprodução ausente. | Adicionar backend compatível homologado ou declarar a função indisponível sem afetar o restante do app. |
| **A24** | **Confirmado pela configuração; precisa homologação macOS.** `macos/Runner/Release.entitlements:5`; `DebugProfile.entitlements`; `macos/Runner/Info.plist` | Sandbox não libera arquivos selecionados pelo usuário, conexões de saída nem localização. Isso conflita com importação/backup, mapa e GPS. Não há descrição de localização no Info.plist macOS. | Declarar somente entitlements necessários e usage description; validar app assinado em release, incluindo cancelamento de picker e GPS negado. |
| **A25** | **Confirmado por configuração.** `android/app/build.gradle.kts:25,34-38` | Release usa chave de debug e applicationId de exemplo. Artefato pode ser gerado, mas não há identidade/assinatura preparada para distribuição e atualização. | Configuração de release por secrets externos, identidade estável e verificação do certificado. Nunca versionar a chave. |
| **A26** | **Confirmado por caminhos de erro.** `player_provider.dart:39-45`; `profile_screen.dart:177-195`; `mission_form_screen.dart:557-564`; `reward_form_screen.dart:198-206` | Providers capturam falha e retornam normalmente; telas limpam dirty state, fecham ou anunciam sucesso. Falha de disco/banco pode descartar a edição visível. | Resultado explícito/propagação de erro; manter formulário e conteúdo em falha; bloquear submissão duplicada. |

Os caminhos abreviados da tabela pertencem a `lib/`, exceto os caminhos nativos indicados.

## Achados P3

| ID | Evidência | Correção |
| --- | --- | --- |
| **A27 — Gráfico de skills usa curva incorreta** | `lib/ui/screens/skills/skills_view.dart:232,329` soma `(level-1)*100+currentXP`, mas o domínio consome 100+200+… por nível. Skill nível 3/0 vale 300 XP acumulados, mas aparece com 200; nível 2/190 aparece com 290 e inverte a comparação. | Utilitário compartilhado para XP acumulado: `50*level*(level-1)+currentXP`; teste do ranking e dos valores. |
| **A28 — Controles secundários sem efeito implementado** | Busca de referências encontra `showXpBar`, `startWeekOnMonday`, `use24HourFormat` e opções sonoras apenas em settings/provider, sem aplicação correspondente. Header desenha XP incondicionalmente (`player_stats_header.dart:215`). Calendário em `main_screen.dart:248-263` apenas anuncia a data escolhida. | Conectar cada controle ao comportamento prometido ou retirar/desabilitar até implementá-lo; não criar uma nova regra de calendário sem definir seu propósito. |
| **A29 — CI não reproduz SDK e não verifica plataformas/segurança** | `.github/workflows/dart.yml:20-36` acompanha `stable` sem fixar `.fvmrc`, só analisa/testa e não faz build/smoke nem scan. A05 demonstra uma quebra que passa nesses gates. | Fixar SDK, preservar resolução do lockfile, acrescentar smoke Web e builds das plataformas suportadas; scan de pacotes e inventário nativo. Actions por SHA melhoram integridade. |

## Segurança e CVEs

### Dependências Pub

Foram consultados os 149 pacotes com `source:hosted` do `pubspec.lock` via [API OSV](https://google.github.io/osv.dev/post-v1-querybatch/), com nome e versão exatos no ecossistema `Pub`. O retorno foi zero advisories para essas versões. Dependências SDK não foram incluídas nessa contagem. Esse resultado não cobre automaticamente Maven/CocoaPods, bibliotecas C/C++, downloads feitos por build hooks, o SQLite do sistema móvel nem os binários copiados para `web/`.

### Gradle — versões afetadas confirmadas, exploração não testada

| Identificador | Severidade upstream | Faixa aplicável ao wrapper atual | Primeira correção na linha 8.14 | Impacto condicionado |
| --- | --- | --- | --- | --- |
| [CVE-2026-22865 / GHSA-mqwm-5m85-gmcv](https://github.com/gradle/gradle/security/advisories/GHSA-mqwm-5m85-gmcv) | Alta | `<8.14.4`, inclui 8.14 | 8.14.4 | Falhas persistentes de repositório podem permitir resolver artefatos de outro repositório controlado pelo atacante. |
| [CVE-2026-22816 / GHSA-w78c-w6vf-rw82](https://github.com/gradle/gradle/security/advisories/GHSA-w78c-w6vf-rw82) | Alta | `<8.14.4`, inclui 8.14 | 8.14.4 | Resolução após host desconhecido pode permitir substituir a origem dos artefatos nas condições descritas pelo upstream. |
| [GHSA-j5m7-59rp-24f5](https://github.com/gradle/gradle/security/advisories/GHSA-j5m7-59rp-24f5) | Alta | `<8.14.6`, inclui 8.14 | 8.14.6 | Erro TLS pode levar a fallback inseguro de repositório; exige condições de controle/interferência descritas no advisory. |
| [GHSA-xwqc-3h47-hg64](https://github.com/gradle/gradle/security/advisories/GHSA-xwqc-3h47-hg64) | Alta | `<8.14.6`, inclui 8.14 | 8.14.6 | Desserialização antes de autenticação no daemon; atacante precisa atingir o canal local. |
| [GHSA-mvvg-497x-hmj8](https://github.com/gradle/gradle/security/advisories/GHSA-mvvg-497x-hmj8) | Alta | `<8.14.6`, inclui 8.14 | 8.14.6 | Canal worker/daemon sem autenticação permite desserialização hostil nas condições do aviso. |

Os três últimos avisos não apresentavam CVE associado nas páginas consultadas. Eles não foram renomeados como CVEs. A exposição é da ferramenta usada para construir o Android; não comprova uma vulnerabilidade remotamente explorável no aplicativo instalado. As [notas oficiais do Gradle 8.14.6](https://docs.gradle.org/8.14.6/release-notes.html) consolidam as correções. Não foram executados exploits.

### SQLite e PDFium — inventário e pendências

- Desktop testado: pacote Dart `sqlite3 3.3.1`, engine **SQLite 3.53.0**, obtida em execução com `SELECT sqlite_version()`.
- `web/sqlite3.wasm`: source ID interno `2025-11-28 17:28:25 281fc0e9afc38674b9b0991943b9e9d1e64c6cbdb133d35f6f5c87ff6af38a88`, correspondente a **SQLite 3.51.1** na [história oficial](https://sqlite.org/changes.html). Atualizar o pacote Dart não demonstra que esse arquivo também foi atualizado.
- [CVE-2026-11822 e CVE-2026-11824](https://sqlite.org/cves.html) têm correção documentada em SQLite 3.53.2. As engines identificadas são anteriores. O upstream descreve pré-condições envolvendo SQL arbitrário, FTS5 e configuração defensiva; o app não mostrou um caminho para SQL arbitrário nem importação de bancos SQLite binários. Portanto: **versões merecem atualização; exploração no LifeRPG não foi demonstrada**. Backup JSON com inserts parametrizados não satisfaz automaticamente essas condições.
- `pdfrx 2.3.3` → `pdfrx_engine 0.4.2` → `pdfium_dart/pdfium_flutter 0.2.1`. O hook nativo instalado fixa PDFium `chromium/7811` e baixa binário externo. Não foi concluído o cruzamento de todos os fixes/CVEs do PDFium com essa revisão e suas opções de compilação. **Não há base para declarar o parser livre de CVEs.** Fazer esse mapeamento antes de prometer cobertura nativa completa.
- O hook do PDFium inspecionado baixa por HTTPS e não verifica hash explícito do binário no trecho de download. Isso é uma lacuna de rastreabilidade/integridade dos artefatos, não uma exploração comprovada.
- [CVE-2026-27704](https://github.com/dart-lang/sdk/security/advisories/GHSA-q739-79rh-vmvp), do extrator Pub, corrige-se a partir de Dart 3.11.0/Flutter 3.41.0. O SDK efetivamente utilizado (3.12.2/3.44.2) está acima desses pisos; não foi contado como vulnerabilidade atual.

## Riscos que precisam de reprodução ou decisão de escopo

1. **Snapshot inconsistente do backup.** `database_helper.dart:610-632` faz queries sequenciais sem transação de leitura. Conclusão/compra concorrente pode separar snapshot do player de histórico/inventário. Confirmada ausência de snapshot; não foi capturado um backup inconsistente nesta auditoria. Testar concorrência com barreira determinística e coletar em transação.
2. **Respostas antigas de notas trocando o caderno visível.** `notebook_provider.dart:86-89` usa lista global e aceita a última consulta a terminar; `notebook_detail_screen.dart:52` não filtra os itens pelo notebook da tela. Reproduzir A→B com respostas fora de ordem antes de promover a bug confirmado; considerar cache por caderno ou token de requisição.
3. **Progresso PDF e `lastOpenedAt` concorrentes.** Reader chama atualizações assíncronas enquanto os repositories podem escrever o modelo inteiro. Reproduzir páginas fora de ordem e `markOpened` concorrente; corrigir com patch por campo e ordenação dos writes.
4. **Backup não é um pacote portátil completo.** A documentação atual admite exportar somente metadados dos PDFs/áudios; arquivos internos, avatar em caminho local e preferências não acompanham o JSON. Restaurar após reinstalação/em outro dispositivo pode deixar referências inexistentes. É limitação documentada, não um novo bug demonstrado. Tornar o alcance explícito na UI e definir backup com anexos/relink como entrega própria.
5. **Distribuição e matriz nativa ainda sem prova.** Android/iOS/macOS/Windows não foram construídos e homologados nesta auditoria. Build Linux foi validado, mas reprodução de áudio, notificações, GPS e sandbox exigem os respectivos sistemas. Maven/CocoaPods e bibliotecas de mídia do SO ainda precisam de inventário por artefato de release.
6. **Datas mensais/anuais em dias inexistentes.** O código deixa `DateTime` normalizar 31/fim de mês e 29/02. Definir se o produto pretende último dia válido ou overflow antes de alterar; incluir casos de calendário/fuso sem classificar a escolha atual automaticamente como bug.
7. **Atribuição de assets.** Há SVGs derivados de game-icons.net e licença MIT do código; não foi concluído inventário de autoria/licença de cada asset nem sua atribuição no app distribuído. Verificar proveniência e obrigações na preparação de release, sem assumir que a licença do código cobre os arquivos de terceiros.

## Irregularidades estruturais que explicam os achados

- **Ownership de mutações:** modelo inteiro é gravado por operações de escopos diferentes; perfil/energia concorrem com progressão. Corrigir contratos de escrita antes de reestruturar camadas.
- **Coordenação global:** reset, restore, conclusão de foco e notificações não têm um mecanismo único de reconciliação/invalidação de estado.
- **Erros como sucesso aparente:** capturar exceções com `debugPrint` e retornar `void`/null sem a UI conferir apaga a distinção entre salvo, parcialmente salvo e falhou.
- **Suporte de plataforma implícito:** providers e bootstrap tratam recursos opcionais como disponíveis em todos os destinos.
- **Regra duplicada na apresentação:** curva de XP do spider chart diverge do domínio.
- **Gates incompletos:** teste isolado de `MyApp` usa playback controlado e não cobre `main()`/bootstrap e integrações reais. Testes verdes coexistem com inicialização quebrada.
- **Documentação desatualizada:** guia ainda diz que limpar todas as skills não relinka, mas `MissionProvider.updateMission:302` já relinka lista vazia. Navegação documentada tem dez telas; implementação tem catorze. Atualizar o guia junto das correções, sem substituir regras válidas por preferências novas.

Não é necessário reescrever o app nem trocar gerenciamento de estado para resolver os problemas principais. Correções pequenas nos contratos de persistência, bootstrap, coordenação de estado e testes dão cobertura mais direta aos cenários encontrados.

## Comportamentos preservados na avaliação

Energia não consumida ao concluir missão, arredondamento na divisão de XP de skills, tema escuro fixo e concessão manual do Pomodoro antes de iniciar não foram classificados como bugs: estão documentados ou exigidos pelos testes atuais. Também não foi encontrado defeito adicional sustentado especificamente na alteração local de `SizeTransition`.

## Critérios para encerrar a remediação

- Banco desktop preservado ao trocar cwd/limpar artefatos; testes incapazes de apagar banco de uso real.
- Nenhum JSON inválido ou incompatível modifica dados existentes; backups próprios com hierarquia restauram e snapshots são coerentes.
- Concorrência de foco/missão/compra/perfil/energia preserva XP, RP e histórico.
- `main()` abre em cada destino declarado; falha de integração opcional não derruba o app.
- Permissões, receivers, cancelamentos e capacidades de notificação verificados nas plataformas correspondentes.
- Formulários mantêm conteúdo em erro; reset/restore não deixam callbacks ou listas antigas ativos.
- Importação homônima concorrente nunca compartilha destino; áudio passa pelos casos de fila/repetição.
- Gradle corrigido e inventário nativo documentado, sem confundir ausência de resultado no ecossistema Pub com ausência global de CVEs.
- Análise estática, suíte isolada, testes de regressão dos achados e smoke/build por plataforma suportada passam; limitações remanescentes ficam explícitas.
