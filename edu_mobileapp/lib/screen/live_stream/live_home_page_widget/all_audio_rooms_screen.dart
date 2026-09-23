import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/screen/audio_call/audio_call_list_controller.dart';
import 'package:geoedu/screen/live_stream/live_home_page_widget/live_audio_rooms_widget.dart';

class AllAudioRoomsScreen extends StatelessWidget {
  const AllAudioRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AudioCallListController>();

    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05070D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Live Audio Rooms', style: TextStyle(color: Colors.white)),
      ),
      body: Obx(() {
        final rooms = controller.audioRooms;
        if (rooms.isEmpty) {
          return const Center(
            child: Text('No live audio rooms right now', style: TextStyle(color: Colors.white38)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(10),
          itemCount: rooms.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final room = rooms[index];
            return AudioRoomCard(
              room: room,
              onTap: () => controller.joinAudioRoom(room),
              width: double.infinity,
            );
          },
        );
      }),
    );
  }
}
