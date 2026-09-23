import 'package:flutter/material.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/livestream/live_room_item.dart';
import 'package:geoedu/utilities/color_res.dart';

/// Single card for the merged Home/AllRooms grid, branching its visual
/// style off [LiveRoomItem.variant] — replaces the previously separate
/// SampleClassCard/RecordedLiveCard (video) and AudioRoomCard (audio) for
/// the unified grid, reusing the exact same badge/pill/gradient styling
/// those already had.
class RoomCard extends StatelessWidget {
  final LiveRoomItem item;

  const RoomCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.variant == RoomCardVariant.audio) {
      return _AudioRoomGridCard(item: item);
    }
    return _VideoOrRecordedGridCard(item: item);
  }
}

class _VideoOrRecordedGridCard extends StatelessWidget {
  final LiveRoomItem item;

  const _VideoOrRecordedGridCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isRecorded = item.variant == RoomCardVariant.recorded;

    return GestureDetector(
      onTap: item.onTap,
      child: AspectRatio(
        aspectRatio: 150 / 220,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: ColorRes.cardBackground,
            border: Border.all(color: ColorRes.bgGrey),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomImage(
                  size: const Size(150, 220),
                  radius: 0,
                  fit: BoxFit.cover,
                  image: item.hostPhotoUrl?.addBaseURL(),
                  fullName: item.title,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                      stops: const [0, 0.4, 1],
                    ),
                  ),
                ),
                // Top-left: LIVE / RECORDED badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isRecorded
                          ? Colors.black.withValues(alpha: 0.55)
                          : ColorRes.liveRed,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRecorded) ...[
                          const Icon(Icons.play_circle_fill_rounded,
                              color: ColorRes.primaryColor, size: 11),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          isRecorded ? 'RECORDED' : 'LIVE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: isRecorded ? 8 : 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                // Top-right: watching count / duration
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: isRecorded
                        ? Text(item.recording?.durationFormatted ?? '',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 9.5))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.remove_red_eye_rounded,
                                  color: Colors.white, size: 10),
                              const SizedBox(width: 3),
                              Text('${item.subCount}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 9.5)),
                            ],
                          ),
                  ),
                ),
                // Bottom-right: category pill / play icon
                if (isRecorded)
                  const Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Icon(Icons.play_circle_fill_rounded,
                          color: Colors.white, size: 40),
                    ),
                  )
                else if (item.categoryName.isNotEmpty)
                  Positioned(
                    bottom: 34,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: ColorRes.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_rounded,
                              color: Colors.black, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            item.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (item.coHostAvatars.isNotEmpty)
                  Positioned(
                    top: 30,
                    left: 8,
                    child: _CoHostAvatars(photos: item.coHostAvatars),
                  ),
                if (item.isPkBattle)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: ColorRes.primaryGradient,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('PK',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                // Bottom: title + host name
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isRecorded)
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700),
                        ),
                      if (!isRecorded) const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.hostName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: isRecorded
                                      ? Colors.white
                                      : const Color(0xFFDADADA),
                                  fontSize: isRecorded ? 12 : 10.5,
                                  fontWeight: isRecorded
                                      ? FontWeight.w700
                                      : FontWeight.normal),
                            ),
                          ),
                          if (item.isVerified) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.verified_rounded,
                                color: Color(0xFF4F7CF9), size: 11),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlapping avatar circles showing who is currently co-hosting.
class _CoHostAvatars extends StatelessWidget {
  final List<String> photos;

  const _CoHostAvatars({required this.photos});

  static const int _maxShown = 3;
  static const double _size = 20;
  static const double _overlap = 13;

  @override
  Widget build(BuildContext context) {
    final shown = photos.take(_maxShown).toList();
    final extra = photos.length - shown.length;
    final width = _overlap * shown.length +
        (_size - _overlap) +
        (extra > 0 ? _overlap : 0);

    return SizedBox(
      height: _size,
      width: width,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * _overlap,
              child: CustomImage(
                size: const Size(_size, _size),
                radius: _size / 2,
                image: shown[i].addBaseURL(),
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * _overlap,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text('+$extra',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

class _AudioRoomGridCard extends StatelessWidget {
  final LiveRoomItem item;

  const _AudioRoomGridCard({required this.item});

  static const _barHeights = [7.0, 13.0, 6.0, 16.0, 9.0, 12.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorRes.orangeDark.withValues(alpha: 0.35),
            ColorRes.cardBackground
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorRes.bgGrey),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(5)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.remove_red_eye_rounded,
                      color: Colors.white, size: 10),
                  const SizedBox(width: 3),
                  Text('${item.subCount}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 9.5)),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                height: 60,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomImage(
                      size: const Size(48, 48),
                      image: item.hostPhotoUrl,
                      fullName:
                          item.hostName.isNotEmpty ? item.hostName : item.title,
                      radius: 24,
                      strokeWidth: 2,
                      strokeColor: ColorRes.liveRed,
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                            color: ColorRes.green1, shape: BoxShape.circle),
                        child: const Icon(Icons.mic_rounded,
                            color: Colors.white, size: 10),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                              color: ColorRes.liveRed,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('LIVE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                item.hostName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(color: ColorRes.primaryColor, fontSize: 11),
              ),
              const Spacer(),
              Row(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _barHeights
                        .map((h) => Container(
                              width: 2.5,
                              height: h,
                              margin: const EdgeInsets.only(right: 2),
                              decoration: BoxDecoration(
                                  color: ColorRes.primaryColor,
                                  borderRadius: BorderRadius.circular(2)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${item.subCount} Listening',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFFB8B8B8), fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: item.onTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                      color: ColorRes.primaryColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Center(
                    child: Text('Join Audio',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
