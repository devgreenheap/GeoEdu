import 'package:flutter/material.dart';
import 'package:geoedu/utilities/theme_res.dart';

class MyRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final bool shouldRefresh;
  final int depth;
  final GlobalKey? refreshKey;

  const MyRefreshIndicator(
      {super.key,
      required this.onRefresh,
      required this.child,
      this.shouldRefresh = true,
      this.depth = 0,
      this.refreshKey});

  @override
  Widget build(BuildContext context) {
    if (shouldRefresh) {
      return RefreshIndicator(
        key: refreshKey,
        onRefresh: onRefresh,
        notificationPredicate: (notification) {
          if (depth == 0) {
            return notification.depth == 0;
          }
          return notification.depth == depth || notification.depth == 0;
        },
        color: themeAccentSolid(context),
        backgroundColor: whitePure(context),
        triggerMode: RefreshIndicatorTriggerMode.onEdge,
        child: child,
      );
    } else {
      return child;
    }
  }
}
