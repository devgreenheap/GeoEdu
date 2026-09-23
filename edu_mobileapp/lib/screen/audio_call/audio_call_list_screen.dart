import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/widget/banner_carousel_new.dart';
import 'package:geoedu/common/widget/level_badge.dart';
import 'package:geoedu/screen/audio_call/audio_call_list_controller.dart';
import 'package:geoedu/screen/audio_call/widget/audio_room_card.dart';
import 'package:geoedu/utilities/color_res.dart';

/// GIO EDU brand gradient (orange -> gold) — used for headers/borders across
/// Audio and Chat, replacing the old purple-pink kFieldGradient.
const kAudioChatCardGradient = LinearGradient(
  colors: [ColorRes.primaryColor, ColorRes.gold],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class AudioCallListScreen extends StatelessWidget {
  const AudioCallListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<AudioCallListController>()
        ? Get.find<AudioCallListController>()
        : Get.put(AudioCallListController());
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => kAudioChatCardGradient.createShader(bounds),
          child: const Text(
            'Audio Rooms',
            style: TextStyle(color: ColorRes.whitePure, fontWeight: FontWeight.w700),
          ),
        ),
        actions: [
          Builder(builder: (context) {
            final level = SessionManager.instance.getUser()?.getLevel;
            return LevelBadge(level: level?.id != null ? level?.level : null);
          }),
          const SizedBox(width: 12),
        ],
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF120A1C), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.35],
          ),
        ),
        child: Column(
          children: [
            const BannerCarousel(type: 'audio'),
            Expanded(child: _buildRoomsList(controller)),
          ],
        ),
      ),
      floatingActionButton: SessionManager.instance.getUser()?.isHost == 1
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFFF7A00),
              onPressed: controller.showCreateRoomDialog,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }

  Widget _buildRoomsList(AudioCallListController controller) {
    return Obx(() {
      if (controller.audioRooms.isEmpty) {
        final isHost = SessionManager.instance.getUser()?.isHost == 1;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic_off, color: Colors.white38, size: 64),
              const SizedBox(height: 16),
              const Text(
                'No active rooms',
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                isHost
                    ? 'Tap + to create a room'
                    : 'Wait for a host to create a room',
                style: const TextStyle(color: Colors.white24, fontSize: 14),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: controller.audioRooms.length,
        itemBuilder: (context, index) {
          final room = controller.audioRooms[index];
          return AudioRoomCard(
            room: room,
            onJoin: () => controller.joinAudioRoom(room),
          );
        },
      );
    });
  }
}
