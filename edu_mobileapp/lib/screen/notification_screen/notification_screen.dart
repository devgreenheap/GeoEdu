import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/load_more_widget.dart';
import 'package:geoedu/common/widget/loader_widget.dart';
import 'package:geoedu/common/widget/no_data_widget.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/misc/activity_notification_model.dart';
import 'package:geoedu/screen/notification_screen/notification_screen_controller.dart';
import 'package:geoedu/screen/notification_screen/widget/activity_notification_page.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationScreenController());

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: Column(
        children: [
          // Orange Gradient Header matching reference UI
          _buildHeader(context, controller),

          // Activity Notification List
          Expanded(
            child: Obx(() {
              return _NotificationListWrapper<ActivityNotification>(
                isLoading: controller.isActivityNotification.value,
                isEmpty: controller.activityNotifications.isEmpty,
                items: controller.activityNotifications,
                itemBuilder: (context, data) => ActivityNotificationPage(
                  data: data,
                  controller: controller,
                ),
                loadMore: controller.fetchActivityNotifications,
                onRefresh: controller.refreshActivityNotifications,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, NotificationScreenController controller) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF5200),
            Color(0xFFFF6900),
            Color(0xFFFF7A00),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topPadding > 0 ? topPadding + 6 : 28),

          // App Bar Row: Back Button | Title | Glowing Bell
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      LKey.notifications.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                // Glowing Bell with sparkles icon
                _buildGlowingBellIcon(),
              ],
            ),
          ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildGlowingBellIcon() {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle warm glow behind bell
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.55),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
          // Bright golden bell
          const Icon(
            Icons.notifications_rounded,
            color: Color(0xFFFFE082),
            size: 25,
          ),
          // Small sparkle star dot at upper-right
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF9C4),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationListWrapper<T> extends StatelessWidget {
  final bool isLoading;
  final bool isEmpty;
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final Future<void> Function() loadMore;
  final Future<void> Function() onRefresh;

  const _NotificationListWrapper({
    required this.isLoading,
    required this.isEmpty,
    required this.items,
    required this.itemBuilder,
    required this.loadMore,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && isEmpty) {
      return const LoaderWidget();
    }

    return NoDataView(
      showShow: isEmpty,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: const Color(0xFFFF6A00),
        child: LoadMoreWidget(
          loadMore: loadMore,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 25),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return itemBuilder(context, items[index]);
            },
          ),
        ),
      ),
    );
  }
}
