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
      final isNetwork = gift.assetUrl.startsWith('http');
      final videoItem = isNetwork
          ? await SVGAParser.shared.decodeFromURL(gift.assetUrl)
          : await SVGAParser.shared.decodeFromAssets(gift.assetUrl);
      videoItem.audios.clear();
      controller.videoItem = videoItem;
      controller.reset();
      controller.repeat();
    } catch (_) {
      // A broken/unsupported SVGA source shouldn't crash the gift
      // animation layer — just skip showing this one.
      controller.dispose();
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
    if (gift.isSvga) {
      Future.microtask(() => _loadSvga(gift));
      final controller = _svgaControllers[gift.timestamp];
      if (controller == null) return SizedBox(width: widget.width, height: widget.height);
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: SVGAImage(controller),
      );
    }
    if (gift.assetUrl.isEmpty) return const SizedBox.shrink();

    final isSvg = gift.assetUrl.toLowerCase().contains('.svg');
    final isNetwork = gift.assetUrl.startsWith('http://') || gift.assetUrl.startsWith('https://');

    if (isSvg) {
      return SizedBox(
        width: widget.width * 1.5,
        height: widget.height * 1.5,
        child: AnimatedSvgPlayer(
          url: gift.assetUrl,
          width: widget.width * 1.5,
          height: widget.height * 1.5,
        ),
      );
    }

    final imgWidget = isNetwork
        ? Image.network(gift.assetUrl, width: widget.width, height: widget.height, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset('assets/images/gifts.png', width: widget.width, height: widget.height))
        : Image.asset(gift.assetUrl, width: widget.width, height: widget.height, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset('assets/images/gifts.png', width: widget.width, height: widget.height));

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
      if (widget.activeGifts.isEmpty) return const SizedBox.shrink();
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

  const AnimatedSvgPlayer({
    super.key,
    required this.url,
    required this.width,
    required this.height,
  });

  static Future<void> preloadAll(List<Gift> gifts) async {
    for (final gift in gifts) {
      final url = gift.effectiveAssetUrl;
      if (url.toLowerCase().contains('.svg')) {
        preloadSvg(url.addBaseURL());
      }
    }
  }

  static Future<void> preloadSvg(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final svgUrl = url.trim();
    if (_AnimatedSvgPlayerState._svgCache.containsKey(svgUrl)) return;
    try {
      if (svgUrl.startsWith('http://') || svgUrl.startsWith('https://')) {
        final response = await http
            .get(Uri.parse(svgUrl))
            .timeout(const Duration(seconds: 6));
        if (response.statusCode == 200 && response.body.contains('<svg')) {
          _AnimatedSvgPlayerState._svgCache[svgUrl] = response.body;
        }
      } else if (svgUrl.startsWith('assets/')) {
        final assetData = await rootBundle.loadString(svgUrl);
        if (assetData.contains('<svg')) {
          _AnimatedSvgPlayerState._svgCache[svgUrl] = assetData;
        }
      }
    } catch (_) {}
  }

  @override
  State<AnimatedSvgPlayer> createState() => _AnimatedSvgPlayerState();
}

class _AnimatedSvgPlayerState extends State<AnimatedSvgPlayer> {
  static final Map<String, String> _svgCache = {};
  WebViewControllerPlus? _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final controller = WebViewControllerPlus();
    try {
      controller.setBackgroundColor(Colors.transparent);
    } catch (_) {}
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    String? svgContent = _svgCache[widget.url];

    if (svgContent == null || svgContent.isEmpty) {
      try {
        if (widget.url.startsWith('http://') || widget.url.startsWith('https://')) {
          final response = await http
              .get(Uri.parse(widget.url))
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == 200 && response.body.contains('<svg')) {
            svgContent = response.body;
            _svgCache[widget.url] = svgContent;
          }
        } else if (widget.url.startsWith('assets/')) {
          final assetData = await rootBundle.loadString(widget.url);
          if (assetData.contains('<svg')) {
            svgContent = assetData;
            _svgCache[widget.url] = svgContent;
          }
        } else if (widget.url.trim().startsWith('<svg')) {
          svgContent = widget.url;
        }
      } catch (e) {
        Loggers.error('AnimatedSvgPlayer fetch error: $e');
      }
    }

    String html;
    if (svgContent != null && svgContent.isNotEmpty) {
      html = _buildSvgHtml(svgContent);
    } else {
      html = _buildImgHtml(widget.url);
    }

    await controller.loadHtmlString(html);
    if (!mounted) return;
    setState(() {
      _controller = controller;
      _isReady = true;
    });
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
</body>
</html>''';
  }

  String _buildImgHtml(String url) {
    return '''<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    *, *::before, *::after {
      margin: 0 !important;
      padding: 0 !important;
      border: 0 none !important;
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
    }
    img {
      width: 100% !important;
      height: 100% !important;
      border: 0 none !important;
      outline: 0 none !important;
      object-fit: contain !important;
    }
  </style>
</head>
<body style="background:transparent; background-color:transparent; margin:0; padding:0; border:0; outline:0;">
  <img src="$url" />
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _controller == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: IgnorePointer(
        ignoring: true,
        child: ClipRect(
          child: WebViewWidget(controller: _controller!),
        ),
      ),
    );
  }
}
