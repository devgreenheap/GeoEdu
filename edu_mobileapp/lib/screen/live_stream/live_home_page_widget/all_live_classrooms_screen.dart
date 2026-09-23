import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/screen/live_stream/live_home_page_widget/sample_live_classes_widget.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';

class AllLiveClassroomsScreen extends StatelessWidget {
  const AllLiveClassroomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveStreamSearchScreenController>();

    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05070D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Live Classrooms', style: TextStyle(color: Colors.white)),
      ),
      body: Obx(() {
        final streams = controller.livestreamFilterList;
        if (streams.isEmpty) {
          return const Center(
            child: Text('No live classrooms right now', style: TextStyle(color: Colors.white38)),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: streams.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 248,
          ),
          itemBuilder: (context, index) => SampleClassCard(
            item: streams[index],
            onTap: () => controller.onLiveUserTap(streams[index]),
          ),
        );
      }),
    );
  }
}
