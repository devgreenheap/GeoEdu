class CityModel {
  bool? status;
  String? message;
  List<CityData>? data;

  CityModel({this.status, this.message, this.data});

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<CityData>.from(json["data"].map((x) => CityData.fromJson(x))),
      );
}

class CityData {
  int? id;
  int? stateId;
  String? name;

  CityData({this.id, this.stateId, this.name});

  factory CityData.fromJson(Map<String, dynamic> json) => CityData(
        id: json["id"],
        stateId: json["state_id"],
        name: json["name"],
      );
}
