import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/screen/effect_preview/effect_preview_screen.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/widgets/Effectstoggle.dart';
import 'package:get/get.dart';

import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';

import '../../../model/star_store/effects_model.dart';

class EffectsStoreScreen extends StatefulWidget {
  const EffectsStoreScreen({super.key});

  @override
  State<EffectsStoreScreen> createState() => _EffectsStoreScreenState();
}

class _EffectsStoreScreenState extends State<EffectsStoreScreen> {
  List<EntryEffectModel> entryEffects = [];
  List<EntryEffectModel> myEffects = [];
  bool isLoading = true;
  bool isMyEffectsLoading = false;
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    fetchEntryEffects();
  }

  Future<void> fetchEntryEffects() async {
    try {
      final result = await GiftWalletService.instance.fetchEntryEffects();
      setState(() {
        entryEffects = result;
        isLoading = false;
      });
    } catch (e) {
      Loggers.error('fetchEntryEffects error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchMyEntryEffects() async {
    setState(() => isMyEffectsLoading = true);
    try {
      final result = await GiftWalletService.instance.fetchMyEntryEffects();
      setState(() {
        myEffects = result;
        isMyEffectsLoading = false;
      });
    } catch (e) {
      Loggers.error('fetchMyEntryEffects error: $e');
      setState(() {
        isMyEffectsLoading = false;
      });
    }
  }

  Future<void> _buyEffect(EntryEffectModel effect) async {
    if (effect.id == null) return;
    try {
      final result = await GiftWalletService.instance.buyEntryEffect(
        entryEffectId: effect.id!,
        diamonds: effect.currentPrice,
      );
      if (result.status == true) {
        Get.snackbar(
          'Purchase Successful',
          'Entry effect purchased!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        fetchMyEntryEffects();
      } else {
        Get.snackbar(
          'Purchase Failed',
          result.message ?? 'Something went wrong',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Loggers.error('buyEntryEffect error: $e');
      Get.snackbar(
        'Error',
        'Failed to purchase effect',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      selectedTab = index;
    });
    if (index == 1 && myEffects.isEmpty) {
      fetchMyEntryEffects();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EffectsToggle(selectedIndex: selectedTab, onChanged: _onTabChanged),
        const SizedBox(height: 20),
        if (selectedTab == 0)
          _buildBuyEffects()
        else
          _buildMyEffects(),
      ],
    );
  }

  Widget _buildBuyEffects() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: ColorRes.gold),
        ),
      );
    }
    if (entryEffects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("No effects available", style: TextStyle(color: Colors.white70)),
        ),
      );
    }
    return _buildEffectsGrid(entryEffects, showBuyButton: true);
  }

  Widget _buildMyEffects() {
    if (isMyEffectsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: ColorRes.gold),
        ),
      );
    }
    if (myEffects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text("No purchased effects yet", style: TextStyle(color: Colors.white70)),
        ),
      );
    }
    return _buildEffectsGrid(myEffects, showBuyButton: false);
  }

  Widget _buildEffectsGrid(List<EntryEffectModel> effects, {required bool showBuyButton}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: effects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, index) {
        final entryEffect = effects[index];
        return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [ColorRes.gold, ColorRes.green],
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: [
                  ColorRes.cardBackground,
                  ColorRes.surfaceBackground,
                ]),
              ),
              child: Stack(
                children: [
                  if (showBuyButton && entryEffect.discountPercent > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: ColorRes.likeRed,
                        ),
                        child: Text(
                          "${entryEffect.discountPercent}% off",
                          style: const TextStyle(fontSize: 7, color: Colors.white),
                        ),
                      ),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: entryEffect.image.isNotEmpty
                              ? () => Navigator.of(context).push(
                                    PageRouteBuilder(
                                      opaque: false,
                                      barrierColor: Colors.black.withOpacity(.70),
                                      pageBuilder: (context, animation, secondaryAnimation) {
                                        return EffectPreviewScreen(
                                          effectName: entryEffect.title,
                                          assetUrl: entryEffect.image,
                                          audio: entryEffect.audio,
                                          isDefault: entryEffect.isDefaultAudio,
                                        );
                                      },
                                    ),
                                  )
                              : null,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(AssetRes.effectFlash, fit: BoxFit.contain),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.5),
                                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                                ),
                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (entryEffect.title.isNotEmpty)
                        Text(
                          entryEffect.title,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        spacing: 5,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(AssetRes.coinIcon, width: 20, height: 20),
                          Text("${entryEffect.currentPrice}",
                              style: const TextStyle(fontSize: 16, color: Colors.yellow)),
                          if (entryEffect.originalPrice > entryEffect.currentPrice)
                            Text("${entryEffect.originalPrice}",
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white54,
                                    decoration: TextDecoration.lineThrough)),
                        ],
                      ),
                      if (entryEffect.duration.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(entryEffect.duration,
                            style: const TextStyle(fontSize: 10, color: Colors.white)),
                      ],
                      const SizedBox(height: 10),
                      if (showBuyButton)
                        InkWell(
                          onTap: () => _buyEffect(entryEffect),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 25),
                            width: double.infinity,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(width: 1, color: ColorRes.whitePure),
                              borderRadius: BorderRadius.circular(18),
                              color: ColorRes.whitePure.withOpacity(.40),
                            ),
                            child: const Center(
                              child: Text("Buy >",
                                  style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
      },
    );
  }
}

class SvgaPreview extends StatefulWidget {
  final String assetPath;
  final bool isNetwork;

  const SvgaPreview({super.key, required this.assetPath, this.isNetwork = false});

  @override
  State<SvgaPreview> createState() => _SvgaPreviewState();
}

class _SvgaPreviewState extends State<SvgaPreview>
    with TickerProviderStateMixin {
  late SVGAAnimationController _controller;
  final SVGAParser _parser = SVGAParser.shared;

  @override
  void initState() {
    super.initState();
    _controller = SVGAAnimationController(vsync: this);
    _loadAnimation();
  }

  Future<void> _loadAnimation() async {
    try {
      final videoItem = widget.isNetwork
          ? await _parser.decodeFromURL(widget.assetPath)
          : await _parser.decodeFromAssets(widget.assetPath);

      if (!mounted) return;
      videoItem.audios.clear();

      _controller.videoItem = videoItem;
      _controller.repeat();
    } catch (e) {
      Loggers.error('SVGA load error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SVGAImage(
        _controller,
        fit: BoxFit.contain,
        clearsAfterStop: true,
        allowDrawingOverflow: false,
      ),
    );
  }
}
