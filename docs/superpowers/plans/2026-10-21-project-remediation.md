# LifeRPG Project Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Este documento é um plano; a auditoria não iniciou a implementação.

**Goal:** Corrigir os 29 achados da auditoria, preservando dados, comportamento intencional e suporte explícito de plataforma.

**Architecture:** Manter Flutter/Provider/SQLite e a estrutura existente. Fortalecer contratos de escrita nos repositories/services, usar transações para agregados e coordenar invalidação de providers e serviços externos. Não introduzir uma migração geral de arquitetura como pré-requisito.

**Tech Stack:** Flutter 3.44.2/Dart 3.12.2 como baseline auditada; Provider; sqflite/FFI/Web; SharedPreferences; notificações locais; just_audio/audio_service; pdfrx; Gradle/AGP.

**Spec:** [Auditoria de 21/10/2026](../../audits/2026-10-21-project-audit.md), com gatilhos, evidências, severidades e limites; [guia do projeto](../../project-guide.md).

## Global Constraints

- Preservar dados e significado dos backups; não fazer reset destrutivo para viabilizar migrações.
- Isolar banco de teste antes de adicionar/executar regressões de persistência.
- Não alterar o comportamento documentado de energia, arredondamento de skill XP, conclusão manual de foco ou tema fixo sem outra solicitação.
- Manter cálculos de negócio fora da UI e reutilizar AppTheme/widgets existentes.
- Não sobrescrever alterações locais já existentes em `.fvmrc`, `.vscode/settings.json`, `main_screen.dart` e assets.
- Não atualizar todas as dependências para majors indiscriminadamente. Resolver advisories e compatibilidade com versões verificadas.
- Consultar documentação atual conforme AGENTS.md quando a tarefa envolver API/configuração de bibliotecas; no máximo três comandos `ctx7` por pergunta.
- Não versionar keys/secrets; build não autoriza publicação, push ou deployment.
- Não considerar ausência de resultado no scan Pub uma prova sobre bibliotecas nativas ou ferramentas de build.
- Em cada entrega: revisar diff, atualizar o guia quando necessário e registrar validação exata. Commit por entrega quando houver implementação autorizada; manter documentação desta auditoria separada de correções.

## Review Focus

1. Dados de desktop existentes em diretórios antigos, destino já preenchido e diretório corrente diferente: nunca sobrescrever uma base válida. Coberto na tarefa 1.
2. Backup com chaves válidas e valores nulos, versão desconhecida, hierarquia fora de ordem e atributos 1–5 ambíguos: recusar ou migrar explicitamente antes de apagar. Coberto nas tarefas 3–4.
3. Foco/compra/missão concorrente com perfil/energia e com reset: preservar saldos e impedir callback antigo de ressuscitar dados. Coberto nas tarefas 2, 6 e 12.
4. Instalação limpa, permissão negada, plataforma sem backend e recurso opcional falhando antes de runApp: permitir abrir o app e representar capacidade real. Coberto nas tarefas 7–9.
5. Arquivos homônimos, falha no meio de uma cópia, resposta assíncrona antiga e fila de uma faixa: não perder mídia, progresso ou edição. Coberto nas tarefas 13–15.

## Ordem e dependências

| Etapa | Tarefas | Objetivo de saída |
| --- | --- | --- |
| 0 — Proteção de dados | 1 | Testes e app com storage separado; migração preservadora |
| 1 — Integridade e segurança | 2–6 | Saldos atômicos, restore validado, backups coerentes, Gradle corrigido e foco consistente |
| 2 — Plataforma | 7–9 | Bootstrap e integrações com capacidades explícitas; release preparado |
| 3 — Fluxos principais | 10–13 | Missões, recorrência, reset e edição corretos |
| 4 — Mídia e apresentação | 14–16 | Importação/fila/progresso confiáveis; controles e documentação coerentes |

Tarefa 1 precede qualquer teste com DB. Tarefa 6 usa a API transacional de 2; tarefa 4 usa o formato/validador de 3. Tarefa 12 depende de 6–9. Demais entregas podem ser revisadas separadamente. Executar conforme o método que for autorizado na futura implementação; este plano não exige delegação nesta auditoria.

## Tarefa 1 — Diretório durável e isolamento de testes

**Resolve:** A01, A02.

**Arquivos:** modificar `lib/core/platform/database_platform_io.dart`, `lib/data/database/database_helper.dart`, testes de DB/repositories/services/providers; criar `test/support/test_database.dart` e `test/core/platform/database_storage_test.dart`.

**Interfaces:** manter `configureDatabasePlatform()` para produção; adicionar configuração de diretório por parâmetro opcional ou factory injetada, sem usar cwd como identidade de dados. Helper de teste produz uma base temporária exclusiva e rotina de fechamento/limpeza; `resetForTesting()` deixa de poder apagar caminho de produção sem uma configuração explícita de teste.

- [ ] Criar `testDatabaseNeverTouchesSentinelDatabase`: sentinel em diretório separado permanece byte a byte igual após reset/teste; duas suítes recebem caminhos diferentes.
- [ ] Criar `desktopPathDoesNotDependOnWorkingDirectory` e `legacyMigrationPreservesExistingDestination`: mesmo storage sob cwd A/B; conflito entre base antiga e destino não sobrescreve nenhuma. Simular limpeza de artefatos em árvore temporária, sem executar clean contra o repositório com dados.
- [ ] Executar somente os novos testes já configurados para diretório temporário; observar as falhas do código atual.
- [ ] Configurar Application Support no desktop e migração da localização antiga conhecida: copiar/validar com banco fechado, preservar original e distinguir destino inexistente de destino já usado. Não adivinhar bases em diretórios arbitrários; documentar recuperação/importação quando o caminho antigo não é localizável.
- [ ] Migrar todos os testes com DB, inclusive o que chama `deleteDatabase` diretamente, para o suporte isolado. Verificar por busca que nenhum teste depende do caminho padrão.
- [ ] Rodar os testes de storage e a suíte completa; confirmar sentinels preservados e permitir concorrência apenas se as suítes estiverem de fato isoladas. Revisar e commit `fix(storage): isolate test databases and preserve desktop data`.

## Tarefa 2 — Escritas do player por responsabilidade

**Resolve:** A04.

**Arquivos:** `lib/data/repositories/player_repository.dart`, `lib/providers/player_provider.dart`, `lib/ui/screens/profile/profile_screen.dart`; criar `test/data/repositories/player_repository_concurrency_test.dart`.

**Interfaces:** manter `get()`; estender `addXP(int xp, {DatabaseExecutor? executor})` e equivalente de RP para participar de uma transação existente. Introduzir métodos de perfil/energia que escrevem somente seus campos, em vez de aceitar saldos do objeto em cache. Nível deriva do total persistido dentro da mesma transação.

- [ ] `concurrentXpIncrementsAreBothApplied`: dois incrementos de 25 resultam em 50 XP. `focusAndMissionPreserveAllRewards`: 25 XP de foco + 100 XP/25 RP de missão resultam em 125 XP/25 RP.
- [ ] `staleEnergyAndProfileCannotOverwriteBalances`: carregar cache com 0, conceder 25, mudar energia/nome pelo cache antigo; persistir 25 XP e a edição. Incluir compra concorrente para preservar débito de RP.
- [ ] Rodar novos testes, confirmar perda no código atual, implementar patches por campo e incrementos atômicos. Não usar apenas reload prévio como solução: ainda haveria janela de corrida.
- [ ] Rodar regressões do player, `mission_completion_service_test.dart` e `reward_inventory_repository_test.dart`; commit `fix(player): preserve progression across concurrent updates`.

## Tarefa 3 — Contrato versionado e validação de backup antes de escrita

**Resolve:** A03, A09.

**Arquivos:** criar `lib/services/backup_document.dart` e `test/services/backup_document_test.dart`; modificar `backup_service_io.dart`, `backup_service_web.dart`, `database_helper.dart` e docs.

**Interfaces:** `BackupDocument.parse(Map<String,dynamic> data)` valida e produz representação tipada; formato novo inclui `formatVersion` e `schemaVersion=13`, independente da versão do app. Ambos backends usam o mesmo parser. Restore recebe dados validados ou revalida na fronteira pública antes de abrir a transação de substituição.

- [ ] `nullPayloadCannotEraseDatabase`: payload de A03 e versões desconhecidas são rejeitados; snapshots de todas as tabelas antes/depois permanecem iguais.
- [ ] Validar tipos e campos obrigatórios, IDs, referências, enums e limites que o domínio realmente exige; rejeitar números que provoquem progressões inválidas ou processamento desproporcional. Não impor limites arbitrários que excluam dados legítimos sem migração.
- [ ] `modernLowPercentValuesRemainUnchanged`: 2/3/5 com schema percentual permanece 2/3/5. `knownLegacyAttributesMigrateToPercent`: fixture identificada do schema antigo vira 40/60/100. Formato antigo `1.0` sem origem suficiente não pode receber conversão baseada apenas nos números; produzir diagnóstico de ambiguidade e caminho de recuperação explícito.
- [ ] Implementar validadores/migradores sem duplicação IO/Web; backup vazio válido exige player válido e listas vazias explícitas, sem confundir ausência com apagamento solicitado.
- [ ] Rodar testes do parser/restore, casos de backups antigos conhecidos e backup/restore de notas/mídia; commit `fix(backup): validate and version restore documents`.

## Tarefa 4 — Snapshot coerente e restore de hierarquias

**Resolve:** A08 e risco de snapshot inconsistente.

**Arquivos:** `lib/data/database/database_helper.dart`; criar `test/data/database/backup_restore_test.dart`.

**Interfaces:** manter `getAllDataForBackup()` e `restoreData(...)` como fronteiras; captura sob uma transação de leitura, restore sob uma única transação de escrita, após validação da tarefa 3.

- [ ] `ownBackupRestoresChildBeforeParent`: filha ID 1 ligada ao pai ID 2, vários níveis e vínculos de skills/drops restauram com os mesmos IDs e dados. `invalidHierarchyRollsBackAllTables`: órfão/ciclo rejeitado sem perda.
- [ ] `backupIsConsistentDuringMissionAndRedemption`: barreiras controlam concorrência; saldo/histórico/inventário do backup devem refletir um estado completo antes ou depois da operação.
- [ ] Implementar ordenação topológica ou diferimento controlado de FKs, incluindo validação final, sem desabilitar permanentemente foreign keys.
- [ ] Rodar restore completo em DB novo e já preenchido, `PRAGMA foreign_key_check` e comparação de todas as tabelas. Documentar que arquivos anexos/preferências continuam fora do formato atual até entrega própria; commit `fix(backup): restore hierarchies from consistent snapshots`.

## Tarefa 5 — Gradle corrigido e gates de segurança reproduzíveis

**Resolve:** A07, A29; amplia evidência nativa sem declarar CVEs inexistentes.

**Arquivos:** `android/gradle/wrapper/gradle-wrapper.properties` e artefatos necessários do wrapper; `.github/workflows/dart.yml`; adicionar configuração de scan adequada e seção de inventário em `SECURITY.md`.

- [ ] Confirmar advisories oficiais na execução, atualizar Gradle para 8.14.6 ou patch posterior validado na mesma linha, com `distributionSha256Sum`. Verificar compatibilidade do AGP 8.11.1/Kotlin 2.2.20 antes de alterar outras versões.
- [ ] Fixar o SDK de CI ao valor aprovado do projeto e verificar lockfile sem atualização silenciosa. Preservar a mudança local de FVM; não substituí-la por um valor assumido.
- [ ] Incluir scan do lockfile Pub e das dependências Maven efetivamente resolvidas; inventariar SQLite/PDFium por plataforma e revisar CVEs/fixes por revisão e flags. Atualizar engines/asset WASM quando aplicável, incluindo worker correspondente; não trocar apenas o pacote Dart.
- [ ] Incluir gates de build/smoke por destino declarado, com credenciais de assinatura apenas nos jobs que precisem delas. Fazer pin de actions por SHA verificado; não executar código de PR não confiável com secrets.
- [ ] Rodar wrapper/build Android e registrar versão efetiva, advisories corrigidos e pendências nativas. Sem SDK Android disponível, deixar essa validação explicitamente pendente; não declarar remediação completa só pelo diff. Commit `fix(security): patch Gradle and add dependency verification`.

## Tarefa 6 — Foco transacional e atualização automática do player

**Resolve:** A10, A14; depende de 2.

**Arquivos:** `focus_session_service.dart`, `focus_session_repository.dart`, `pomodoro_provider.dart`, `main.dart`, `pomodoro_screen.dart`, testes de foco/Pomodoro e integração do header.

**Interfaces:** conclusão participa de uma única transação usando a API de XP da tarefa 2; emitir conclusão bem-sucedida para sincronizar PlayerProvider. Acrescentar identidade de sessão se usada para idempotência, com migração aditiva.

- [ ] `historyFailureRollsBackXp`: trigger rejeita INSERT, XP/histórico ficam inalterados. `retrySameSessionRewardsOnce`: mesma identidade não duplica XP.
- [ ] `timerCompletionRefreshesPlayerHeader`: relógio controlado conclui uma sessão; header/nível refletem o banco sem acionar botão. Testar falha e conclusão concorrente manual/automática.
- [ ] Implementar transação e notificação, mantendo 1–240 minutos e 1 XP/minuto; não alterar a política atual de conclusão manual nesta tarefa.
- [ ] Rodar `focus_session_service_test.dart`, `pomodoro_provider_test.dart` e concorrência do player; commit `fix(focus): persist rewards atomically and refresh player state`.

## Tarefa 7 — Bootstrap resiliente em Web e Windows

**Resolve:** A05, A06.

**Arquivos:** `main.dart`, `local_media_import_service*.dart`, providers Tome/Tavern e `mission_reminder_service.dart`; criar testes de bootstrap e smoke Web real.

**Interfaces:** factory do importador sempre retorna um serviço construível; capacidade de importar deve ser consultável ou a operação devolve erro tipado. Inicialização das notificações fornece Windows settings válidos ou capability indisponível sem exceção fatal.

- [ ] `unsupportedMediaDoesNotCrashProviderConstruction` e `optionalServiceFailureStillStartsApp`: construir app e abrir missões sem mídia ou serviço nativo disponível.
- [ ] `windowsNotificationInitializationHasValidSettings`: executar caminho Windows e verificar ausência do ArgumentError atual; manter teste real em runner Windows.
- [ ] Implementar fallback com mensagem somente quando o usuário solicitar recurso indisponível; não esconder falha de storage essencial sob app aparentemente vazio.
- [ ] Build Web seguido de Chromium com perfil novo e asserção de primeira tela funcional/sem exceção; build e startup Windows. Commit `fix(platform): keep optional integrations from breaking startup`.

## Tarefa 8 — Capacidade de áudio, sandbox macOS e identidade de release

**Resolve:** A23, A24, A25.

**Arquivos:** `pubspec.yaml/lock` se backend for adotado, `tavern_audio_service.dart`, UI de Tavern; entitlements/Info.plist macOS; `android/app/build.gradle.kts`; documentação de suporte/release.

- [ ] Definir matriz explícita para áudio local/background, picker, GPS e notificações por plataforma. Para Linux/Windows, adotar backend compatível testado ou apresentar indisponibilidade da reprodução; não assumir que AudioService NoOp fornece áudio.
- [ ] Testar tocar/pausar/seek/trocar faixa em arquivo local em cada destino suportado, com falha de backend retornando diagnóstico e app continuando utilizável.
- [ ] Configurar entitlements macOS mínimos para arquivos selecionados, rede de saída e localização, com usage description. Verificar importação/backup/mapa/GPS em release assinado e permissão negada.
- [ ] Preparar signing de release Android por secrets externos e applicationId definitivo conforme identidade já adotada, se houver. Validar que release não usa certificado debug; documentar atualização de instalações existentes ao alterar identidade.
- [ ] Separar commits conforme plataforma quando revisões independentes forem úteis. Encerrar apenas com evidência das plataformas disponíveis e pendências explícitas das restantes.

## Tarefa 9 — Ciclo completo de lembretes

**Resolve:** A16, A17, A18, A19.

**Arquivos:** `mission_reminder_service.dart`, `mission_provider.dart`, `settings_provider.dart`, UI de configurações/mission form, AndroidManifest e testes novos de lembrete com adaptador controlável.

**Interfaces:** serviço recebe preferências reais e capacidade por plataforma; `reconcileReminders(...)` deriva agendamentos de missões/preferências, cancela pendências obsoletas e não altera sucesso da persistência da missão. Expor resultado de autorização e aviso de agendamento ao chamador.

- [ ] `firstReminderRequestsPermission` e `deniedPermissionDoesNotPretendScheduled`: testar instalação limpa e recusa em Android/iOS/macOS.
- [ ] `disableNotificationsCancelsPendingAndPreventsRecurringReschedule`; incluir exclusão de pai com filhas, arquivamento, restore e reset.
- [ ] `linuxSaveSucceedsWithoutZonedSchedule`: missão salva e lista recarrega sem invocar API não suportada; usuário recebe informação sobre indisponibilidade do lembrete.
- [ ] Adicionar receivers de agendamento/boot e permissões necessárias; verificar manifest mesclado e alerta antes/depois de reboot Android. Manter agendamento inexato, sem ampliar permissões desnecessariamente.
- [ ] Implementar reconciliação e separar gravação de efeitos externos. Rodar testes de mission provider/forms e smoke nos SOs suportados; commit `fix(reminders): reconcile permissions and platform scheduling`.

## Tarefa 10 — Cópia e campos anuláveis de missões

**Resolve:** A11.

**Arquivos:** `data/models/mission.dart`, `missions_list_screen.dart`, `mission_editor_screen.dart`, testes de modelo e ações de missão.

**Interfaces:** `Mission.copyWith` distingue argumento omitido de null nos campos anuláveis, seguindo o padrão já usado por Player. Cópia para criação deve produzir `id=null` e limpar datas de conclusão, sem perder skills/drops pretendidos.

- [ ] `duplicateMissionCreatesDistinctId`: original permanece igual; cópia ativa recebe outro ID e vínculos/drops esperados. `nullableFieldsCanBeCleared`: remover parent, dueDate, reminder, coordenadas e completedAt persiste null; omissão preserva valor.
- [ ] Implementar sentinel/operação explícita de duplicação e revisar os call sites que dependiam do comportamento anterior.
- [ ] Rodar testes de model, lista, formulário e conclusão; commit `fix(missions): clear nullable fields and duplicate without identity`.

## Tarefa 11 — Recorrência com intervalos e atrasos longos

**Resolve:** A12, A13; política de calendário do risco 6 deve ser registrada sem alteração implícita.

**Arquivos:** `mission_completion_service.dart`, eventual utilitário puro de recorrência e `test/services/mission_completion_service_test.dart`.

- [ ] `biweeklySelectedWeekdayAdvancesFourteenDays`: intervalo 2 e weekday correspondente resultam em +14 dias. Cobrir vários weekdays dentro da semana elegível.
- [ ] `veryOldDailyMissionAdvancesBeyondNow`: atraso de 2.005 dias resulta em data futura após uma conclusão; segunda imediata bloqueia e não altera XP/RP/drops.
- [ ] Incluir intervalo inválido, vencimento ausente, continuous e limites de calendário. Registrar comportamento de 31/fim de mês e 29/02 antes de alterar sua política.
- [ ] Implementar cálculo com pós-condições, sem loop que retorne silenciosamente data ainda vencida. Rodar conclusão e filtros de missão; commit `fix(recurrence): honor intervals and advance overdue missions safely`.

## Tarefa 12 — Reset e restore coordenados

**Resolve:** A20; depende das APIs de sessão/capacidades/reconciliação anteriores.

**Arquivos:** `settings_provider.dart`, `settings_screen.dart`, `main.dart`, providers de dados e serviços de sessão; `test/ui/screens/settings/settings_screen_test.dart` e teste de integração.

**Interfaces:** uma operação da aplicação coordena troca de dados, pausa de sessões, invalidação de callbacks e recarga de Player/Mission/Skill/Reward/Inventory/Notebook/Tome/Tavern/Pomodoro. Não concentrar novamente todas as regras numa sequência manual dentro do widget.

- [ ] `factoryResetClearsEveryProviderAndStopsSessions`: preencher todas as áreas, iniciar áudio/foco, resetar; DB e listas mostram padrão e callbacks antigos não recriam dados.
- [ ] `restoreReplacesAllCachedDataBeforeEditing`: conteúdo novo aparece sem caches velhos; nenhum write pendente de nota/player/PDF restaura valores anteriores.
- [ ] Garantir cancelamento/reconciliação de notificações e tratamento visível de falha; definir limpeza de arquivos gerenciados com cuidado para não deletar referências de backup ainda necessárias.
- [ ] Rodar testes de settings/providers e cenário completo de reset/restore; commit `fix(reset): synchronize providers and active sessions`.

## Tarefa 13 — Perfil reativo e formulários que preservam edição em erro

**Resolve:** A15, A26; aproveita writes por campo de 2.

**Arquivos:** providers Player/Mission/Reward e formulários/profile; testes de telas correspondentes.

**Interfaces:** métodos de gravação devolvem resultado estruturado com sucesso/erro/aviso ou propagam erro tipado; a UI fecha e limpa dirty state só após persistência confirmada. Erro de lembrete após gravação é aviso, não falha total.

- [ ] `latePlayerLoadHydratesProfile`: montar sem player, carregar depois; campos mostram dados e editar habilita salvar. `providerRefreshDoesNotOverwriteDirtyProfile`: manter texto pendente.
- [ ] `saveFailureKeepsFormContent`: simular erro de disco/repository em perfil, missão e recompensa; nenhum sucesso, nenhum pop, conteúdo preservado. `doubleSubmitCreatesOneRecord`: duas ações enquanto grava não duplicam.
- [ ] Implementar contratos de erro e estados de gravação, sem duplicar cálculo na tela. Rodar testes de profile/mission/reward e regressões de persistência; commit `fix(forms): preserve edits and report persistence failures`.

## Tarefa 14 — Importação de mídia sem colisão

**Resolve:** A21.

**Arquivos:** `local_media_import_service_io.dart`, integração com Tome/Tavern e `test/services/local_media_import_service_test.dart`.

- [ ] `concurrentHomonymousImportsKeepDistinctBytes`: importar simultaneamente 20 pares homônimos, verificar 40 caminhos distintos e bytes exatos de cada origem. Incluir streams e nomes sanitizados que colidem.
- [ ] `interruptedCopyDoesNotPublishPartialMedia`: stream falha no meio; não publicar registro de mídia válida nem sobrescrever arquivo anterior.
- [ ] Implementar nomes únicos/reserva exclusiva, escrita temporária e finalização atômica. Se persistência no DB falhar após cópia, descartar somente o arquivo novo comprovadamente não referenciado.
- [ ] Rodar testes de importação/providers Tome/Tavern, incluindo arquivo grande via stream; commit `fix(media): prevent concurrent import overwrites`.

## Tarefa 15 — Reprodução e persistência assíncrona de notas/PDFs

**Resolve:** A22 e triagem dos riscos 2–3.

**Arquivos:** `tavern_provider.dart`, `tavern_audio_service.dart`, `notebook_provider.dart`, `notebook_detail_screen.dart`, `tome_provider.dart`, reader e repositories relacionados; testes de providers e mídia.

- [ ] `singleTrackRepeatAllRestartsAtZero`: completion com uma faixa faz seek zero/restart; testar repeat one/off, avanço, shuffle e erro de load. Playback controlado deve reproduzir a semântica real da Future de `play`.
- [ ] Persistir início/progresso sem esperar a reprodução inteira terminar. Verificar que completions antigos não alteram faixa recém-selecionada e que disposal encerra subscriptions apropriadamente.
- [ ] Reproduzir `lateNotebookResponseCannotReplaceCurrentNotebook` com consultas A/B concluídas fora de ordem. Só promover o risco a correção após observar a falha; cache por notebook ou token de consulta deve manter IDs visíveis coerentes.
- [ ] Reproduzir `pdfProgressKeepsLatestUpdateAndOpenedTimestamp` com updates fora de ordem e markOpened concorrente; corrigir patches/serialização no responsável apropriado quando confirmado.
- [ ] Rodar testes de fila/notas/PDF e reprodução nativa em backend real; separar commits de áudio e corridas de persistência, com evidências próprias.

## Tarefa 16 — Curva exibida, configurações e documentação

**Resolve:** A27, A28 e documentação divergente; fecha rastreabilidade de A29 com 5.

**Arquivos:** `core/utils/xp_calculator.dart`, `skills_view.dart`, header/settings/main, testes de widgets/core utils e `docs/project-guide.md`.

- [ ] `skillAccumulatedXpUsesTriangularCurve`: nível 3/0 = 300; nível 2/190 = 290; ranking do spider acompanha o domínio. Compartilhar cálculo, sem duplicar fórmula na UI.
- [ ] `showXpPreferenceControlsHeader` e verificações dos controles que permanecerem disponíveis. Aplicar formato 24h, início de semana e som onde houver função real; desabilitar/remover promessa não implementada. Calendário precisa ter propósito definido antes de ganhar regra nova.
- [ ] Atualizar guia para navegação de 14 telas, limpeza de skills já funcional, schema/caminhos/backup efetivos e matriz de plataforma. Diferenciar backup de metadados de pacote com arquivos; backlog de anexos/preferências deve ter escopo e aceite próprios.
- [ ] Inventariar atribuição/licenças dos assets usados na distribuição e registrar componentes nativos/limites de scan. Não declarar licença MIT sobre terceiros sem proveniência.
- [ ] Rodar análise, suíte isolada e gates correspondentes às plataformas declaradas. Fazer revisão final comparando A01–A29 com commits/evidências; registrar pendências de plataforma e riscos ainda não reproduzidos. Commit(s) de apresentação/docs separados de mudanças de integridade.

## Encerramento e evidências exigidas

Cada tarefa deve registrar comandos, resultados e plataforma, sem confundir build com execução. Para as áreas alteradas, primeiro observar regressão no código anterior e depois verificar correção. A suíte completa e gates de plataforma entram nos marcos de integração; não repetir toda a matriz em cada alteração documental.

Antes de considerar encerrado: todos os P1 resolvidos, P2 corrigidos ou com escopo/limitação explícita aprovado, nenhum teste com acesso destrutivo a storage real, scan refeito e inventário nativo concluído ou claramente pendente. Não declarar “zero CVEs” com base apenas no ecossistema Pub.

**Execução autorizada e realizada:** as 16 frentes receberam implementação e verificações locais; consulte [resultado e limites](../../audits/2026-10-21-remediation-results.md). Os checklists acima preservam os critérios originais de aceite; validações de SOs/dispositivos e inventário nativo ainda pendentes estão explicitados no relatório, sem marcar evidência inexistente.
