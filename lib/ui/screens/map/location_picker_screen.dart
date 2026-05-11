import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/common/game_snack_bar.dart';

class MissionLocationSelection {
  final String? name;
  final double latitude;
  final double longitude;

  const MissionLocationSelection({
    this.name,
    required this.latitude,
    required this.longitude,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final MissionLocationSelection? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _fallbackCenter = LatLng(-9.6498, -35.7089);
  final _mapController = MapController();
  final _nameController = TextEditingController();
  LatLng? _selected;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    if (initial != null) {
      _selected = LatLng(initial.latitude, initial.longitude);
      _nameController.text = initial.name ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final center = selected ?? _fallbackCenter;
    return Scaffold(
      appBar: AppBar(title: const Text('Mission Location')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: selected == null ? 12 : 15,
                onTap: (_, point) => setState(() => _selected = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.cicero.liferpg',
                ),
                if (selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selected,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_pin,
                          color: AppTheme.accentRed,
                          size: 42,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do local',
                      hintText: 'Casa, academia, biblioteca...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _useCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('GPS atual'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: selected == null ? null : _confirm,
                          icon: const Icon(Icons.check),
                          label: const Text('Usar local'),
                        ),
                      ),
                    ],
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${selected.latitude.toStringAsFixed(5)}, ${selected.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (!mounted) return;
      GameSnackBar.show(
        context,
        title: 'Location',
        message: 'Serviço de localização desativado.',
        type: GameSnackBarType.error,
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      GameSnackBar.show(
        context,
        title: 'Location',
        message: 'Permissão negada. Toque no mapa para escolher manualmente.',
        type: GameSnackBarType.error,
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final point = LatLng(position.latitude, position.longitude);
    setState(() => _selected = point);
    _mapController.move(point, 16);
  }

  void _confirm() {
    final selected = _selected;
    if (selected == null) return;
    Navigator.of(context).pop(
      MissionLocationSelection(
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        latitude: selected.latitude,
        longitude: selected.longitude,
      ),
    );
  }
}
