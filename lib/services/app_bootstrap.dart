import 'package:flutter/foundation.dart';
import 'tavern_audio_service.dart';

Future<TavernPlayback> initializeTavernPlayback({
  Future<TavernPlayback> Function()? initializer,
}) async {
  try {
    return await (initializer ?? initTavernAudioService)();
  } catch (error) {
    debugPrint('Audio is unavailable: $error');
    return UnavailableTavernPlayback();
  }
}
