import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Shared full-screen player for a recorded live session's video_url —
/// used from both Profile > My Lives and the Home page's public recorded
/// lives feed.
class RecordedVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const RecordedVideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<RecordedVideoPlayerScreen> createState() => _RecordedVideoPlayerScreenState();
}

class _RecordedVideoPlayerScreenState extends State<RecordedVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller = controller;
    controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
        controller.play();
      }
    }).catchError((_) {
      if (mounted) setState(() => _hasError = true);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(
        child: _hasError
            ? const Text('Unable to play this recording', style: TextStyle(color: Colors.white70))
            : (controller != null && controller.value.isInitialized)
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(controller),
                        GestureDetector(
                          onTap: () => setState(() {
                            controller.value.isPlaying ? controller.pause() : controller.play();
                          }),
                          child: AnimatedOpacity(
                            opacity: controller.value.isPlaying ? 0 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.play_arrow, size: 64, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.white38),
      ),
    );
  }
}
