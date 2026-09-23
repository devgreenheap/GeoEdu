import 'package:geoedu/model/general/settings_model.dart';

class LanguagesModel {
  bool? status;
  String? message;
  List<Language>? data;

  LanguagesModel({this.status, this.message, this.data});

  factory LanguagesModel.fromJson(Map<String, dynamic> json) =>
      LanguagesModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Language>.from(
                json["data"].map((x) => Language.fromJson(x))),
      );
}