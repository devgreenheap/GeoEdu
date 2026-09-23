import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/gradient_border.dart';
import 'package:geoedu/model/course/course_model.dart';
import 'package:geoedu/screen/learn_screen/learn_screen_controller.dart';
import 'package:geoedu/utilities/color_res.dart';

const _kLearnCardGradient = LinearGradient(
  colors: [ColorRes.primaryColor, ColorRes.gold],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LearnScreenController());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => _kLearnCardGradient.createShader(bounds),
          child: const Text('Learn',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF120A1C), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.35],
          ),
        ),
        child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: ColorRes.primaryColor));
        }
        return RefreshIndicator(
          color: ColorRes.primaryColor,
          onRefresh: controller.fetchAll,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              if (controller.continueLearning.isNotEmpty) ...[
                const SizedBox(height: 12),
                const _SectionHeader(title: 'Continue Learning'),
                const SizedBox(height: 10),
                _ContinueLearningList(courses: controller.continueLearning),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 12),
              const _SectionHeader(title: 'Trending Courses'),
              const SizedBox(height: 10),
              _CategoryChips(controller: controller),
              const SizedBox(height: 12),
              _TrendingCoursesList(courses: controller.trendingCourses),
            ],
          ),
        );
      }),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final LearnScreenController controller;

  const _CategoryChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final categories = controller.filterCategories;
      final selectedIndex = controller.selectedCategoryIndex.value;
      final totalCount = categories.length + 1;

      return SizedBox(
        height: 35,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: totalCount,
          itemBuilder: (context, index) {
            final isSelected = selectedIndex == index;
            final label = index == 0 ? 'All' : (categories[index - 1].name ?? '');
            final chip = Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              height: 35,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected ? ColorRes.primaryColor : const Color(0xFF171717),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            );
            return GestureDetector(
              onTap: () => controller.onCategorySelected(index),
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: isSelected
                    ? chip
                    : GradientBorder(
                        strokeWidth: 1.1,
                        radius: 12,
                        gradient: _kLearnCardGradient,
                        child: chip,
                      ),
              ),
            );
          },
        ),
      );
    });
  }
}

class _TrendingCoursesList extends StatelessWidget {
  final List<Course> courses;

  const _TrendingCoursesList({required this.courses});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return const _EmptyRow(text: 'No courses yet');
    }
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: courses.length,
        itemBuilder: (context, index) => _CourseCard(course: courses[index]),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: GradientBorder(
        strokeWidth: 1.2,
        radius: 14,
        gradient: _kLearnCardGradient,
        child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141823),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: CustomImage(
              size: const Size(150, 90),
              image: course.thumbnail?.addBaseURL(),
              fullName: course.title,
              radius: 0,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  course.trainerName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: ColorRes.primaryColor, size: 12),
                    const SizedBox(width: 2),
                    Text('${course.avgRating ?? 0}',
                        style: const TextStyle(color: Colors.white60, fontSize: 10)),
                    const Spacer(),
                    const Icon(Icons.menu_book_rounded, color: Colors.white38, size: 12),
                    const SizedBox(width: 2),
                    Text('${course.lessonCount ?? 0}',
                        style: const TextStyle(color: Colors.white60, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }
}

class _ContinueLearningList extends StatelessWidget {
  final List<Course> courses;

  const _ContinueLearningList({required this.courses});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          final percent = ((course.progressPercent ?? 0).clamp(0, 100)) / 100;
          return Container(
            width: 190,
            margin: const EdgeInsets.only(right: 12),
            child: GradientBorder(
              strokeWidth: 1.2,
              radius: 14,
              gradient: _kLearnCardGradient,
              child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141823),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  course.trainerName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(ColorRes.primaryColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${course.progressPercent ?? 0}% Completed',
                    style: const TextStyle(color: ColorRes.primaryColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String text;

  const _EmptyRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 13)),
    );
  }
}
