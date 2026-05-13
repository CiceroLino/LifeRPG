# Guia do Projeto LifeRPG

Este guia é para humanos e agentes de código trabalhando no LifeRPG. Leia antes de mudar comportamento para não precisar redescobrir as regras pelo código.

Se este guia conflitar com o código, trate o código como a verdade atual e atualize este arquivo como parte da mudança.

## Modelo do Produto

LifeRPG é um app Flutter que transforma tarefas reais em progressão de RPG.

- Missões são tarefas.
- Completar missões concede XP, Moedas/RP e pode conceder recompensas.
- Skills recebem XP quando as missões vinculadas são completadas.
- Recompensas são itens usáveis comprados na loja ou dropados por missões.
- Recompensas obtidas viram itens no inventário, onde podem ser consumidas.
- Energia é exibida como HP e diminui/aumenta conforme tempo acordado e tempo dormindo, ou por ajuste manual.
- Pomodoro é tratado como Focus Quest: uma sessão de foco com duração limitada que concede XP ao player.
- Notebooks são cadernos locais para capturar notas livres fora do fluxo de missões.
- Tomes são referências PDF locais catalogadas no app, com caminho do arquivo e progresso manual de leitura.

Referência de produto: o raciocínio de missões, atributos, RP, recompensas e HP segue a linha do artigo "LifeRPG Strategy Guide (v1.0.0)", de kolayāna, adaptado ao código atual deste app.

O app é local-first. Os dados vivem em SQLite via `sqflite`/`sqflite_common_ffi`; configurações vivem em `SharedPreferences`; importação/exportação usam serviços específicos por plataforma.

## Arquitetura

O app segue uma estrutura simples em camadas:

- `lib/ui`: telas e widgets. A UI deve compor providers e renderizar estado.
- `lib/providers`: estado `ChangeNotifier` e operações expostas para a aplicação.
- `lib/services`: fluxos de negócio transacionais que tocam múltiplas tabelas.
- `lib/data/repositories`: acesso ao banco para um agregado ou área de persistência.
- `lib/data/models`: modelos de dados com `toMap`, `fromMap`, `copyWith`.
- `lib/data/database/database_helper.dart`: schema, migrações, backup/restore e auxiliares de reset.
- `lib/core/utils`: calculadoras puras e auxiliares de negócio.
- `lib/core/theme/app_theme.dart`: tokens de design e tema Material.

Regra importante de responsabilidade: não duplique cálculos de negócio na UI. Reuse utilitários como `XPCalculator`, `RewardPointAdvisor`, `DailyTimeBudgetAdvisor` e `EnergyScheduleCalculator`.

## Setup em Runtime

`lib/main.dart`:

- Chama `configureDatabasePlatform()` e inicializa `MissionReminderService` antes de `runApp`.
- Registra providers com `MultiProvider`.
- Carrega imediatamente player, recompensas, inventário, missões, skills, notebooks e configurações.
- Força `ThemeMode.dark`.
- Suporta locales `en`, `pt` e `es`.

Providers principais:

- `PlayerProvider`
- `MissionProvider`
- `PomodoroProvider`
- `SkillProvider`
- `RewardProvider`
- `InventoryProvider`
- `NotebookProvider`
- `TomeProvider`
- `SettingsProvider`

## Banco de Dados

Arquivo do banco: `liferpg.db`.

Versão atual do schema: `12`.

Tabelas principais:

- `player`: linha única do jogador, garantida por `id INTEGER PRIMARY KEY CHECK (id = 1)`.
- `skills`: progressão de skills.
- `missions`: registros de missões/tarefas.
- `mission_skills`: relacionamento many-to-many entre missões e skills.
- `mission_completion_events`: registros históricos de conclusões de missão.
- `mission_completion_skill_rewards`: registros históricos de XP por skill.
- `rewards`: definições de recompensas da loja.
- `inventory_items`: itens possuídos.
- `reward_redemptions`: registros históricos de compras.
- `mission_reward_drops`: drops configurados por missão.
- `mission_completion_reward_drops`: rolagens históricas de drops na conclusão.
- `focus_sessions`: histórico de sessões Pomodoro/Focus Quest concluídas.
- `notebooks`: cadernos de notas locais.
- `notes`: notas vinculadas a um notebook.
- `tomes`: PDFs locais catalogados como tomos, com metadados e progresso manual.

Notas de migração:

- A versão 5 migrou `difficulty`, `urgency` e `fear` de missões da escala antiga 1-5 para a escala atual 0-100, multiplicando valores 1-5 por 20.
- A versão 6 adicionou recompensas, inventário e histórico de resgates.
- A versão 7 adicionou local, lembrete e dias de recorrência em missões, além de drops configuráveis e histórico de rolagens.
- A versão 8 adicionou notas de missão e texto livre de lembrete.
- A versão 9 adicionou sessões Pomodoro/Focus Quest com XP concedido por minuto focado.
- A versão 10 adiciona o campo `description` no player (`player.description`) com valor padrão vazio, permitindo perfil com texto personalizado.
- A versão 11 adiciona `notebooks` e `notes`.
- A versão 12 adiciona `tomes`.
- Foreign keys são habilitadas em `onConfigure`.

Backup/restore:

- `DatabaseHelper.getAllDataForBackup()` exporta todas as tabelas principais com `version` e `timestamp`.
- `DatabaseHelper.restoreData()` limpa os dados existentes e insere o payload de backup dentro de uma transação.
- Restore assume que as linhas do backup são compatíveis com o schema atual.

## Regras do Player

Modelo: `lib/data/models/player.dart`.

Padrões:

- `id`: `1`
- `name`: `Player`
- `title`: `Adventurer`
- `totalXP`: `0`
- `level`: `1`
- `rewardPoints`: `0`
- `currentEnergy`: `100`
- `energyMode`: `manual`
- `themeMode`: `light`, embora o app atualmente rode em dark mode.

`PlayerProvider` expõe XP atual, nível, XP necessário para o próximo nível, XP dentro do nível atual e progresso até o próximo nível.

Energia manual:

- Só é válida em `energyMode == 'manual'`.
- `setManualEnergy` limita valores a `0..100`.

Energia automática:

- `energyMode` precisa ser `auto`.
- `wakeUpTime` e `sleepTime` precisam ser strings `HH:mm` parseáveis.
- O valor visível de energia é calculado em `PlayerStatsHeader` usando `EnergyScheduleCalculator`.

## XP e Níveis

Dono: `lib/core/utils/xp_calculator.dart`.

Curva de nível:

- XP necessário para o próximo nível é `currentLevel * 100`.
- O nível começa em `1`.
- XP total é cumulativo.
- XP dentro do nível atual é `totalXP - XP exigido pelos níveis anteriores`.

Exemplos:

- Nível 1 precisa de 100 XP para chegar ao nível 2.
- Nível 2 precisa de mais 200 XP.
- Nível 3 precisa de mais 300 XP.

Fórmula de XP da missão:

```text
xp = difficulty * urgency * (1 + fear / 100)
```

Regras:

- `difficulty`, `urgency` e `fear` são limitados a `0..100`.
- Se `difficulty == 0` ou `urgency == 0`, o XP é `0`.
- `fear` é um multiplicador, não um bloqueador.
- O resultado é arredondado para o inteiro mais próximo.
- Evite desenhar fluxos que incentivem atributos em `0`, porque dificuldade e urgência acima de zero são a base para a missão conceder XP.

Bandas dos atributos de missão:

- `0..25`: Low
- `26..50`: Medium
- `51..75`: High
- `76..100`: Extreme

Use `XPCalculator.attributeGuideLabel` para os rótulos estratégicos exibidos junto aos sliders.

Guia estratégico dos atributos:

- Difficulty mede o esforço da tarefa, de trivial/beginner até extreme/transformational.
- Urgency mede pressão temporal ou prioridade, de optional/non-urgent até immediate/critical.
- Fear mede aversão, incerteza ou ansiedade, de negligible/eustress até dread/mortal.
- O app agrupa a escala em Low, Medium, High e Extreme, mas a UI pode mostrar rótulos mais granulares para ajudar o usuário a calibrar valores de forma consistente.

## Regras de Pomodoro / Focus Quest

Donos:

- `lib/services/focus_session_service.dart`
- `lib/providers/pomodoro_provider.dart`
- `lib/data/repositories/focus_session_repository.dart`

Regras:

- Pomodoro aparece como uma tela do painel com o nome visual `Focus Quest`.
- A duração configurável vai de `1` a `240` minutos; a UI oferece presets e slider de `5` a `240` minutos.
- `240` minutos é o limite absoluto: sessões acima de 4 horas devem ser rejeitadas ou limitadas antes da conclusão.
- Uma sessão concluída concede `1 XP` por minuto focado ao player.
- Concluir a sessão cria uma linha em `focus_sessions` com duração planejada, duração concluída, XP concedido, início e conclusão.
- Pomodoro não completa missão automaticamente e não concede RP, moedas, drops ou XP de skill.
- A tela deve recarregar o `PlayerProvider` após a conclusão para refletir XP e nível imediatamente no header.

## Regras de Missão

Modelo: `lib/data/models/mission.dart`.

Campos importantes:

- `status`: atualmente `active`, `completed` ou `archived`.
- `difficulty`, `urgency`, `fear`: escala percentual `0..100`.
- `energyRequired`: banco restringe a `1..5`, mas a lógica de conclusão ainda não consome energia.
- `xpReward`: quantidade de XP armazenada e concedida na conclusão.
- `rewardPoints`: quantidade de RP armazenada e concedida na conclusão.
- Recompensas dropadas por missão são configuradas em `mission_reward_drops` e tratadas como itens concedidos além de XP/RP.
- `dueDate`: usada por filtros e avanço de recorrência.
- `reminderAt`: agenda notificação local para a missão.
- `notes`: notas livres do Quest Log da missão.
- `reminderNote`: texto livre para lembretes RPG-like além do horário agendado.
- `locationName`, `latitude`, `longitude`: ponto real no mapa vinculado à missão.
- `isRecurring`, `recurrenceType`, `recurrenceInterval`, `recurrenceDays`: metadados de recorrência.
- `lastCompletedAt`, `streak`: tracking de recorrência.
- `parentMissionId`: subtarefas; são deletadas em cascade junto com a missão pai.
- `skillIds`: carregado via `mission_skills`, não armazenado na tabela `missions`.

Criação de missão:

- O formulário inicia com difficulty 50, urgency 50, fear 30.
- XP é pré-visualizado com `XPCalculator.calculateMissionXP`.
- Duração é limitada a `0..60` minutos.
- Valores de recorrência da UI: `once`, `continuous`, `daily`, `weekly`, `monthly`, `yearly`.
- `once` é salvo como `isRecurring = false` e `recurrenceType = null`.
- Qualquer outra recorrência é salva como `isRecurring = true` e `recurrenceType` com o valor escolhido.
- Uma missão pode ser criada já concluída; isso define `status = completed` e `completedAt = now`, mas não concede recompensas por `MissionCompletionService`.
- Uma missão só deve ter uma missão pai, mas pode ter várias missões filhas. Missões filhas representam partes executáveis de um projeto maior.
- Missões com duração e vencimento para hoje podem exibir aviso visual quando o total planejado excede o tempo acordado restante do player em modo auto.
- O botão de subtarefa no card abre criação com `parentMissionId` já preenchido.
- Lembretes usam `MissionReminderService` e respeitam a preferência `notificationsEnabled`.
- Localização usa mapa real com tiles OSM; o usuário pode usar GPS ou tocar no mapa.

Vínculo com skills:

- Use `MissionRepository.linkSkills`.
- Atualizar vínculos apaga as linhas existentes da missão e insere a lista recebida.
- Cuidado ao atualizar uma missão com `skillIds` vazio: `MissionProvider.updateMission` atualmente só relinka quando a lista não está vazia, então limpar todos os vínculos pode exigir tratamento no repository.

## Regras de Conclusão de Missão

Dono: `lib/services/mission_completion_service.dart`.

Sempre conclua missões por `MissionProvider.completeMission` ou `MissionProvider.updateMissionStatus(id, 'completed')`. Não use `MissionRepository.complete` em fluxos visíveis ao usuário, porque ele só altera status e ignora XP/RP/histórico/recompensas de skill.

A conclusão é transacional:

1. Carrega a missão e os IDs de skills vinculadas.
2. Bloqueia conclusões duplicadas quando aplicável.
3. Insere `mission_completion_events`.
4. Concede XP às skills e insere `mission_completion_skill_rewards`.
5. Concede XP/RP ao player e recalcula o nível.
6. Rola drops configurados, incrementa inventário quando houver sucesso e registra cada rolagem.
7. Atualiza status da missão ou estado de recorrência.

Regras de duplicidade:

- Missão não recorrente: bloqueia se já estiver `completed`.
- Missão recorrente com `recurrenceType == 'continuous'`: nunca bloqueia duplicidade.
- Outras missões recorrentes: bloqueia quando `dueDate != null && dueDate.isAfter(now)`.

Recompensas concedidas:

- O player recebe exatamente `mission.xpReward` e `mission.rewardPoints`.
- O nível do player é recalculado a partir do XP total.
- Skills vinculadas dividem o XP da missão igualmente com `(xpReward / skillIds.length).round()`.
- XP de skill usa progressão por skill: enquanto `currentXP >= level * 100`, subtrai `level * 100` e incrementa o nível.
- Drops usam chance percentual `0..100` e quantidade mínima `1`.
- Chance `0` nunca concede item; chance `100` sempre concede item.
- Toda rolagem de drop é registrada em `mission_completion_reward_drops`, inclusive falhas.
- Drops concedidos criam ou incrementam `inventory_items` pela chave `reward_id`.

Status da missão após conclusão:

- Missão não recorrente vira `completed`, `completedAt = now`.
- Missão recorrente permanece `active`, define `lastCompletedAt = now`, incrementa `streak`, limpa `completedAt` e avança `dueDate`.
- Missão recorrente contínua mantém o mesmo `dueDate`.
- Recorrência diária/semanal/mensal/anual avança a partir do due date antigo até ficar depois de `now`.
- `recurrenceInterval` é respeitado por recorrência diária, semanal, mensal e anual.
- `recurrenceDays` pode guiar a próxima data em recorrência semanal.
- Tipos de recorrência desconhecidos se comportam como daily.

Status do resultado de conclusão:

- `completed`: missão não recorrente concluída.
- `recurringAdvanced`: missão recorrente avançada para uma data futura.
- `recurringCompleted`: missão recorrente contínua concluída.
- `duplicateBlocked`: nenhuma recompensa concedida.

## Filtros e Ordenação de Missões

Dono: `lib/providers/mission_provider.dart`.

Estado padrão:

- Ordenação: `recent`.
- Filtro: `all`.
- Missões concluídas ficam ocultas, salvo quando `showCompleted == true`.

Filtros:

- `plan`: missões ativas sem `dueDate`.
- `all`: todas as missões exceto concluídas ocultas.
- `next`: missões ativas com `dueDate >= now`.
- `today`: missões ativas vencendo de hoje 00:00 até amanhã 00:00.
- `tomorrow`: missões ativas vencendo de amanhã 00:00 até o dia seguinte.
- `overdue`: missões ativas com `dueDate` antes de hoje 00:00.

Busca:

- Faz `trim` da busca.
- Compara título e descrição em letras minúsculas.

Filtro de skill:

- Uma missão passa quando qualquer skill ID vinculado está no conjunto selecionado.

Ordenações:

- `recent`: `createdAt` mais novo primeiro.
- `oldest`: `createdAt` mais antigo primeiro.
- `difficultyDesc`: maior difficulty primeiro.
- `priorityDesc`: compara `(urgency * 100) + (fear * 10) + difficulty`.
- `rewardDesc`: mais Reward Points primeiro.

## Reward Points

Dono: `lib/core/utils/reward_point_advisor.dart`.

RP funciona como moeda de recompensa. Missões concedem RP para motivar progresso; recompensas custam RP na loja e, ao serem adquiridas ou dropadas, viram itens consumíveis no inventário.

RP recomendado para missões:

- Missão avulsa diária: `1`.
- Missão filha diária ou semanal: `1`.
- Missão avulsa por XP:
  - `<= 100`: 5 RP
  - `<= 1.000`: 10 RP
  - `<= 10.000`: 25 RP
  - `<= 100.000`: 50 RP
  - `<= 1.000.000`: 75 RP
  - `> 1.000.000`: 100 RP
- Missão filha por XP:
  - `<= 1.000`: 5 RP
  - `<= 10.000`: 10 RP
  - `<= 100.000`: 25 RP
  - `<= 1.000.000`: 50 RP
  - `> 1.000.000`: 75 RP

XP negativo é tratado como `0` para recomendação.

## Recompensas, Loja e Inventário

Modelos:

- `Reward`
- `InventoryItem`
- `RewardRedemption`
- `MissionRewardDrop`
- `MissionCompletionRewardDrop`

Repositório: `lib/data/repositories/reward_repository.dart`.
Drops de missão: `lib/data/repositories/mission_reward_drop_repository.dart`.

Campos de recompensa:

- `priceRp` precisa ser não negativo no banco.
- `isUnlimitedStock` controla comportamento de estoque.
- `stockRemaining` é armazenado como null para recompensas ilimitadas.
- `isActive` arquiva recompensas em vez de deletar do histórico de compras.

Modelo estratégico de preço:

- Recompensas representam itens ou permissões reais que o usuário pode "comprar" com RP.
- Para recompensas com custo financeiro real, a referência estratégica é `ceilToUsefulCurrencyUnit(cost) * modifier / stock`.
- Arredonde o custo real para a próxima unidade prática da moeda antes de aplicar o modificador.
- Tipo I: ajuda missões futuras e não desvia atenção/energia de missões, modificador `0.5`.
- Tipo II: ajuda missões futuras, mas desvia atenção/energia, modificador `1`.
- Tipo III: não ajuda missões futuras e não desvia atenção/energia, modificador `1`.
- Tipo IV: não ajuda missões futuras e desvia atenção/energia, modificador `2`.
- `stock` divide o preço quando uma compra real gera múltiplas unidades consumíveis.

Fluxo de compra é transacional:

1. Exige recompensa ativa.
2. Se o estoque for finito, exige estoque restante > 0.
3. Exige RP do player >= preço.
4. Subtrai RP do player.
5. Decrementa estoque finito.
6. Cria ou incrementa um item de inventário pela chave `reward_id`.
7. Insere registro histórico de resgate.

Erros expostos pelo provider:

- RP insuficiente: `RP insuficiente para comprar esta recompensa.`
- Sem estoque: `Recompensa sem estoque disponível.`
- Recompensa indisponível: `Recompensa indisponível.`

Inventário:

- `InventoryRepository.consumeItem` deleta o item quando a quantidade é `1`.
- Caso contrário, decrementa a quantidade e atualiza `updated_at`.
- Itens de inventário são ordenados por `updated_at DESC`.
- Consumo de item é o ponto onde a recompensa deixa de estar disponível para uso. Não trate inventário apenas como histórico de compras.

Shop e Rewards:

- `RewardsScreen` administra recompensas: cria, edita e arquiva itens disponíveis.
- `ShopScreen` é a loja real: compra recompensas ativas com RP e envia para inventário.
- Drops de missão usam as mesmas recompensas cadastradas para gerar itens no inventário sem compra.

## Regras de Energia

Dono: `lib/core/utils/energy_schedule_calculator.dart`.

Energia deve ser pensada e exibida como HP:

- O HP ajuda o usuário a calibrar quanto consegue executar em um dia.
- Em modo automático, o HP é derivado do ciclo acordado/dormindo, não de custo de missão.
- Em modo manual, o usuário informa diretamente seu estado atual de energia.

Modo manual:

- O valor armazenado é `player.currentEnergy`.
- A UI permite tap/drag na barra de energia para definir `0..100`.

Modo automático:

- Exige `wakeUpTime` e `sleepTime` válidos.
- Se algum horário for inválido ou a duração acordado for zero, o resultado fica não configurado e energia é `0`.
- Durante o período acordado, HP drena linearmente de 100 para 0.
- Durante o sono, HP recarrega linearmente de 0 para 100.
- Agendas podem atravessar a meia-noite.
- `MainScreen` atualiza a energia automática a cada minuto enquanto o player está em modo auto.

Rótulo da UI:

- Modo manual mostra `manual`.
- Modo auto sem horários configurados mostra `set schedule`.
- Modo auto configurado mostra tempo restante até dormir ou acordar.

## Configurações e Reset

Dono: `lib/providers/settings_provider.dart`.

Chaves de `SharedPreferences`:

- `language`
- `sound_effects_enabled`
- `notification_sounds_enabled`
- `notifications_enabled`
- `start_week_on_monday`
- `use_24_hour_format`
- `show_xp_bar`

Padrões:

- Idioma: `en`
- Efeitos sonoros: false
- Sons de notificação: true
- Notificações: true
- Semana começa na segunda: false
- Formato 24h: false
- Mostrar barra de XP: true

Comportamento de reset:

- `resetCharacter()` reseta XP, nível, RP, energia, modo de energia e horários de acordar/dormir do player.
- `factoryReset()` deleta dados de recompensas, inventário, histórico de conclusão, missões, skills e player; reinsere apenas o player padrão; limpa preferências e recarrega padrões.

Estado inicial de skills:

- Novos bancos e factory reset começam sem skills.
- O gráfico spider só é exibido quando existem pelo menos 3 skills.

## Navegação e Telas

`MainScreen` controla a navegação de topo com um `IndexedStack`.

Ordem do drawer:

1. Missions
2. Map
3. Rewards
4. Inventory
5. Skills
6. Statistics
7. Profile
8. Shop
9. Settings
10. Help

`PlayerStatsHeader` fica oculto em Skills, Settings e Help. Ele mostra tabs somente em Missions.

Tabs de missões mapeiam para filtros:

1. PLAN -> `MissionFilterMode.plan`
2. ALL -> `MissionFilterMode.all`
3. NEXT -> `MissionFilterMode.next`
4. OVERDUE -> `MissionFilterMode.overdue`
5. TODAY -> `MissionFilterMode.today`
6. TOMORROW -> `MissionFilterMode.tomorrow`

Ações da app bar são contextuais:

- Missions: alternar stats, busca, adicionar missão, mostrar concluídas, ordenar, filtro por skill.
- Profile: alternar stats, editar, resetar avatar, compartilhar perfil.
- Statistics: alternar stats, calendário, exportar dados, limpar histórico.

O título `LifeRPG` da app bar abre navegação alternativa entre telas. Ele não deve abrir workspace nem sugerir partição persistida de dados.

`StatisticsScreen` usa dados reais de `mission_completion_events` para sumarizar os últimos sete dias. Não use gráficos com dados aleatórios nessa tela.

## Sistema de Design

Dono: `lib/core/theme/app_theme.dart`.

O app usa intencionalmente um estilo denso de dashboard RPG escuro:

- Fundo escuro, controles compactos e superfícies funcionais.
- Ícones e rótulos curtos são preferidos a blocos explicativos.
- Cards devem ser compactos e densos em informação.
- Evite layouts de landing page, heroes gigantes e gradientes decorativos.

Cores principais:

- `background`: `#212121`
- `surface`: `#303030`
- `primary`: `#03A9F4`
- `accentRed`: `#F44336`
- `accentAmber`: `#FFC107`
- `textPrimary`: `#F5F5F5`
- `textSecondary`: `#BDBDBD`
- `border`: `#424242`
- `successGreen`: `#4CAF50`

Tema:

- Material 3.
- Roboto via `google_fonts`.
- Fundo escuro no scaffold.
- Densidade visual compacta.
- Cards usam `surface`, borda `border`, elevação 2 e raio 12.
- Inputs são preenchidos com `surface`, raio de borda 10 e borda primária no foco.
- FAB usa azul primário com foreground escuro.

Padrões comuns de UI:

- Use constantes de `AppTheme` em vez de cores ad hoc.
- Use `LifeRPGAppBar` para comportamento de app bar em telas de topo.
- Use `AppDrawer` para navegação principal.
- Use `PlayerStatsHeader` para resumo de player, XP, RP e energia.
- Use `GameSnackBar` para eventos de feedback principais, principalmente conclusão de missão, compra, drop, backup e erros relevantes.
- Use assets SVG de `assets/game-icons.net.svg/...` para ícones com tema RPG.
- Use `normalizeMissionIconAsset` ao renderizar ícones salvos de missão.
- Mantenha textos curtos e escaneáveis. Muitas strings atuais estão em inglês mesmo em áreas do app em português; preserve o estilo local salvo quando a tarefa for localizar intencionalmente.

Regras visuais do card de missão:

- Cor da faixa de prioridade:
  - urgency >= 76: vermelho
  - difficulty >= 76: laranja
  - fear >= 76: azul primário
  - urgency >= 51: amber
  - caso contrário: text secondary
- Caixa do ícone da missão tem 50x50 com raio 8.
- Card expandido expõe dropdown de status e botão de editar.
- Reward Points aparecem com ícone de gem e texto amber.

Regras visuais do header do player:

- Avatar tem 60x60 com raio 8 e borda.
- Level é texto grande dourado.
- Barras de XP e HP são empilhadas, com 20px de altura.
- HP é vermelho em modo manual/drenando; carregamento automático interpola de vermelho para ciano.
- Tabs de missões são rótulos uppercase em um `TabBar` compacto.
- O bloco com avatar, nome e título do player deve ser clicável e navegar para personalização/perfil.

## Localização e Textos

O app tem estrutura de localização gerada, mas muitas strings visíveis ainda estão hardcoded em inglês ou português.

Ao adicionar texto visível ao usuário:

- Siga o estilo local do arquivo que está editando.
- Se tocar uma tela localizada, prefira usar `AppLocalizations`.
- Evite refactors amplos de localização salvo quando solicitado.

## Notas de Plataforma

Setup de banco por plataforma vive em `lib/core/platform/database_platform*.dart`.

Avatar e backup usam implementações específicas por plataforma:

- Auxiliares de imagem/storage de avatar em `lib/core/platform/custom_avatar_storage*.dart` e `lib/ui/widgets/common/avatar_image*.dart`.
- Implementações de backup em `lib/services/backup_service*.dart`.

Suporte web inclui assets SQLite wasm em `web/`.

## Expectativas de Teste

Rode testes focados para a área alterada, depois testes mais amplos quando o risco for alto.

Comandos úteis:

```bash
flutter analyze
flutter test
flutter test test/core/utils/mission_strategy_calculator_test.dart
flutter test test/core/utils/energy_schedule_calculator_test.dart
flutter test test/services/mission_completion_service_test.dart
flutter test test/data/repositories/reward_inventory_repository_test.dart
flutter test test/providers/mission_provider_test.dart
```

Adicione ou atualize testes ao mudar:

- Fórmulas de XP ou nível.
- Recompensas de conclusão de missão, recorrência, bloqueio de duplicidade ou histórico.
- Filtros/ordenação de missão.
- Compra de recompensa, estoque, inventário ou histórico de resgate.
- Matemática de agenda de energia ou interações de energia na UI.
- Migrações de banco, backup, restore, reset ou factory reset.
- Comportamento de provider que afete estado visível ou mensagens de erro.

Arquivos de teste focados existentes:

- `test/core/utils/mission_strategy_calculator_test.dart`
- `test/core/utils/energy_schedule_calculator_test.dart`
- `test/core/utils/daily_time_budget_advisor_test.dart`
- `test/services/mission_completion_service_test.dart`
- `test/data/database/mission_attribute_migration_test.dart`
- `test/data/database/mission_v7_strategy_migration_test.dart`
- `test/data/repositories/mission_reward_drop_repository_test.dart`
- `test/data/repositories/reward_inventory_repository_test.dart`
- `test/providers/mission_provider_test.dart`
- `test/providers/reward_inventory_provider_test.dart`
- Testes de UI/widget em `test/ui/...`

## Pontos de Atenção Conhecidos

- `MissionRepository.complete` ignora recompensa e histórico. Evite em conclusão visível ao usuário.
- `MissionProvider.updateMission` não limpa skills da missão quando `skillIds` está vazio.
- Criar uma missão com `Mission Complete` marcado não concede XP/RP. Apenas salva status concluído.
- `energyRequired` existe, mas conclusão de missão não consome energia.
- `themeMode` existe em `Player`, mas `MaterialApp` atualmente força dark theme.
- `RewardRepository.purchaseReward` assume que a linha do player existe.
- Restore de backup insere linhas cruas e assume schema compatível.

## Como Estender com Segurança

Ao adicionar uma nova regra:

1. Coloque matemática pura em `lib/core/utils`.
2. Coloque fluxos transacionais multi-tabela em `lib/services`.
3. Mantenha acesso ao banco em repositories.
4. Exponha estado e erros por providers.
5. Mantenha widgets de UI finos e reutilizáveis.
6. Adicione testes focados junto da área de teste existente.
7. Atualize este guia quando o comportamento virar contrato do projeto.

Ao adicionar uma nova tela:

1. Adicione a tela em `lib/ui/screens/<area>/`.
2. Reuse `AppTheme`, padrões de app bar/drawer e estilo escuro compacto.
3. Adicione APIs de provider ou repository só se as existentes não cobrirem o fluxo.
4. Adicione testes de widget para interações visíveis ao usuário.

Ao adicionar uma nova dependência ou usar API de biblioteca:

1. Use `ctx7` primeiro para documentação atual.
2. Prefira dependências existentes antes de adicionar pacotes novos.
3. Atualize `pubspec.yaml`, rode `flutter pub get` e inclua mudanças de `pubspec.lock`.
