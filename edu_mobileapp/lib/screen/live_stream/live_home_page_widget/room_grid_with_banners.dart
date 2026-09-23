import 'package:flutter/material.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/model/general/leaderboard_user_model.dart';
import 'package:geoedu/model/livestream/live_room_item.dart';
import 'package:geoedu/screen/live_stream/live_home_page_widget/room_card.dart';
import 'package:geoedu/screen/live_stream/live_home_page_widget/top_gifters_banner.dart';

/// 2-column rooms grid with a [TopGiftersBanner] after every 4 cards, used
/// by both the Home preview grid and the full "View All" grid.
class RoomGridWithBanners extends StatefulWidget {
  final List<LiveRoomItem> items;
  final double mainAxisExtent;

  const RoomGridWithBanners({
    super.key,
    required this.items,
    required this.mainAxisExtent,
  });

  static const int bannerEvery = 4;

  @override
  State<RoomGridWithBanners> createState() => _RoomGridWithBannersState();
}

class _RoomGridWithBannersState extends State<RoomGridWithBanners> {
  List<LeaderboardUser> gifters = [];

  @override
  void initState() {
    super.initState();
    _fetchGifters();
  }

  Future<void> _fetchGifters() async {
    try {
      final model = await CommonService.instance
          .fetchTopGifters(period: 'today', limit: 3);
      if (!mounted) return;
      setState(() => gifters = model.data ?? []);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final chunks = <List<LiveRoomItem>>[];
    for (int i = 0; i < widget.items.length; i += RoomGridWithBanners.bannerEvery) {
      final end = (i + RoomGridWithBanners.bannerEvery).clamp(0, widget.items.length);
      chunks.add(widget.items.sublist(i, end));
    }

    return Column(
      children: [
        for (int c = 0; c < chunks.length; c++) ...[
          if (c > 0 && gifters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TopGiftersBanner(gifters: gifters),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: chunks[c].length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: widget.mainAxisExtent,
            ),
            itemBuilder: (context, index) => RoomCard(item: chunks[c][index]),
          ),
          if (c < chunks.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
