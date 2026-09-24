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
  final String? audio;
  final String? senderPhoto;
  final int timestamp;
  final int? coinPrice;

  GiftEffect({
    required this.userId,
    required this.username,
    required this.giftName,
    required this.assetUrl,
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

    String assetUrl = json['asset_url']?.toString() ?? '';
    if (assetUrl.isEmpty) {
      assetUrl = 'assets/svg_icons/Pen Animation.svg';
    }

    final giftName = json['giftName']?.toString() ?? 'Gift';
    final int? giftId = json['gift_id'] != null
        ? int.tryParse(json['gift_id'].toString())
        : (json['giftId'] != null
            ? int.tryParse(json['giftId'].toString())
            : null);

    // Resolve audio: first priority is what's passed if valid remote/asset audio,
    // otherwise lookup the actual gift uploaded in admin
    String audio = json['audio']?.toString().trim() ?? '';
    if (audio.isEmpty || audio == 'assets/images/fairy-sparkle.mp3') {
      final serverGifts =
          SessionManager.instance.getSettings()?.availableGifts ?? [];
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
      if (matched != null && matched.effectiveSoundUrl.isNotEmpty) {
        audio = matched.effectiveSoundUrl;
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
      audio: audio,
      coinPrice: parsedCoinPrice,
      senderPhoto: json['senderPhoto']?.toString(),
      timestamp: parsedTimestamp,
    );
  }

  bool get isSvga => assetUrl.toLowerCase().endsWith('.svga');
}