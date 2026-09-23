import 'package:geoedu/common/service/api/api_service.dart';
import 'package:geoedu/common/service/utils/web_service.dart';
import 'package:geoedu/model/course/course_model.dart';
import 'package:geoedu/model/course/trainer_model.dart';
import 'package:geoedu/model/general/status_model.dart';

class CourseService {
  CourseService._();

  static final CourseService instance = CourseService._();

  Future<List<Course>> fetchCourses({
    int? categoryId,
    int? lastItemId,
  }) async {
    CourseListResponse response = await ApiService.instance.call(
      url: WebService.course.fetchCourses,
      fromJson: CourseListResponse.fromJson,
      cancelAuthToken: true,
      param: {
        'limit': 20,
        if (categoryId != null) 'category_id': categoryId,
        if (lastItemId != null) 'last_item_id': lastItemId,
      },
    );
    return response.data ?? [];
  }

  Future<Course?> fetchCourseDetail({required int courseId}) async {
    CourseDetailResponse response = await ApiService.instance.call(
      url: WebService.course.fetchCourseDetail,
      fromJson: CourseDetailResponse.fromJson,
      param: {'course_id': courseId},
    );
    return response.data;
  }

  Future<List<Trainer>> fetchPopularTrainers({int? lastItemId}) async {
    TrainerListResponse response = await ApiService.instance.call(
      url: WebService.course.fetchPopularTrainers,
      fromJson: TrainerListResponse.fromJson,
      cancelAuthToken: true,
      param: {
        'limit': 20,
        if (lastItemId != null) 'last_item_id': lastItemId,
      },
    );
    return response.data ?? [];
  }

  Future<StatusModel> enrollCourse({required int courseId}) async {
    StatusModel response = await ApiService.instance.call(
      url: WebService.course.enrollCourse,
      fromJson: StatusModel.fromJson,
      param: {'course_id': courseId},
    );
    return response;
  }

  Future<StatusModel> markLessonComplete({required int lessonId}) async {
    StatusModel response = await ApiService.instance.call(
      url: WebService.course.markLessonComplete,
      fromJson: StatusModel.fromJson,
      param: {'lesson_id': lessonId},
    );
    return response;
  }

  Future<StatusModel> rateCourse({
    required int courseId,
    required int rating,
    String? review,
  }) async {
    StatusModel response = await ApiService.instance.call(
      url: WebService.course.rateCourse,
      fromJson: StatusModel.fromJson,
      param: {
        'course_id': courseId,
        'rating': rating,
        if (review != null) 'review': review,
      },
    );
    return response;
  }

  Future<List<Course>> fetchMyEnrolledCourses({int? lastItemId}) async {
    CourseListResponse response = await ApiService.instance.call(
      url: WebService.course.fetchMyEnrolledCourses,
      fromJson: CourseListResponse.fromJson,
      param: {
        'limit': 20,
        if (lastItemId != null) 'last_item_id': lastItemId,
      },
    );
    return response.data ?? [];
  }
}
