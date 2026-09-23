import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/screen/live_stream/live_home_page_widget/room_grid_with_banners.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:geoedu/utilities/color_res.dart';

/// Merged "View All" grid replacing the previously separate
/// AllLiveClassroomsScreen (video-only) and AllAudioRoomsScreen
/// (audio-only) — one 2-column grid mixing video, recorded, and audio
/// [RoomCard]s, sourced from [LiveStreamSearchScreenController.mergedRoomItems].
class AllRoomsScreen extends StatelessWidget {
  const AllRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveStreamSearchScreenController>();

    return Scaffold(
      backgroundColor: ColorRes.blackPure,
      appBar: AppBar(
        backgroundColor: ColorRes.blackPure,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Live Rooms', style: TextStyle(color: Colors.white)),
      ),
      body: Obx(() {
        final items = controller.mergedRoomItems;
        if (items.isEmpty) {
          return const Center(
            child: Text('No live rooms right now', style: TextStyle(color: Colors.white38)),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: RoomGridWithBanners(items: items, mainAxisExtent: 248),
        );
      }),
    );
  }
}
