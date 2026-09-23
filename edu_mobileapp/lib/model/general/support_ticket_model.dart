class SupportTicketModel {
  bool? status;
  String? message;
  List<SupportTicket>? data;

  SupportTicketModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = (json['data'] as List)
          .map((e) => SupportTicket.fromJson(e))
          .toList();
    }
  }
}

class SupportTicket {
  int? id;
  int? userId;
  String? subject;
  String? message;
  String? adminReply;
  String? status;
  String? createdAt;
  String? updatedAt;

  SupportTicket.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    subject = json['subject'];
    message = json['message'];
    adminReply = json['admin_reply'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
}
