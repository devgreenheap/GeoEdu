import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/audio_call/audio_room.dart';
import 'package:geoedu/screen/audio_call/audio_call_list_controller.dart';
import 'package:geoedu/screen/live_stream/live_home_page_widget/all_audio_rooms_screen.dart';
import 'package:geoedu/utilities/color_res.dart';

class LiveAudioRoomsWidget extends StatelessWidget {
  const LiveAudioRoomsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AudioCallListController>();

    return Obx(() {
      final rooms = controller.audioRooms;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.graphic_eq_rounded, color: ColorRes.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Live Audio Rooms',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.to(() => const AllAudioRoomsScreen()),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: ColorRes.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text('No live audio rooms right now',
                  style: TextStyle(color: Color(0xFFB8B8B8), fontSize: 13)),
            )
          else
            SizedBox(
              height: 146,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return AudioRoomCard(
                    room: room,
                    onTap: () => controller.joinAudioRoom(room),
                  );
                },
              ),
            ),
        ],
      );
    });
  }
}

class AudioRoomCard extends StatelessWidget {
  final AudioRoom room;
  final VoidCallback? onTap;
  final double width;

  const AudioRoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.width = 230,
  });

  static const _barHeights = [7.0, 13.0, 6.0, 16.0, 9.0, 12.0];

  @override
  Widget build(BuildContext context) {
    final listening = room.participantIds?.length ?? 0;

    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorRes.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorRes.bgGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// AVATAR WITH LIVE + MIC BADGE (audio, not video)
          SizedBox(
            width: 52,
            height: 60,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomImage(
                  size: const Size(48, 48),
                  image: room.hostPhoto,
                  fullName: room.hostName ?? room.roomName,
                  radius: 24,
                  strokeWidth: 2,
                  strokeColor: ColorRes.liveRed,
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: ColorRes.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_rounded, color: Colors.white, size: 10),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: ColorRes.liveRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.roomName ?? 'Audio Room',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  room.hostName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ColorRes.primaryColor, fontSize: 11),
                ),
                const Spacer(),
                Row(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _barHeights
                          .map((h) => Container(
                                width: 2.5,
                                height: h,
                                margin: const EdgeInsets.only(right: 2),
                                decoration: BoxDecoration(
                                  color: ColorRes.primaryColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$listening Listening',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFB8B8B8), fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: ColorRes.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'Join Audio',
                        style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
