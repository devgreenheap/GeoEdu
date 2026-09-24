import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/model/general/settings_model.dart';

/// Preloads and caches gift audio files locally to ensure instant 0ms playback
/// on click, perfectly synchronized with visual SVG animations.
class GiftAudioPlayer {
  static final Map<String, String> _cache = {};
  static AudioPlayer? _player;
  static String? _cacheDirPath;
  static int _lastPlayTimestamp = 0;
  static String? _lastPlayUrl;

  static AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  static Future<String> _getCacheDir() async {
    if (_cacheDirPath != null) return _cacheDirPath!;
    final tempDir = await getTemporaryDirectory();
    final dir = Directory('${tempDir.path}/gift_audio_cache');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _cacheDirPath = dir.path;
    return _cacheDirPath!;
  }

  static String _getFilePath(String cacheDir, String url) {
    final cleanName = url.split('/').last.split('?').first;
    final hash = url.hashCode.abs();
    return '$cacheDir/${hash}_$cleanName';
  }

  /// Preload a list of gifts ahead of time (e.g. on room entry or settings load)
  static Future<void> preloadAll(List<Gift> gifts) async {
    for (final gift in gifts) {
      final url = gift.effectiveSoundUrl;
      if (url.isNotEmpty) {
        preload(url);
      }
    }
  }

  /// Preload audio file into local disk cache for instant 0ms playback
  static Future<void> preload(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final soundUrl = url.trim();
    if (!soundUrl.startsWith('http://') && !soundUrl.startsWith('https://')) return;

    if (_cache.containsKey(soundUrl)) {
      final f = File(_cache[soundUrl]!);
      if (await f.exists() && await f.length() > 0) return;
    } 

    try {
      final cacheDir = await _getCacheDir();
      final filePath = _getFilePath(cacheDir, soundUrl);
      final file = File(filePath);

      if (await file.exists() && await file.length() > 0) {
        _cache[soundUrl] = filePath;
        return;
      }

      final response = await http
          .get(Uri.parse(soundUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes, flush: true);
        _cache[soundUrl] = filePath;
        Loggers.info('GiftAudioPlayer preloaded: $soundUrl -> $filePath');
      }
    } catch (e) {
      Loggers.error('GiftAudioPlayer preload error ($soundUrl): $e');
    }
  }

  /// Play gift sound with zero latency (uses cached local file if available)
  static Future<void> play(String? sound) async {
    if (sound == null || sound.trim().isEmpty) return;
    final soundUrl = sound.trim();

    // Prevent duplicate triggers within 600ms for the same sound URL
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastPlayUrl == soundUrl && (now - _lastPlayTimestamp) < 600) {
      return;
    }
    _lastPlayUrl = soundUrl;
    _lastPlayTimestamp = now;

    try {
      final p = player;
      await p.stop();

      if (soundUrl.startsWith('http://') || soundUrl.startsWith('https://')) {
        String? cachedPath = _cache[soundUrl];
        if (cachedPath == null) {
          final cacheDir = await _getCacheDir();
          final filePath = _getFilePath(cacheDir, soundUrl);
          final file = File(filePath);
          if (await file.exists() && await file.length() > 0) {
            cachedPath = filePath;
            _cache[soundUrl] = cachedPath;
          }
        }

        if (cachedPath != null) {
          final cachedFile = File(cachedPath);
          if (await cachedFile.exists() && await cachedFile.length() > 0) {
            // Instant playback from local file (0ms delay!)
            await p.setFilePath(cachedPath);
            p.play();
            return;
          } else {
            _cache.remove(soundUrl);
          }
        }

        // If not cached yet, download and cache locally for seamless playback
        try {
          final cacheDir = await _getCacheDir();
          final filePath = _getFilePath(cacheDir, soundUrl);
          final file = File(filePath);
          final resp = await http
              .get(Uri.parse(soundUrl))
              .timeout(const Duration(seconds: 8));
          if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
            await file.writeAsBytes(resp.bodyBytes, flush: true);
            _cache[soundUrl] = filePath;
            await p.setFilePath(filePath);
            p.play();
            return;
          }
        } catch (downloadErr) {
          Loggers.error('GiftAudioPlayer download error: $downloadErr');
        }

        // Fallback to URL streaming if download fails
        await p.setUrl(soundUrl).timeout(const Duration(seconds: 8));
        p.play();
      } else {
        await p.setAsset(soundUrl);
        p.play();
      }
    } catch (e) {
      Loggers.error('GiftAudioPlayer play error ($soundUrl): $e');
      if (soundUrl != 'assets/images/fairy-sparkle.mp3') {
        try {
          final p = player;
          await p.setAsset('assets/images/fairy-sparkle.mp3');
          p.play();
        } catch (_) {}
      }
    }
  }

  static void stop() {
    try {
      _player?.stop();
     } catch (_) {}
  }
}
