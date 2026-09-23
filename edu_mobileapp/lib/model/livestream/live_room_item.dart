import 'package:geoedu/model/audio_call/audio_room.dart';
import 'package:geoedu/model/livestream/live_history_model.dart';
import 'package:geoedu/model/livestream/livestream.dart';

enum RoomCardVariant { liveVideo, recorded, audio }

/// Thin, additive wrapper unifying [Livestream] (live video), [LiveHistory]
/// (recorded VOD), and [AudioRoom] (live audio) into one type so the Home
/// page's live-rooms grid can render/sort them together. Does not replace
/// or modify any of the three underlying models — each item just carries a
/// reference to its real source object plus the fields [RoomCard] needs to
/// render generically, and a caller-supplied [onTap] since navigation
/// targets differ per variant.
class LiveRoomItem {
  final RoomCardVariant variant;
  final Livestream? livestream;
  final LiveHistory? recording;
  final AudioRoom? audioRoom;
  final void Function() onTap;

  /// Profile photos of users currently co-hosting, resolved by the caller
  /// from the Firestore app-users list. Empty when nobody has joined.
  final List<String> coHostAvatars;

  LiveRoomItem.video(this.livestream,
      {required this.onTap, this.coHostAvatars = const []})
      : variant = RoomCardVariant.liveVideo,
        recording = null,
        audioRoom = null;

  LiveRoomItem.recorded(this.recording, {required this.onTap})
      : variant = RoomCardVariant.recorded,
        livestream = null,
        audioRoom = null,
        coHostAvatars = const [];

  LiveRoomItem.audio(this.audioRoom, {required this.onTap})
      : variant = RoomCardVariant.audio,
        livestream = null,
        recording = null,
        coHostAvatars = const [];

  String get title {
    switch (variant) {
      case RoomCardVariant.liveVideo:
        final description = livestream?.description?.trim();
        if (description != null && description.isNotEmpty) return description;
        return hostName.isNotEmpty ? hostName : 'Live Class';
      case RoomCardVariant.recorded:
        return recording?.title ?? hostName;
      case RoomCardVariant.audio:
        return audioRoom?.roomName ?? 'Audio Room';
    }
  }

  String get hostName {
    switch (variant) {
      case RoomCardVariant.liveVideo:
        return livestream?.hostUser?.fullname ?? livestream?.hostUser?.username ?? '';
      case RoomCardVariant.recorded:
        return recording?.hostFullname ?? recording?.hostUsername ?? 'Host';
      case RoomCardVariant.audio:
        return audioRoom?.hostName ?? '';
    }
  }

  String? get hostPhotoUrl {
    switch (variant) {
      case RoomCardVariant.liveVideo:
        return livestream?.hostUser?.profile;
      case RoomCardVariant.recorded:
        return recording?.thumbnail ?? recording?.hostProfilePhoto;
      case RoomCardVariant.audio:
        return audioRoom?.hostPhoto;
    }
  }

  bool get isVerified {
    switch (variant) {
      case RoomCardVariant.liveVideo:
        return livestream?.hostUser?.isVerify == 1;
      case RoomCardVariant.recorded:
        return recording?.hostIsVerify == 1;
      case RoomCardVariant.audio:
        return false;
    }
  }

  String get categoryName {
    switch (variant) {
      case RoomCardVariant.liveVideo:
        return livestream?.categoryName ?? '';
      case RoomCardVariant.recorded:
        return recording?.categoryName ?? '';
      case RoomCardVariant.audio:
        return '';
    }
  }

  /// Watching count (video/recorded) or listening count (audio).
  int get subCount {
    switch (variant) {
      case RoomCardVariant.liveVideo:
        return livestream?.watchingCount ?? 0;
      case RoomCardVariant.recorded:
        return recording?.viewerCount ?? 0;
      case RoomCardVariant.audio:
        return audioRoom?.participantIds?.length ?? 0;
    }
  }

  int get sortTimestamp {
    switch (variant) {
      case RoomCardVariant.liveVideo:
        return livestream?.createdAt ?? 0;
      case RoomCardVariant.recorded:
        return DateTime.tryParse(recording?.createdAt ?? '')?.millisecondsSinceEpoch ?? 0;
      case RoomCardVariant.audio:
        return audioRoom?.createdAt ?? 0;
    }
  }

  /// Host's user id — used for the "Following" home filter. Recorded items
  /// have no live host to follow, so they're excluded from that filter.
  int? get hostUserId {
    switch (variant) {
      case RoomCardVariant.liveVideo:
        return livestream?.hostId;
      case RoomCardVariant.recorded:
        return recording?.userId;
      case RoomCardVariant.audio:
        return audioRoom?.hostId;
    }
  }

  /// Real PK-battle signal from the room's own type — not a guess.
  bool get isPkBattle =>
      variant == RoomCardVariant.liveVideo && livestream?.type == LivestreamType.battle;

  /// Category + hashtag text combined, used by the home "Love" filter chip
  /// to match rooms tagged with a romance/love hashtag or category.
  String get hashtagText {
    switch (variant) {
      case RoomCardVariant.liveVideo:
        return '${livestream?.categoryName ?? ''} ${livestream?.hashtag ?? ''}';
      case RoomCardVariant.recorded:
        return recording?.categoryName ?? '';
      case RoomCardVariant.audio:
        return audioRoom?.hashtag ?? '';
    }
  }
}
