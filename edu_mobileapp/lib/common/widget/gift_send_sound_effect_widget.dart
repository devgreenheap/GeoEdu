import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playGiftSound() async {
    try {
      await _player.stop();
      await _player.setAsset('assets/images/fairy-sparkle.mp3');
      await _player.play();

    } catch (e) {
      print("Audio error: $e");
    }
  }
}