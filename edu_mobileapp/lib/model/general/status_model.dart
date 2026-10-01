class StatusModel {
  StatusModel({
    bool? status,
    String? message,
    bool? alreadyRegistered,
    bool? notRegistered,
  }) {
    _status = status;
    _message = message;
    _alreadyRegistered = alreadyRegistered;
    _notRegistered = notRegistered;
  }

  StatusModel.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _alreadyRegistered = json['already_registered'] == true ||
        json['alreadyRegistered'] == true;
    _notRegistered = json['not_registered'] == true ||
        json['notRegistered'] == true;
  }

  bool? _status;
  String? _message;
  bool? _alreadyRegistered;
  bool? _notRegistered;

  bool? get status => _status;

  String? get message => _message;

  bool get alreadyRegistered => _alreadyRegistered ?? false;
  bool get notRegistered => _notRegistered ?? false;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    map['already_registered'] = _alreadyRegistered;
    map['not_registered'] = _notRegistered;
    return map;
  }
}
