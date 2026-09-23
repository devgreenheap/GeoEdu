import 'package:flutter/material.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/gradient_border.dart';
import 'package:geoedu/model/audio_call/audio_room.dart';
import 'package:geoedu/screen/audio_call/audio_call_list_screen.dart' show kAudioChatCardGradient;
import 'package:geoedu/utilities/color_res.dart';

class AudioRoomCard extends StatelessWidget {
  final AudioRoom room;
  final VoidCallback onJoin;

  const AudioRoomCard({
    super.key,
    required this.room,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final participantCount = room.participantIds?.length ?? 0;
    final maxParticipants = room.maxParticipants ?? 8;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GradientBorder(
        strokeWidth: 1.2,
        radius: 12,
        gradient: kAudioChatCardGradient,
        child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CustomImage(
            size: const Size(48, 48),
            image: room.hostPhoto,
            radius: 24,
            fullName: room.hostName,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.roomName ?? 'Audio Room',
                  style: const TextStyle(
                    color: ColorRes.whitePure,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Host: ${room.hostName ?? 'Unknown'}',
                  style: TextStyle(
                    color: ColorRes.whitePure.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people, color: Color(0xFFFF7A00), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$participantCount / $maxParticipants',
                      style: const TextStyle(
                        color: Color(0xFFFF7A00),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: participantCount < maxParticipants ? onJoin : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: participantCount < maxParticipants
                    ? const Color(0xFFFF7A00)
                    : Colors.grey.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                participantCount < maxParticipants ? 'Join' : 'Full',
                style: TextStyle(
                  color: participantCount < maxParticipants ? Colors.black : ColorRes.whitePure,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }
}
