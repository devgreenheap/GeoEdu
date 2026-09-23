class DiamondSpendHistoryListModel {
  bool? status;
  String? message;
  List<DiamondSpendHistoryModel>? data;

  DiamondSpendHistoryListModel({this.status, this.message, this.data});

  factory DiamondSpendHistoryListModel.fromJson(Map<String, dynamic> json) =>
      DiamondSpendHistoryListModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<DiamondSpendHistoryModel>.from(
                json["data"].map((x) => DiamondSpendHistoryModel.fromJson(x))),
      );
}

class DiamondSpendHistoryModel {
  final int? id;
  final String? title;
  final String? purpose;
  final String? note;
  final String? userName;
  final String? date;
  final String? time;
  final String? transactionId;
  final int? diamonds;
  final String? createdAt;

  DiamondSpendHistoryModel({
    this.id,
    this.title,
    this.purpose,
    this.note,
    this.userName,
    this.date,
    this.time,
    this.transactionId,
    this.diamonds,
    this.createdAt,
  });

  factory DiamondSpendHistoryModel.fromJson(Map<String, dynamic> json) {
    // Parse created_at to derive date and time
    String? derivedDate;
    String? derivedTime;
    final createdAtStr = json['created_at'];
    if (createdAtStr != null) {
      final parsedDate = DateTime.tryParse(createdAtStr);
      if (parsedDate != null) {
        final local = parsedDate.toLocal();
        derivedDate =
            '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year.toString().substring(2)}';
        final hour = local.hour > 12
            ? local.hour - 12
            : (local.hour == 0 ? 12 : local.hour);
        final amPm = local.hour >= 12 ? 'PM' : 'AM';
        derivedTime =
            '${hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} $amPm';
      }
    }

    // Build display title from note or purpose
    final displayTitle = json['note'] ?? json['title'] ?? _formatPurpose(json['purpose']);

    return DiamondSpendHistoryModel(
      id: json['id'],
      title: displayTitle,
      purpose: json['purpose'],
      note: json['note'],
      userName: json['user_name'] ?? json['userName'],
      date: json['date'] ?? derivedDate,
      time: json['time'] ?? derivedTime,
      transactionId: json['transaction_id']?.toString(),
      diamonds: json['diamonds'],
      createdAt: json['created_at'],
    );
  }

  /// Converts "entry_effect_purchase" → "Entry Effect Purchase"
  static String _formatPurpose(String? purpose) {
    if (purpose == null || purpose.isEmpty) return 'Diamond Spent';
    return purpose
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'purpose': purpose,
      'note': note,
      'user_name': userName,
      'date': date,
      'time': time,
      'transaction_id': transactionId,
      'diamonds': diamonds,
      'created_at': createdAt,
    };
  }
}
