class DiamondTransactionListModel {
  bool? status;
  String? message;
  List<DiamondTransactionModel>? data;

  DiamondTransactionListModel({this.status, this.message, this.data});

  factory DiamondTransactionListModel.fromJson(Map<String, dynamic> json) =>
      DiamondTransactionListModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<DiamondTransactionModel>.from(
                json["data"].map((x) => DiamondTransactionModel.fromJson(x))),
      );
}

class DiamondTransactionModel {
  final int? id;
  final String? title;
  final DateTime? dateTime;
  final String? date;
  final String? time;
  final String? transactionId;
  final String? paymentId;
  final int? diamonds;
  final double? amount;
  final String? currency;
  final String? status;
  final String? createdAt;

  DiamondTransactionModel({
    this.id,
    this.title,
    this.dateTime,
    this.transactionId,
    this.paymentId,
    this.diamonds,
    this.amount,
    this.currency,
    this.date,
    this.time,
    this.status,
    this.createdAt,
  });

  factory DiamondTransactionModel.fromJson(Map<String, dynamic> json) {
    // Parse created_at to derive date and time if not provided
    DateTime? parsedDate;
    String? derivedDate;
    String? derivedTime;
    final createdAtStr = json['created_at'];
    if (createdAtStr != null) {
      parsedDate = DateTime.tryParse(createdAtStr);
      if (parsedDate != null) {
        final local = parsedDate.toLocal();
        derivedDate =
            '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year.toString().substring(2)}';
        final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
        final amPm = local.hour >= 12 ? 'PM' : 'AM';
        derivedTime =
            '${hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} $amPm';
      }
    }

    // amount may come as String from API
    double? parsedAmount;
    if (json['amount'] != null) {
      parsedAmount = double.tryParse(json['amount'].toString());
    }

    return DiamondTransactionModel(
      id: json['id'],
      title: json['title'] ?? 'Diamond Purchased',
      dateTime: parsedDate,
      transactionId: json['transaction_id'] ?? json['transactionId'] ?? json['payment_id'],
      paymentId: json['payment_id'],
      diamonds: json['diamonds'],
      amount: parsedAmount,
      currency: json['currency'],
      date: json['date'] ?? derivedDate,
      time: json['time'] ?? derivedTime,
      status: json['status']?.toString(),
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime?.toIso8601String(),
      'transaction_id': transactionId,
      'payment_id': paymentId,
      'diamonds': diamonds,
      'amount': amount,
      'currency': currency,
      'date': date,
      'time': time,
      'status': status,
      'created_at': createdAt,
    };
  }
}
