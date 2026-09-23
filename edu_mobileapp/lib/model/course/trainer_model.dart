class TrainerListResponse {
  bool? status;
  String? message;
  List<Trainer>? data;

  TrainerListResponse({this.status, this.message, this.data});

  factory TrainerListResponse.fromJson(Map<String, dynamic> json) =>
      TrainerListResponse(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Trainer>.from(json["data"].map((x) => Trainer.fromJson(x))),
      );
}

class Trainer {
  int? id;
  String? name;
  String? photo;
  String? categoryName;
  double? avgRating;
  int? studentCount;

  Trainer({
    this.id,
    this.name,
    this.photo,
    this.categoryName,
    this.avgRating,
    this.studentCount,
  });

  factory Trainer.fromJson(Map<String, dynamic> json) => Trainer(
        id: json["id"],
        name: json["name"],
        photo: json["photo"],
        categoryName: json["category_name"],
        avgRating: (json["avg_rating"] as num?)?.toDouble(),
        studentCount: json["student_count"],
      );
}
