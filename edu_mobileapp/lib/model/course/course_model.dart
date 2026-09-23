class CourseListResponse {
  bool? status;
  String? message;
  List<Course>? data;

  CourseListResponse({this.status, this.message, this.data});

  factory CourseListResponse.fromJson(Map<String, dynamic> json) =>
      CourseListResponse(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Course>.from(json["data"].map((x) => Course.fromJson(x))),
      );
}

class CourseDetailResponse {
  bool? status;
  String? message;
  Course? data;

  CourseDetailResponse({this.status, this.message, this.data});

  factory CourseDetailResponse.fromJson(Map<String, dynamic> json) =>
      CourseDetailResponse(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null ? null : Course.fromJson(json["data"]),
      );
}

class Course {
  int? id;
  String? title;
  String? description;
  String? thumbnail;
  int? trainerId;
  String? trainerName;
  String? trainerPhoto;
  String? categoryName;
  String? level;
  int? lessonCount;
  int? enrolledCount;
  double? avgRating;
  int? ratingsCount;
  int? progressPercent;
  List<CourseLesson>? lessons;

  Course({
    this.id,
    this.title,
    this.description,
    this.thumbnail,
    this.trainerId,
    this.trainerName,
    this.trainerPhoto,
    this.categoryName,
    this.level,
    this.lessonCount,
    this.enrolledCount,
    this.avgRating,
    this.ratingsCount,
    this.progressPercent,
    this.lessons,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json["id"],
        title: json["title"],
        description: json["description"],
        thumbnail: json["thumbnail"],
        trainerId: json["trainer_id"],
        trainerName: json["trainer_name"],
        trainerPhoto: json["trainer_photo"],
        categoryName: json["category_name"],
        level: json["level"],
        lessonCount: json["lesson_count"],
        enrolledCount: json["enrolled_count"],
        avgRating: (json["avg_rating"] as num?)?.toDouble(),
        ratingsCount: json["ratings_count"],
        progressPercent: json["progress_percent"],
        lessons: json["lessons"] == null
            ? null
            : List<CourseLesson>.from(
                json["lessons"].map((x) => CourseLesson.fromJson(x))),
      );
}

class CourseLesson {
  int? id;
  String? title;
  String? videoUrl;
  int? durationSeconds;
  int? sortOrder;
  bool? isCompleted;

  CourseLesson({
    this.id,
    this.title,
    this.videoUrl,
    this.durationSeconds,
    this.sortOrder,
    this.isCompleted,
  });

  factory CourseLesson.fromJson(Map<String, dynamic> json) => CourseLesson(
        id: json["id"],
        title: json["title"],
        videoUrl: json["video_url"],
        durationSeconds: json["duration_seconds"],
        sortOrder: json["sort_order"],
        isCompleted: json["is_completed"],
      );
}
