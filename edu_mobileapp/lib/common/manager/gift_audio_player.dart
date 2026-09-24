import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/model/general/settings_model.dart';

/// Preloads and caches gift audio files locally to ensure instant 0ms playback
/// on click, perfectly synchronized with visual SVG animations.
/// Supports both pure audio files (.mp3, .wav, .m4a, .aac) via just_audio and
/// video container files (.mp4, .mov, .webm) via VideoPlayerController.
class GiftAudioPlayer {
  static final Map<String, String> _cache = {};
  static AudioPlayer? _player;
  static VideoPlayerController? _videoPlayerController;
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

  /// Detects whether the file or URL is an MP4/video container file
  static bool _isVideoContainer(String urlOrPath) {
    final lower = urlOrPath.toLowerCase();
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.contains('.mp4?') ||
        lower.contains('.mp4/') ||
        lower.contains('.mov?') ||
        lower.contains('.webm?')) {
      return true;
    }
    try {
      final f = File(urlOrPath);
      if (f.existsSync() && f.lengthSync() >= 12) {
        final bytes = f.openSync().readSync(12);
        // MP4 / MOV containers have 'ftyp' at bytes 4..7
        if (bytes.length >= 8 &&
            bytes[4] == 0x66 && // f
            bytes[5] == 0x74 && // t
            bytes[6] == 0x79 && // y
            bytes[7] == 0x70) { // p
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Stop both audio and video players cleanly
  static Future<void> _stopAll() async {
    try {
      _player?.stop();
    } catch (_) {}
    await _stopVideoPlayer();
  }

  static Future<void> _stopVideoPlayer() async {
    if (_videoPlayerController != null) {
      final c = _videoPlayerController;
      _videoPlayerController = null;
      try {
        await c?.pause();
        await c?.dispose();
      } catch (_) {}
    }
  }

  /// Play audio via VideoPlayerController (handles .mp4 audio/video tracks natively)
  static Future<void> _playVideoContainer({
    String? filePath,
    String? url,
    String? asset,
  }) async {
    await _stopVideoPlayer();
    VideoPlayerController controller;
    if (filePath != null && filePath.isNotEmpty) {
      controller = VideoPlayerController.file(File(filePath));
    } else if (asset != null && asset.isNotEmpty) {
      controller = VideoPlayerController.asset(asset);
    } else if (url != null && url.isNotEmpty) {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
    } else {
      return;
    }

    _videoPlayerController = controller;
    await controller.initialize();
    await controller.setVolume(1.0);
    await controller.play();

    // Auto-dispose when finished playing
    controller.addListener(() {
      if (controller.value.isInitialized &&
          !controller.value.isPlaying &&
          controller.value.position >= controller.value.duration &&
          controller.value.duration > Duration.zero) {
        if (_videoPlayerController == controller) {
          _videoPlayerController = null;
          try {
            controller.dispose();
          } catch (_) {}
        }
      }
    });

    Loggers.info('GiftAudioPlayer played via VideoPlayerController: ${filePath ?? asset ?? url}');
  }

  /// Play audio via just_audio (handles .mp3, .wav, .aac, .ogg)
  static Future<void> _playAudioPlayer({
    String? filePath,
    String? url,
    String? asset,
  }) async {
    final p = player;
    await p.stop();
    if (filePath != null && filePath.isNotEmpty) {
      await p.setFilePath(filePath);
    } else if (asset != null && asset.isNotEmpty) {
      await p.setAsset(asset);
    } else if (url != null && url.isNotEmpty) {
      await p.setUrl(url).timeout(const Duration(seconds: 8));
    } else {
      return;
    }
    await p.play();
    Loggers.info('GiftAudioPlayer played via AudioPlayer: ${filePath ?? asset ?? url}');
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

    // Prevent duplicate triggers within 400ms for the exact same sound URL
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastPlayUrl == soundUrl && (now - _lastPlayTimestamp) < 400) {
      return;
    }
    _lastPlayUrl = soundUrl;
    _lastPlayTimestamp = now;

    try {
      await _stopAll();

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

        // If local cached file is ready, play instantly with 0ms delay!
        if (cachedPath != null) {
          final cachedFile = File(cachedPath);
          if (await cachedFile.exists() && await cachedFile.length() > 0) {
            if (_isVideoContainer(cachedPath) || _isVideoContainer(soundUrl)) {
              try {
                await _playVideoContainer(filePath: cachedPath);
                return;
              } catch (videoErr) {
                Loggers.error('GiftAudioPlayer VideoPlayerController local file error ($soundUrl): $videoErr');
                // Try AudioPlayer as second attempt
                try {
                  await _playAudioPlayer(filePath: cachedPath);
                  return;
                } catch (_) {}
              }
            } else {
              try {
                await _playAudioPlayer(filePath: cachedPath);
                return;
              } catch (audioErr) {
                Loggers.error('GiftAudioPlayer AudioPlayer local file error ($soundUrl): $audioErr');
                // Try VideoPlayerController as second attempt
                try {
                  await _playVideoContainer(filePath: cachedPath);
                  return;
                } catch (_) {}
              }
            }
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
              .timeout(const Duration(seconds: 4));
          if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
            await file.writeAsBytes(resp.bodyBytes, flush: true);
            _cache[soundUrl] = filePath;
            if (_isVideoContainer(filePath) || _isVideoContainer(soundUrl)) {
              await _playVideoContainer(filePath: filePath);
            } else {
              await _playAudioPlayer(filePath: filePath);
            }
            return;
          }
        } catch (downloadErr) {
          Loggers.error('GiftAudioPlayer fast download error ($soundUrl): $downloadErr');
        }

        // Fallback to streaming directly from URL if download timed out
        if (_isVideoContainer(soundUrl)) {
          await _playVideoContainer(url: soundUrl);
        } else {
          try {
            await _playAudioPlayer(url: soundUrl);
          } catch (_) {
            await _playVideoContainer(url: soundUrl);
          }
        }
      } else {
        // Local asset sound (e.g. assets/audios/pen audio.mp4 or assets/images/fairy-sparkle.mp3)
        if (_isVideoContainer(soundUrl)) {
          await _playVideoContainer(asset: soundUrl);
        } else {
          try {
            await _playAudioPlayer(asset: soundUrl);
          } catch (_) {
            await _playVideoContainer(asset: soundUrl);
          }
        }
      }
    } catch (e) {
      Loggers.error('GiftAudioPlayer play error ($soundUrl): $e');
      if (soundUrl != 'assets/images/fairy-sparkle.mp3') {
        try {
          await _stopAll();
          final p = player;
          await p.setAsset('assets/images/fairy-sparkle.mp3');
          await p.play();
        } catch (_) {}
      }
    }
  }

  static void stop() {
    _stopAll();
  }
}
