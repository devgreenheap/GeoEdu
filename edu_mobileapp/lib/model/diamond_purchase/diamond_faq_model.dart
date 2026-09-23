class DiamondFaqModel {
  bool? status;
  String? message;
  List<DiamondFaq>? data;

  DiamondFaqModel({this.status, this.message, this.data});

  factory DiamondFaqModel.fromJson(Map<String, dynamic> json) =>
      DiamondFaqModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<DiamondFaq>.from(
                json["data"].map((x) => DiamondFaq.fromJson(x))),
      );
}

class DiamondFaq {
  int? id;
  String? question;
  String? answer;

  DiamondFaq({this.id, this.question, this.answer});

  factory DiamondFaq.fromJson(Map<String, dynamic> json) => DiamondFaq(
        id: json["id"],
        question: json["question"],
        answer: json["answer"],
      );
}
