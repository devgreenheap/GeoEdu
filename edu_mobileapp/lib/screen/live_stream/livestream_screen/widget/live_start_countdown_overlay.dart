import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:geoedu/utilities/asset_res.dart';

/// Fullscreen countdown overlay (3 -> 2 -> 1 -> GO!)
/// with smooth circular progress ring decreasing to GO!, sound effects,
/// and automatic room start callback.
class LiveStartCountdownOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  final bool isVideo;

  const LiveStartCountdownOverlay({
    super.key,
    required this.onFinished,
    this.isVideo = true,
  });

  @override
  State<LiveStartCountdownOverlay> createState() =>
      _LiveStartCountdownOverlayState();
}

class _LiveStartCountdownOverlayState extends State<LiveStartCountdownOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _popController;
  late final Animation<double> _popAnimation;

  late final AudioPlayer _audioPlayer;
  int _currentNumber = 3;
  bool _isGo = false;
  bool _finished = false;
  Timer? _goTimer;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();

    // 3 seconds total duration for 3 -> 2 -> 1 (1 second per count)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Number / GO! scale bounce animation
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _popAnimation = Tween<double>(begin: 1.25, end: 1.0).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeOutBack),
    );

    _progressController.addListener(_onProgressTick);
    _progressController.addStatusListener(_onProgressStatus);

    _loadAudio();
    _popController.forward(from: 0.0);
    _progressController.forward();
  }

  Future<void> _loadAudio() async {
    try {
      await _audioPlayer.setAsset(AssetRes.battleStart);
      await _playTick();
    } catch (_) {}
  }

  void _onProgressTick() {
    if (!mounted || _isGo) return;

    final val = _progressController.value;
    int number;
    if (val < 1.0 / 3.0) {
      number = 3;
    } else if (val < 2.0 / 3.0) {
      number = 2;
    } else {
      number = 1;
    }

    if (number != _currentNumber) {
      setState(() {
        _currentNumber = number;
      });
      _popController.forward(from: 0.0);
      _playTick();
    }
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted && !_isGo) {
      setState(() {
        _isGo = true;
      });
      _popController.forward(from: 0.0);
      _playTick();

      // Show "GO!" for 750ms, then start live room automatically
      _goTimer = Timer(const Duration(milliseconds: 750), () {
        if (mounted && !_finished) {
          _finished = true;
          widget.onFinished();
        }
      });
    }
  }

  Future<void> _playTick() async {
    try {
      if (_audioPlayer.duration != null) {
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _goTimer?.cancel();
    _progressController.removeListener(_onProgressTick);
    _progressController.removeStatusListener(_onProgressStatus);
    _progressController.dispose();
    _popController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streamType = widget.isVideo ? 'stream' : 'audio room';

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.black.withValues(alpha: 0.94),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Title: Your LIVE [stream / audio room] starts in
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

                // Smooth Circular Progress Ring + Number / GO!
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    final progress = _isGo
                        ? 0.0
                        : (1.0 - _progressController.value).clamp(0.0, 1.0);

                    return SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(180, 180),
                            painter: _CircularProgressRingPainter(
                              progress: progress,
                              isCompleted: _isGo,
                              progressColor: const Color(0xFFFF5500),
                              trackColor: Colors.white.withValues(alpha: 0.15),
                              strokeWidth: 8,
                            ),
                          ),
                          ScaleTransition(
                            scale: _popAnimation,
                            child: Text(
                              _isGo ? 'GO!' : '$_currentNumber',
                              style: TextStyle(
                                color: const Color(0xFFFF5500),
                                fontSize: _isGo ? 56 : 90,
                                fontWeight: FontWeight.w900,
                                letterSpacing: _isGo ? 1.5 : -2,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const Spacer(flex: 3),

                // Moderation Warning Box (Red Card at Bottom)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
      ),
    );
  }
}

class _CircularProgressRingPainter extends CustomPainter {
  final double progress;
  final bool isCompleted;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _CircularProgressRingPainter({
    required this.progress,
    required this.isCompleted,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Draw subtle background track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw smooth decreasing progress arc (or completed ring at GO!)
    if (isCompleted) {
      // Completed ring around GO!
      final completedPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, completedPaint);
    } else if (progress > 0.001) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Start at 12 o'clock (-pi / 2) and sweep clockwise
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.progressColor != progressColor;
  }
}
