import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/audio_call/audio_room.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/screen/audio_call/audio_call_list_controller.dart';
import 'package:geoedu/screen/audio_call/audio_room_controller.dart';
import 'package:geoedu/screen/audio_call/audio_room_screen.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/audience/live_stream_audience_screen.dart';

/// Real-time side drawer/panel appearing on the right side of the screen when tapping "Lives >".
/// Shows other active live streams and audio chatrooms with video/photo preview,
/// live badge, watching count, verified badge, Chatroom badge, and play icon.
class OtherLivesSidePanel extends StatelessWidget {
  final VoidCallback onClose;
  final int? currentAudioHostId;

  const OtherLivesSidePanel({
    super.key,
    required this.onClose,
    this.currentAudioHostId,
  });

  @override
  Widget build(BuildContext context) {
    final searchController = Get.isRegistered<LiveStreamSearchScreenController>()
        ? Get.find<LiveStreamSearchScreenController>()
        : Get.put(LiveStreamSearchScreenController());

    final audioListController = Get.isRegistered<AudioCallListController>()
        ? Get.find<AudioCallListController>()
        : Get.put(AudioCallListController());

    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * 0.52; // Takes ~50-52% of the screen on the right

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: panelWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF14141E).withValues(alpha: 0.96),
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(-4, 0),
            ),
          ],
          border: Border(
            left: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Drag handle / Close Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Rooms',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable list of lives in real time
              Expanded(
                child: Obx(() {
                  // Real-time video streams from LiveStreamSearchScreenController
                  final videoStreams = searchController.livestreamList;

                  // Real-time audio rooms from AudioCallListController (excluding current room)
                  final audioRooms = audioListController.audioRooms
                      .where((r) => r.hostId != currentAudioHostId && (r.isActive ?? true))
                      .toList();

                  final totalCount = videoStreams.length + audioRooms.length;

                  if (totalCount == 0) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.live_tv_rounded,
                              size: 38,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No other lives active right now',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 2, 8, 16),
                    itemCount: totalCount,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index < videoStreams.length) {
                        final stream = videoStreams[index];
                        return _buildVideoLiveCard(context, stream);
                      } else {
                        final room = audioRooms[index - videoStreams.length];
                        return _buildAudioRoomCard(context, room);
                      }
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoLiveCard(BuildContext context, Livestream stream) {
    final hostUser = stream.hostUser;
    final name = hostUser?.fullname ?? hostUser?.username ?? 'Host';
    final photo = hostUser?.profile;
    final watching = stream.watchingCount ?? 0;

    return GestureDetector(
      onTap: () async {
        onClose();
        if (Get.isRegistered<AudioRoomController>()) {
          await Get.find<AudioRoomController>().leaveRoom(shouldPop: false);
        }
        Get.off(() => LiveStreamAudienceScreen(
              livestream: stream,
              isHost: false,
            ));
      },
      child: Container(
        height: 175,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1E1E2C),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Host photo or video thumbnail
              CustomImage(
                size: const Size(double.infinity, 175),
                image: photo?.addBaseURL(),
                radius: 0,
                fit: BoxFit.cover,
                fullName: name,
              ),

              // Gradient dark overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // Top row: LIVE badge & Watching count
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Red LIVE badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2200),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sensors_rounded, color: Colors.white, size: 10),
                          SizedBox(width: 3),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Semi-transparent Watching Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$watching Watching',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom details: Host Name with checkmark + Classroom pill + Play circle
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name & Blue verified tick
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(color: Colors.black87, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF29B6F6),
                          size: 13,
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Classroom pill on the left & Play circle icon on the right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Classroom Cyan Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00ADB5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school_rounded, color: Colors.white, size: 9.5),
                              SizedBox(width: 3),
                              Text(
                                'Classroom',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Translucent Play Icon
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
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

  Widget _buildAudioRoomCard(BuildContext context, AudioRoom room) {
    final name = room.hostName ?? room.roomName ?? 'Audio Host';
    final photo = room.hostPhoto;
    final watching = room.participantIds?.length ?? 1;

    return GestureDetector(
      onTap: () async {
        onClose();
        if (Get.isRegistered<AudioRoomController>()) {
          await Get.find<AudioRoomController>().leaveRoom(shouldPop: false);
        }
        Get.off(() => AudioRoomScreen(
              room: room,
              isHost: false,
            ));
      },
      child: Container(
        height: 175,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1E1E2C),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Host photo
              CustomImage(
                size: const Size(double.infinity, 175),
                image: photo?.addBaseURL(),
                radius: 0,
                fit: BoxFit.cover,
                fullName: name,
              ),

              // Gradient dark overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // Top row: LIVE badge & Watching count
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2200),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_rounded, color: Colors.white, size: 10),
                          SizedBox(width: 3),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$watching In Room',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom details
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(color: Colors.black87, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF29B6F6),
                          size: 13,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00ADB5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school_rounded, color: Colors.white, size: 9.5),
                              SizedBox(width: 3),
                              Text(
                                'Classroom',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
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
