import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/model/star_store/effects_model.dart';
import 'package:geoedu/screen/my_effects_screen/my_effects_screen_controller.dart';

class MyEffectsScreen extends StatefulWidget {
  const MyEffectsScreen({super.key});

  @override
  State<MyEffectsScreen> createState() => _MyEffectsScreenState();
}

class _MyEffectsScreenState extends State<MyEffectsScreen> {
  final controller = Get.put(MyEffectsScreenController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !controller.isLoadingMore.value &&
        controller.hasMore) {
      controller.fetchEffects(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1015),
      body: Stack(
        children: [
          // Background Gradient matching reference (vibrant warm orange at top fading to deep charcoal)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 260,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFF5722),
                    Color(0xFFFF6D00),
                    Color(0xFF26181C),
                    Color(0xFF0F1015),
                  ],
                  stops: [0.0, 0.35, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // Decorative header atmospheric watermarks
          Positioned(
            top: 40,
            left: 55,
            child: Icon(
              Icons.star_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            top: 55,
            left: 140,
            child: Icon(
              Icons.auto_awesome,
              size: 14,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            top: 32,
            right: 40,
            child: Icon(
              Icons.favorite_rounded,
              size: 26,
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 68,
            right: 80,
            child: Icon(
              Icons.star_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.20),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Custom Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'My Effects',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Content Area
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7A00)),
                        ),
                      );
                    }

                    if (controller.effects.isEmpty) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B1822),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF3F3532).withValues(alpha: 0.7),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6D00), Color(0xFFFF3D00)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF5722).withValues(alpha: 0.3),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'No Entry Effects Yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Unlock stunning visual entrance animations to make your live streams unforgettable!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white60,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: const Color(0xFFFF7A00),
                      backgroundColor: const Color(0xFF1B1822),
                      onRefresh: () => controller.fetchEffects(),
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: controller.effects.length +
                            (controller.isLoadingMore.value ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == controller.effects.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7A00)),
                                ),
                              ),
                            );
                          }
                          return _EffectCard(effect: controller.effects[index]);
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EffectCard extends StatelessWidget {
  final EntryEffectModel effect;

  const _EffectCard({required this.effect});

  @override
  Widget build(BuildContext context) {
    final expired = effect.isExpired;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF19171E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF382F2C),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            // Subtle ambient warm wave & decorative watermark on bottom-right matching screenshot
            Positioned(
              right: -15,
              bottom: -20,
              width: 160,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.bottomRight,
                    radius: 0.9,
                    colors: [
                      const Color(0xFFFF5722).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Faint watermarks (crown / heart / stars)
            Positioned(
              right: 48,
              bottom: 12,
              child: Icon(
                Icons.favorite_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 10,
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 26,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              right: 12,
              top: 14,
              child: Icon(
                Icons.star_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Animated SVGA / Image Thumbnail
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF261D22), Color(0xFF131017)],
                      ),
                      border: Border.all(
                        color: const Color(0xFFFF8555).withValues(alpha: 0.55),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14.5),
                      child: _EffectThumbnail(effect: effect, size: 74),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Middle text information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          effect.title.isNotEmpty ? effect.title : 'Entry Effect',
                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 15,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              effect.durationHours != null
                                  ? '${effect.durationHours} hours'
                                  : (effect.duration.isNotEmpty
                                      ? effect.duration
                                      : '24 hours'),
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Right Status Badge Pill
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: expired
                              ? const Color(0xFFE55757).withValues(alpha: 0.12)
                              : const Color(0xFF4CAF50).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: expired
                                ? const Color(0xFFE55757).withValues(alpha: 0.85)
                                : const Color(0xFF4CAF50).withValues(alpha: 0.85),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          expired ? 'Expired' : 'Active',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: expired
                                ? const Color(0xFFF27272)
                                : const Color(0xFF81C784),
                          ),
                        ),
                      ),
                      if (!expired && effect.remainingTimeDisplay != 'Active') ...[
                        const SizedBox(height: 4),
                        Text(
                          effect.remainingTimeDisplay,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dynamic thumbnail player for Entry Effects.
/// Handles SVGA animations (both network and bundled fallback) as well as standard images.
class _EffectThumbnail extends StatefulWidget {
  final EntryEffectModel effect;
  final double size;

  const _EffectThumbnail({
    required this.effect,
    required this.size,
  });

  @override
  State<_EffectThumbnail> createState() => _EffectThumbnailState();
}

class _EffectThumbnailState extends State<_EffectThumbnail>
    with TickerProviderStateMixin {
  SVGAAnimationController? _svgaController;
  bool _isSvga = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisual();
  }

  @override
  void didUpdateWidget(covariant _EffectThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effect.image != widget.effect.image ||
        oldWidget.effect.id != widget.effect.id ||
        oldWidget.effect.entryEffectId != widget.effect.entryEffectId) {
      _cleanup();
      _loadVisual();
    }
  }

  void _cleanup() {
    _svgaController?.stop();
    _svgaController?.dispose();
    _svgaController = null;
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  Future<void> _loadVisual() async {
    final rawUrl = widget.effect.image.trim();
    final effId = widget.effect.entryEffectId ?? widget.effect.id;

    // Check if the effect is an SVGA animation
    final checkSvga = rawUrl.toLowerCase().contains('.svga') ||
        rawUrl.isEmpty ||
        (effId != null && effId >= 1 && effId <= 9);

    if (checkSvga) {
      _isSvga = true;
      _svgaController = SVGAAnimationController(vsync: this);

      try {
        dynamic videoItem;

        // 1. Try URL if valid http
        if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
          try {
            videoItem = await SVGAParser.shared.decodeFromURL(rawUrl);
          } catch (e) {
            Loggers.error('SVGA decodeFromURL error ($rawUrl): $e');
          }
        } else if (rawUrl.startsWith('assets/')) {
          try {
            videoItem = await SVGAParser.shared.decodeFromAssets(rawUrl);
          } catch (_) {}
        } else if (rawUrl.isNotEmpty) {
          final fullUrl = rawUrl.addBaseURL();
          if (fullUrl.startsWith('http')) {
            try {
              videoItem = await SVGAParser.shared.decodeFromURL(fullUrl);
            } catch (_) {}
          }
        }

        // 2. Fallback to bundled asset if network was unavailable
        if (videoItem == null) {
          int? localId = effId;
          if (localId == null && rawUrl.contains('animation-')) {
            final match = RegExp(r'animation-(\d+)').firstMatch(rawUrl);
            if (match != null) {
              localId = int.tryParse(match.group(1)!);
            }
          }
          if (localId != null && localId >= 1 && localId <= 9) {
            try {
              videoItem = await SVGAParser.shared
                  .decodeFromAssets('assets/images/animation-$localId.svga');
            } catch (_) {}
          }
        }

        // 3. Fallback to animation-1..9 based on ID hash
        if (videoItem == null) {
          final fallbackIdx = ((effId ?? 1) % 9 == 0) ? 9 : ((effId ?? 1) % 9);
          try {
            videoItem = await SVGAParser.shared
                .decodeFromAssets('assets/images/animation-$fallbackIdx.svga');
          } catch (_) {}
        }

        if (!mounted) return;

        if (videoItem != null) {
          videoItem.audios.clear(); // Mute in thumbnail list
          _svgaController!.videoItem = videoItem;
          _svgaController!.repeat();
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        Loggers.error('SVGA thumbnail load error: $e');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Standard raster image (PNG, JPG, WebP)
      _isSvga = false;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSvga && _svgaController != null && _svgaController!.videoItem != null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: SVGAImage(
          _svgaController!,
          fit: BoxFit.contain,
          clearsAfterStop: true,
          allowDrawingOverflow: false,
        ),
      );
    }

    final imageUrl = widget.effect.image.trim();
    if (!_isSvga && imageUrl.isNotEmpty) {
      final fullUrl = imageUrl.startsWith('http') ? imageUrl : imageUrl.addBaseURL();
      return CachedNetworkImage(
        imageUrl: fullUrl,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildPlaceholder(),
        errorWidget: (_, __, ___) => _buildFallback(),
      );
    }

    if (_isLoading) {
      return _buildPlaceholder();
    }

    return _buildFallback();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      color: const Color(0xFF1B171F),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7A00)),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF332028), Color(0xFF1B1522)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome,
          color: Color(0xFFFF9E80),
          size: 26,
        ),
      ),
    );
  }
}
