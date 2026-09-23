class LiveAudioTeacherModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final int totalSeats;
  final bool isLive;
  final String buttonText;

  LiveAudioTeacherModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.totalSeats,
    required this.isLive,
    required this.buttonText,
  });

  factory LiveAudioTeacherModel.fromJson(Map<String, dynamic> json) {
    return LiveAudioTeacherModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      totalSeats: json['totalSeats'] ?? 0,
      isLive: json['isLive'] ?? false,
      buttonText: json['buttonText'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'totalSeats': totalSeats,
      'isLive': isLive,
      'buttonText': buttonText,
    };
  }
}
