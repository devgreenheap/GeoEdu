import 'package:flutter/material.dart';

class DiamondPurchaseTabs extends StatelessWidget {
  const DiamondPurchaseTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1F44),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: Colors.blueAccent,
            width: 3,
          ),
        ),
        labelColor: Color(0xFFB6FF52),
        unselectedLabelColor: Color(0xFFFAFAFA),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "Purchase"),
          Tab(text: "History"),
        ],
      ),
    );
  }
}
