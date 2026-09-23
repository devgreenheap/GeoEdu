enum AudioCommentType { text, joined, gift }

/// Real-time chat message for an audio room — mirrors the shape of the
/// video room's LivestreamComment closely enough to reuse the same visual
/// language (avatar/name/level, joined rows, gift rows), scaled down since
/// audio rooms don't have the request/co-host comment types video does.
class AudioComment {
  final int senderId;
  final String senderName;
  final String? senderPhoto;
  final int? senderLevel;
  final AudioCommentType type;
  final String? text;
  final String? giftName;
  final String? giftImage;
  final int? giftCoinPrice;
  final int timestamp;

  AudioComment({
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    this.senderLevel,
    required this.type,
    this.text,
    this.giftName,
    this.giftImage,
    this.giftCoinPrice,
    required this.timestamp,
  });

  factory AudioComment.fromJson(Map<String, dynamic> json) => AudioComment(
        senderId: json['sender_id'] ?? 0,
        senderName: json['sender_name'] ?? '',
        senderPhoto: json['sender_photo'],
        senderLevel: json['sender_level'],
        type: AudioCommentType.values.firstWhere(
            (t) => t.name == json['type'],
            orElse: () => AudioCommentType.text),
        text: json['text'],
        giftName: json['gift_name'],
        giftImage: json['gift_image'],
        giftCoinPrice: json['gift_coin_price'],
        timestamp: json['timestamp'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_photo': senderPhoto,
        'sender_level': senderLevel,
        'type': type.name,
        'text': text,
        'gift_name': giftName,
        'gift_image': giftImage,
        'gift_coin_price': giftCoinPrice,
        'timestamp': timestamp,
      };
}
