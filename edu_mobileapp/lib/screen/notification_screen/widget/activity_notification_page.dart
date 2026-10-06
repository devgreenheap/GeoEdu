import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:geoedu/common/extensions/common_extension.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/misc/activity_notification_model.dart';
import 'package:geoedu/common/service/api/post_service.dart';
import 'package:geoedu/model/post_story/post_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/comment_sheet/helper/comment_helper.dart';
import 'package:geoedu/screen/notification_screen/notification_screen_controller.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class ActivityNotificationPage extends StatelessWidget {
  final ActivityNotification data;
  final NotificationScreenController controller;

  const ActivityNotificationPage({
    super.key,
    required this.data,
    required this.controller,
  });

  static const List<List<Color>> _avatarGradients = [
    [Color(0xFF4A80F0), Color(0xFF6DA2FF)], // Sky Blue
    [Color(0xFF8C52FF), Color(0xFFA57BFF)], // Purple
    [Color(0xFFFF5376), Color(0xFFFF7E98)], // Coral Pink
    [Color(0xFF1E88E5), Color(0xFF42A5F5)], // Electric Blue
    [Color(0xFF48BB78), Color(0xFF68D391)], // Mint Green
    [Color(0xFFFF922B), Color(0xFFFFA94D)], // Warm Orange
    [Color(0xFFB042FF), Color(0xFFCC7EFF)], // Violet
    [Color(0xFF00B4D8), Color(0xFF48CAE4)], // Cyan / Teal
    [Color(0xFFE83E8C), Color(0xFFFF69B4)], // Rose Pink
    [Color(0xFF3B5BDB), Color(0xFF5C7CFA)], // Periwinkle Indigo
  ];

  @override
  Widget build(BuildContext context) {
    final gift = data.data?.gift;
    final isGift = data.type == ActivityNotifyType.notifyGiftUser || gift != null;
    final post = data.data?.post;

    return InkWell(
      onTap: () {
        if (isGift || data.type == ActivityNotifyType.notifyFollowUser) {
          controller.onUserTap(data.fromUser);
        } else {
          controller.onPostTap(data);
        }
      },
      splashColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131317),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF26262E),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Left: User Initial or Photo Avatar
            _buildAvatar(data.fromUser),

            const SizedBox(width: 12),

            // Middle Left: Username, Action Subtitle, Timestamp
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          data.fromUser?.username ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      if (data.fromUser?.isVerify == 1) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF2196F3),
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _getNotificationSubtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFA2A2AC),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Color(0xFF6E6E78),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatRelativeTime(data.createdAt),
                        style: const TextStyle(
                          color: Color(0xFF6E6E78),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Center-Right: Gift Image (or post thumbnail if post notification)
            if (isGift)
              _buildGiftImage(gift)
            else if (post != null && post.postType != PostType.text)
              _buildPostThumbnail(post),

            const SizedBox(width: 8),

            // Right: Coin Capsule Badge (for gifts)
            if (isGift) ...[
              _buildCoinBadge(gift?.coinPrice ?? 1),
              const SizedBox(width: 8),
            ],

            // Far Right: Chevron Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF555562),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(User? user) {
    final photo = user?.profilePhoto;
    final name = (user?.username?.trim().isNotEmpty ?? false)
        ? user!.username!.trim()
        : (user?.fullname?.trim().isNotEmpty ?? false)
            ? user!.fullname!.trim()
            : 'U';

    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';

    // Pick deterministic gradient for this user
    final charCode = initial.codeUnitAt(0);
    final userSeed = user?.id?.toInt() ?? charCode;
    final gradientColors = _avatarGradients[userSeed.abs() % _avatarGradients.length];

    if (photo != null && photo.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 44,
          height: 44,
          child: CustomImage(
            image: photo.addBaseURL(),
            size: const Size(44, 44),
            fit: BoxFit.cover,
            isShowPlaceHolder: true,
          ),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildGiftImage(Gift? gift) {
    final imgUrl = gift?.image;
    if (imgUrl != null && imgUrl.isNotEmpty) {
      return SizedBox(
        width: 48,
        height: 48,
        child: CustomImage(
          image: imgUrl.addBaseURL(),
          size: const Size(48, 48),
          fit: BoxFit.contain,
          isShowPlaceHolder: false,
        ),
      );
    }

    // Fallback gift icon if image missing
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.card_giftcard_rounded,
        color: Color(0xFFFF7A00),
        size: 26,
      ),
    );
  }

  Widget _buildPostThumbnail(dynamic post) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 44,
        height: 44,
        child: CustomImage(
          image: (post?.postType == PostType.image
                  ? post?.images?.first?.image
                  : post?.thumbnail)
              ?.toString()
              .addBaseURL(),
          size: const Size(44, 44),
          fit: BoxFit.cover,
          isShowPlaceHolder: true,
        ),
      ),
    );
  }

  Widget _buildCoinBadge(num amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
      decoration: BoxDecoration(
        color: const Color(0xFF222228),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF33333E),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AssetRes.icCoin,
            width: 17,
            height: 17,
          ),
          const SizedBox(width: 5),
          Text(
            '$amount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _getNotificationSubtitle() {
    final commentDesc = data.data?.comment?.commentDescription ?? '';
    final replyCommentDesc =
        (data.data?.reply ?? data.data?.comment)?.commentDescription ?? '';

    switch (data.type) {
      case ActivityNotifyType.notifyGiftUser:
        return LKey.activitySentGift.tr; // "has sent you gift"
      case ActivityNotifyType.notifyLikePost:
        return LKey.activityLikedPost.tr;
      case ActivityNotifyType.notifyCommentPost:
        if (data.data?.comment?.type == CommentType.image) {
          return LKey.activityGIFComment.tr;
        }
        return LKey.activityCommentedPost
            .trParams({'comment_description': commentDesc});
      case ActivityNotifyType.notifyMentionPost:
        return LKey.notifyMentionedInPost.tr;
      case ActivityNotifyType.notifyMentionComment:
      case ActivityNotifyType.notifyReplyComment:
        return LKey.activityReplyingToComment.trParams({
          'username': data.fromUser?.username ?? '',
          'comment_description': replyCommentDesc,
        });
      case ActivityNotifyType.notifyMentionReply:
        return LKey.notifyReplyMentionedInComment
            .trParams({'comment_description': commentDesc});
      case ActivityNotifyType.notifyFollowUser:
        return LKey.notifyStartedFollowing.tr;
      default:
        if (data.data?.gift != null) {
          return LKey.activitySentGift.tr;
        }
        return '';
    }
  }

  String _formatRelativeTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      DateTime time = DateTime.parse(dateStr).toLocal();
      DateTime now = DateTime.now();
      Duration diff = now.difference(time);

      if (diff.inSeconds < 60) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        final mins = diff.inMinutes;
        return '$mins ${mins == 1 ? "minute" : "minutes"} ago';
      } else if (diff.inHours < 24) {
        final hours = diff.inHours;
        return '$hours ${hours == 1 ? "hour" : "hours"} ago';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 30) {
        final days = diff.inDays;
        return '$days ${days == 1 ? "day" : "days"} ago';
      } else {
        return DateFormat('dd MMM yyyy').format(time);
      }
    } catch (_) {
      return dateStr;
    }
  }
}

enum ActivityNotifyType {
  none(0),
  notifyLikePost(1),
  notifyCommentPost(2),
  notifyMentionPost(3),
  notifyMentionComment(4),
  notifyFollowUser(5),
  notifyGiftUser(6),
  notifyReplyComment(7),
  notifyMentionReply(8);

  final int type;

  const ActivityNotifyType(this.type);

  static ActivityNotifyType fromString(int value) {
    return ActivityNotifyType.values.firstWhere(
      (e) => e.type == value,
      orElse: () => ActivityNotifyType.none,
    );
  }
}

class NotificationGiftIcon extends StatelessWidget {
  final Gift? gift;

  const NotificationGiftIcon({super.key, this.gift});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Container(
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: textDarkGrey(context),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            CustomImage(
              size: const Size(25, 25),
              image: gift?.image?.addBaseURL(),
              isShowPlaceHolder: true,
            ),
            const SizedBox(width: 5),
            Image.asset(AssetRes.icCoin, height: 18, width: 18),
            const SizedBox(width: 5),
            Text(
              (gift?.coinPrice ?? 0).numberFormat,
              style: TextStyleCustom.outFitRegular400(
                color: whitePure(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
