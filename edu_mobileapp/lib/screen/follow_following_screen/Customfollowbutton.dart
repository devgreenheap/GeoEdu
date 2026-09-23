import 'package:get/get.dart';

import '../../languages/languages_keys.dart';
import '../../utilities/theme_res.dart';
import 'follow_following_screen.dart';
import 'package:flutter/material.dart';
class CustomFollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final Future<void> Function() onTap;
  final ActionName actionName;

  const CustomFollowButton({
    super.key,
    required this.isFollowing,
    required this.isLoading,
    required this.onTap,
    required this.actionName,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFollowAction = actionName == ActionName.follow;

    final String title = isFollowAction
        ? (isFollowing ? LKey.unFollow.tr : LKey.follow.tr)
        : (isFollowing ? LKey.unBlock.tr : LKey.block.tr);

    final Color backgroundColor =
    isFollowing ? Colors.white : blueFollow(context);

    final Color textColor =
    isFollowing ? textLightGrey(context) : Colors.white;

    final BorderSide borderSide =
    isFollowing ? BorderSide(color: bgGrey(context)) : BorderSide.none;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.fromBorderSide(borderSide),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: textColor,
            ),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isFollowing && isFollowAction) ...[
                const Icon(Icons.add, size: 16, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
