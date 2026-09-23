class CountryStateModel {
  bool? status;
  String? message;
  List<CountryData>? data;

  CountryStateModel({this.status, this.message, this.data});

  factory CountryStateModel.fromJson(Map<String, dynamic> json) =>
      CountryStateModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<CountryData>.from(
                json["data"].map((x) => CountryData.fromJson(x))),
      );
}

class CountryData {
  int? id;
  String? name;
  List<StateData>? states;

  CountryData({this.id, this.name, this.states});

  factory CountryData.fromJson(Map<String, dynamic> json) => CountryData(
        id: json["id"],
        name: json["name"],
        states: json["states"] == null
            ? []
            : List<StateData>.from(
                json["states"].map((x) => StateData.fromJson(x))),
      );
}

class StateData {
  int? id;
  int? countryId;
  String? name;

  StateData({this.id, this.countryId, this.name});

  factory StateData.fromJson(Map<String, dynamic> json) => StateData(
        id: json["id"],
        countryId: json["country_id"],
        name: json["name"],
      );
}
