import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/model/general/category_sub_category_topic_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/auth_screen/interest_topic_screen.dart';
import 'package:geoedu/screen/auth_screen/widget/auth_theme.dart';

/// Interest Screen 2 of 3 — Sub-category selection.
class InterestSubcategoryScreen extends StatefulWidget {
  final User? userData;
  final List<Category> selectedCategories;
  final List<SubCategory> allSubCategories;

  const InterestSubcategoryScreen({
    super.key,
    this.userData,
    required this.selectedCategories,
    required this.allSubCategories,
  });

  @override
  State<InterestSubcategoryScreen> createState() =>
      _InterestSubcategoryScreenState();
}

class _InterestSubcategoryScreenState extends State<InterestSubcategoryScreen>
    with SingleTickerProviderStateMixin {
  final Set<SubCategory> _selected = {};
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_selected.isEmpty && widget.allSubCategories.isNotEmpty) {
      Get.snackbar('Select Subjects',
          'Please select at least one subject to continue.',
          backgroundColor: AuthColors.surface,
          colorText: AuthColors.textPrimary,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16));
      return;
    }
    final topics = _selected
        .expand((sub) => sub.topics ?? <Topic>[])
        .toList();
    Get.to(() => InterestTopicScreen(
          userData: widget.userData,
          selectedCategories: widget.selectedCategories,
          selectedSubCategories: _selected.toList(),
          allTopics: topics,
        ));
  }

  static const List<IconData> _icons = [
    Icons.book_rounded,
    Icons.quiz_rounded,
    Icons.lightbulb_rounded,
    Icons.star_rounded,
    Icons.emoji_objects_rounded,
    Icons.grade_rounded,
    Icons.school_rounded,
    Icons.auto_graph_rounded,
    Icons.trending_up_rounded,
    Icons.workspace_premium_rounded,
    Icons.library_books_rounded,
    Icons.class_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: widget.allSubCategories.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AuthColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AuthColors.border.withValues(alpha: 0.6)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AuthColors.textPrimary, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              // Progress
              Expanded(
                child: Row(
                  children: [
                    _progressPill(active: false, done: true),
                    const SizedBox(width: 6),
                    _progressPill(active: true, done: false),
                    const SizedBox(width: 6),
                    _progressPill(active: false, done: false),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            AuthColors.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('2 of 3',
                          style: TextStyle(
                              color: AuthColors.primaryOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Choose your\nSubjects',
              style: TextStyle(
                  color: AuthColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.25)),
          const SizedBox(height: 8),
          const Text(
            'Select the subjects you\'d like to explore.',
            style: TextStyle(color: AuthColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Selected categories pills
          if (widget.selectedCategories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.selectedCategories.map((cat) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AuthColors.gioGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              AuthColors.gioGreen.withValues(alpha: 0.4)),
                    ),
                    child: Text(cat.name ?? '',
                        style: const TextStyle(
                            color: AuthColors.gioGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _progressPill({required bool active, required bool done}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 6,
      width: active ? 40 : 20,
      decoration: BoxDecoration(
        color: done
            ? AuthColors.gioGreen
            : active
                ? AuthColors.primaryOrange
                : AuthColors.border,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildList() {
    // Group sub-categories by their parent category
    final grouped = <Category, List<SubCategory>>{};
    for (final sub in widget.allSubCategories) {
      final parent = widget.selectedCategories
          .firstWhereOrNull((c) => c.id == sub.categoryId);
      if (parent != null) {
        grouped.putIfAbsent(parent, () => []).add(sub);
      } else {
        // Unmatched — put under first selected cat
        final fallback =
            widget.selectedCategories.isNotEmpty ? widget.selectedCategories.first : null;
        if (fallback != null) {
          grouped.putIfAbsent(fallback, () => []).add(sub);
        }
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: grouped.length,
      itemBuilder: (context, idx) {
        final category = grouped.keys.elementAt(idx);
        final subs = grouped[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                category.name ?? '',
                style: const TextStyle(
                    color: AuthColors.gioGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: subs.asMap().entries.map((e) {
                final sub = e.value;
                final icon = _icons[e.key % _icons.length];
                final isSelected = _selected.contains(sub);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(sub);
                      } else {
                        _selected.add(sub);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AuthColors.primaryOrange.withValues(alpha: 0.14)
                          : AuthColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AuthColors.primaryOrange
                            : AuthColors.border.withValues(alpha: 0.5),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AuthColors.primaryOrange
                                    .withValues(alpha: 0.2),
                                blurRadius: 10,
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            color: isSelected
                                ? AuthColors.primaryOrange
                                : AuthColors.textSecondary,
                            size: 16),
                        const SizedBox(width: 7),
                        Text(
                          sub.name ?? '',
                          style: TextStyle(
                            color: isSelected
                                ? AuthColors.primaryOrange
                                : AuthColors.textPrimary,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.check_circle_rounded,
                              color: AuthColors.primaryOrange, size: 14),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_rounded,
              color: AuthColors.textSecondary, size: 48),
          const SizedBox(height: 12),
          const Text('No sub-categories available.',
              style: TextStyle(color: AuthColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AuthPrimaryButton(
              text: 'Skip to Topics',
              trailingIcon: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
              onTap: () => Get.to(() => InterestTopicScreen(
                    userData: widget.userData,
                    selectedCategories: widget.selectedCategories,
                    selectedSubCategories: [],
                    allTopics: [],
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      decoration: BoxDecoration(
        color: AuthColors.background,
        border: Border(
            top: BorderSide(
                color: AuthColors.border.withValues(alpha: 0.4), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      color: AuthColors.gioGreen, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    '${_selected.length} subject${_selected.length == 1 ? '' : 's'} selected',
                    style: const TextStyle(
                        color: AuthColors.gioGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          AuthPrimaryButton(
            text: 'Continue',
            trailingIcon: const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 18),
            onTap: _next,
          ),
        ],
      ),
    );
  }
}
