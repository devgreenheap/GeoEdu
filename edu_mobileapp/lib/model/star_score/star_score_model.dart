class StarScoreModel {
  final String title;
  final String time;
  final String date;
  final String transactionId;
  final int points;
  final String rewardIcon;

  StarScoreModel({
    required this.title,
    required this.time,
    required this.date,
    required this.transactionId,
    required this.points,
    required this.rewardIcon,
  });

  factory StarScoreModel.fromJson(Map<String, dynamic> json) {
    return StarScoreModel(
      title: json['title'],
      time: json['time'],
      date: json['date'],
      transactionId: json['transactionId'],
      points: json['points'],
      rewardIcon: json['rewardIcon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': time,
      'date': date,
      'transactionId': transactionId,
      'points': points,
      'rewardIcon': rewardIcon,
    };
  }
}


class StarTransactionItem {
  final int? id;
  final String? type;
  final String? source;
  final int? stars;
  final String? title;
  final String? description;
  final int? referenceId;
  final int? fromUserId;
  final String? createdAt;

  StarTransactionItem({
    this.id,
    this.type,
    this.source,
    this.stars,
    this.title,
    this.description,
    this.referenceId,
    this.fromUserId,
    this.createdAt,
  });

  factory StarTransactionItem.fromJson(Map<String, dynamic> json) {
    return StarTransactionItem(
      id: json['id'],
      type: json['type'],
      source: json['source'],
      stars: json['stars'],
      title: json['title'],
      description: json['description'],
      referenceId: json['reference_id'],
      fromUserId: json['from_user_id'],
      createdAt: json['created_at'],
    );
  }
}

class StarScoreResponseModel {
  bool? status;
  String? message;
  int? starWallet;
  int? starCollectedLifetime;
  int? starGiftedLifetime;
  List<StarTransactionItem>? transactions;
  Map<String, List<StarTransactionItem>>? groupedTransactions;
  Map<String, int>? groupTotals;
  int? nextLastItemId;
  bool? hasMore;

  StarScoreResponseModel({
    this.status,
    this.message,
    this.starWallet,
    this.starCollectedLifetime,
    this.starGiftedLifetime,
    this.transactions,
    this.groupedTransactions,
    this.groupTotals,
    this.nextLastItemId,
    this.hasMore,
  });

  StarScoreResponseModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    final data = json['data'];
    if (data != null) {
      starWallet = data['star_wallet'];
      starCollectedLifetime = data['star_collected_lifetime'];
      starGiftedLifetime = data['star_gifted_lifetime'];
      nextLastItemId = data['next_last_item_id'];
      hasMore = data['has_more'];

      if (data['transactions'] != null) {
        transactions = (data['transactions'] as List)
            .map((v) => StarTransactionItem.fromJson(v))
            .toList();
      }

      if (data['grouped_transactions'] != null) {
        groupedTransactions = {};
        (data['grouped_transactions'] as Map<String, dynamic>)
            .forEach((key, value) {
          groupedTransactions![key] = (value as List)
              .map((v) => StarTransactionItem.fromJson(v))
              .toList();
        });
      }

      if (data['group_totals'] != null) {
        groupTotals = {};
        (data['group_totals'] as Map<String, dynamic>).forEach((key, value) {
          groupTotals![key] = value is int ? value : (value as num).toInt();
        });
      }
    }
  }
}
