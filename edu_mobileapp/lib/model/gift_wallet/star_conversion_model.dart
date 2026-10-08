class StarConversionModel {
  bool? status;
  String? message;
  List<StarConversionItem>? data;

  StarConversionModel({this.status, this.message, this.data});

  StarConversionModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <StarConversionItem>[];
      json['data'].forEach((v) {
        data!.add(StarConversionItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class StarConversionItem {
  int? id;
  String? requestNumber;
  int? categoryId;
  String? categoryName;
  String? payoutMethod;
  String? accountHolderName;
  String? accountNumber;
  String? ifscCode;
  String? phoneNumber;
  String? upiNumber;
  String? upiId;
  int? coins;
  num? coinValue;
  num? amount;
  num? paidAmount;
  int? status;
  String? statusText;
  String? transactionId;
  String? paymentDate;
  String? paymentTime;
  String? adminNote;
  String? currency;
  String? createdAt;

  StarConversionItem({
    this.id,
    this.requestNumber,
    this.categoryId,
    this.categoryName,
    this.payoutMethod,
    this.accountHolderName,
    this.accountNumber,
    this.ifscCode,
    this.phoneNumber,
    this.upiNumber,
    this.upiId,
    this.coins,
    this.coinValue,
    this.amount,
    this.paidAmount,
    this.status,
    this.statusText,
    this.transactionId,
    this.paymentDate,
    this.paymentTime,
    this.adminNote,
    this.currency,
    this.createdAt,
  });

  StarConversionItem.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    requestNumber = json['request_number']?.toString();
    categoryId = json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id']?.toString() ?? '0');
    categoryName = json['category_name']?.toString() ?? 'All';
    payoutMethod = json['payout_method']?.toString() ?? 'Bank Transfer';
    accountHolderName = json['account_holder_name']?.toString();
    accountNumber = json['account_number']?.toString();
    ifscCode = json['ifsc_code']?.toString();
    phoneNumber = json['phone_number']?.toString();
    upiNumber = json['upi_number']?.toString();
    upiId = json['upi_id']?.toString();
    coins = json['coins'] is int ? json['coins'] : int.tryParse(json['coins']?.toString() ?? '0');
    coinValue = json['coin_value'] is num ? json['coin_value'] : num.tryParse(json['coin_value']?.toString() ?? '1');
    amount = json['amount'] is num ? json['amount'] : num.tryParse(json['amount']?.toString() ?? '0');
    paidAmount = json['paid_amount'] is num ? json['paid_amount'] : num.tryParse(json['paid_amount']?.toString() ?? '0');
    status = json['status'] is int ? json['status'] : int.tryParse(json['status']?.toString() ?? '0');
    statusText = json['status_text']?.toString() ?? 'Pending';
    transactionId = json['transaction_id']?.toString();
    paymentDate = json['payment_date']?.toString();
    paymentTime = json['payment_time']?.toString();
    adminNote = json['admin_note']?.toString();
    currency = json['currency']?.toString() ?? '₹';
    createdAt = json['created_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_number': requestNumber,
      'category_id': categoryId,
      'category_name': categoryName,
      'payout_method': payoutMethod,
      'account_holder_name': accountHolderName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'phone_number': phoneNumber,
      'upi_number': upiNumber,
      'upi_id': upiId,
      'coins': coins,
      'coin_value': coinValue,
      'amount': amount,
      'paid_amount': paidAmount,
      'status': status,
      'status_text': statusText,
      'transaction_id': transactionId,
      'payment_date': paymentDate,
      'payment_time': paymentTime,
      'admin_note': adminNote,
      'currency': currency,
      'created_at': createdAt,
    };
  }

  bool get isPaid => status == 1;
  bool get isPending => status == 0;
  bool get isRejected => status == 2;
}
