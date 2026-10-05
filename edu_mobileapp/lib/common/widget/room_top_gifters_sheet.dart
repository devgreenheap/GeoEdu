import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/follow_controller.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/livestream/livestream_comment.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/audio_call/audio_room_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';

/// Item representing a gifter in either the live room or API leaderboards.
class RoomGifterItem {
  final int userId;
  final String username;
  final String fullname;
  final String? profilePhoto;
  final int totalDiamonds;
  bool isFollowing;
  final int rank;

  RoomGifterItem({
    required this.userId,
    required this.username,
    required this.fullname,
    this.profilePhoto,
    required this.totalDiamonds,
    this.isFollowing = false,
    required this.rank,
  });
}

/// Item representing a gift received by the host in this session.
class RoomGiftReceivedItem {
  final int? giftId;
  final String title;
  final String? image;
  int count;
  int totalCoins;

  RoomGiftReceivedItem({
    this.giftId,
    required this.title,
    this.image,
    this.count = 1,
    required this.totalCoins,
  });
}

/// Modern Bottom Sheet matching the user's reference screenshot:
/// - Top Navigation Tabs: [Top Gifters] | [Gift Received] with orange underline
/// - Filter Chips under Top Gifters: [This Live] [This Week] [This Month] [Last Month]
/// - Hexagonal Rank Badge, User Avatar, Fullname, Diamonds Sent ("291 💎"), Follow Button
/// - Real-time "This Live" data powered by live comments/gifts stream
/// - Sticky bottom footer: "Sorted as per the Total Value of Gifts Sent by Users"
class RoomTopGiftersSheet extends StatefulWidget {
  final String? roomId;
  final int? hostId;
  final bool isAudio;
  final LivestreamScreenController? videoController;
  final AudioRoomController? audioController;

  const RoomTopGiftersSheet({
    super.key,
    this.roomId,
    this.hostId,
    required this.isAudio,
    this.videoController,
    this.audioController,
  });

  /// Static helper to display the sheet in any context.
  static void show({
    required BuildContext context,
    String? roomId,
    int? hostId,
    required bool isAudio,
    LivestreamScreenController? videoController,
    AudioRoomController? audioController,
  }) {
    Get.bottomSheet(
      RoomTopGiftersSheet(
        roomId: roomId,
        hostId: hostId,
        isAudio: isAudio,
        videoController: videoController,
        audioController: audioController,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<RoomTopGiftersSheet> createState() => _RoomTopGiftersSheetState();
}

class _RoomTopGiftersSheetState extends State<RoomTopGiftersSheet> {
  // 0 = Top Gifters, 1 = Gift Received
  int _selectedTab = 0;

  // Filter index under Top Gifters: 0 = This Live, 1 = This Week, 2 = This Month, 3 = Last Month
  int _selectedFilter = 0;

  final List<String> _filters = [
    'This Live',
    'This Week',
    'This Month',
    'Last Month',
  ];

  // API Leaderboard cache
  bool _isLoadingApi = false;
  final Map<int, List<RoomGifterItem>> _apiCache = {};

  // Following state tracker
  final Set<int> _followingUserIds = {};

  @override
  void initState() {
    super.initState();
    _fetchApiLeaderboardIfNeeded(_selectedFilter);
  }

  void _onTabChanged(int index) {
    if (_selectedTab != index) {
      setState(() => _selectedTab = index);
    }
  }

  void _onFilterChanged(int index) {
    if (_selectedFilter != index) {
      setState(() => _selectedFilter = index);
      if (index > 0) {
        _fetchApiLeaderboardIfNeeded(index);
      }
    }
  }

  String _mapFilterToPeriod(int index) {
    switch (index) {
      case 1:
        return 'this_week';
      case 2:
        return 'this_month';
      case 3:
        return 'last_month';
      default:
        return 'today';
    }
  }

  Future<void> _fetchApiLeaderboardIfNeeded(int filterIndex) async {
    if (filterIndex == 0) return; // "This Live" uses real-time stream
    if (_apiCache.containsKey(filterIndex)) return;

    setState(() => _isLoadingApi = true);
    final period = _mapFilterToPeriod(filterIndex);

    try {
      final res = await CommonService.instance.fetchTopGifters(
        period: period,
        type: widget.isAudio ? 'audio' : 'video',
        limit: 50,
      );

      final items = (res.data ?? []).map((u) {
        final isFollowing = u.isFollowing ?? false;
        if (isFollowing && u.userId != null) {
          _followingUserIds.add(u.userId!);
        }
        return RoomGifterItem(
          userId: u.userId ?? 0,
          username: u.username ?? '',
          fullname: u.fullname ?? u.username ?? 'User',
          profilePhoto: u.profilePhoto,
          totalDiamonds: (u.totalStars ?? 0).toInt(),
          isFollowing: isFollowing,
          rank: u.rank ?? 0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _apiCache[filterIndex] = items;
          _isLoadingApi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingApi = false);
      }
    }
  }

  Future<void> _toggleFollow(RoomGifterItem gifter) async {
    final currentUserId = SessionManager.instance.getUser()?.id;
    if (currentUserId == gifter.userId) return;

    final targetUser = User(
      id: gifter.userId,
      username: gifter.username,
      fullname: gifter.fullname,
      profilePhoto: gifter.profilePhoto,
      isFollowing: _followingUserIds.contains(gifter.userId),
    );

    FollowController followController;
    if (Get.isRegistered<FollowController>(tag: '${gifter.userId}')) {
      followController = Get.find<FollowController>(tag: '${gifter.userId}');
      followController.updateUser(targetUser);
    } else {
      followController = Get.put(
        FollowController(targetUser.obs),
        tag: '${gifter.userId}',
      );
    }

    try {
      final updated = await followController.followUnFollowUser();
      final nowFollowing = updated?.isFollowing ?? !_followingUserIds.contains(gifter.userId);
      setState(() {
        if (nowFollowing) {
          _followingUserIds.add(gifter.userId);
        } else {
          _followingUserIds.remove(gifter.userId);
        }
        gifter.isFollowing = nowFollowing;
      });
    } catch (_) {
      // Revert if error
      setState(() {});
    }
  }

  // -------------------------------------------------------------
  // Real-time "This Live" Top Gifters derivation
  // -------------------------------------------------------------
  List<RoomGifterItem> _buildThisLiveGifters() {
    final Map<int, RoomGifterItem> gifterMap = {};

    if (!widget.isAudio && widget.videoController != null) {
      // 1. Video Call: Aggregate from real-time comments stream
      final comments = widget.videoController!.comments;
      for (final c in comments) {
        if (c.commentType == LivestreamCommentType.gift) {
          final senderId = c.senderId;
          if (senderId == null || senderId <= 0) continue;
          final coins = c.gift?.coinPrice ?? 0;
          final user = c.senderUser;

          if (gifterMap.containsKey(senderId)) {
            final existing = gifterMap[senderId]!;
            gifterMap[senderId] = RoomGifterItem(
              userId: senderId,
              username: user?.username ?? existing.username,
              fullname: user?.fullname ?? existing.fullname,
              profilePhoto: user?.profile ?? existing.profilePhoto,
              totalDiamonds: existing.totalDiamonds + coins,
              isFollowing: existing.isFollowing,
              rank: 0,
            );
          } else {
            gifterMap[senderId] = RoomGifterItem(
              userId: senderId,
              username: user?.username ?? 'User',
              fullname: user?.fullname ?? user?.username ?? 'User',
              profilePhoto: user?.profile,
              totalDiamonds: coins,
              isFollowing: _followingUserIds.contains(senderId),
              rank: 0,
            );
          }
        }
      }
    } else if (widget.isAudio && widget.audioController != null) {
      // 2. Audio Call: Aggregate from gifterTotals and participants
      final controller = widget.audioController!;
      final totals = controller.gifterTotals;
      final participants = controller.participants;

      totals.forEach((name, coins) {
        final p = participants.firstWhereOrNull(
          (u) => (u.fullname == name || u.username == name),
        );
        final userId = p?.userId ?? name.hashCode;
        gifterMap[userId] = RoomGifterItem(
          userId: userId,
          username: p?.username ?? name,
          fullname: p?.fullname ?? name,
          profilePhoto: p?.profilePhoto,
          totalDiamonds: coins,
          isFollowing: _followingUserIds.contains(userId),
          rank: 0,
        );
      });

      for (final g in controller.receivedGiftsHistory) {
        final userId = g.userId ?? g.username.hashCode;
        if (gifterMap.containsKey(userId)) {
          final existing = gifterMap[userId]!;
          if (existing.profilePhoto == null && g.senderPhoto != null) {
            gifterMap[userId] = RoomGifterItem(
              userId: existing.userId,
              username: existing.username,
              fullname: existing.fullname,
              profilePhoto: g.senderPhoto,
              totalDiamonds: existing.totalDiamonds,
              isFollowing: existing.isFollowing,
              rank: 0,
            );
          }
        } else {
          gifterMap[userId] = RoomGifterItem(
            userId: userId,
            username: g.username,
            fullname: g.username,
            profilePhoto: g.senderPhoto,
            totalDiamonds: (g.coinPrice ?? 0).toInt(),
            isFollowing: _followingUserIds.contains(userId),
            rank: 0,
          );
        }
      }
    }

    final list = gifterMap.values.toList()
      ..sort((a, b) => b.totalDiamonds.compareTo(a.totalDiamonds));

    return List.generate(list.length, (i) {
      final item = list[i];
      return RoomGifterItem(
        userId: item.userId,
        username: item.username,
        fullname: item.fullname,
        profilePhoto: item.profilePhoto,
        totalDiamonds: item.totalDiamonds,
        isFollowing: item.isFollowing,
        rank: i + 1,
      );
    });
  }

  // -------------------------------------------------------------
  // Real-time "Gift Received" items derivation
  // -------------------------------------------------------------
  List<RoomGiftReceivedItem> _buildGiftsReceived() {
    final Map<String, RoomGiftReceivedItem> giftMap = {};

    if (!widget.isAudio && widget.videoController != null) {
      for (final c in widget.videoController!.comments) {
        if (c.commentType == LivestreamCommentType.gift && c.gift != null) {
          final g = c.gift!;
          final key = '${g.id ?? g.title}';
          final price = g.coinPrice ?? 0;
          if (giftMap.containsKey(key)) {
            final item = giftMap[key]!;
            item.count += 1;
            item.totalCoins += price;
          } else {
            giftMap[key] = RoomGiftReceivedItem(
              giftId: g.id,
              title: g.title ?? 'Gift',
              image: g.image,
              count: 1,
              totalCoins: price,
            );
          }
        }
      }
    } else if (widget.isAudio && widget.audioController != null) {
      for (final g in widget.audioController!.receivedGiftsHistory) {
        final key = g.giftName;
        final price = (g.coinPrice ?? 0).toInt();
        if (giftMap.containsKey(key)) {
          final item = giftMap[key]!;
          item.count += 1;
          item.totalCoins += price;
        } else {
          giftMap[key] = RoomGiftReceivedItem(
            giftId: null,
            title: g.giftName,
            image: g.thumbnailUrl ?? g.assetUrl,
            count: 1,
            totalCoins: price,
          );
        }
      }
    }

    final list = giftMap.values.toList()
      ..sort((a, b) => b.totalCoins.compareTo(a.totalCoins));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF22242A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            // Drag handle indicator
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Primary Navigation Tabs: Top Gifters | Gift Received ──
            _buildTabBar(),
            const Divider(color: Colors.white10, height: 1, thickness: 1),

            // ── Content Area (Top Gifters or Gift Received) ──
            Expanded(
              child: _selectedTab == 0
                  ? _buildTopGiftersView()
                  : _buildGiftReceivedView(),
            ),

            // ── Sticky Footer Note ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: const Color(0xFF191B20),
              alignment: Alignment.center,
              child: const Text(
                'Sorted as per the Total Value of Gifts Sent by Users',
                style: TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Tabs Header
  // -------------------------------------------------------------
  Widget _buildTabBar() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onTabChanged(0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Top Gifters',
                    style: TextStyle(
                      color: _selectedTab == 0 ? Colors.white : Colors.white60,
                      fontSize: 16,
                      fontWeight:
                          _selectedTab == 0 ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  height: 3,
                  width: double.infinity,
                  color: _selectedTab == 0
                      ? const Color(0xFFFF5722)
                      : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onTabChanged(1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Gift Received',
                    style: TextStyle(
                      color: _selectedTab == 1 ? Colors.white : Colors.white60,
                      fontSize: 16,
                      fontWeight:
                          _selectedTab == 1 ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  height: 3,
                  width: double.infinity,
                  color: _selectedTab == 1
                      ? const Color(0xFFFF5722)
                      : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Top Gifters Tab Body
  // -------------------------------------------------------------
  Widget _buildTopGiftersView() {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Filter Pills: [This Live] [This Week] [This Month] [Last Month]
        _buildFilterPills(),
        const SizedBox(height: 12),

        // List of Gifters
        Expanded(
          child: _selectedFilter == 0
              ? _buildThisLiveList()
              : _buildApiLeaderboardList(),
        ),
      ],
    );
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilter == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onFilterChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF5722)
                      : const Color(0xFF2C2F36),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildThisLiveList() {
    // If Video Call, observe comments reactively
    if (!widget.isAudio && widget.videoController != null) {
      return Obx(() {
        final gifters = _buildThisLiveGifters();
        if (gifters.isEmpty) {
          return _buildEmptyState('No gifts sent in this live yet');
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          itemCount: gifters.length,
          itemBuilder: (context, index) => _buildGifterRow(gifters[index]),
        );
      });
    }

    final gifters = _buildThisLiveGifters();
    if (gifters.isEmpty) {
      return _buildEmptyState('No gifts sent in this live yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      itemCount: gifters.length,
      itemBuilder: (context, index) => _buildGifterRow(gifters[index]),
    );
  }

  Widget _buildApiLeaderboardList() {
    if (_isLoadingApi) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
        ),
      );
    }

    final items = _apiCache[_selectedFilter] ?? [];
    if (items.isEmpty) {
      return _buildEmptyState('No contributors found for this period');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildGifterRow(items[index]),
    );
  }

  Widget _buildGifterRow(RoomGifterItem gifter) {
    final currentUserId = SessionManager.instance.getUser()?.id;
    final isMe = currentUserId == gifter.userId;
    final isFollowing = _followingUserIds.contains(gifter.userId) || gifter.isFollowing;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // 1. Hexagonal Rank Badge
          _HexagonRankBadge(rank: gifter.rank),
          const SizedBox(width: 10),

          // 2. Avatar
          CustomImage(
            size: const Size(38, 38),
            image: gifter.profilePhoto?.addBaseURL(),
            fullName: gifter.fullname,
            radius: 19,
          ),
          const SizedBox(width: 10),

          // 3. Name
          Expanded(
            child: Text(
              gifter.fullname.isNotEmpty ? gifter.fullname : gifter.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 4. Diamonds amount ("291 💎")
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${gifter.totalDiamonds}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 3),
              const Text('💎', style: TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(width: 12),

          // 5. Follow / Following button
          if (!isMe)
            GestureDetector(
              onTap: () => _toggleFollow(gifter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isFollowing
                      ? Colors.transparent
                      : const Color(0xFF2E323B),
                  borderRadius: BorderRadius.circular(16),
                  border: isFollowing
                      ? null
                      : Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Text(
                  isFollowing ? 'Following' : '+ Follow',
                  style: TextStyle(
                    color: isFollowing ? Colors.white70 : Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Gift Received Tab Body
  // -------------------------------------------------------------
  Widget _buildGiftReceivedView() {
    if (!widget.isAudio && widget.videoController != null) {
      return Obx(() {
        final gifts = _buildGiftsReceived();
        if (gifts.isEmpty) {
          return _buildEmptyState('No gifts received in this live yet');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: gifts.length,
          separatorBuilder: (_, __) =>
              const Divider(color: Colors.white10, height: 16),
          itemBuilder: (context, index) {
            final gift = gifts[index];
            return Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImage(
                    size: const Size(44, 44),
                    image: gift.image?.addBaseURL(),
                    fullName: gift.title,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gift.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total value: ${gift.totalCoins} 💎',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'x${gift.count}',
                    style: const TextStyle(
                      color: Color(0xFFFF5722),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      });
    }

    return _buildEmptyState('No gifts received in this live yet');
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard_rounded,
                color: Colors.white24, size: 48),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(color: Colors.white54, fontSize: 13.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom hexagonal outline badge with the rank number centered inside.
class _HexagonRankBadge extends StatelessWidget {
  final int rank;

  const _HexagonRankBadge({required this.rank});

  Color _getBadgeColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFE0E0E0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBadgeColor();
    return SizedBox(
      width: 25,
      height: 25,
      child: CustomPaint(
        painter: _HexagonBorderPainter(
          color: color,
          strokeWidth: 1.4,
        ),
        child: Center(
          child: Text(
            '$rank',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _HexagonBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _HexagonBorderPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Hexagon with flat top and bottom, pointed sides:
    path.moveTo(w * 0.28, 0);
    path.lineTo(w * 0.72, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(w * 0.72, h);
    path.lineTo(w * 0.28, h);
    path.lineTo(0, h * 0.5);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
