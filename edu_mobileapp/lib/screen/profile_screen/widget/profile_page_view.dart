import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/widget/confirmation_dialog.dart';
import 'package:geoedu/common/widget/no_data_widget.dart';
import 'package:geoedu/common/widget/recorded_video_player_screen.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/livestream/live_history_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/live_stream/go_live_setup_screen.dart';
import 'package:geoedu/screen/profile_screen/widget/host_interview_recording_screen.dart';
import 'package:geoedu/screen/profile_screen/profile_screen_controller.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/service/api/post_service.dart';
import 'package:geoedu/screen/leader_board/top_gifters_screen.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/star_store_diamond _screen.dart';
import 'package:geoedu/screen/star_wallet_screen/star_wallet_screen.dart';
import 'package:geoedu/screen/post_screen/single_post_screen.dart';
import 'package:geoedu/screen/profile_screen/profile_screen.dart';
import '../../../common/extensions/string_extension.dart';

class ProfilePageView extends StatefulWidget {
  final ProfileScreenController controller;

  const ProfilePageView({super.key, required this.controller});

  @override
  State<ProfilePageView> createState() => _ProfilePageViewState();
}

class _ProfilePageViewState extends State<ProfilePageView> {
  /// Buckets sessions by calendar day (most recent day first, sessions
  /// within a day kept in their existing most-recent-first order) for the
  /// date-grouped Insights list.
  List<MapEntry<DateTime, List<LiveHistory>>> _groupByDate(List<LiveHistory> lives) {
    final Map<DateTime, List<LiveHistory>> grouped = {};
    for (final live in lives) {
      final date = live.sessionDate ?? DateTime.now();
      final dayKey = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(dayKey, () => []).add(live);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Obx(() {
      User? user = widget.controller.userData.value;
      bool isHost = user?.isHost == 1;
      bool isMe = user?.id == SessionManager.instance.getUserID();
      bool isUserNotFound = widget.controller.isUserNotFound.value;
      return isUserNotFound
          ? NoDataView(
              title: LKey.noUserPostsTitle.tr,
              description: LKey.noUserPostsDescription.tr)
          : user?.isBlock == true
              ? const BlockUserView()
              : user?.isFreez == 1
                  ? const FreezeUser()
                  : PageView(
                      key: ValueKey('pageview_${user?.id}_$isHost'),
                      controller: widget.controller.pageController,
                      onPageChanged: widget.controller.onTabChanged,
                      children: isHost
                          ? [
                              /// Host Page 0: My Lives
                              Obx(() {
                                if (widget.controller.isMyLivesLoading.value &&
                                    widget.controller.myLives.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(40),
                                      child: CircularProgressIndicator(
                                          color: Colors.white38, strokeWidth: 2),
                                    ),
                                  );
                                }
                                if (widget.controller.myLives.isEmpty) {
                                  return _NoRecordedLivesView(isMe: isMe);
                                }
                                return GridView.builder(
                                  padding: const EdgeInsets.all(10),
                                  shrinkWrap: true,
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  itemCount: widget.controller.myLives.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1,
                                  ),
                                  itemBuilder: (context, index) {
                                    final live = widget.controller.myLives[index];
                                    return _LiveRecordingGridCard(
                                      live: live,
                                      user: user,
                                      isMe: isMe,
                                      onTap: () => _openRecordedVideo(context, live),
                                      onLongPress: isMe
                                          ? () => _confirmDeleteLive(context, live)
                                          : null,
                                    );
                                  },
                                );
                              }),

                              /// Host Page 1: Insights
                              Obx(() {
                                if (widget.controller.isMyLivesLoading.value &&
                                    widget.controller.myLives.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(40),
                                      child: CircularProgressIndicator(
                                          color: Colors.white38, strokeWidth: 2),
                                    ),
                                  );
                                }
                                if (widget.controller.myLives.isEmpty) {
                                  return _NoRecordedLivesView(isMe: isMe, isInsights: true);
                                }
                                final groups = _groupByDate(widget.controller.myLives);
                                return ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 30),
                                  itemCount: groups.length,
                                  itemBuilder: (context, groupIndex) {
                                    final group = groups[groupIndex];
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 10, top: 6),
                                          child: Text(
                                            _formatDateHeader(group.key),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        ...group.value.map((live) => Padding(
                                              padding: const EdgeInsets.only(bottom: 14),
                                              child: _LiveSessionInsightCard(live: live),
                                            )),
                                      ],
                                    );
                                  },
                                );
                              }),
                            ]
                          : [
                              /// Gifter Page 0: Gifting Activity & Wallet
                              _GifterActivityView(controller: widget.controller, isMe: isMe),

                              /// Gifter Page 1: Supported Hosts with Real-time Live
                              _GifterSupportedHostsView(controller: widget.controller),

                              /// Gifter Page 2: My Posts & Reels
                              _GifterPostsView(controller: widget.controller),
                            ],
                    );
    }));
  }

  void _confirmDeleteLive(BuildContext context, LiveHistory live) {
    Get.bottomSheet(
      ConfirmationSheet(
        title: 'Delete Live',
        description: 'Are you sure you want to delete this recorded live? This cannot be undone.',
        positiveText: 'Delete',
        actionColor: ColorRes.liveRed,
        onTap: () async {
          final success = await widget.controller.deleteLive(live);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Live deleted')),
            );
          }
        },
      ),
      isScrollControlled: true,
    );
  }

  void _openRecordedVideo(BuildContext context, LiveHistory live) {
    // If stream has a recording URL, resolve it; otherwise play standard sample lecture recording
    final rawUrl = live.videoUrl?.trim();
    final url = (rawUrl != null && rawUrl.isNotEmpty)
        ? rawUrl.addBaseURL()
        : 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordedVideoPlayerScreen(
          videoUrl: url,
          title: live.title ?? 'Live Recording',
          duration: live.durationFormatted,
        ),
      ),
    );
  }
}

class _LiveRecordingGridCard extends StatelessWidget {
  final LiveHistory live;
  final User? user;
  final bool isMe;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _LiveRecordingGridCard({
    required this.live,
    required this.user,
    required this.isMe,
    required this.onTap,
    this.onLongPress,
  });

  String? _resolveImageUrl() {
    final t = live.thumbnail?.trim();
    if (t != null && t.isNotEmpty) return t.addBaseURL();
    final hp = live.hostProfilePhoto?.trim();
    if (hp != null && hp.isNotEmpty) return hp.addBaseURL();
    final up = user?.profilePhoto?.trim();
    if (up != null && up.isNotEmpty) return up.addBaseURL();
    return null;
  }

  List<Color> _getThemeColors(String? title) {
    final t = (title ?? '').toLowerCase();
    if (t.contains('engine') || t.contains('tech') || t.contains('code') || t.contains('dev')) {
      return const [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF020617)];
    }
    if (t.contains('sci') || t.contains('phys') || t.contains('chem') || t.contains('bio')) {
      return const [Color(0xFF1E1B4B), Color(0xFF172554), Color(0xFF030712)];
    }
    if (t.contains('math') || t.contains('calc') || t.contains('stat')) {
      return const [Color(0xFF311042), Color(0xFF1F1135), Color(0xFF0F0B18)];
    }
    if (t.contains('art') || t.contains('design') || t.contains('craft')) {
      return const [Color(0xFF3B1824), Color(0xFF261019), Color(0xFF11070C)];
    }
    return const [Color(0xFF26262B), Color(0xFF1A1A1E), Color(0xFF111113)];
  }

  IconData _getThemeIcon(String? title) {
    final t = (title ?? '').toLowerCase();
    if (t.contains('engine') || t.contains('tech') || t.contains('code') || t.contains('dev')) {
      return Icons.engineering_rounded;
    }
    if (t.contains('sci') || t.contains('chem') || t.contains('lab')) {
      return Icons.science_rounded;
    }
    if (t.contains('math') || t.contains('calc')) {
      return Icons.calculate_rounded;
    }
    if (t.contains('bio') || t.contains('med')) {
      return Icons.medical_services_rounded;
    }
    return Icons.school_rounded;
  }

  Widget _buildFallbackCard(String? title) {
    final colors = _getThemeColors(title);
    final icon = _getThemeIcon(title);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle watermark icon in corner
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(
              icon,
              size: 80,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          // Topic badge watermark in center
          Icon(
            icon,
            size: 44,
            color: Colors.white.withOpacity(0.12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background image or educational theme fallback
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackCard(live.title),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return _buildFallbackCard(live.title);
                },
              )
            else
              _buildFallbackCard(live.title),

            // 2. High-contrast gradient overlay (for readability of text and buttons)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.65),
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // 3. Center Play Button
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.55),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // 4. Top Header: Time Ago pill (left) & Viewer Count pill (right)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Time Ago pill with red dot
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4D4F),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          live.timeAgo.isNotEmpty ? live.timeAgo : 'Live',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Viewer count pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.remove_red_eye_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${live.viewerCount ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 5. Bottom Footer: Title (left) & Duration badge (right)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      live.title != null && live.title!.isNotEmpty
                          ? live.title!
                          : 'Live Session',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 4),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (live.duration != null && live.duration! > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        live.durationFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveSessionInsightCard extends StatelessWidget {
  final LiveHistory live;

  const _LiveSessionInsightCard({required this.live});

  @override
  Widget build(BuildContext context) {
    final timeStr = live.sessionDate != null
        ? DateFormat('hh:mm a').format(live.sessionDate!)
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (live.title == null || live.title!.isEmpty) ? 'Live Show' : live.title!,
            style: const TextStyle(
              color: Color(0xFFFF7A00),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(timeStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          _InsightRow(icon: Icons.access_time_rounded, label: 'Duration', value: live.durationFormatted),
          _InsightRow(
              icon: Icons.person_add_alt_1_outlined,
              label: 'Followers',
              value: '${live.followersGained ?? 0}'),
          _InsightRow(
              icon: Icons.remove_red_eye_outlined,
              label: 'Viewers',
              value: '${live.viewerCount ?? 0}'),
          _InsightRow(
              icon: Icons.star_rounded,
              label: 'Stars Earned',
              value: '${live.starsEarned ?? 0}'),
          _InsightRow(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Comments',
              value: '${live.totalComments ?? 0}'),
          _InsightRow(
              icon: Icons.card_giftcard_rounded,
              label: 'Gifts',
              value: '${live.totalGifts ?? 0}'),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatusChip(
                label: live.isLive ? 'Live' : 'Ended',
                color: live.isLive ? const Color(0xFF34D948) : Colors.white60,
                backgroundColor: live.isLive ? const Color(0xFF34D948).withOpacity(0.15) : const Color(0xFF262626),
                borderColor: live.isLive ? const Color(0xFF34D948) : const Color(0xFF383838),
              ),
              const SizedBox(width: 8),
              const _StatusChip(
                label: 'Host',
                color: Color(0xFFFF7A00),
                borderColor: Color(0xFFFF7A00),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InsightRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final Color? borderColor;

  const _StatusChip({
    required this.label,
    required this.color,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? color, width: 1.2),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _NoRecordedLivesView extends StatelessWidget {
  final bool isMe;
  final bool isInsights;

  const _NoRecordedLivesView({
    required this.isMe,
    this.isInsights = false,
  });

  void _confirmBecomeHost(BuildContext context) {
    Get.to(() => const HostInterviewRecordingScreen());
  }

  void _onHostALive(BuildContext context) {
    final isHost = SessionManager.instance.getUser()?.isHost == 1;
    if (isHost) {
      Get.to(() => const GoLiveSetupScreen());
    } else {
      _confirmBecomeHost(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isInsights ? Icons.analytics_outlined : Icons.video_camera_back_outlined,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 20),
          Text(
            isInsights ? 'No Live Insights Yet' : 'No Recorded Lives',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            isInsights
                ? (isMe
                    ? 'You have not completed any Live sessions yet.\nYour streaming analytics and session summaries will appear here.'
                    : 'No live session insights available yet.')
                : (isMe
                    ? 'You have not hosted any Lives yet.\nAll your recorded Lives will be shown here.'
                    : 'No recorded lives yet.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
          if (isMe) ...[
            const SizedBox(height: 24),
            InkWell(
              onTap: () => _onHostALive(context),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [ColorRes.primaryColor, ColorRes.orangeDark],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sensors_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isInsights ? 'Host a Live Stream' : 'Host a Live',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BlockUserView extends StatelessWidget {
  const BlockUserView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        LKey.youAreBlockThisUser.tr,
        style: TextStyleCustom.outFitRegular400(
            color: textLightGrey(context), fontSize: 17),
      ),
    );
  }
}

class FreezeUser extends StatelessWidget {
  const FreezeUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        LKey.thisUserIsFreeze.tr,
        style: TextStyleCustom.outFitRegular400(
            color: textLightGrey(context), fontSize: 17),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GIFTER DASHBOARD VIEWS (Separated completely from Host Live & Insights UI)
// ---------------------------------------------------------------------------

class _GifterActivityView extends StatelessWidget {
  final ProfileScreenController controller;
  final bool isMe;

  const _GifterActivityView({required this.controller, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.userData.value;
      final diamondCount = user?.coinWallet ?? 0;
      final transactions = controller.gifterTransactions;
      final isLoading = controller.isGifterTransactionsLoading.value;

      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Gifter Status & Diamond Wallet Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF281434), Color(0xFF160E22), Color(0xFF0F0A18)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFFF9500).withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Gifter Badge & Community Tier
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.workspace_premium_rounded,
                                color: Color(0xFFFFD700), size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'GIFTER WALLET',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Color(0xFF00E676), size: 8),
                            SizedBox(width: 5),
                            Text(
                              'Active Supporter',
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Middle Row: Diamond Balance
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.diamond_rounded, color: Color(0xFF00E5FF), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$diamondCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            'Available Diamonds',
                            style: TextStyle(color: Colors.white60, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Get.to(() => const StarStoreDiamondScreen(showBackButton: true)),
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9500), Color(0xFFFF5E00)],
                              ),
                              borderRadius: BorderRadius.circular(21),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6900).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Get Diamonds',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Get.to(() => const StarWalletScreen()),
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(21),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFFFD700), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Stars Wallet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Quick Feature Shortcuts Row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.to(() => const TopGiftersScreen()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1A24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Top Gifters',
                                  style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Leaderboard',
                                  style: TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 12),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.to(() => const StarWalletScreen()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1A24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFF5252), size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gift History',
                                  style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Categories',
                                  style: TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 3. Recent Gifting History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Gifting Activity',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (transactions.isNotEmpty)
                  GestureDetector(
                    onTap: () => Get.to(() => const StarWalletScreen()),
                    child: const Text(
                      'View All',
                      style: TextStyle(color: Color(0xFFFF9500), fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (isLoading && transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(color: Color(0xFFFF9500), strokeWidth: 2),
                ),
              )
            else if (transactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFF141418),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9500).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFF9500), size: 30),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No Gifts Sent Yet',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Support educators and live speakers during live classes to earn top gifter badges and climb the leaderboards!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () {
                        if (controller.pageController.hasClients) {
                          controller.pageController.animateToPage(
                            1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.linear,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9500), Color(0xFFFF5500)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Explore Live Hosts',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...transactions.take(8).map((tx) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9500).withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.stars_rounded, color: Color(0xFFFF9500), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.title ?? 'Gift Sent',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tx.createdAt ?? '',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${tx.stars ?? 0} ⭐',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      );
    });
  }
}

class _GifterSupportedHostsView extends StatelessWidget {
  final ProfileScreenController controller;

  const _GifterSupportedHostsView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hosts = controller.similarHosts;
      final liveIds = controller.liveHostUserIds;
      final isLoading = controller.isSimilarHostsLoading.value;

      if (isLoading && hosts.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: Color(0xFFFF9500), strokeWidth: 2),
          ),
        );
      }

      if (hosts.isEmpty) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_alt_rounded, color: Colors.white38, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Supported Hosts Yet',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Find and follow your favorite educators to see when they go live and send them gifts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        itemCount: hosts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final host = hosts[index];
          final isLive = liveIds.contains(host.id);

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF16161B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isLive ? const Color(0xFFFF3300).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06),
                width: isLive ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Host Avatar with live indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLive ? const Color(0xFFFF3300) : Colors.white24,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: CustomImage(
                          size: const Size(48, 48),
                          image: host.profilePhoto?.addBaseURL(),
                          fullName: host.fullname,
                        ),
                      ),
                    ),
                    if (isLive)
                      Positioned(
                        bottom: -3,
                        left: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFF2200), Color(0xFFFF5500)]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'LIVE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Host Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              host.fullname ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Color(0xFF2196F3), size: 15),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isLive
                            ? '🔴 Streaming Live Classroom'
                            : '${host.followerCount ?? 0} Followers',
                        style: TextStyle(
                          color: isLive ? const Color(0xFFFF5252) : Colors.white54,
                          fontSize: 12,
                          fontWeight: isLive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Button
                if (isLive)
                  GestureDetector(
                    onTap: () => controller.openLiveStreamForHost(host),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF3300), Color(0xFFFF6600)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3300).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Watch & Gift',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => Get.to(() => ProfileScreen(user: host)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Text(
                        'View Profile',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _GifterPostsView extends StatelessWidget {
  final ProfileScreenController controller;

  const _GifterPostsView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final posts = controller.posts;
      final reels = controller.reels;
      final allPosts = [...posts, ...reels];
      final isLoading = controller.isPostLoading.value || controller.isReelLoading.value;

      if (isLoading && allPosts.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2),
          ),
        );
      }

      if (allPosts.isEmpty) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.grid_on_rounded, color: Colors.white38, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Posts Yet',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Shared education posts, notes, and reels will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12.5),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(10),
        itemCount: allPosts.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final item = allPosts[index];
          final imageUrl = item.thumbnail ??
              (item.images?.isNotEmpty == true ? item.images!.first.image : null) ??
              item.video;
          final isVideo = item.postType == PostType.reel || item.postType == PostType.video;

          return GestureDetector(
            onTap: () {
              Get.to(() => SinglePostScreen(post: item));
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImage(
                    size: const Size(120, 120),
                    image: imageUrl?.addBaseURL(),
                  ),
                ),
                if (isVideo)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
                  ),
              ],
            ),
          );
        },
      );
    });
  }
}

