import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:geoedu/utilities/asset_res.dart';

/// Fullscreen countdown overlay (5 -> 4 -> 3 -> 2 -> 1 -> 0)
/// matching the exact UI in the user reference image, with sound effects.
class LiveStartCountdownOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  final bool isVideo;

  const LiveStartCountdownOverlay({
    super.key,
    required this.onFinished,
    this.isVideo = true,
  });

  @override
  State<LiveStartCountdownOverlay> createState() => _LiveStartCountdownOverlayState();
}

class _LiveStartCountdownOverlayState extends State<LiveStartCountdownOverlay>
    with SingleTickerProviderStateMixin {
  int _count = 5;
  Timer? _timer;
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playBeepSound();
    _startCountdown();
  }

  Future<void> _playBeepSound() async {
    try {
      // Re-trigger audio on each tick
      await _audioPlayer.setAsset(AssetRes.battleStart);
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } catch (_) {}
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_count > 0) {
        setState(() {
          _count--;
        });
        _playBeepSound();
      } else {
        timer.cancel();
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streamType = widget.isVideo ? 'stream' : 'audio room';

    return Material(
      color: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Title: Your LIVE stream starts in
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'Your ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  children: [
                    const TextSpan(
                      text: 'LIVE ',
                      style: TextStyle(
                        color: Color(0xFFFF2200),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: '$streamType starts in',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Circular Arc + Big Number in Orange
              SizedBox(
                width: 170,
                height: 170,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Orange curved arc
                    CustomPaint(
                      size: const Size(170, 170),
                      painter: _ArcPainter(
                        color: const Color(0xFFFF5500),
                        strokeWidth: 7,
                      ),
                    ),
                    // Giant Count Number
                    Text(
                      '$_count',
                      style: const TextStyle(
                        color: Color(0xFFFF5500),
                        fontSize: 90,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Moderation Warning Box (Red Card at Bottom)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2D20),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2D20).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Nudity, Pornography, Smoking, Abuse is strictly prohibited. Live streams are moderated 24 x 7',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ArcPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // Draw an arc spanning ~180 degrees from top to bottom left
    canvas.drawArc(rect, 2.5, 3.2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
