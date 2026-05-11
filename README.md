# 🎮 LifeRPG - Guia de Onboarding

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura do Projeto](#arquitetura-do-projeto)
3. [Estrutura de Pastas](#estrutura-de-pastas)
4. [Tecnologias e Dependências](#tecnologias-e-dependências)
5. [Modelos de Dados](#modelos-de-dados)
6. [Camada de Dados](#camada-de-dados)
7. [Camada de Lógica (Providers)](#camada-de-lógica-providers)
8. [Camada de UI](#camada-de-ui)
9. [Tema e Design System](#tema-e-design-system)
10. [Fluxos Principais](#fluxos-principais)
11. [Como Executar](#como-executar)
12. [Próximos Passos](#próximos-passos)

---

## 🎯 Visão Geral

**LifeRPG** é um aplicativo Flutter que gamifica tarefas do dia a dia, transformando atividades rotineiras em missões de RPG. O projeto permite que usuários:

- ✅ Criem e gerenciem missões (tarefas)
- 📊 Acompanhem progresso através de XP e níveis
- 🎯 Desenvolvam habilidades (skills) relacionadas às missões
- 💎 Ganhem pontos de recompensa
- 📈 Visualizem estatísticas e gráficos de progresso

### Conceito Principal

O app funciona como um RPG onde:
- **Missões** = Tarefas do dia a dia
- **XP (Experiência)** = Progresso do jogador
- **Level** = Nível do jogador baseado no XP acumulado
- **Skills** = Habilidades que podem ser desenvolvidas
- **Reward Points / Moedas** = Moeda virtual recebida por missões e usada na loja
- **Recompensas** = Itens usáveis comprados na loja ou dropados por missões
- **Inventário** = Onde recompensas obtidas ficam disponíveis para consumo
- **Energy / HP** = Energia do jogador, drenando enquanto acordado e recarregando durante o sono no modo automático

---

## 🏗️ Arquitetura do Projeto

O projeto segue uma arquitetura em **camadas** (Layered Architecture):

```
┌─────────────────────────────────────┐
│         UI Layer (Screens/Widgets)   │
│  ─────────────────────────────────  │
│  - Telas (Screens)                  │
│  - Componentes Reutilizáveis         │
│  - Navegação                         │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Logic Layer (Providers)        │
│  ─────────────────────────────────  │
│  - PlayerProvider                   │
│  - MissionProvider                   │
│  - SkillProvider                     │
│  - State Management (Provider)       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Data Layer (Repositories)      │
│  ─────────────────────────────────  │
│  - PlayerRepository                  │
│  - MissionRepository                 │
│  - SkillRepository                   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Database Layer (SQLite)        │
│  ─────────────────────────────────  │
│  - DatabaseHelper                    │
│  - Schema & Migrations               │
└─────────────────────────────────────┘
```

### Princípios da Arquitetura

1. **Separação de Responsabilidades**: Cada camada tem uma responsabilidade específica
2. **Inversão de Dependências**: Camadas superiores dependem de abstrações
3. **State Management**: Provider para gerenciamento de estado reativo
4. **Repository Pattern**: Abstração da camada de dados

---

## 📁 Estrutura de Pastas

```
lib/
├── main.dart                          # Ponto de entrada da aplicação
│
├── core/                              # Funcionalidades centrais
│   ├── constants/
│   │   └── app_strings.dart          # Constantes de strings
│   ├── theme/
│   │   └── app_theme.dart             # Tema e cores da aplicação
│   └── utils/
│       └── xp_calculator.dart         # Cálculos de XP e níveis
│
├── data/                              # Camada de dados
│   ├── database/
│   │   └── database_helper.dart      # Configuração do SQLite
│   ├── models/                        # Modelos de dados
│   │   ├── player.dart               # Modelo do jogador
│   │   ├── mission.dart              # Modelo de missão
│   │   └── skill.dart                # Modelo de habilidade
│   └── repositories/                  # Repositórios (acesso aos dados)
│       ├── player_repository.dart
│       ├── mission_repository.dart
│       └── skill_repository.dart
│
├── providers/                         # State Management (Provider)
│   ├── player_provider.dart
│   ├── mission_provider.dart
│   └── skill_provider.dart
│
└── ui/                                # Interface do usuário
    ├── screens/                       # Telas da aplicação
    │   ├── main_screen.dart           # Tela principal (navegação)
    │   ├── missions/
    │   │   ├── missions_list_screen.dart
    │   │   ├── mission_editor_screen.dart
    │   │   └── mission_form_screen.dart
    │   └── skills/
    │       └── skills_view.dart
    │
    └── widgets/                       # Componentes reutilizáveis
        ├── common/
        │   ├── app_drawer.dart        # Menu lateral
        │   ├── icon_picker_dialog.dart
        │   ├── level_badge.dart
        │   └── xp_bar.dart
        ├── mission/
        │   ├── mission_card.dart      # Card de missão
        │   └── mission_list_item.dart
        ├── player/
        │   └── player_stats_header.dart # Header com stats do jogador
        └── skill/
            └── skill_linear_item.dart
```

---

## 🛠️ Tecnologias e Dependências

### Framework Principal
- **Flutter** (SDK ^3.10.4)

### State Management
- **provider** (^6.1.5+1) - Gerenciamento de estado reativo

### Banco de Dados
- **sqflite** (^2.4.2) - SQLite para mobile
- **sqflite_common_ffi** (^2.4.0+1) - SQLite para desktop (Linux/Windows/macOS)
- **path_provider** (^2.1.5) - Caminhos de diretórios
- **path** (^1.9.1) - Manipulação de caminhos

### UI e Design
- **google_fonts** (^6.3.3) - Fontes do Google (Roboto)
- **font_awesome_flutter** (^10.12.0) - Ícones FontAwesome
- **flutter_svg** (^2.2.3) - Suporte a SVG
- **fl_chart** (^1.1.1) - Gráficos (RadarChart, etc)
- **flutter_animate** (^4.5.2) - Animações
- **percent_indicator** (^4.2.5) - Indicadores de progresso

### Utilitários
- **intl** (^0.20.2) - Internacionalização e formatação
- **uuid** (^4.5.2) - Geração de UUIDs

### Desenvolvimento
- **flutter_lints** (^6.0.0) - Linting e análise de código

---

## 📊 Modelos de Dados

### 1. Player (Jogador)

Representa o jogador principal do sistema.

```dart
class Player {
  final int id;                    // ID único (sempre 1)
  final String name;               // Nome do jogador
  final int totalXP;               // XP total acumulado
  final int level;                 // Nível atual
  final int rewardPoints;          // Pontos de recompensa
  final String? avatarPath;        // Caminho do avatar
  final int currentEnergy;         // Energia atual (HP)
  final String energyMode;         // 'manual' ou 'auto'
  final String? wakeUpTime;        // Horário de acordar no modo auto
  final String? sleepTime;         // Horário de dormir no modo auto
  final String themeMode;          // Modo de tema
  final DateTime createdAt;        // Data de criação
  final DateTime updatedAt;        // Última atualização
}
```

**Características:**
- Singleton: Apenas um jogador pode existir (id = 1)
- Level é calculado automaticamente baseado no `totalXP`
- `currentEnergy` representa HP manual; em modo auto, o HP visível é calculado por `wakeUpTime`/`sleepTime`

### 2. Mission (Missão)

Representa uma tarefa/missão que o jogador pode completar.

```dart
class Mission {
  final int? id;                   // ID único (null se nova)
  final String title;              // Título da missão
  final String description;       // Descrição detalhada
  final int difficulty;            // Dificuldade (0-100)
  final int urgency;              // Urgência (0-100)
  final int fear;                 // Medo/Ansiedade (0-100)
  final int energyRequired;       // Energia necessária (1-5)
  final int xpReward;             // XP ganho ao completar
  final int rewardPoints;         // Pontos de recompensa
  final String status;            // 'active', 'completed', 'archived'
  final DateTime? dueDate;        // Data de vencimento
  final int? estimatedDuration;   // Duração estimada (minutos)
  final bool isRecurring;         // É recorrente?
  final String? recurrenceType;   // 'daily', 'weekly', 'monthly', etc
  final int? parentMissionId;     // ID da missão pai (subtasks)
  final String? icon;             // Caminho do ícone SVG
  final String? emoji;            // Emoji alternativo
  final List<int> skillIds;       // IDs das skills relacionadas
  // ... timestamps
}
```

**Características:**
- Suporta hierarquia (missões pai/filho para subtasks)
- Pode ser recorrente (diária, semanal, etc)
- Relacionamento many-to-many com Skills
- Atributos gamificados (difficulty, urgency, fear)
- Difficulty, Urgency e Fear seguem escala percentual: Low 0-25, Medium 26-50, High 51-75, Extreme 76-100

### 3. Skill (Habilidade)

Representa uma habilidade que pode ser desenvolvida.

```dart
class Skill {
  final int? id;                  // ID único
  final String name;              // Nome da habilidade
  final String description;       // Descrição
  final int currentXP;            // XP atual da skill
  final int level;                // Nível atual
  final String color;             // Cor (hex)
  final String? icon;             // Ícone
  final bool isActive;            // Está ativa?
  // ... timestamps
}
```

**Características:**
- Cada skill tem seu próprio XP e nível
- Skills ganham XP quando missões relacionadas são completadas
- Sistema de níveis independente do jogador

---

## 💾 Camada de Dados

### DatabaseHelper

Singleton que gerencia a conexão com o banco SQLite.

**Localização:** `lib/data/database/database_helper.dart`

**Responsabilidades:**
- Inicialização do banco de dados
- Criação do schema (tabelas)
- Migrações (onUpgrade)
- Configuração de foreign keys

**Schema do Banco:**

1. **Tabela `player`**
   - Armazena dados do jogador (singleton, id = 1)

2. **Tabela `missions`**
   - Armazena todas as missões
   - Foreign key para `parent_mission_id` (subtasks)
   - Índices em `status` e `parent_mission_id`

3. **Tabela `skills`**
   - Armazena habilidades
   - Soft delete com `is_active`

4. **Tabela `mission_skills`** (Junction Table)
   - Relacionamento many-to-many entre missions e skills
   - Foreign keys para ambas as tabelas

5. **Tabelas de conclusão e recompensas**
   - `mission_completion_events` registra conclusões de missão
   - `mission_completion_skill_rewards` registra XP concedido às skills
   - `rewards` define itens de loja/recompensas
   - `inventory_items` guarda recompensas obtidas e consumíveis
   - `reward_redemptions` registra compras/resgates

### Repositórios

Cada repositório encapsula operações CRUD para seu modelo.

#### PlayerRepository

**Localização:** `lib/data/repositories/player_repository.dart`

**Métodos principais:**
- `get()` - Obtém o jogador (cria se não existir)
- `update(Player)` - Atualiza dados do jogador
- `addXP(int)` - Adiciona XP e recalcula nível
- `addRewardPoints(int)` - Adiciona pontos de recompensa

**Lógica de XP:**
- Usa `XPCalculator` para calcular nível baseado no XP total
- Atualiza automaticamente o nível quando necessário

#### MissionRepository

**Localização:** `lib/data/repositories/mission_repository.dart`

**Métodos principais:**
- `insert(Mission)` - Cria nova missão
- `getAll()` - Lista todas as missões
- `getByStatus(String)` - Filtra por status
- `getById(int)` - Obtém missão específica
- `getWithSkills(int)` - Obtém missão com skills relacionadas
- `update(Mission)` - Atualiza missão
- `complete(int)` - Marca como completa
- `delete(int)` - Remove missão
- `linkSkills(int, List<int>)` - Vincula skills à missão

#### SkillRepository

**Localização:** `lib/data/repositories/skill_repository.dart`

**Métodos principais:**
- `insert(Skill)` - Cria nova skill
- `getAll()` - Lista skills ativas
- `getById(int)` - Obtém skill específica
- `update(Skill)` - Atualiza skill
- `delete(int)` - Soft delete (is_active = 0)
- `addXP(int, int)` - Adiciona XP à skill e recalcula nível

---

## 🧠 Camada de Lógica (Providers)

Providers gerenciam o estado da aplicação e fazem a ponte entre UI e dados.

### PlayerProvider

**Localização:** `lib/providers/player_provider.dart`

**Estado:**
- `_player` - Dados do jogador atual
- `_isLoading` - Estado de carregamento

**Getters úteis:**
- `player` - Jogador atual
- `totalXP` - XP total
- `level` - Nível atual
- `xpForNextLevel` - XP necessário para próximo nível
- `xpInCurrentLevel` - XP no nível atual
- `progressToNextLevel` - Progresso (0.0 a 1.0)

**Métodos:**
- `loadPlayer()` - Carrega jogador do banco
- `updatePlayer(Player)` - Atualiza e recarrega

### MissionProvider

**Localização:** `lib/providers/mission_provider.dart`

**Estado:**
- `_missions` - Lista de missões
- `_isLoading` - Estado de carregamento
- `_error` - Mensagem de erro

**Getters:**
- `missions` - Todas as missões
- `activeMissions` - Missões ativas
- `completedMissions` - Missões completas

**Métodos:**
- `loadMissions()` - Carrega todas as missões
- `addMission(Mission)` - Adiciona nova missão
- `completeMission(int)` - Completa missão e distribui recompensas
- `updateMission(Mission)` - Atualiza missão
- `deleteMission(int)` - Remove missão

**Lógica de Completar Missão:**
1. Marca missão como completa
2. Adiciona XP ao jogador
3. Adiciona reward points ao jogador
4. Distribui XP proporcionalmente às skills relacionadas

### SkillProvider

**Localização:** `lib/providers/skill_provider.dart`

**Estado:**
- `_skills` - Lista de skills
- `_isLoading` - Estado de carregamento

**Métodos:**
- `loadSkills()` - Carrega todas as skills
- `addSkill(Skill)` - Adiciona nova skill
- `updateSkill(Skill)` - Atualiza skill
- `deleteSkill(int)` - Remove skill

---

## 🎨 Camada de UI

### Estrutura de Telas

#### MainScreen

**Localização:** `lib/ui/screens/main_screen.dart`

**Responsabilidades:**
- Tela principal com navegação lateral (Drawer)
- Gerencia qual tela está ativa via `IndexedStack`
- Mostra `PlayerStatsHeader` em todas as telas (exceto Settings/Help)
- FloatingActionButton para criar missões (apenas na tela de Missions)

**Navegação:**
- Drawer lateral com 10 opções
- Índices: 0=Missions, 1=Map, 2=Rewards, 3=Inventory, 4=Skills, 5=Statistics, 6=Profile, 7=Shop, 8=Settings, 9=Help

#### MissionsListScreen

**Localização:** `lib/ui/screens/missions/missions_list_screen.dart`

**Funcionalidades:**
- Lista todas as missões
- Filtros: Todas, Ativas, Completas, Arquivadas
- RefreshIndicator para atualizar
- Usa `MissionCard` para exibir cada missão

#### MissionEditorScreen

**Localização:** `lib/ui/screens/missions/mission_editor_screen.dart`

**Funcionalidades:**
- Formulário completo para criar/editar missões
- Sliders para Difficulty, Urgency, Fear
- Seleção de Skills, Parent Mission, Date Due, Repetition
- Picker circular para Reward Points

### Widgets Principais

#### PlayerStatsHeader

**Localização:** `lib/ui/widgets/player/player_stats_header.dart`

**Componentes:**
- Avatar do jogador
- Nome e título
- Level grande (amarelo/dourado)
- Reward Points
- Barra de XP (azul)
- Barra de HP/Energy (vermelha)
- TabBar com filtros: PLAN, ALL, NEXT, OVERDUE, TODAY, TOMORROW

#### MissionCard

**Localização:** `lib/ui/widgets/mission/mission_card.dart`

**Layout:**
- Faixa de prioridade colorida (esquerda)
- Ícone da missão (SVG/emoji/FontAwesome)
- Título e descrição
- Indicador de recorrência
- Reward points
- Barra de progresso (opcional)
- Botão "+" para subtasks

#### AppDrawer

**Localização:** `lib/ui/widgets/common/app_drawer.dart`

**Funcionalidades:**
- Menu lateral com navegação
- Ícones SVG dos assets
- Destaque visual para item selecionado
- Header com logo do jogo

---

## 🎨 Tema e Design System

### AppTheme

**Localização:** `lib/core/theme/app_theme.dart`

### Paleta de Cores

```dart
background: #212121      // Fundo escuro principal
surface: #303030         // Superfície de cards
primary: #03A9F4         // Azul principal (destaques)
accentRed: #F44336      // Vermelho (HP/Urgência)
accentAmber: #FFC107    // Amarelo (Level/XP)
textPrimary: #F5F5F5    // Texto principal
textSecondary: #BDBDBD  // Texto secundário
border: #424242         // Bordas
```

### Características do Tema

- **Dark Mode** por padrão
- **Material 3** habilitado
- **Visual Density: Compact** (menos padding)
- **Fonte:** Roboto (via Google Fonts)
- **Cards:** Bordas arredondadas (12px), borda sutil
- **Inputs:** Fundo escuro, borda azul no foco

### Uso no Código

```dart
// Acessar cores
AppTheme.primary
AppTheme.accentRed
AppTheme.textPrimary

// Acessar tema
Theme.of(context).colorScheme.primary
Theme.of(context).cardTheme
```

---

## 🔄 Fluxos Principais

### 1. Fluxo de Criar Missão

```
User clica FAB
    ↓
MissionEditorScreen abre
    ↓
User preenche formulário
    ↓
User clica "Save"
    ↓
MissionProvider.addMission()
    ↓
MissionRepository.insert()
    ↓
Skills vinculadas (se houver)
    ↓
MissionProvider.loadMissions()
    ↓
UI atualiza automaticamente
```

### 2. Fluxo de Completar Missão

```
User toca em MissionCard
    ↓
MissionProvider.completeMission()
    ↓
MissionCompletionService executa transação
    ↓
Registra histórico de conclusão
    ↓
Player recebe XP e Reward Points/Moedas
    ↓
Skills vinculadas recebem XP
    ↓
Missão muda status ou avança recorrência
    ↓
Drops de recompensa geram itens de inventário quando implementados
    ↓
Providers notificam listeners
    ↓
UI atualiza (XP, Level, Skills)
```

### 3. Fluxo de Carregamento Inicial

```
main() executa
    ↓
MyApp cria Providers
    ↓
Providers chamam loadPlayer/loadMissions/loadSkills
    ↓
Repositories consultam banco
    ↓
Dados são populados nos Providers
    ↓
UI renderiza com dados
```

---

## 🚀 Como Executar

### Pré-requisitos

1. **Flutter SDK** (gerenciado via FVM)
2. **FVM** (Flutter Version Management)
3. **Dependências do sistema** (para desktop)

### Passos

1. **Clone o repositório** (se aplicável)

2. **Instale as dependências:**
   ```bash
   fvm flutter pub get
   ```

3. **Execute o app:**
   ```bash
   # Linux
   fvm flutter run -d linux
   
   # Android
   fvm flutter run -d android
   
   # iOS
   fvm flutter run -d ios
   ```

### Inicialização do Banco

O banco SQLite é criado automaticamente na primeira execução:
- **Mobile:** `getDatabasesPath()` retorna diretório do app
- **Desktop:** `sqflite_common_ffi` é usado automaticamente

### Dados Iniciais

O `DatabaseHelper._onCreate()` cria:
- Um jogador padrão (id=1, name='Player')
- 5 skills padrão: Inteligência, Força, Saúde, Social, Criatividade

---

## 📈 Sistema de XP e Níveis

### XPCalculator

**Localização:** `lib/core/utils/xp_calculator.dart`

**Fórmula de XP por Nível:**
```
XP necessário para nível N = N * 100
```

**Exemplos:**
- Nível 1 → 2: 100 XP
- Nível 2 → 3: 200 XP
- Nível 3 → 4: 300 XP
- Total para nível 5: 100 + 200 + 300 + 400 = 1000 XP

**Métodos:**
- `xpForNextLevel(int level)` - XP necessário para próximo nível
- `calculateLevel(int totalXP)` - Calcula nível baseado no XP total
- `xpInCurrentLevel(int totalXP, int level)` - XP no nível atual

### Skills

Skills usam fórmula similar, mas com cálculo independente:
- Cada skill tem seu próprio `currentXP` e `level`
- XP é distribuído entre as skills vinculadas quando missões são completadas

### Missões e Recompensas

Ao completar uma missão pelo fluxo de provider/service:
- O jogador recebe XP e Reward Points/Moedas.
- Skills vinculadas recebem XP da missão.
- Missões recorrentes avançam para a próxima ocorrência quando aplicável.
- Recompensas dropadas por missão devem virar itens de inventário quando esse fluxo estiver ativo.

Recompensas são itens ou permissões que o usuário compra na loja com RP/Moedas ou recebe como drop. Depois de obtidas, ficam no inventário e podem ser consumidas. O consumo decrementa a quantidade do item ou remove o item quando a quantidade chega a zero.

### Energia / HP

A barra de energia é tratada como HP:
- No modo manual, o usuário ajusta o valor atual diretamente.
- No modo automático, horários de acordar e dormir definem o ciclo.
- Durante o tempo acordado, HP drena de 100 para 0.
- Durante o sono, HP recarrega de 0 para 100.
- O app atualiza a visualização automática a cada minuto.

---

## 🔍 Pontos Importantes para Desenvolvedores

### 1. State Management

- **Provider** é usado para gerenciamento de estado
- Sempre use `Consumer` ou `context.read<T>()` para acessar providers
- Providers notificam listeners automaticamente quando dados mudam

### 2. Banco de Dados

- **Singleton Pattern** para `DatabaseHelper`
- **Foreign Keys** habilitadas via `PRAGMA foreign_keys = ON`
- **Soft Delete** para Skills (`is_active = 0`)

### 3. Assets

- **SVG Icons** em `assets/game-icons.net.svg/`
- Use `SvgPicture.asset()` para carregar
- Sempre forneça `placeholderBuilder` e `errorBuilder`

### 4. Navegação

- **Drawer** para navegação principal
- **IndexedStack** para manter estado das telas
- **Navigator.push()** para telas modais (ex: MissionEditorScreen)

### 5. Performance

- Use `ListView.builder` para listas grandes
- `IndexedStack` mantém todas as telas em memória (trade-off)
- Considere lazy loading para grandes volumes de dados

---

## 📝 Próximos Passos

### Funcionalidades Pendentes

1. **Drops de Recompensas por Missão**
   - Definir modelo e histórico para recompensas concedidas automaticamente ao concluir missões
   - Integrar drops ao inventário na mesma transação da conclusão

2. **Gráfico Radar**
   - Completar implementação do RadarChart em `SkillsView`

3. **Energia na Priorização**
   - Usar HP restante como sinal opcional na ordenação sugerida de missões

4. **Missões Recorrentes**
   - Expandir uso de `recurrenceInterval`
   - Melhorar feedback de streak

5. **Subtasks**
   - Refinar criação e visualização de missões filhas

### Melhorias Técnicas

1. **Testes**
   - Unit tests para repositories
   - Widget tests para componentes principais

2. **Tratamento de Erros**
   - SnackBars para erros do usuário
   - Logging estruturado

3. **Validações**
   - Validação de formulários mais robusta
   - Mensagens de erro claras

4. **Otimizações**
   - Cache de dados
   - Debounce em buscas

---

## 📚 Recursos Adicionais

### Documentação Flutter
- [Flutter Docs](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [sqflite](https://pub.dev/packages/sqflite)

### Design
- [Material Design 3](https://m3.material.io/)
- [Google Fonts](https://fonts.google.com/)

### Assets
- [Game Icons](https://game-icons.net/) - Ícones SVG usados no projeto

---

## ❓ Dúvidas Frequentes

### Como adicionar uma nova tela?

1. Crie o arquivo em `lib/ui/screens/`
2. Adicione à lista `_pages` no `MainScreen`
3. Adicione o título em `_titleForIndex()`
4. Adicione item no `AppDrawer` (se necessário)

### Como adicionar um novo campo ao modelo?

1. Adicione o campo no modelo (ex: `Mission`)
2. Atualize `toMap()` e `fromMap()`
3. Atualize `copyWith()`
4. Adicione coluna no `DatabaseHelper._onCreate()`
5. Crie migration em `_onUpgrade()` (se necessário)

### Como criar um novo provider?

1. Crie classe estendendo `ChangeNotifier`
2. Adicione estado privado
3. Adicione getters públicos
4. Adicione métodos que chamam `notifyListeners()`
5. Registre no `MultiProvider` em `main.dart`

---

## 🎉 Conclusão

Este guia cobre os aspectos principais do projeto LifeRPG. Para dúvidas específicas, consulte o código-fonte ou adicione documentação inline conforme necessário.

**Boa sorte no desenvolvimento! 🚀**
