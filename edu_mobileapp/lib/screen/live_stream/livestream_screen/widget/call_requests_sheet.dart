import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/model/livestream/livestream_user_state.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/livestream_screen_controller.dart';

class CallRequestsSheet extends StatefulWidget {
  const CallRequestsSheet({super.key});

  /// Static call request history for the live session
  static final RxList<Map<String, dynamic>> sessionHistory =
      <Map<String, dynamic>>[].obs;

  static void show(BuildContext context) {
    HapticManager.shared.light();
    Get.bottomSheet(
      const CallRequestsSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
    );
  }

  @override
  State<CallRequestsSheet> createState() => _CallRequestsSheetState();
}

class _CallRequestsSheetState extends State<CallRequestsSheet> {
  final LivestreamScreenController controller =
      Get.find<LivestreamScreenController>();

  int _selectedTabIndex = 0; // 0: All, 1: Welcome, 2: History

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.60,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E2026),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          // Header: "Call Requests" & Close Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Call Requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticManager.shared.light();
                    Get.back();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs: All | Welcome | History
          _buildTabsRow(),

          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFF2A2D35),
          ),

          // Tab Content Area
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildAllRequestsTab(),
                _buildWelcomeTab(),
                _buildHistoryTab(),
              ],
            ),
          ),

          // Bottom Bar: "List sorted as per Diamonds Gifted"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: const Color(0xFF282A31),
            child: const Text(
              'List sorted as per Diamonds Gifted',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Tabs Row
  // -------------------------------------------------------------
  Widget _buildTabsRow() {
    final tabs = ['All', 'Welcome', 'History'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticManager.shared.light();
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      tabs[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    height: 3,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF5722)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // -------------------------------------------------------------
  // Tab 1: All Requests (Real-time listener on requestList)
  // -------------------------------------------------------------
  Widget _buildAllRequestsTab() {
    return Obx(() {
      final requests = List<LivestreamUserState>.from(controller.requestList);

      // Sort as per diamonds gifted (liveCoin descending)
      requests.sort((a, b) => b.liveCoin.compareTo(a.liveCoin));

      if (requests.isEmpty) {
        return _buildEmptyState(
          title: 'No one here!',
          subtitle: 'All requests will appear here',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: requests.length,
        separatorBuilder: (_, __) => const Divider(
          height: 16,
          thickness: 0.6,
          color: Color(0xFF2A2D35),
        ),
        itemBuilder: (context, index) {
          final state = requests[index];
          final user = controller.firestoreController.users.firstWhereOrNull(
                (u) => u.userId == state.userId,
              ) ??
              state.user;

          return _buildRequestItem(state, user);
        },
      );
    });
  }

  // -------------------------------------------------------------
  // Single Request Item with Accept & Reject buttons
  // -------------------------------------------------------------
  Widget _buildRequestItem(LivestreamUserState state, AppUser? user) {
    final username = user?.username ?? 'user_${state.userId}';
    final fullname = user?.fullname ?? username;
    final photoUrl = user?.profile?.addBaseURL();
    final diamonds = state.liveCoin;

    return Row(
      children: [
        // Avatar
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: photoUrl != null && photoUrl.isNotEmpty
              ? CustomImage(
                  image: photoUrl,
                  size: const Size(46, 46),
                  fit: BoxFit.cover,
                )
              : Container(
                  color: Colors.white12,
                  child: const Icon(Icons.person, color: Colors.white70),
                ),
        ),
        const SizedBox(width: 12),

        // User Details & Diamonds
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      fullname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (user?.isVerify == 1) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2196F3),
                      size: 14,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(
                    Icons.diamond_rounded,
                    color: Color(0xFFBA68C8),
                    size: 13,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    diamonds > 0 ? '$diamonds Diamonds gifted' : 'Call request',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Reject Button (Red)
        GestureDetector(
          onTap: () {
            HapticManager.shared.medium();
            CallRequestsSheet.sessionHistory.insert(0, {
              'user': user,
              'userId': state.userId,
              'status': 'Rejected',
              'time': DateTime.now(),
            });
            controller.handleRequestResponse(user: user, isRefused: true);
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFF3D00).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF3D00).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFFFF5252),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Accept Button (Green)
        GestureDetector(
          onTap: () {
            HapticManager.shared.medium();
            CallRequestsSheet.sessionHistory.insert(0, {
              'user': user,
              'userId': state.userId,
              'status': 'Accepted',
              'time': DateTime.now(),
            });
            Get.back(); // close sheet when accepted so host sees new co-host
            controller.handleRequestResponse(user: user, isRefused: false);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E676), Color(0xFF00C853)],
              ),
              borderRadius: BorderRadius.circular(19),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Accept',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Tab 2: Welcome (Audience list for host to welcome/invite)
  // -------------------------------------------------------------
  Widget _buildWelcomeTab() {
    return Obx(() {
      final audience = controller.audienceList;

      if (audience.isEmpty) {
        return _buildEmptyState(
          title: 'No viewers yet',
          subtitle: 'Viewers in room will appear here to welcome',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: audience.length,
        separatorBuilder: (_, __) => const Divider(
          height: 16,
          thickness: 0.6,
          color: Color(0xFF2A2D35),
        ),
        itemBuilder: (context, index) {
          final state = audience[index];
          final user = controller.firestoreController.users.firstWhereOrNull(
                (u) => u.userId == state.userId,
              ) ??
              state.user;
          final fullname = user?.fullname ?? user?.username ?? 'Viewer';
          final photoUrl = user?.profile?.addBaseURL();
          final isInvited = state.type == LivestreamUserType.invited;

          return Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                clipBehavior: Clip.antiAlias,
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? CustomImage(
                        image: photoUrl,
                        size: const Size(44, 44),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.white12,
                        child: const Icon(Icons.person, color: Colors.white70),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fullname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticManager.shared.light();
                  controller.onInvite(user, isInvited: isInvited);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isInvited
                        ? Colors.white12
                        : const Color(0xFFFF5722).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isInvited
                          ? Colors.white24
                          : const Color(0xFFFF5722),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isInvited ? 'Invited' : 'Invite to Call',
                    style: TextStyle(
                      color: isInvited
                          ? Colors.white54
                          : const Color(0xFFFF7043),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  // -------------------------------------------------------------
  // Tab 3: History (Session call request history)
  // -------------------------------------------------------------
  Widget _buildHistoryTab() {
    return Obx(() {
      final history = CallRequestsSheet.sessionHistory;

      if (history.isEmpty) {
        return _buildEmptyState(
          title: 'No call history yet',
          subtitle: 'Accepted and rejected calls will show here',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: history.length,
        separatorBuilder: (_, __) => const Divider(
          height: 16,
          thickness: 0.6,
          color: Color(0xFF2A2D35),
        ),
        itemBuilder: (context, index) {
          final item = history[index];
          final AppUser? user = item['user'] as AppUser?;
          final String status = item['status'] as String? ?? '';
          final bool isAccepted = status == 'Accepted';
          final fullname = user?.fullname ?? user?.username ?? 'User';
          final photoUrl = user?.profile?.addBaseURL();

          return Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                clipBehavior: Clip.antiAlias,
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? CustomImage(
                        image: photoUrl,
                        size: const Size(44, 44),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.white12,
                        child: const Icon(Icons.person, color: Colors.white70),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fullname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAccepted
                      ? const Color(0xFF00E676).withValues(alpha: 0.15)
                      : const Color(0xFFFF5252).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isAccepted
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF5252),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  // -------------------------------------------------------------
  // Empty State matching screenshot
  // -------------------------------------------------------------
  Widget _buildEmptyState({
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          // Confused character custom illustration
          const SizedBox(
            width: 150,
            height: 130,
            child: CustomPaint(
              painter: ConfusedCharacterPainter(),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFF5722),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Custom painter recreating the exact blue confused character from the reference screenshot
class ConfusedCharacterPainter extends CustomPainter {
  const ConfusedCharacterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double groundY = size.height * 0.90;

    // 1. Ground white shadow oval
    final groundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, groundY),
        width: size.width * 0.72,
        height: 11,
      ),
      groundPaint,
    );

    // 2. Black spindly legs
    final legPaint = Paint()
      ..color = const Color(0xFF141926)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Left leg
    final leftLeg = Path()
      ..moveTo(cx - 10, groundY - 26)
      ..lineTo(cx - 16, groundY - 10)
      ..lineTo(cx - 24, groundY - 2);
    canvas.drawPath(leftLeg, legPaint);

    // Right leg
    final rightLeg = Path()
      ..moveTo(cx + 8, groundY - 26)
      ..lineTo(cx + 18, groundY - 12)
      ..lineTo(cx + 28, groundY - 2);
    canvas.drawPath(rightLeg, legPaint);

    // Feet
    final footPaint = Paint()
      ..color = const Color(0xFF141926)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 24, groundY - 2), width: 10, height: 4),
      footPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 28, groundY - 2), width: 10, height: 4),
      footPaint,
    );

    // 3. Blue Oval Character Body
    final bodyRect = Rect.fromCenter(
      center: Offset(cx, groundY - 55),
      width: 48,
      height: 66,
    );
    final bodyPaint = Paint()
      ..color = const Color(0xFF2962FF)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(24)),
      bodyPaint,
    );

    // Subtle body highlight
    final highlightPaint = Paint()
      ..color = const Color(0xFF448AFF)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - 4, groundY - 60),
          width: 36,
          height: 52,
        ),
        const Radius.circular(18),
      ),
      highlightPaint,
    );

    // 4. White paper sheet held by character
    final paperPaint = Paint()
      ..color = const Color(0xFFECEFF1)
      ..style = PaintingStyle.fill;
    final paperPath = Path()
      ..moveTo(cx - 36, groundY - 52)
      ..lineTo(cx - 10, groundY - 45)
      ..lineTo(cx - 16, groundY - 18)
      ..lineTo(cx - 42, groundY - 25)
      ..close();
    canvas.drawPath(paperPath, paperPaint);

    // Lines on the paper
    final linePaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - 34, groundY - 45),
      Offset(cx - 16, groundY - 40),
      linePaint,
    );
    canvas.drawLine(
      Offset(cx - 36, groundY - 38),
      Offset(cx - 18, groundY - 33),
      linePaint,
    );
    canvas.drawLine(
      Offset(cx - 38, groundY - 31),
      Offset(cx - 22, groundY - 27),
      linePaint,
    );

    // 5. Left arm scratching head
    final armPaint = Paint()
      ..color = const Color(0xFF141926)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final headScratchArm = Path()
      ..moveTo(cx + 20, groundY - 60)
      ..lineTo(cx + 30, groundY - 72)
      ..lineTo(cx + 18, groundY - 78);
    canvas.drawPath(headScratchArm, armPaint);

    // Hand scratching top
    canvas.drawCircle(Offset(cx + 17, groundY - 78), 3, footPaint);

    // Arm holding paper
    final paperArm = Path()
      ..moveTo(cx - 15, groundY - 52)
      ..lineTo(cx - 22, groundY - 38);
    canvas.drawPath(paperArm, armPaint);

    // 6. Confused/Sleepy Eyes
    // Eye whites
    final eyeWhite = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 6, groundY - 64), width: 10, height: 7),
      eyeWhite,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 9, groundY - 64), width: 10, height: 7),
      eyeWhite,
    );

    // Droopy dark eyelids
    final eyelidPaint = Paint()..color = const Color(0xFF0D1B2A);
    final leftLid = Path()
      ..moveTo(cx - 12, groundY - 67)
      ..lineTo(cx, groundY - 64)
      ..lineTo(cx - 1, groundY - 69)
      ..close();
    canvas.drawPath(leftLid, eyelidPaint);

    final rightLid = Path()
      ..moveTo(cx + 3, groundY - 64)
      ..lineTo(cx + 15, groundY - 67)
      ..lineTo(cx + 14, groundY - 69)
      ..close();
    canvas.drawPath(rightLid, eyelidPaint);

    // Pupils looking down at paper
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(cx - 8, groundY - 63), 2.2, pupilPaint);
    canvas.drawCircle(Offset(cx + 7, groundY - 63), 2.2, pupilPaint);

    // Frowning mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF0D1B2A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 1, groundY - 51), width: 8, height: 6),
      3.14,
      3.14,
      false,
      mouthPaint,
    );

    // 7. Light Blue Question Marks (??)
    final qMarkPaint = Paint()
      ..color = const Color(0xFF64B5F6)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // First question mark
    _drawQuestionMark(canvas, Offset(cx - 42, groundY - 68), qMarkPaint);
    // Second question mark
    _drawQuestionMark(canvas, Offset(cx - 32, groundY - 78), qMarkPaint);
  }

  void _drawQuestionMark(Canvas canvas, Offset offset, Paint paint) {
    final path = Path()
      ..moveTo(offset.dx - 3, offset.dy - 6)
      ..cubicTo(
        offset.dx - 3,
        offset.dy - 12,
        offset.dx + 5,
        offset.dy - 12,
        offset.dx + 4,
        offset.dy - 6,
      )
      ..lineTo(offset.dx, offset.dy - 2);
    canvas.drawPath(path, paint);

    // Dot
    final dotPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(offset.dx, offset.dy + 3), 1.4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
