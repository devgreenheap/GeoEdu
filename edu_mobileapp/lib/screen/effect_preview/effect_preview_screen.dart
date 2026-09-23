import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:geoedu/screen/effect_preview/widgets/animation_widget.dart';
import 'package:just_audio/just_audio.dart';

import '../audio/widget/buy_effects_screen.dart';

class EffectPreviewScreen extends StatefulWidget {
  final String effectName;
  final String assetUrl;
  final String audio;
  final bool? isDefault;
  const EffectPreviewScreen({
    super.key,
    required this.effectName,
    required this.assetUrl,
    this.audio = '',
    this.isDefault = false,
  });

  @override
  State<EffectPreviewScreen> createState() => _EffectPreviewScreenState();
}

class _EffectPreviewScreenState extends State<EffectPreviewScreen> with TickerProviderStateMixin{
  bool _showReplay = false;
  late SVGAAnimationController _controller;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    if(widget.audio != '' && widget.isDefault != true) {
        playSound(widget.audio);
      }
    _controller = SVGAAnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _player.stop();
        if (mounted) {
          setState(() => _showReplay = true);
        }
      }
    });

    _loadSVGA();
  }

  Future<void> playSound(String soundUrl) async {
    try {
      if (soundUrl.startsWith('http')) {
        await _player.setUrl(soundUrl);
      } else {
        await _player.setAsset(soundUrl);
      }
      await _player.play();
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  Future<void> _loadSVGA() async {
    try {
      final isNetwork = widget.assetUrl.startsWith('http');
      final videoItem = isNetwork
          ? await SVGAParser.shared.decodeFromURL(widget.assetUrl)
          : await SVGAParser.shared.decodeFromAssets(widget.assetUrl);
      if (!mounted) return;
      if (widget.isDefault != true) {
        videoItem.audios.clear();
      }
      _controller.videoItem = videoItem;
      _controller.forward();
    } catch (e) {
      debugPrint('SVGA load error: $e');
    }
  }

  void _replayEffect() {
    setState(() => _showReplay = false);

    if (_controller.isAnimating) {
      _controller.stop();
    }

    if (widget.audio.isNotEmpty && widget.isDefault != true) {
      playSound(widget.audio);
    }

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _player.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(color: Colors.black.withOpacity(0.1)),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 140,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF320026).withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          /// RIGHT COLOR SPREAD
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 140,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    const Color(0xFF320026).withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// ✨ SVGA CARD
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height / 1.5,
                      width: MediaQuery.of(context).size.width,
                      child: SVGAImage(_controller),
                    ),
                  ),
                ),

                /// 🔁 Premium Replay Button
                if (_showReplay)
                  AnimatedScale(
                    scale: _showReplay ? 1 : 0.7,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _replayEffect,
                        borderRadius: BorderRadius.circular(40),
                        child: Ink(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF4D6D),
                                Color(0xFF7B2FF7),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF4D6D).withOpacity(0.6),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.replay_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),


          // Center(
          //   child: ClipRRect(
          //     borderRadius: BorderRadius.circular(16),
          //     child: SizedBox(
          //       height: MediaQuery.of(context).size.height/1.5,
          //       width: MediaQuery.of(context).size.width,
          //       child: SVGAImage(_controller),
          //     ),
          //   ),
          // ),

          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Text(
              "${widget.effectName} - Preview",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SlideFadeRight(
            top: 150,
            right: 0,
            child: Container(
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
                              text: widget.effectName,
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
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 36,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border:
                        Border.all(width: 2, color: Colors.white),
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: (){
                      showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      barrierColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BuyCoinsBottomSheet(image: widget.assetUrl,),
                      );
                      },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 36,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFffc420),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          width: 2,
                          color: const Color(0xFFffc420),
                        ),
                      ),
                      child: const Text(
                        "Buy",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
