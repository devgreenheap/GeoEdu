import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/screen/audio_call/create_audio_room_screen.dart';
import 'package:geoedu/screen/live_stream/create_live_stream_screen/create_live_stream_screen.dart';
import 'package:geoedu/screen/live_stream/go_live_shared_state.dart';
import 'package:geoedu/utilities/color_res.dart';

/// Video and Audio go-live setup behind one tab bar. Language, hashtags and
/// Auto Call live in [GoLiveSharedState] so switching tabs keeps them.
/// Tab order is Audio(0) / Video(1) — matching the bottom bar's left-to-
/// right "🎤 Audio | 🎥 Video" order — with Video as the default tab.
class GoLiveSetupScreen extends StatefulWidget {
  final int initialTab;

  const GoLiveSetupScreen({super.key, this.initialTab = 1});

  @override
  State<GoLiveSetupScreen> createState() => _GoLiveSetupScreenState();
}

class _GoLiveSetupScreenState extends State<GoLiveSetupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<GoLiveSharedState>()) Get.put(GoLiveSharedState());
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorRes.blackPure,
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                CreateAudioRoomScreen(),
                CreateLiveStreamScreen(),
              ],
            ),
          ),
          // Bottom tab selector — plain text, active = white + orange
          // underline (no filled pill), matching the reference exactly.
          SafeArea(
            top: false,
            child: Container(
              color: Colors.black,
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorColor: ColorRes.primaryColor,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(icon: Icon(Icons.mic_rounded, size: 18), text: 'Audio', iconMargin: EdgeInsets.only(bottom: 2)),
                  Tab(icon: Icon(Icons.videocam_rounded, size: 18), text: 'Video', iconMargin: EdgeInsets.only(bottom: 2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
