class BannerModel {
  bool? status;
  String? message;
  List<BannerData>? data;

  BannerModel({this.status, this.message, this.data});

  BannerModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = (json['data'] as List).map((e) => BannerData.fromJson(e)).toList();
    }
  }
}

class BannerData {
  int? id;
  String? type;
  String? image;
  String? imageUrl;

  BannerData({this.id, this.type, this.image, this.imageUrl});

  BannerData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    image = json['image'];
    imageUrl = json['image_url'];
  }
}
