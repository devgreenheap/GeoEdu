import 'package:get/get.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/course_service.dart';
import 'package:geoedu/model/course/course_model.dart';
import 'package:geoedu/model/general/category_sub_category_topic_model.dart';

class LearnScreenController extends GetxController {
  RxBool isLoading = true.obs;

  RxList<Category> filterCategories = <Category>[].obs;
  RxInt selectedCategoryIndex = 0.obs;

  RxList<Course> trendingCourses = <Course>[].obs;
  RxList<Course> continueLearning = <Course>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    await Future.wait([
      fetchFilterCategories(),
      fetchTrendingCourses(),
      fetchContinueLearning(),
    ]);
    isLoading.value = false;
  }

  Future<void> fetchFilterCategories() async {
    try {
      final result = await CommonService.instance.fetchCategorySubCategoryTopic();
      filterCategories.value = result.data ?? [];
    } catch (e) {
      Loggers.error('LearnScreen fetchFilterCategories error: $e');
    }
  }

  void onCategorySelected(int index) {
    selectedCategoryIndex.value = index;
    fetchTrendingCourses();
  }

  Future<void> fetchTrendingCourses() async {
    try {
      int? categoryId;
      if (selectedCategoryIndex.value > 0 &&
          selectedCategoryIndex.value - 1 < filterCategories.length) {
        categoryId = filterCategories[selectedCategoryIndex.value - 1].id;
      }
      trendingCourses.value = await CourseService.instance.fetchCourses(categoryId: categoryId);
    } catch (e) {
      Loggers.error('LearnScreen fetchTrendingCourses error: $e');
    }
  }

  Future<void> fetchContinueLearning() async {
    try {
      continueLearning.value = await CourseService.instance.fetchMyEnrolledCourses();
    } catch (e) {
      Loggers.error('LearnScreen fetchContinueLearning error: $e');
    }
  }
}
