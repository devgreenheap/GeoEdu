class StatusModel {
  StatusModel({
    bool? status,
    String? message,
    bool? alreadyRegistered,
  }) {
    _status = status;
    _message = message;
    _alreadyRegistered = alreadyRegistered;
  }

  StatusModel.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _alreadyRegistered = json['already_registered'] == true ||
        json['alreadyRegistered'] == true;
  }

  bool? _status;
  String? _message;
  bool? _alreadyRegistered;

  bool? get status => _status;

  String? get message => _message;

  bool get alreadyRegistered => _alreadyRegistered ?? false;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    map['already_registered'] = _alreadyRegistered;
    return map;
  }
}
