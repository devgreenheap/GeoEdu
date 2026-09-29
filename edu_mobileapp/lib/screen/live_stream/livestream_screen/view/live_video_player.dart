import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/utilities/color_res.dart';

class LivestreamVideoPlayer extends StatelessWidget {
  final Rx<VideoPlayerController?> controller;
  final Livestream? livestream;

  const LivestreamVideoPlayer({
    super.key,
    required this.controller,
    this.livestream,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final VideoPlayerController? player = controller.value;
      final bool isReady = player != null &&
          player.value.isInitialized &&
          player.value.size.width > 0 &&
          player.value.size.height > 0;

      if (isReady) {
        final double width = player.value.size.width;
        final double height = player.value.size.height;
        return ClipRRect(
          child: SizedBox.expand(
            child: FittedBox(
              fit: width < height ? BoxFit.cover : BoxFit.fitWidth,
              child: SizedBox(
                width: width,
                height: height,
                child: VideoPlayer(player),
              ),
            ),
          ),
        );
      }

      // Elegant host cover fallback while loading or if video stream is connecting
      final host = livestream?.hostUser;
      final photo = host?.profile ?? livestream?.thumbnailUrl;
      final name = host?.fullname ?? host?.username ?? livestream?.description ?? 'Live Host';

      return Container(
        color: const Color(0xFF0C0A1A),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo != null && photo.isNotEmpty)
              Opacity(
                opacity: 0.35,
                child: CustomImage(
                  image: photo.addBaseURL(),
                  size: Size.infinite,
                  radius: 0,
                  fit: BoxFit.cover,
                ),
              ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ColorRes.primaryColor, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66FF3366),
                          blurRadius: 24,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: CustomImage(
                      size: const Size(90, 90),
                      image: photo?.addBaseURL(),
                      fullName: name,
                      radius: 45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFF3366).withValues(alpha: 0.6)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF3366),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Connecting Live...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
