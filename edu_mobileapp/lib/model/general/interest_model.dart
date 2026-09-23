class InterestsModel {
  bool? status;
  String? message;
  List<Interest>? data;

  InterestsModel({this.status, this.message, this.data});

  factory InterestsModel.fromJson(Map<String, dynamic> json) =>
      InterestsModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Interest>.from(
                json["data"].map((x) => Interest.fromJson(x))),
      );
}

class Interest {
  int? id;
  String? name;

  Interest({this.id, this.name});

  factory Interest.fromJson(Map<String, dynamic> json) => Interest(
        id: json["id"],
        name: json["name"],
      );
}
