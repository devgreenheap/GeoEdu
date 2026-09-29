import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/model/general/settings_model.dart';

class EntryEffect {
  final int id;
  final int userId;
  final String username;
  final String effectType;
  final String assetUrl;
  final int timestamp;
  final String effectName;
  final String audio;

  EntryEffect({
    required this.id,
    required this.userId,
    required this.username,
    required this.effectType,
    required this.assetUrl,
    required this.timestamp,
    required this.effectName,
    required this.audio,
  });

  factory EntryEffect.fromJson(Map<String, dynamic> json) {
    return EntryEffect(
      id: json['id'],
      userId: json['userId'],
      username: json['username'],
      effectType: json['effectType'],
      assetUrl: json['asset_url'],
      timestamp: json['timestamp'],
      effectName: json['effect_name'],
      audio: json['audio'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id' : id,
    'userId': userId,
    'username': username,
    'effectType': effectType,
    'image': assetUrl,
    'timestamp': timestamp,
    'effect_name' : effectName,
    'audio' : audio
  };
}

class GiftEffect {
  final int userId;
  final String username;
  final String giftName;
  final String assetUrl;
  final String? thumbnailUrl;
  final String? audio;
  final String? senderPhoto;
  final int timestamp;
  final int? coinPrice;

  GiftEffect({
    required this.userId,
    required this.username,
    required this.giftName,
    required this.assetUrl,
    this.thumbnailUrl,
    this.audio,
    this.senderPhoto,
    required this.timestamp,
    this.coinPrice,
  });

  factory GiftEffect.fromJson(Map<String, dynamic> json) {
    int parsedUserId = 0;
    if (json['userId'] is int) {
      parsedUserId = json['userId'];
    } else if (json['userId'] != null) {
      parsedUserId = int.tryParse(json['userId'].toString()) ?? 0;
    }

    int parsedTimestamp = DateTime.now().millisecondsSinceEpoch;
    if (json['timestamp'] is int) {
      parsedTimestamp = json['timestamp'];
    } else if (json['timestamp'] != null) {
      parsedTimestamp =
          int.tryParse(json['timestamp'].toString()) ?? parsedTimestamp;
    }

    int? parsedCoinPrice;
    if (json['coin_price'] is int) {
      parsedCoinPrice = json['coin_price'];
    } else if (json['coin_price'] != null) {
      parsedCoinPrice = int.tryParse(json['coin_price'].toString());
    }

    final giftName = json['giftName']?.toString() ?? 'Gift';
    final int? giftId = json['gift_id'] != null
        ? int.tryParse(json['gift_id'].toString())
        : (json['giftId'] != null
            ? int.tryParse(json['giftId'].toString())
            : null);

    final settings = SessionManager.instance.getSettings();
    final serverGifts = settings?.availableGifts ?? settings?.gifts ?? [];
    Gift? matched;
    if (giftId != null && giftId > 0) {
      matched = serverGifts.firstWhereOrNull((g) => g.id == giftId);
    }
    if (matched == null && giftName.isNotEmpty && giftName != 'Gift') {
      matched = serverGifts.firstWhereOrNull((g) =>
          g.displayName.toLowerCase() == giftName.toLowerCase() ||
          (g.title != null &&
              g.title!.toLowerCase().trim() == giftName.toLowerCase().trim()));
    }

    String thumbnailUrl = json['thumbnail_url']?.toString().trim() ?? '';
    if (thumbnailUrl.isEmpty && matched != null && (matched.image?.isNotEmpty ?? false)) {
      thumbnailUrl = matched.image!;
    }
    if (thumbnailUrl.isNotEmpty &&
        !thumbnailUrl.startsWith('http://') &&
        !thumbnailUrl.startsWith('https://') &&
        !thumbnailUrl.startsWith('assets/')) {
      thumbnailUrl = thumbnailUrl.addBaseURL();
    }

    String assetUrl = json['asset_url']?.toString().trim() ?? '';
    if (assetUrl.isEmpty || assetUrl == 'assets/svg_icons/Pen Animation.svg') {
      if (matched != null && matched.effectiveAssetUrl.isNotEmpty) {
        assetUrl = matched.effectiveAssetUrl;
      }
    }
    if (assetUrl.isEmpty && thumbnailUrl.isNotEmpty) {
      assetUrl = thumbnailUrl;
    }

    if (assetUrl.isNotEmpty &&
        !assetUrl.startsWith('http://') &&
        !assetUrl.startsWith('https://') &&
        !assetUrl.startsWith('assets/')) {
      assetUrl = assetUrl.addBaseURL();
    }

    if (assetUrl.isEmpty) {
      assetUrl = thumbnailUrl.isNotEmpty ? thumbnailUrl : 'assets/svg_icons/Pen Animation.svg';
    }

    // Resolve audio: first priority is what's passed if valid remote/asset audio,
    // otherwise lookup the actual gift uploaded in admin
    String audio = json['audio']?.toString().trim() ?? '';
    if (audio.isEmpty || audio == 'assets/images/fairy-sparkle.mp3') {
      if (matched != null && matched.effectiveSoundUrl.isNotEmpty) {
        audio = matched.effectiveSoundUrl;
      } else if (giftName.toLowerCase().trim() == 'pen') {
        audio = Gift.penGift.effectiveSoundUrl;
      }
    }

    if (audio.isNotEmpty) {
      audio = audio.addBaseURL();
    } else {
      audio = 'assets/images/fairy-sparkle.mp3';
    }

    return GiftEffect(
      userId: parsedUserId,
      username: json['username']?.toString() ?? '',
      giftName: giftName,
      assetUrl: assetUrl,
      thumbnailUrl: thumbnailUrl.isNotEmpty ? thumbnailUrl : null,
      audio: audio,
      coinPrice: parsedCoinPrice,
      senderPhoto: json['senderPhoto']?.toString(),
      timestamp: parsedTimestamp,
    );
  }

  bool get isSvga => assetUrl.toLowerCase().contains('.svga');
}