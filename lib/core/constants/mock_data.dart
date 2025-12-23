class MockMission {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final int difficulty;
  final int urgency;
  final bool isCompleted;
  final List<String> skills;

  MockMission({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.difficulty,
    required this.urgency,
    this.isCompleted = false,
    this.skills = const [],
  });
}

class MockData {
  static final List<MockMission> missions = [
    MockMission(
      id: '1',
      title: 'Estudar Flutter por 2 horas',
      description: 'Completar módulo de State Management',
      xpReward: 50,
      difficulty: 3,
      urgency: 4,
      skills: ['Programação', 'Inteligência'],
    ),
    MockMission(
      id: '2',
      title: 'Fazer 30 min de exercícios',
      description: 'Treino de força e cardio',
      xpReward: 30,
      difficulty: 2,
      urgency: 5,
      skills: ['Saúde', 'Força'],
    ),
    MockMission(
      id: '3',
      title: 'Ler 20 páginas do livro',
      description: 'Continuar leitura de Clean Code',
      xpReward: 25,
      difficulty: 1,
      urgency: 2,
      skills: ['Inteligência', 'Programação'],
    ),
    MockMission(
      id: '4',
      title: 'Meditar por 15 minutos',
      description: 'Praticar mindfulness',
      xpReward: 20,
      difficulty: 1,
      urgency: 3,
      skills: ['Foco', 'Saúde'],
    ),
    MockMission(
      id: '5',
      title: 'Revisar Pull Requests',
      description: 'Revisar 3 PRs do time',
      xpReward: 40,
      difficulty: 3,
      urgency: 5,
      skills: ['Programação', 'Social'],
    ),
  ];

  static final playerData = {
    'name': 'Player',
    'level': 5,
    'currentXP': 350,
    'xpForNextLevel': 500,
    'totalXP': 2350,
  };
}