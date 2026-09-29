import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import '../../../../model/livestream/entry_effects_model.dart';
import '../../../effect_preview/widgets/animation_widget.dart';
import '../livestream_screen_controller.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/common/manager/gift_audio_player.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
 
class EntryEffectLayer extends StatefulWidget {
  final LivestreamScreenController controller;

  const EntryEffectLayer({super.key, required this.controller});

  @override
  State<EntryEffectLayer> createState() => _EntryEffectLayerState();
}

class _EntryEffectLayerState extends State<EntryEffectLayer>
    with TickerProviderStateMixin {
  final Map<int, SVGAAnimationController> _controllers = {};

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEffect(EntryEffect effect) async {
    if (_controllers.containsKey(effect.id)) return;

    final controller = SVGAAnimationController(vsync: this);

    final isNetwork = effect.assetUrl.startsWith('http');
    final videoItem = isNetwork
        ? await SVGAParser.shared.decodeFromURL(effect.assetUrl)
        : await SVGAParser.shared.decodeFromAssets(effect.assetUrl);

    controller.videoItem = videoItem;

    /// ⭐ Create local player for each effect
    AudioPlayer? player;

    if (effect.audio.isNotEmpty && LivestreamScreenController.isGiftSoundOn.value) {
      try {
        player = AudioPlayer();
        if (effect.audio.startsWith('http')) {
          await player.setUrl(effect.audio);
        } else {
          await player.setAsset(effect.audio);
        }
        player.play();
      } catch (e) {
        // A broken/unsupported audio source shouldn't stop the entry
        // animation itself from playing.
        player?.dispose();
        player = null;
      }
    }

    controller.forward();

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.controller.entryEffects.remove(effect);

        controller.dispose();
        _controllers.remove(effect.id);

        player?.dispose();
      }
    });

    _controllers[effect.id] = controller;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final effects = widget.controller.entryEffects;

      return Stack(
        children: effects.map((effect) {
          Future.microtask(() => _loadEffect(effect));

          final svgaController = _controllers[effect.id];

          if (svgaController == null) return const SizedBox();

          return Positioned.fill(
            child: Stack(
              children: [
                Container(color: Colors.black.withValues(alpha: 0.1)),

                /// LEFT GLOW
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF320026).withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                /// RIGHT GLOW
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF320026).withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ),
                SlideFadeRight(
                  top: 150,
                  right: 0,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2d0927), Color(0xFF320026)],
                          ),
                          border: Border.all(
                            width: 1,
                            color: const Color(0xFFf6c041),
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            bottomLeft: Radius.circular(30),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 1,
                                  color: const Color(0xFFf6c041),
                                ),
                                image: const DecorationImage(
                                  image: AssetImage(
                                    "assets/images/profile-4.jpg",
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "You",
                                  style: TextStyle(
                                    color: Color(0xFFf8c717),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    text: "Entered with ",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: effect.username,
                                        style: const TextStyle(
                                          color: Color(0xFFf8c717),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        "Effect: ${effect.effectName}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                /// SVGA CENTER
                Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Center(
                    child: SVGAImage(svgaController),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}

class GiftEffectWidget extends StatefulWidget {
  final RxList<GiftEffect> activeGifts;
  final double width;
  final double height;

  const GiftEffectWidget({
    super.key,
    this.width = 200,
    this.height = 200,
    required this.activeGifts,
  });

  @override
  State<GiftEffectWidget> createState() => _GiftEffectWidgetState();
}

class _GiftEffectWidgetState extends State<GiftEffectWidget>
    with TickerProviderStateMixin {
  final Map<int, SVGAAnimationController> _svgaControllers = {};
  int _lastPlayedGiftTimestamp = 0;

  @override
  void dispose() {
    for (final c in _svgaControllers.values) {
      c.dispose();
    }
    GiftAudioPlayer.stop();
    super.dispose();
  }

  /// Plays the gift's sound with 0ms delay via GiftAudioPlayer
  Future<void> _playAudioIfNeeded(GiftEffect gift) async {
    if (_lastPlayedGiftTimestamp == gift.timestamp) return;
    _lastPlayedGiftTimestamp = gift.timestamp;
    if (gift.audio == null || gift.audio!.trim().isEmpty) return;
    await GiftAudioPlayer.play(gift.audio);
  }

  Future<void> _loadSvga(GiftEffect gift) async {
    if (_svgaControllers.containsKey(gift.timestamp)) return;

    final controller = SVGAAnimationController(vsync: this);
    try {
      final raw = gift.assetUrl.trim();
      final url = (raw.isNotEmpty &&
              !raw.startsWith('http://') &&
              !raw.startsWith('https://') &&
              !raw.startsWith('assets/'))
          ? raw.addBaseURL()
          : raw;
      final isNetwork = url.startsWith('http');
      final videoItem = isNetwork
          ? await SVGAParser.shared.decodeFromURL(url)
          : await SVGAParser.shared.decodeFromAssets(url);
      videoItem.audios.clear();
      controller.videoItem = videoItem;
      controller.reset();

      // Cut sound and dismiss gift immediately when SVGA finishes its single run
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          GiftAudioPlayer.stop();
          widget.activeGifts.remove(gift);
          controller.dispose();
          _svgaControllers.remove(gift.timestamp);
        }
      });

      // Play ONLY ONCE (never repeat!)
      controller.forward();
    } catch (_) {
      // A broken/unsupported SVGA source shouldn't crash the gift
      // animation layer — just skip showing this one.
      controller.dispose();
      widget.activeGifts.remove(gift);
      return;
    }

    if (!mounted) {
      controller.dispose();
      return;
    }
    _svgaControllers[gift.timestamp] = controller;
    setState(() {});
  }

  Widget _buildGiftVisual(GiftEffect gift) {
    final rawUrl = gift.assetUrl.trim();
    final String url = (rawUrl.isNotEmpty &&
            !rawUrl.startsWith('http://') &&
            !rawUrl.startsWith('https://') &&
            !rawUrl.startsWith('assets/'))
        ? rawUrl.addBaseURL()
        : rawUrl;

    final rawThumb = (gift.thumbnailUrl?.trim() ?? '');
    final String resolvedThumb = (rawThumb.isNotEmpty &&
            !rawThumb.startsWith('http://') &&
            !rawThumb.startsWith('https://') &&
            !rawThumb.startsWith('assets/'))
        ? rawThumb.addBaseURL()
        : rawThumb;

    // If animation url was missing or empty, use the actual uploaded gift image/thumbnail
    final effectiveDisplayUrl = url.isNotEmpty ? url : resolvedThumb;

    if (gift.isSvga) {
      Future.microtask(() => _loadSvga(gift));
      final controller = _svgaControllers[gift.timestamp];
      if (controller != null) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: SVGAImage(controller),
        );
      }
      // While SVGA controller is decoding, display thumbnail so screen is never blank
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: _GiftVisualWithMotion(
          child: resolvedThumb.isNotEmpty
              ? CustomImage(
                  image: resolvedThumb,
                  size: Size(widget.width, widget.height),
                  fit: BoxFit.contain,
                )
              : Image.asset('assets/images/gifts.png', fit: BoxFit.contain),
        ),
      );
    }
    if (effectiveDisplayUrl.isEmpty) return const SizedBox.shrink();

    final isSvg = effectiveDisplayUrl.toLowerCase().contains('.svg');

    if (isSvg) {
      return SizedBox(
        width: widget.width * 1.5,
        height: widget.height * 1.5,
        child: AnimatedSvgPlayer(
          url: effectiveDisplayUrl,
          giftName: gift.giftName,
          thumbnailUrl: resolvedThumb.isNotEmpty ? resolvedThumb : null,
          width: widget.width * 1.5,
          height: widget.height * 1.5,
          onAnimationEnd: () {
            // Cut sound and dismiss gift immediately when SVG animation ends
            GiftAudioPlayer.stop();
            widget.activeGifts.remove(gift);
          },
        ),
      );
    }

    // Static image / GIF / WebP: dismiss and cut audio after 2.8s
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted && widget.activeGifts.contains(gift)) {
        GiftAudioPlayer.stop();
        widget.activeGifts.remove(gift);
      }
    });

    final imgWidget = CustomImage(
      image: effectiveDisplayUrl,
      size: Size(widget.width, widget.height),
      fit: BoxFit.contain,
      placeHolderImage: resolvedThumb.isNotEmpty ? resolvedThumb : null,
    );

    return _GiftVisualWithMotion(child: imgWidget);
  }

  void _pruneExpiredControllers(Iterable<int> activeTimestamps) {
    final activeSet = activeTimestamps.toSet();
    final expiredKeys =
        _svgaControllers.keys.where((k) => !activeSet.contains(k)).toList();
    for (final key in expiredKeys) {
      _svgaControllers.remove(key)?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _pruneExpiredControllers(widget.activeGifts.map((g) => g.timestamp));
      if (widget.activeGifts.isEmpty) {
        GiftAudioPlayer.stop();
        return const SizedBox.shrink();
      }
      return IgnorePointer(
        ignoring: true,
        child: Stack(
          children: widget.activeGifts.map((gift) {
            Future.microtask(() => _playAudioIfNeeded(gift));
            final myUserId = SessionManager.instance.getUserID();
            final myUsername = (SessionManager.instance.getUser()?.username ?? '').toLowerCase().trim();
            final isMe = (gift.userId > 0 && gift.userId == myUserId) ||
                (myUsername.isNotEmpty && gift.username.toLowerCase().trim() == myUsername);
            final senderDisplayName = isMe ? 'You' : gift.username;
            return Positioned.fill(
              child: Stack(
                children: [
                  SlideFadeRight(
                    top: 150,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2d0927), Color(0xFF320026)],
                            ),
                            border: Border.all(
                              width: 1,
                              color: const Color(0xFFf6c041),
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              bottomLeft: Radius.circular(30),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    width: 1,
                                    color: const Color(0xFFf6c041),
                                  ),
                                ),
                                child: CustomImage(
                                  size: const Size(40, 40),
                                  image: gift.senderPhoto?.addBaseURL(),
                                  radius: 20,
                                  fullName: gift.username,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      text: "$senderDisplayName sent a ",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: gift.giftName,
                                          style: const TextStyle(
                                            color: Color(0xFFf8c717),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: _buildGiftVisual(gift),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

class _GiftVisualWithMotion extends StatefulWidget {
  final Widget child;

  const _GiftVisualWithMotion({required this.child});

  @override
  State<_GiftVisualWithMotion> createState() => _GiftVisualWithMotionState();
}

class _GiftVisualWithMotionState extends State<_GiftVisualWithMotion>
  with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
    ]).animate(_animController);

    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );

    _tiltAnimation = Tween<double>(begin: -0.06, end: 0.06).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.rotate(
            angle: _tiltAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class AnimatedSvgPlayer extends StatefulWidget {
  final String url;
  final double width;
  final double height;
  final String? giftName;
  final String? thumbnailUrl;

  final VoidCallback? onAnimationEnd;

  const AnimatedSvgPlayer({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.giftName,
    this.thumbnailUrl,
    this.onAnimationEnd,
  });

  static final Map<String, String> _svgCache = {};

  /// Preload Pen Animation.svg from local assets into memory so it's ready with 0ms latency
  static Future<void> initCache() async {
    try {
      final penSvg =
          await rootBundle.loadString('assets/svg_icons/Pen Animation.svg');
      if (penSvg.contains('<svg')) {
        _svgCache['assets/svg_icons/Pen Animation.svg'] = penSvg;
        _svgCache['uploads/pen_animation.svg'] = penSvg;
        _svgCache['uploads/pen_gift.svg'] = penSvg;
        _svgCache['pen'] = penSvg;
      }
    } catch (_) {}
  }

  static Future<void> preloadAll(List<Gift> gifts) async {
    await initCache();
    for (final gift in gifts) {
      final url = gift.effectiveAssetUrl;
      if (url.toLowerCase().contains('pen')) continue;
      if (url.toLowerCase().contains('.svg')) {
        preloadSvg(url.addBaseURL());
        preloadSvg(url);
      }
    }
  }

  static Future<void> preloadSvg(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final svgUrl = url.trim();
    if (_svgCache.containsKey(svgUrl)) return;
    if (svgUrl.toLowerCase().contains('pen')) {
      await initCache();
      return;
    }
    try {
      if (svgUrl.startsWith('http://') || svgUrl.startsWith('https://')) {
        final response = await http
            .get(Uri.parse(svgUrl))
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200 && response.body.contains('<svg')) {
          _svgCache[svgUrl] = response.body;
        }
      } else if (svgUrl.startsWith('assets/')) {
        final assetData = await rootBundle.loadString(svgUrl);
        if (assetData.contains('<svg')) {
          _svgCache[svgUrl] = assetData;
        }
      }
    } catch (_) {}
  }

  @override
  State<AnimatedSvgPlayer> createState() => _AnimatedSvgPlayerState();
}

class _AnimatedSvgPlayerState extends State<AnimatedSvgPlayer> {
  WebViewControllerPlus? _controller;
  bool _isReady = false;
  Timer? _fallbackTimer;
  bool _hasEnded = false;

  void _notifyEnd() {
    if (_hasEnded) return;
    _hasEnded = true;
    _fallbackTimer?.cancel();
    if (mounted) {
      widget.onAnimationEnd?.call();
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final isPen = (widget.giftName?.toLowerCase().contains('pen') ?? false) ||
          widget.url.toLowerCase().contains('pen');

      String? svgContent = AnimatedSvgPlayer._svgCache[widget.url] ??
          AnimatedSvgPlayer._svgCache[
              widget.url.replaceAll(RegExp(r'^https?://[^/]+/'), '')];

      if (svgContent == null && isPen) {
        if (!AnimatedSvgPlayer._svgCache.containsKey('pen')) {
          await AnimatedSvgPlayer.initCache();
        }
        svgContent = AnimatedSvgPlayer._svgCache['pen'] ??
            AnimatedSvgPlayer._svgCache['assets/svg_icons/Pen Animation.svg'];
      }

      if (svgContent == null || svgContent.isEmpty) {
        if (widget.url.startsWith('http://') ||
            widget.url.startsWith('https://')) {
          final response = await http
              .get(Uri.parse(widget.url))
              .timeout(const Duration(seconds: 4));
          if (response.statusCode == 200 && response.body.contains('<svg')) {
            svgContent = response.body;
            AnimatedSvgPlayer._svgCache[widget.url] = svgContent;
          }
        } else if (widget.url.startsWith('assets/')) {
          final assetData = await rootBundle.loadString(widget.url);
          if (assetData.contains('<svg')) {
            svgContent = assetData;
            AnimatedSvgPlayer._svgCache[widget.url] = svgContent;
          }
        } else if (widget.url.trim().startsWith('<svg')) {
          svgContent = widget.url;
        }
      }

      if (svgContent == null || svgContent.isEmpty) {
        return;
      }

      final controller = WebViewControllerPlus();
      try {
        controller.setBackgroundColor(Colors.transparent);
      } catch (_) {}
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      controller.addJavaScriptChannel(
        'SvgEndChannel',
        onMessageReceived: (message) {
          _notifyEnd();
        },
      );

      final html = _buildSvgHtml(svgContent);
      await controller.loadHtmlString(html);

      // Fallback timer: ensure animation end is notified even if SVG has no end events (e.g. 3.2s)
      _fallbackTimer?.cancel();
      _fallbackTimer = Timer(const Duration(milliseconds: 3200), _notifyEnd);

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isReady = true;
      });
    } catch (e) {
      Loggers.error('AnimatedSvgPlayer init error: $e');
    }
  }

  Widget _buildNativeVisual() {
    final isPen = (widget.giftName?.toLowerCase().contains('pen') ?? false) ||
        widget.url.toLowerCase().contains('pen');

    Widget imageChild;
    if (isPen) {
      // Instant high-res pen visual loaded from local asset (0ms latency!)
      imageChild = Image.asset(
        'assets/images/pen_gift.png',
        width: widget.width,
        height: widget.height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/svg_icons/pen_frame_0.png',
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/gifts.png',
            width: widget.width,
            height: widget.height,
            fit: BoxFit.contain,
          ),
        ),
      );
    } else if (widget.thumbnailUrl != null && widget.thumbnailUrl!.trim().isNotEmpty) {
      imageChild = CustomImage(
        image: widget.thumbnailUrl!,
        size: Size(widget.width, widget.height),
        fit: BoxFit.contain,
      );
    } else {
      imageChild = Image.asset(
        'assets/images/gifts.png',
        width: widget.width,
        height: widget.height,
        fit: BoxFit.contain,
      );
    }

    return _GiftVisualWithMotion(child: imageChild);
  }

  String _buildSvgHtml(String svgXml) {
    return '''<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    *, *::before, *::after {
      margin: 0 !important;
      padding: 0 !important;
      border: 0 none !important;
      border-width: 0 !important;
      outline: 0 none !important;
      box-shadow: none !important;
      box-sizing: border-box !important;
      -webkit-tap-highlight-color: transparent !important;
    }
    html, body {
      width: 100vw !important;
      height: 100vh !important;
      margin: 0 !important;
      padding: 0 !important;
      border: 0 none !important;
      outline: 0 none !important;
      box-shadow: none !important;
      background: transparent !important;
      background-color: transparent !important;
      overflow: hidden !important;
      display: flex !important;
      align-items: center !important;
      justify-content: center !important;
      -webkit-user-select: none !important;
      user-select: none !important;
    }
    *, *::before, *::after, svg, svg * {
      animation-iteration-count: 1 !important;
      -webkit-animation-iteration-count: 1 !important;
    }
    svg {
      width: 100% !important;
      height: 100% !important;
      max-width: 100% !important;
      max-height: 100% !important;
      border: 0 none !important;
      outline: 0 none !important;
      box-shadow: none !important;
      display: block !important;
      object-fit: contain !important;
    }
  </style>
</head>
<body style="background:transparent; background-color:transparent; margin:0; padding:0; border:0; outline:0;">
  $svgXml
  <script>
    (function() {
      // Force SMIL elements to play only once
      var anims = document.querySelectorAll('animate, animateTransform, animateMotion, animateColor');
      anims.forEach(function(el) {
        el.setAttribute('repeatCount', '1');
      });

      var posted = false;
      function notifyFlutter() {
        if (posted) return;
        posted = true;
        if (window.SvgEndChannel) {
          window.SvgEndChannel.postMessage('completed');
        }
      }

      // Listen for CSS animation end
      document.addEventListener('animationend', notifyFlutter);
      document.addEventListener('webkitAnimationEnd', notifyFlutter);

      // Listen for SVG SMIL animation end
      anims.forEach(function(el) {
        el.addEventListener('endEvent', notifyFlutter);
      });

      // Calculate duration from CSS
      var maxDur = 2500;
      try {
        var allEls = document.querySelectorAll('*');
        allEls.forEach(function(el) {
          var dur = parseFloat(window.getComputedStyle(el).animationDuration) || 0;
          var delay = parseFloat(window.getComputedStyle(el).animationDelay) || 0;
          if (dur + delay > 0) {
            maxDur = Math.max(maxDur, (dur + delay) * 1000 + 200);
          }
        });
      } catch(e) {}
      setTimeout(notifyFlutter, Math.min(Math.max(maxDur, 1500), 3800));
    })();
  </script>
</body>
</html>''';
  }


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: (_isReady && _controller != null)
            ? IgnorePointer(
                ignoring: true,
                child: ClipRect(
                  child: WebViewWidget(controller: _controller!),
                ),
              )
            : _buildNativeVisual(),
      ),
    );
  }
}
