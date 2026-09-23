class GiftProfitItem {
  final int? categoryId;
  final String? categoryName;
  final int? totalCoins;

  GiftProfitItem({
    this.categoryId,
    this.categoryName,
    this.totalCoins,
  });

  factory GiftProfitItem.fromJson(Map<String, dynamic> json) {
    return GiftProfitItem(
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      totalCoins: json['total_coins'],
    );
  }
}

class GiftProfitModel {
  bool? status;
  String? message;
  List<GiftProfitItem>? data;

  GiftProfitModel({this.status, this.message, this.data});

  GiftProfitModel.fromJson(dynamic json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = (json['data'] as List)
          .map((item) => GiftProfitItem.fromJson(item))
          .toList();
    }
  }
}
