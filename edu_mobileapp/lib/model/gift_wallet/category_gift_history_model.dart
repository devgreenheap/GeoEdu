class CategoryGiftTransactionItem {
  final int? id;
  final int? giftId;
  final String? giftName;
  final String? giftImage;
  final int? categoryId;
  final String? categoryName;
  final int? senderId;
  final String? senderName;
  final String? senderUsername;
  final String? senderImage;
  final int? receiverId;
  final String? receiverName;
  final int? diamonds;
  final int? starsEarned;
  final String? createdAt;
  final String? date;
  final String? time;
  final String? relativeTime;

  CategoryGiftTransactionItem({
    this.id,
    this.giftId,
    this.giftName,
    this.giftImage,
    this.categoryId,
    this.categoryName,
    this.senderId,
    this.senderName,
    this.senderUsername,
    this.senderImage,
    this.receiverId,
    this.receiverName,
    this.diamonds,
    this.starsEarned,
    this.createdAt,
    this.date,
    this.time,
    this.relativeTime,
  });

  factory CategoryGiftTransactionItem.fromJson(Map<String, dynamic> json) {
    return CategoryGiftTransactionItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      giftId: json['gift_id'] is int
          ? json['gift_id']
          : int.tryParse('${json['gift_id']}'),
      giftName: json['gift_name']?.toString(),
      giftImage: json['gift_image']?.toString(),
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse('${json['category_id']}'),
      categoryName: json['category_name']?.toString(),
      senderId: json['sender_id'] is int
          ? json['sender_id']
          : int.tryParse('${json['sender_id']}'),
      senderName: json['sender_name']?.toString(),
      senderUsername: json['sender_username']?.toString(),
      senderImage: json['sender_image']?.toString(),
      receiverId: json['receiver_id'] is int
          ? json['receiver_id']
          : int.tryParse('${json['receiver_id']}'),
      receiverName: json['receiver_name']?.toString(),
      diamonds: json['diamonds'] is int
          ? json['diamonds']
          : int.tryParse('${json['diamonds']}'),
      starsEarned: json['stars_earned'] is int
          ? json['stars_earned']
          : int.tryParse('${json['stars_earned']}'),
      createdAt: json['created_at']?.toString(),
      date: json['date']?.toString(),
      time: json['time']?.toString(),
      relativeTime: json['relative_time']?.toString(),
    );
  }
}

class CategoryGiftHistoryData {
  final int? categoryId;
  final String? categoryName;
  final String? filter;
  final int? totalStars;
  final int? totalDiamonds;
  final int? totalTransactions;
  final List<CategoryGiftTransactionItem>? transactions;

  CategoryGiftHistoryData({
    this.categoryId,
    this.categoryName,
    this.filter,
    this.totalStars,
    this.totalDiamonds,
    this.totalTransactions,
    this.transactions,
  });

  factory CategoryGiftHistoryData.fromJson(Map<String, dynamic> json) {
    return CategoryGiftHistoryData(
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse('${json['category_id']}'),
      categoryName: json['category_name']?.toString(),
      filter: json['filter']?.toString(),
      totalStars: json['total_stars'] is int
          ? json['total_stars']
          : int.tryParse('${json['total_stars']}'),
      totalDiamonds: json['total_diamonds'] is int
          ? json['total_diamonds']
          : int.tryParse('${json['total_diamonds']}'),
      totalTransactions: json['total_transactions'] is int
          ? json['total_transactions']
          : int.tryParse('${json['total_transactions']}'),
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
              .map((e) => CategoryGiftTransactionItem.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
    );
  }
}

class CategoryGiftHistoryModel {
  bool? status;
  String? message;
  CategoryGiftHistoryData? data;

  CategoryGiftHistoryModel({this.status, this.message, this.data});

  CategoryGiftHistoryModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message']?.toString();
    if (json['data'] != null && json['data'] is Map) {
      data = CategoryGiftHistoryData.fromJson(
          Map<String, dynamic>.from(json['data'] as Map));
    }
  }
}
