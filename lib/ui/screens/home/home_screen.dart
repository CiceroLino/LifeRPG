// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../data/models/player.dart';
// import '../../../providers/mission_provider.dart';
// import '../../../providers/player_provider.dart';
// import '../../../providers/skill_provider.dart';
// import '../../../data/models/mission.dart';
// import '../../../core/constants/app_strings.dart';
// import '../../widgets/mission/mission_card.dart';
// import '../../widgets/player/player_stats_header.dart';
// import '../missions/mission_form_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(AppStrings.appName),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: () async {
//           await context.read<MissionProvider>().loadMissions();
//           await context.read<PlayerProvider>().loadPlayer();
//         },
//         child: Consumer2<PlayerProvider, MissionProvider>(
//           builder: (context, playerProvider, missionProvider, _) {
//             if (playerProvider.isLoading || missionProvider.isLoading) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             final player = playerProvider.player;
//             final missions = missionProvider.activeMissions;

//             return ListView(
//               padding: EdgeInsets.zero,
//               children: [
//                 // Player Stats Header
//                 if (player != null)
//                   PlayerStatsHeader(
//                     player: player,
//                     title: 'Adventurer', // TODO: Adicionar campo title ao Player model
//                     onTabChanged: (index) {
//                       // TODO: Implementar filtro de missões baseado na tab selecionada
//                       // 0: PLAN, 1: ALL, 2: NEXT, 3: OVERDUE, 4: TODAY
//                     },
//                   ),
                
//                 const SizedBox(height: 16),
                
//                 // Missions Header
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Missões Ativas (${missions.length})',
//                         style: const TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 const SizedBox(height: 8),
                
//                 // Missions List
//                 if (missions.isEmpty)
//                   const Padding(
//                     padding: EdgeInsets.all(32),
//                     child: Center(
//                       child: Text(
//                         'Nenhuma missão ativa.\nToque em + para criar uma!',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(fontSize: 16, color: Colors.grey),
//                       ),
//                     ),
//                   )
//                 else
//                   ...missions.map((mission) => MissionCard(
//                         mission: mission,
//                         onTap: () => _completeMission(mission),
//                         onAddSubtask: () {
//                           // TODO: Implementar adicionar subtask
//                         },
//                       )),
//               ],
//             );
//           },
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.of(context).push(
//             MaterialPageRoute(builder: (_) => const MissionFormScreen()),
//           );
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }


//   Future<void> _completeMission(Mission mission) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Completar Missão?'),
//         content: Text('Você ganhará ${mission.xpReward} XP!'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancelar'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Completar'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true && mounted) {
//       await context.read<MissionProvider>().completeMission(mission.id!);
//       await context.read<PlayerProvider>().loadPlayer();
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('🎉 +${mission.xpReward} XP!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     }
//   }
// }