import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/misc/admin_notification_model.dart';

class SystemNotificationPage extends StatelessWidget {
  final AdminNotificationData data;

  const SystemNotificationPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131317),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF26262E),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.image != null && data.image!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomImage(
                  image: data.image?.addBaseURL(),
                  size: const Size(double.infinity, 160),
                  fit: BoxFit.cover,
                  isShowPlaceHolder: true,
                ),
              ),
            ),
          Text(
            data.title ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          DetectableText(
            text: data.description ?? '',
            basicStyle: const TextStyle(
              color: Color(0xFFA2A2AC),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
            detectionRegExp:
                detectionRegExp(atSign: false, hashtag: false, url: true)!,
            detectedStyle: const TextStyle(
              color: Color(0xFFFF7A00),
              fontWeight: FontWeight.w600,
            ),
            onTap: (p0) {
              p0.lunchUrlWithHttps;
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 12,
                color: Color(0xFF6E6E78),
              ),
              const SizedBox(width: 4),
              Text(
                _formatTime(data.createdAt),
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
    );
  }

  String _formatTime(String? dateStr) {
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
