import 'package:flutter/material.dart';

class StarScoreTabs extends StatelessWidget {
  const StarScoreTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF300278),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: Colors.yellowAccent,
            width: 3,
          ),
        ),
        unselectedLabelColor: Color(0xFFFAFAFA),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "All"),
          Tab(text: "Video"),
          Tab(text: "Audio"),
          Tab(text: "Chat"),

        ],
      ),
    );
  }
}
