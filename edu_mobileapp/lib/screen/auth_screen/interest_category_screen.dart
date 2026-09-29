import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/model/general/category_sub_category_topic_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/auth_screen/interest_subcategory_screen.dart';
import 'package:geoedu/screen/auth_screen/widget/auth_theme.dart';
import 'package:geoedu/utilities/asset_res.dart';

/// Interest Screen 1 of 3 — Category selection.
/// Shown immediately after successful registration (new users only).
class InterestCategoryScreen extends StatefulWidget {
  final User? userData;

  const InterestCategoryScreen({super.key, this.userData});

  @override
  State<InterestCategoryScreen> createState() => _InterestCategoryScreenState();
}

class _InterestCategoryScreenState extends State<InterestCategoryScreen>
    with SingleTickerProviderStateMixin {
  final Set<Category> _selected = {};
  bool _isLoading = true;
  List<Category> _categories = [];
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await CommonService.instance.fetchCategorySubCategoryTopic();
      if (mounted) {
        setState(() {
          _categories = result.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      Loggers.error('Interest categories load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _next() {
    if (_selected.isEmpty) {
      Get.snackbar('Select Interests',
          'Please select at least one category to continue.',
          backgroundColor: AuthColors.surface,
          colorText: AuthColors.textPrimary,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16));
      return;
    }
    final subCategories = _selected
        .expand((cat) => cat.subCategories ?? <SubCategory>[])
        .toList();
    Get.to(() => InterestSubcategoryScreen(
          userData: widget.userData,
          selectedCategories: _selected.toList(),
          allSubCategories: subCategories,
        ));
  }

  static const List<IconData> _categoryIcons = [
    Icons.science_rounded,
    Icons.calculate_rounded,
    Icons.history_edu_rounded,
    Icons.language_rounded,
    Icons.palette_rounded,
    Icons.music_note_rounded,
    Icons.sports_soccer_rounded,
    Icons.computer_rounded,
    Icons.psychology_rounded,
    Icons.biotech_rounded,
    Icons.public_rounded,
    Icons.eco_rounded,
    Icons.auto_stories_rounded,
    Icons.architecture_rounded,
    Icons.engineering_rounded,
    Icons.health_and_safety_rounded,
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
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AuthColors.primaryOrange))
                    : _categories.isEmpty
                        ? _buildEmpty()
                        : _buildGrid(),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Row(
            children: [
              _progressPill(active: true, done: false),
              const SizedBox(width: 6),
              _progressPill(active: false, done: false),
              const SizedBox(width: 6),
              _progressPill(active: false, done: false),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AuthColors.primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('1 of 3',
                    style: TextStyle(
                        color: AuthColors.primaryOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Image.asset(AssetRes.appLogo, width: 52, height: 52),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('What are you\ninterested in?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AuthColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.25)),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Pick categories that interest you.\nWe\'ll personalise your learning feed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AuthColors.textSecondary,
                  fontSize: 13,
                  height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
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

  Widget _buildGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _categories.asMap().entries.map((entry) {
          final idx = entry.key;
          final cat = entry.value;
          final icon = _categoryIcons[idx % _categoryIcons.length];
          final isSelected = _selected.contains(cat);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selected.remove(cat);
                } else {
                  _selected.add(cat);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AuthColors.primaryOrange.withValues(alpha: 0.14)
                    : AuthColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AuthColors.primaryOrange
                      : AuthColors.border.withValues(alpha: 0.5),
                  width: isSelected ? 1.6 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              AuthColors.primaryOrange.withValues(alpha: 0.22),
                          blurRadius: 14,
                          spreadRadius: 1,
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
                      size: 18),
                  const SizedBox(width: 8),
                  Text(
                    cat.name ?? '',
                    style: TextStyle(
                      color: isSelected
                          ? AuthColors.primaryOrange
                          : AuthColors.textPrimary,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle_rounded,
                        color: AuthColors.primaryOrange, size: 15),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text('No categories found.',
          style: TextStyle(color: AuthColors.textSecondary, fontSize: 14)),
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
                    '${_selected.length} selected',
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
