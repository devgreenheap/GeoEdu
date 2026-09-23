class EntryEffectResponseModel {
  bool? status;
  String? message;
  List<EntryEffectModel>? data;

  EntryEffectResponseModel({this.status, this.message, this.data});

  factory EntryEffectResponseModel.fromJson(Map<String, dynamic> json) {
    return EntryEffectResponseModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] == null
          ? null
          : (json['data'] as List)
              .map((e) => EntryEffectModel.fromJson(e))
              .toList(),
    );
  }
}

class EntryEffectModel {
  final int? id;
  final String image;
  final String title;
  final int currentPrice;
  final int originalPrice;
  final int discountPercent;
  final String duration;
  final String buttonText;
  final String videoPath;
  final String audio;
  final bool? isDefaultAudio;

  // Purchase/expiry fields (from fetchMyEntryEffects API)
  final int? entryEffectId;
  final DateTime? purchasedAt;
  final DateTime? expiresAt;
  final int? durationHours;
  final bool? isActive;

  EntryEffectModel({
    this.id,
    required this.image,
    required this.title,
    required this.currentPrice,
    required this.originalPrice,
    required this.discountPercent,
    required this.duration,
    required this.buttonText,
    required this.videoPath,
    this.audio = '',
    this.isDefaultAudio = false,
    this.entryEffectId,
    this.purchasedAt,
    this.expiresAt,
    this.durationHours,
    this.isActive,
  });

  factory EntryEffectModel.fromJson(Map<String, dynamic> json) {
    return EntryEffectModel(
      id: _toInt(json['id']),
      image: _toStr(json['image']),
      title: _toStr(json['title'] ?? json['name'] ?? 'Entry Effect'),
      currentPrice: _toInt(json['coin_price']) ?? 0,
      originalPrice: _toInt(json['original_price'] ?? json['coin_price']) ?? 0,
      discountPercent: _toInt(json['discount_percent']) ?? 0,
      duration: json['duration'] != null ? 'For ${json['duration']} hours' : '',
      buttonText: _toStr(json['button_text']).isEmpty ? 'Buy' : _toStr(json['button_text']),
      videoPath: _toStr(json['video_path'] ?? json['svga_url']),
      audio: _toStr(json['audio'] ?? json['audio_url']),
      isDefaultAudio: json['is_default_audio'] ?? false,
      entryEffectId: _toInt(json['entry_effect_id']),
      purchasedAt: _tryParseDate(json['purchased_at']),
      expiresAt: _tryParseDate(json['expires_at']),
      durationHours: _toInt(json['duration']),
      isActive: json['is_active'] is bool ? json['is_active'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'title': title,
      'currentPrice': currentPrice,
      'originalPrice': originalPrice,
      'discountPercent': discountPercent,
      'duration': duration,
      'buttonText': buttonText,
      'videoPath': videoPath,
      'audio': audio,
      'isDefaultAudio': isDefaultAudio,
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _toStr(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  double get calculatedDiscount =>
      ((originalPrice - currentPrice) / originalPrice) * 100;

  bool get isExpired =>
      (expiresAt != null && DateTime.now().isAfter(expiresAt!)) ||
      isActive == false;

  String get remainingTimeDisplay {
    if (expiresAt == null || isExpired) return 'Expired';
    final diff = expiresAt!.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m left';
    return '${minutes}m left';
  }
}
