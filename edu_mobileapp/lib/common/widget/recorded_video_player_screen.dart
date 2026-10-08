import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:geoedu/utilities/color_res.dart';

/// Shared full-screen player for a recorded live session's video_url —
/// used from both Profile > My Lives and the Home page's public recorded
/// lives feed.
class RecordedVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final String? duration;

  const RecordedVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    this.title,
    this.duration,
  });

  @override
  State<RecordedVideoPlayerScreen> createState() =>
      _RecordedVideoPlayerScreenState();
}

class _RecordedVideoPlayerScreenState extends State<RecordedVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _hasError = false;
  bool _showControls = true;

  static const String fallbackVideoUrl =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

  @override
  void initState() {
    super.initState();
    _initPlayer(widget.videoUrl);
  }

  void _initPlayer(String url) {
    final effectiveUrl = url.trim().isNotEmpty ? url.trim() : fallbackVideoUrl;
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(effectiveUrl));
    _controller = controller;
    controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _hasError = false;
        });
        controller.play();
        controller.addListener(_videoListener);
      }
    }).catchError((_) {
      if (url != fallbackVideoUrl && mounted) {
        // Try fallback if primary URL failed
        _controller?.dispose();
        _initPlayer(fallbackVideoUrl);
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    });
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isInitialized = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.85),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title ?? 'Live Recording',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.duration != null && widget.duration!.isNotEmpty) ...[
              Text(
                'Recorded Session • ${widget.duration}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Center(
          child: _hasError
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.white54, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Recording is being processed or unavailable',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorRes.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onTap: () => _initPlayer(fallbackVideoUrl),
                      child: const Text('Play Sample Recording'),
                    ),
                  ],
                )
              : isInitialized
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: controller.value.aspectRatio > 0
                              ? controller.value.aspectRatio
                              : (9 / 16),
                          child: VideoPlayer(controller),
                        ),

                        // Center Play / Pause Animated Button
                        if (_showControls)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                controller.value.isPlaying
                                    ? controller.pause()
                                    : controller.play();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.55),
                                border: Border.all(
                                    color: Colors.white70, width: 2),
                              ),
                              child: Icon(
                                controller.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 54,
                                color: Colors.white,
                              ),
                            ),
                          ),

                        // Bottom Scrub Bar and Timers
                        if (_showControls)
                          Positioned(
                            bottom: 24,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  VideoProgressIndicator(
                                    controller,
                                    allowScrubbing: true,
                                    colors: const VideoProgressColors(
                                      playedColor: ColorRes.primaryColor,
                                      bufferedColor: Colors.white24,
                                      backgroundColor: Colors.white12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(
                                            controller.value.position),
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11),
                                      ),
                                      Text(
                                        _formatDuration(
                                            controller.value.duration),
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: ColorRes.primaryColor, strokeWidth: 2.5),
                        SizedBox(height: 14),
                        Text(
                          'Loading live recording...',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
