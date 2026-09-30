import 'package:flutter/material.dart';
import 'package:geoedu/common/widget/custom_image.dart';

/// Circular avatar + sunset gradient ring + "LIVE" pill badge + cyan status dot
/// + viewer count (e.g. 3.2K) for the Home page's "Popular Hosts" row.
class PopularHostAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final int count;
  final VoidCallback? onTap;

  const PopularHostAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.count = 0,
    this.onTap,
  });

  String _formatCount(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final countText = count > 0 ? _formatCount(count) : '';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            // Circular Avatar with Gradient Ring & Badges
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Gradient Ring Border
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Color(0xFFFF2A6D),
                          Color(0xFFFF7A00),
                          Color(0xFFFFB800),
                          Color(0xFF8B5CF6),
                          Color(0xFFFF2A6D),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0C0C0C),
                      ),
                      padding: const EdgeInsets.all(1.5),
                      child: ClipOval(
                        child: CustomImage(
                          size: const Size(60, 60),
                          image: photoUrl,
                          fullName: name,
                          radius: 30,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // LIVE Pill Badge at Bottom Center
                  Positioned(
                    bottom: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF5E62),
                            Color(0xFFFF2A6D),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2A6D)
                                .withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),

                  // Cyan Status Dot at bottom right
                  Positioned(
                    right: 4,
                    bottom: 2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0C0C0C),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF)
                                .withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Host Name
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),

            if (countText.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                countText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
