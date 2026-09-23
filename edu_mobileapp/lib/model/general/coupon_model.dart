class CouponsModel {
  bool? status;
  String? message;
  List<Coupon>? data;

  CouponsModel({this.status, this.message, this.data});

  CouponsModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data =
          (json['data'] as List).map((e) => Coupon.fromJson(e)).toList();
    }
  }
}

class Coupon {
  int? id;
  String? code;
  String? type;
  num? value;
  String? expiryDate;
  int? maxUses;
  int? usedCount;
  int? isActive;

  Coupon({
    this.id,
    this.code,
    this.type,
    this.value,
    this.expiryDate,
    this.maxUses,
    this.usedCount,
    this.isActive,
  });

  Coupon.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    type = json['type'];
    value = json['value'];
    expiryDate = json['expiry_date'];
    maxUses = json['max_uses'];
    usedCount = json['used_count'];
    isActive = json['is_active'];
  }

  String get displayValue {
    if (type == 'percentage') return '${value ?? 0}%';
    return '${value ?? 0}';
  }
}
