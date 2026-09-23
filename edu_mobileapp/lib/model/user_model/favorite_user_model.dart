import 'package:geoedu/model/user_model/user_model.dart';

class FavoriteUserModel {
  FavoriteUserModel({bool? status, String? message, List<FavoriteUser>? data}) {
    _status = status;
    _message = message;
    _data = data;
  }

  FavoriteUserModel.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(FavoriteUser.fromJson(v));
      });
    }
  }

  bool? _status;
  String? _message;
  List<FavoriteUser>? _data;

  bool? get status => _status;

  String? get message => _message;

  List<FavoriteUser>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class FavoriteUser {
  FavoriteUser({
    int? id,
    int? fromUserId,
    int? toUserId,
    String? createdAt,
    String? updatedAt,
    User? favoriteUser,
  }) {
    _id = id;
    _fromUserId = fromUserId;
    _toUserId = toUserId;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _favoriteUser = favoriteUser;
  }

  FavoriteUser.fromJson(dynamic json) {
    _id = json['id'];
    _fromUserId = json['from_user_id'];
    _toUserId = json['to_user_id'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _favoriteUser = json['favorite_user'] != null
        ? User.fromJson(json['favorite_user'])
        : null;
  }

  int? _id;
  int? _fromUserId;
  int? _toUserId;
  String? _createdAt;
  String? _updatedAt;
  User? _favoriteUser;

  int? get id => _id;

  int? get fromUserId => _fromUserId;

  int? get toUserId => _toUserId;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  User? get favoriteUser => _favoriteUser;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['from_user_id'] = _fromUserId;
    map['to_user_id'] = _toUserId;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    if (_favoriteUser != null) {
      map['favorite_user'] = _favoriteUser?.toJson();
    }
    return map;
  }
}
