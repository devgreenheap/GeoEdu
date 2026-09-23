import 'package:flutter/material.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/recorded_video_player_screen.dart';
import 'package:geoedu/model/livestream/live_history_model.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:geoedu/utilities/color_res.dart';

/// Live Classrooms row: currently-live classes first (sourced from the
/// caller's [LiveStreamSearchScreenController.livestreamFilterList], the
/// same Firestore-backed list the category chips above already filter),
/// followed by recorded sessions for the same category — one unified list
/// rather than a separate "Recorded Sessions" section.
///
/// Takes the resolved lists + controller as plain parameters rather than
/// reading them via its own `Obx`/`Get.find` — the caller ([LiveStreamListView]
/// in live_stream_search_screen.dart) already wraps this in an `Obx` watching
/// the same sources, and a second nested `Obx` on an identical Rx source can
/// race with the outer one's rebuild and hit a disposed-element assertion.
class SampleLiveClassesWidget extends StatelessWidget {
  final List<Livestream> streams;
  final List<LiveHistory> recordedLives;
  final LiveStreamSearchScreenController controller;

  const SampleLiveClassesWidget({
    super.key,
    required this.streams,
    required this.recordedLives,
    required this.controller,
  });

  void _openRecording(BuildContext context, LiveHistory live) {
    final url = live.videoUrl;
    if (url == null || url.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecordedVideoPlayerScreen(videoUrl: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = streams.length + recordedLives.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalCount == 0)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text('No live classrooms right now',
                style: TextStyle(color: Color(0xFFB8B8B8), fontSize: 13)),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: totalCount,
              itemBuilder: (context, index) {
                final child = index < streams.length
                    ? SampleClassCard(
                        item: streams[index],
                        onTap: () => controller.onLiveUserTap(streams[index]),
                      )
                    : RecordedLiveCard(
                        live: recordedLives[index - streams.length],
                        onTap: () => _openRecording(context, recordedLives[index - streams.length]),
                      );
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(width: 150, child: child),
                );
              },
            ),
          ),
      ],
    );
  }
}

class SampleClassCard extends StatelessWidget {
  final Livestream item;
  final VoidCallback? onTap;

  const SampleClassCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (item.description != null && item.description!.trim().isNotEmpty)
        ? item.description!
        : (item.hostUser?.fullname ?? item.hostUser?.username ?? 'Live Class');
    final trainerName = item.hostUser?.fullname ?? item.hostUser?.username ?? '';
    final isVerified = item.hostUser?.isVerify == 1;
    final category = item.categoryName ?? '';
    final watching = item.watchingCount ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: ColorRes.cardBackground,
          border: Border.all(color: ColorRes.bgGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomImage(
                size: const Size(150, 220),
                radius: 0,
                fit: BoxFit.cover,
                image: item.hostUser?.profile?.addBaseURL(),
                fullName: title,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0, 0.4, 1],
                  ),
                ),
              ),
              // Top-left: LIVE badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                      color: ColorRes.liveRed, borderRadius: BorderRadius.circular(5)),
                  child: const Text('LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ),
              // Top-right: watching count
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 10),
                      const SizedBox(width: 3),
                      Text('$watching',
                          style: const TextStyle(color: Colors.white, fontSize: 9.5)),
                    ],
                  ),
                ),
              ),
              // Bottom-right: category / chat pill (Elo-style)
              if (category.isNotEmpty)
                Positioned(
                  bottom: 34,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: ColorRes.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_rounded, color: Colors.black, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              // Bottom: title + host name overlaid on the image
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            trainerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFDADADA), fontSize: 10.5),
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 3),
                          const Icon(Icons.verified_rounded, color: Color(0xFF4F7CF9), size: 11),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card for a recorded (VOD) session, styled to match [SampleClassCard] but
/// with a "RECORDED" tag + duration instead of "LIVE" + watching count, and
/// a play icon instead of a chat pill.
class RecordedLiveCard extends StatelessWidget {
  final LiveHistory live;
  final VoidCallback onTap;

  const RecordedLiveCard({super.key, required this.live, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hostName = live.hostFullname ?? live.hostUsername ?? 'Host';
    final isVerified = live.hostIsVerify == 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: ColorRes.cardBackground,
          border: Border.all(color: ColorRes.bgGrey),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomImage(
                size: const Size(150, 220),
                radius: 0,
                fit: BoxFit.cover,
                image: live.thumbnail ?? live.hostProfilePhoto,
                fullName: hostName,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0, 0.4, 1],
                  ),
                ),
              ),
              // Top-left: recorded tag
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_fill_rounded, color: ColorRes.primaryColor, size: 11),
                      SizedBox(width: 3),
                      Text('RECORDED',
                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              // Top-right: duration
              if ((live.duration ?? 0) > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(live.durationFormatted,
                        style: const TextStyle(color: Colors.white, fontSize: 9.5)),
                  ),
                ),
              // Center: play button
              const Center(
                child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40),
              ),
              // Bottom: host name
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        hostName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.verified_rounded, color: Color(0xFF4F7CF9), size: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
