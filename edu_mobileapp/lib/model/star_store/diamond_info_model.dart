class DiamondInfoModel {
  DiamondInfoModel({
    int? id,
    int? pointNo,
    String? information,
  }) {
    _id = id;
    _pointNo = pointNo;
    _information = information;
  }

  DiamondInfoModel.fromJson(dynamic json) {
    _id = json['id'];
    _pointNo = json['point_no'];
    _information = json['information'];
  }

  int? _id;
  int? _pointNo;
  String? _information;

  int? get id => _id;
  int? get pointNo => _pointNo;
  String? get information => _information;
}

class DiamondInfoResponseModel {
  DiamondInfoResponseModel({
    bool? status,
    String? message,
    List<DiamondInfoModel>? data,
  }) {
    _status = status;
    _message = message;
    _data = data;
  }

  DiamondInfoResponseModel.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(DiamondInfoModel.fromJson(v));
      });
    }
  }

  bool? _status;
  String? _message;
  List<DiamondInfoModel>? _data;

  bool? get status => _status;
  String? get message => _message;
  List<DiamondInfoModel>? get data => _data;
}
