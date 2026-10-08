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
  String? category;
  String? question;
  String? answer;

  DiamondFaq({this.id, this.category, this.question, this.answer});

  factory DiamondFaq.fromJson(Map<String, dynamic> json) => DiamondFaq(
        id: json["id"],
        category: json["category"],
        question: json["question"],
        answer: json["answer"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "category": category,
        "question": question,
        "answer": answer,
      };
}
