import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/utilities/text_style_custom.dart';

/// Full-screen transition overlay matching Screenshot 2:
/// "Connecting to ((•)) LIVE Room" with avatar and stars when switching hosts
class ConnectingLiveRoomOverlay extends StatelessWidget {
  final AppUser? targetUser;

  const ConnectingLiveRoomOverlay({super.key, this.targetUser});

  @override
  Widget build(BuildContext context) {
    final name = targetUser?.fullname ?? targetUser?.username ?? 'Host';
    final profile = targetUser?.profile;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        color: Colors.black.withOpacity(0.65),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Connecting to ((•)) LIVE Room"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Connecting to ',
                  style: TextStyleCustom.outFitSemiBold600(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1744),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sensors, color: Colors.white, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        'LIVE',
                        style: TextStyleCustom.outFitBold700(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  ' Room',
                  style: TextStyleCustom.outFitSemiBold600(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Host avatar with glowing stars
            Stack(
              alignment: Alignment.center,
              children: [
                // Star glow container
                Container(
                  width: 106,
                  height: 106,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),

                // Avatar with gold border
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 2.8,
                    ),
                  ),
                  child: CustomImage(
                    size: const Size(96, 96),
                    radius: 48,
                    image: profile?.addBaseURL(),
                    fullName: name,
                  ),
                ),

                // Star accents around the circle
                const Positioned(
                  top: 2,
                  right: 8,
                  child: Text('✨', style: TextStyle(fontSize: 18)),
                ),
                const Positioned(
                  bottom: 4,
                  left: 6,
                  child: Text('⭐', style: TextStyle(fontSize: 14)),
                ),
                const Positioned(
                  bottom: -2,
                  child: Text('✨', style: TextStyle(fontSize: 16)),
                ),
                const Positioned(
                  top: 12,
                  left: 4,
                  child: Text('⭐', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Host Name
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyleCustom.outFitBold700(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
