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
  final String? orderId;
  final int? diamonds;
  final double? amount;
  final double? originalPrice;
  final double? discount;
  final String? currency;
  final String? status;
  final String? createdAt;
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final String? paymentMode;
  final String? placeOfSupply;

  DiamondTransactionModel({
    this.id,
    this.title,
    this.dateTime,
    this.transactionId,
    this.paymentId,
    this.orderId,
    this.diamonds,
    this.amount,
    this.originalPrice,
    this.discount,
    this.currency,
    this.date,
    this.time,
    this.status,
    this.createdAt,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.paymentMode,
    this.placeOfSupply,
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

    double? parsedOrigPrice;
    if (json['original_price'] != null) {
      parsedOrigPrice = double.tryParse(json['original_price'].toString());
    } else if (parsedAmount != null) {
      parsedOrigPrice = parsedAmount;
    }

    double? parsedDiscount;
    if (json['discount'] != null) {
      parsedDiscount = double.tryParse(json['discount'].toString());
    } else if (parsedOrigPrice != null && parsedAmount != null && parsedOrigPrice > parsedAmount) {
      parsedDiscount = parsedOrigPrice - parsedAmount;
    } else {
      parsedDiscount = 0.0;
    }

    return DiamondTransactionModel(
      id: json['id'],
      title: json['title'] ?? 'Diamond Purchased',
      dateTime: parsedDate,
      transactionId: json['transaction_id'] ?? json['transactionId'] ?? json['payment_id'],
      paymentId: json['payment_id'],
      orderId: json['order_id'],
      diamonds: json['diamonds'],
      amount: parsedAmount,
      originalPrice: parsedOrigPrice,
      discount: parsedDiscount,
      currency: json['currency'] ?? '₹',
      date: json['date'] ?? derivedDate,
      time: json['time'] ?? derivedTime,
      status: json['status']?.toString(),
      createdAt: json['created_at'],
      userName: json['user_name'] ?? json['userName'],
      userPhone: json['user_phone'],
      userEmail: json['user_email'],
      paymentMode: json['payment_mode'] ?? 'UPI',
      placeOfSupply: json['place_of_supply'] ?? 'Tamil Nadu, India',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime?.toIso8601String(),
      'transaction_id': transactionId,
      'payment_id': paymentId,
      'order_id': orderId,
      'diamonds': diamonds,
      'amount': amount,
      'original_price': originalPrice,
      'discount': discount,
      'currency': currency,
      'date': date,
      'time': time,
      'status': status,
      'created_at': createdAt,
      'user_name': userName,
      'user_phone': userPhone,
      'user_email': userEmail,
      'payment_mode': paymentMode,
      'place_of_supply': placeOfSupply,
    };
  }
}
