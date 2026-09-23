class AgentCommissionModel {
  bool? status;
  String? message;
  AgentCommissionData? data;

  AgentCommissionModel({this.status, this.message, this.data});

  AgentCommissionModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = AgentCommissionData.fromJson(json['data']);
    }
  }
}

class AgentCommissionData {
  num? totalCommission;
  num? paidCommission;
  num? balanceCommission;
  num? commissionRate;
  List<CommissionTransaction>? transactions;

  AgentCommissionData({this.totalCommission, this.paidCommission, this.balanceCommission, this.commissionRate, this.transactions});

  AgentCommissionData.fromJson(Map<String, dynamic> json) {
    totalCommission = json['total_commission'];
    paidCommission = json['paid_commission'];
    balanceCommission = json['balance_commission'];
    commissionRate = json['commission_rate'];
    if (json['transactions'] != null) {
      transactions = (json['transactions'] as List)
          .map((e) => CommissionTransaction.fromJson(e))
          .toList();
    }
  }
}

class CommissionTransaction {
  int? id;
  int? userId;
  String? fullname;
  String? username;
  String? profilePhoto;
  num? diamondAmount;
  num? commissionEarned;
  String? createdAt;

  CommissionTransaction({
    this.id,
    this.userId,
    this.fullname,
    this.username,
    this.profilePhoto,
    this.diamondAmount,
    this.commissionEarned,
    this.createdAt,
  });

  CommissionTransaction.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    fullname = json['fullname'];
    username = json['username'];
    profilePhoto = json['profile_photo'];
    diamondAmount = json['diamond_amount'];
    commissionEarned = json['commission_earned'];
    createdAt = json['created_at'];
  }
}
