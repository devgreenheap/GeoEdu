import 'package:geoedu/common/extensions/string_extension.dart';

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
    final rawImage = _toStr(json['image'] ?? json['thumbnail'] ?? json['asset_url'] ?? json['video_path']);
    final entryEffectId = _toInt(json['entry_effect_id']);
    final id = _toInt(json['id']);

    String resolvedImage = rawImage;
    if (resolvedImage.isNotEmpty && !resolvedImage.startsWith('http') && !resolvedImage.startsWith('assets/')) {
      resolvedImage = resolvedImage.addBaseURL();
    }
    if (resolvedImage.isEmpty) {
      final effId = entryEffectId ?? id;
      if (effId != null && effId >= 1 && effId <= 9) {
        resolvedImage = 'assets/images/animation-$effId.svga';
      }
    }

    final rawTitle = _toStr(json['title'] ?? json['name'] ?? json['effect_name']);
    final title = rawTitle.isNotEmpty ? rawTitle : 'Entry Effect';

    final durHours = _toInt(json['duration']);
    final durationStr = durHours != null && durHours > 0
        ? '$durHours hours'
        : (json['duration'] != null ? '${json['duration']}' : '');

    return EntryEffectModel(
      id: id,
      image: resolvedImage,
      title: title,
      currentPrice: _toInt(json['coin_price']) ?? 0,
      originalPrice: _toInt(json['original_price'] ?? json['coin_price']) ?? 0,
      discountPercent: _toInt(json['discount_percent']) ?? 0,
      duration: durationStr,
      buttonText: _toStr(json['button_text']).isEmpty ? 'Buy' : _toStr(json['button_text']),
      videoPath: _toStr(json['video_path'] ?? json['svga_url'] ?? resolvedImage),
      audio: _toStr(json['audio'] ?? json['audio_url']),
      isDefaultAudio: json['is_default_audio'] ?? false,
      entryEffectId: entryEffectId,
      purchasedAt: _tryParseDate(json['purchased_at']),
      expiresAt: _tryParseDate(json['expires_at']),
      durationHours: durHours,
      isActive: json['is_active'] is bool
          ? json['is_active']
          : (json['is_active'] != null ? json['is_active'] == 1 || json['is_active'] == '1' : null),
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
