class DiamondWalletModel {
  bool? status;
  String? message;
  DiamondWallet? data;

  DiamondWalletModel({this.status, this.message, this.data});

  factory DiamondWalletModel.fromJson(Map<String, dynamic> json) =>
      DiamondWalletModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : json["data"] is Map<String, dynamic>
                ? DiamondWallet.fromJson(json["data"])
                : null,
      );
}

class DiamondWallet {
  int? diamondBalance;
  int? totalPurchased;
  int? totalSpent;

  DiamondWallet({this.diamondBalance, this.totalPurchased, this.totalSpent});

  factory DiamondWallet.fromJson(Map<String, dynamic> json) => DiamondWallet(
        diamondBalance: _toInt(json["diamond_wallet"] ?? json["diamond_balance"]),
        totalPurchased: _toInt(json["diamond_purchased_lifetime"] ?? json["total_purchased"]),
        totalSpent: _toInt(json["diamond_spent_lifetime"] ?? json["total_spent"]),
      );

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
