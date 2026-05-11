import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/mission.dart';
import '../../../providers/mission_provider.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static const _fallbackCenter = LatLng(-9.6498, -35.7089);

  @override
  Widget build(BuildContext context) {
    return Consumer<MissionProvider>(
      builder: (context, provider, _) {
        final missions = provider.missions
            .where(
              (mission) =>
                  mission.latitude != null && mission.longitude != null,
            )
            .toList();
        final center = missions.isEmpty
            ? _fallbackCenter
            : LatLng(missions.first.latitude!, missions.first.longitude!);

        return Column(
          children: [
            Expanded(
              child: FlutterMap(
                options: MapOptions(initialCenter: center, initialZoom: 12),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.cicero.liferpg',
                  ),
                  MarkerLayer(
                    markers: missions
                        .map(
                          (mission) => Marker(
                            point: LatLng(
                              mission.latitude!,
                              mission.longitude!,
                            ),
                            width: 46,
                            height: 46,
                            child: GestureDetector(
                              onTap: () => _showMission(context, mission),
                              child: const Icon(
                                Icons.location_pin,
                                color: AppTheme.accentRed,
                                size: 38,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            if (missions.isEmpty)
              Container(
                width: double.infinity,
                color: AppTheme.surface,
                padding: const EdgeInsets.all(12),
                child: const Text(
                  'Nenhuma missão com local definido.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showMission(BuildContext context, Mission mission) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mission.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mission.locationName ?? 'Local sem nome',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _Chip(label: '${mission.xpReward} XP'),
                _Chip(label: '${mission.rewardPoints} RP'),
                if (mission.estimatedDuration != null)
                  _Chip(label: '${mission.estimatedDuration} min'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppTheme.background,
      labelStyle: const TextStyle(color: AppTheme.textPrimary),
    );
  }
}
