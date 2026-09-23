import 'package:flutter/material.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/utilities/color_res.dart';

/// Circular avatar + red ring + "LIVE" badge for the Home page's
/// "Popular Hosts" row. Built on the existing [CustomImage] (same
/// avatar/initials-fallback widget used everywhere else in the app) rather
/// than a new image widget.
class PopularHostAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final VoidCallback? onTap;

  const PopularHostAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                CustomImage(
                  size: const Size(56, 56),
                  image: photoUrl,
                  fullName: name,
                  radius: 28,
                  strokeWidth: 2,
                  strokeColor: ColorRes.liveRed,
                ),
                Positioned(
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: ColorRes.liveRed, borderRadius: BorderRadius.circular(6)),
                    child: const Text('LIVE',
                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
