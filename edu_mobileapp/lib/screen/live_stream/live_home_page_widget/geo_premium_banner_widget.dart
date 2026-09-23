import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/star_store_diamond _screen.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';

/// Promotes the existing Diamond Store feature — tapping goes straight into
/// [StarStoreDiamondScreen], the same real purchase flow used everywhere
/// else. Only the copy/visuals here are new; no purchase logic changes.
class GeoPremiumBannerWidget extends StatelessWidget {
  const GeoPremiumBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () => Get.to(() => const StarStoreDiamondScreen()),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFB8202E), ColorRes.primaryColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorRes.primaryColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const _SparkleDots(),
              Row(
                children: [
                  Image.asset(AssetRes.starstoreDiamond, height: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Support Your Favorite Educator',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Gift During Live Classes',
                          style: TextStyle(
                            color: Color(0xFFFFE1B8),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'Buy Diamonds',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparkleDots extends StatelessWidget {
  const _SparkleDots();

  static const _dots = [
    Offset(0.15, 0.15),
    Offset(0.35, 0.75),
    Offset(0.55, 0.2),
    Offset(0.75, 0.65),
    Offset(0.9, 0.3),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          children: _dots
              .map((d) => Positioned(
                    left: constraints.maxWidth * d.dx,
                    top: constraints.maxHeight * d.dy,
                    child: Icon(Icons.star, color: Colors.white.withValues(alpha: 0.35), size: 8),
                  ))
              .toList(),
        );
      }),
    );
  }
}
