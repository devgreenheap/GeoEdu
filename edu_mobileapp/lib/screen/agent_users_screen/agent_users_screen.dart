import 'package:flutter/material.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/service/navigation/navigate_with_controller.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/general/agent_users_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:get/get.dart';

class AgentUsersScreen extends StatefulWidget {
  const AgentUsersScreen({super.key});

  @override
  State<AgentUsersScreen> createState() => _AgentUsersScreenState();
}

class _AgentUsersScreenState extends State<AgentUsersScreen> {
  final List<AgentUser> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchMore();
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final result = await CommonService.instance.fetchAgentUsers();
      if (result.status == true && result.data != null) {
        setState(() {
          _users.addAll(result.data!);
          _hasMore = result.data!.length >= 20;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMore() async {
    if (_users.isEmpty) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await CommonService.instance
          .fetchAgentUsers(lastItemId: _users.last.id);
      if (result.status == true && result.data != null) {
        setState(() {
          _users.addAll(result.data!);
          _hasMore = result.data!.length >= 20;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080C1A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
        title: const Text(
          "My Users",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_users.length} users',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.white38, strokeWidth: 2))
          : _users.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, color: Colors.white24, size: 60),
                      SizedBox(height: 12),
                      Text(
                        'No users assigned yet',
                        style: TextStyle(color: Colors.white60, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: _users.length + (_isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    if (index == _users.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.white38, strokeWidth: 2),
                        ),
                      );
                    }
                    return _AgentUserTile(
                      user: _users[index],
                      onHostApproved: () {
                        setState(() {
                          _users[index].isHost = 1;
                          _users[index].hostRequested = 0;
                        });
                      },
                      onScreenshotDisableApproved: () {
                        setState(() {
                          _users[index].screenshotDisableStatus = 1;
                        });
                      },
                    );
                  },
                ),
    );
  }
}

class _AgentUserTile extends StatelessWidget {
  final AgentUser user;
  final VoidCallback? onHostApproved;
  final VoidCallback? onScreenshotDisableApproved;

  const _AgentUserTile({
    required this.user,
    this.onHostApproved,
    this.onScreenshotDisableApproved,
  });

  Future<void> _approveHost(BuildContext context) async {
    BaseController.share.showLoader();
    final result = await CommonService.instance.approveHost(userId: user.id!);
    BaseController.share.stopLoader();
    if (result.status == true) {
      onHostApproved?.call();
      Get.snackbar('Approved', '${user.fullname} is now a host',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
    } else {
      Get.snackbar('Failed', result.message ?? 'Could not approve host',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
    }
  }

  Future<void> _approveScreenshotDisable(BuildContext context) async {
    if (user.screenshotDisableRequestId == null) return;
    BaseController.share.showLoader();
    final result = await CommonService.instance.approveScreenshotDisable(requestId: user.screenshotDisableRequestId!);
    BaseController.share.stopLoader();
    if (result.status == true) {
      onScreenshotDisableApproved?.call();
      Get.snackbar('Approved', 'Screenshot disable approved for ${user.fullname}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
    } else {
      Get.snackbar('Failed', result.message ?? 'Could not approve',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPendingHost = user.hostRequested == 1 && user.isHost != 1;
    final bool isPendingScreenshotDisable =
        user.screenshotDisableRequested == 1 && user.screenshotDisableStatus == 0;
    return InkWell(
      onTap: () async {
        BaseController.share.showLoader();
        User? fetchedUser = await UserService.instance.fetchUserDetails(userId: user.id);
        BaseController.share.stopLoader();
        if (fetchedUser != null) {
          NavigationService.shared.openProfileScreen(fetchedUser);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            /// Profile photo
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: user.isFreez == 1
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: CustomImage(
                size: const Size(50, 50),
                image: (user.profilePhoto ?? '').addBaseURL(),
                fullName: user.fullname,
              ),
            ),
            const SizedBox(width: 12),

            /// User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullname ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isHost == 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'HOST',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (isPendingHost) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PENDING',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (user.isFreez == 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'FROZEN',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (isPendingScreenshotDisable) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SS DISABLE',
                            style: TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '@${user.username ?? ''}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _statChip(Icons.people_outline, '${user.followerCount ?? 0}'),
                      const SizedBox(width: 12),
                      _statChip(Icons.monetization_on_outlined, '${user.coinWallet ?? 0}'),
                      const SizedBox(width: 12),
                      _statChip(Icons.star_outline_rounded, 'Lv.${user.level ?? 0}'),
                    ],
                  ),
                  if (isPendingHost) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton.icon(
                        onPressed: () => _approveHost(context),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Approve Host', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (isPendingScreenshotDisable) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton.icon(
                        onPressed: () => _approveScreenshotDisable(context),
                        icon: const Icon(Icons.screenshot_outlined, size: 16),
                        label: const Text('Approve Screenshot Disable', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            /// Arrow
            const Icon(Icons.chevron_right, color: Colors.white24, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
