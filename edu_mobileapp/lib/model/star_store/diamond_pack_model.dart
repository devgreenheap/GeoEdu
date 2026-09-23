class DiamondPackResponseModel {
  bool? status;
  String? message;
  List<DiamondPackModel>? data;

  DiamondPackResponseModel({this.status, this.message, this.data});

  factory DiamondPackResponseModel.fromJson(Map<String, dynamic> json) =>
      DiamondPackResponseModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<DiamondPackModel>.from(
                json["data"].map((x) => DiamondPackModel.fromJson(x))),
      );
}

class DiamondPackModel {
  final int? id;
  final String? image;
  final int? diamonds;
  final double? originalPrice;
  final double? discountedPrice;
  final String? buttonText;
  final int? status;

  DiamondPackModel({
    this.id,
    this.image,
    this.diamonds,
    this.originalPrice,
    this.discountedPrice,
    this.buttonText,
    this.status,
  });

  factory DiamondPackModel.fromJson(Map<String, dynamic> json) {
    return DiamondPackModel(
      id: json['id'],
      image: json['image'],
      diamonds: json['diamonds'],
      originalPrice: (json['original_price'] ?? json['originalPrice'])?.toDouble(),
      discountedPrice: (json['discounted_price'] ?? json['discountedPrice'])?.toDouble(),
      buttonText: json['button_text'] ?? json['buttonText'] ?? 'Buy For',
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'diamonds': diamonds,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'button_text': buttonText,
      'status': status,
    };
  }
}