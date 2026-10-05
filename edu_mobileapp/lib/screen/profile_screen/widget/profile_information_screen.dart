import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart' show kAppBarGradient;
import 'package:geoedu/model/general/category_sub_category_topic_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/theme_res.dart';

/// Moved out of the Profile screen's tab bar (which now only shows
/// My Lives / Insights) into Settings, reachable via "Profile Information".
class ProfileInformationScreen extends StatefulWidget {
  const ProfileInformationScreen({super.key});

  @override
  State<ProfileInformationScreen> createState() => _ProfileInformationScreenState();
}

class _ProfileInformationScreenState extends State<ProfileInformationScreen> {
  int selectedIndex = 0;
  final tabs = ["About", "Experience", "Skill"];
  User? user;
  List<Category> categoryList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    user = SessionManager.instance.getUser();
    _fetchFreshUserData();
  }

  Future<void> _fetchFreshUserData() async {
    setState(() => isLoading = true);
    try {
      // Fetch category tree to guarantee names can always be resolved
      final catResult = await CommonService.instance.fetchCategorySubCategoryTopic();
      categoryList = catResult.data ?? [];

      final current = SessionManager.instance.getUser();
      if (current?.id != null) {
        final freshUser = await UserService.instance.fetchUserDetails(userId: current!.id);
        if (freshUser != null) {
          _resolveMissingSkillNames(freshUser);
          SessionManager.instance.setUser(freshUser);
          if (mounted) {
            setState(() {
              user = freshUser;
              isLoading = false;
            });
          }
          return;
        }
      }
      if (user != null) {
        _resolveMissingSkillNames(user!);
      }
    } catch (_) {}

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _resolveMissingSkillNames(User targetUser) {
    if (categoryList.isEmpty) return;

    Category? cat;
    if (targetUser.categoryId != null) {
      cat = categoryList.firstWhereOrNull((e) => e.id == targetUser.categoryId);
      if ((targetUser.categoryName ?? '').isEmpty && cat?.name != null) {
        targetUser.categoryName = cat!.name;
      }
    }

    SubCategory? subCat;
    if (targetUser.subCategoryId != null) {
      if (cat != null && cat.subCategories != null) {
        subCat = cat.subCategories!.firstWhereOrNull((e) => e.id == targetUser.subCategoryId);
      }
      if (subCat == null) {
        for (final c in categoryList) {
          final found = (c.subCategories ?? []).firstWhereOrNull((e) => e.id == targetUser.subCategoryId);
          if (found != null) {
            subCat = found;
            if ((targetUser.categoryName ?? '').isEmpty && c.name != null) {
              targetUser.categoryName = c.name;
            }
            break;
          }
        }
      }
      if ((targetUser.subCategoryName ?? '').isEmpty && subCat?.name != null) {
        targetUser.subCategoryName = subCat!.name;
      }
    }

    if (targetUser.topicId != null) {
      Topic? top;
      if (subCat != null && subCat.topics != null) {
        top = subCat.topics!.firstWhereOrNull((e) => e.id == targetUser.topicId);
      }
      if (top == null) {
        for (final c in categoryList) {
          for (final s in (c.subCategories ?? [])) {
            final found = (s.topics ?? []).firstWhereOrNull((e) => e.id == targetUser.topicId);
            if (found != null) {
              top = found;
              if ((targetUser.subCategoryName ?? '').isEmpty && s.name != null) {
                targetUser.subCategoryName = s.name;
              }
              if ((targetUser.categoryName ?? '').isEmpty && c.name != null) {
                targetUser.categoryName = c.name;
              }
              break;
            }
          }
          if (top != null) break;
        }
      }
      if ((targetUser.topicName ?? '').isEmpty && top?.name != null) {
        targetUser.topicName = top!.name;
      }
    }
  }

  String _getCategoryDisplay() {
    if ((user?.categoryName ?? '').trim().isNotEmpty) {
      return user!.categoryName!.trim();
    }
    if (user?.categoryId != null && categoryList.isNotEmpty) {
      final cat = categoryList.firstWhereOrNull((e) => e.id == user!.categoryId);
      if (cat?.name != null) return cat!.name!;
    }
    return '';
  }

  String _getSubCategoryDisplay() {
    if ((user?.subCategoryName ?? '').trim().isNotEmpty) {
      return user!.subCategoryName!.trim();
    }
    if (user?.subCategoryId != null && categoryList.isNotEmpty) {
      for (final c in categoryList) {
        final sub = (c.subCategories ?? []).firstWhereOrNull((e) => e.id == user!.subCategoryId);
        if (sub?.name != null) return sub!.name!;
      }
    }
    return '';
  }

  String _getTopicDisplay() {
    if ((user?.topicName ?? '').trim().isNotEmpty) {
      return user!.topicName!.trim();
    }
    if (user?.topicId != null && categoryList.isNotEmpty) {
      for (final c in categoryList) {
        for (final s in (c.subCategories ?? [])) {
          final top = (s.topics ?? []).firstWhereOrNull((e) => e.id == user!.topicId);
          if (top?.name != null) return top!.name!;
        }
      }
    }
    return '';
  }

  List<Map<String, dynamic>> _buildAboutFields(User? currentUser) {
    String age = '';
    if (currentUser?.dateOfBirth != null && currentUser!.dateOfBirth!.isNotEmpty) {
      try {
        final dob = DateTime.parse(currentUser.dateOfBirth!);
        final now = DateTime.now();
        int years = now.year - dob.year;
        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          years--;
        }
        age = '$years';
      } catch (_) {}
    }

    return [
      {"title": "School Name", "value": currentUser?.collegeName ?? '', "icon": Icons.school},
      {"title": "Email", "value": currentUser?.identity ?? '', "icon": Icons.email},
      {"title": "Age", "value": age, "icon": Icons.person},
      {"title": "Stream Language", "value": currentUser?.languageName ?? '', "icon": Icons.language},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = user ?? SessionManager.instance.getUser();

    return Scaffold(
      backgroundColor: ColorRes.blackPure,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: kAppBarGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Profile Information', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        color: ColorRes.primaryColor,
        backgroundColor: ColorRes.cardBackground,
        onRefresh: _fetchFreshUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final isSelected = selectedIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedIndex = index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? ColorRes.primaryColor : ColorRes.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                tabs[index],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),
              _buildSubTabContent(currentUser),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabContent(User? currentUser) {
    switch (selectedIndex) {
      case 0:
        final fields = _buildAboutFields(currentUser);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ColorRes.cardBackground, ColorRes.surfaceBackground],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            separatorBuilder: (context, i) => Container(height: .5, color: textLightGrey(context)),
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: fields.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final item = fields[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withValues(alpha: .15),
                      child: Icon(item["icon"] as IconData, size: 16, color: ColorRes.gold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "${item["title"]}:",
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                    Text(
                      item["value"].toString().isEmpty ? '-' : item["value"].toString(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              );
            },
          ),
        );

      case 1:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ColorRes.cardBackground, ColorRes.surfaceBackground],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withValues(alpha: .15),
                    child: const Icon(Icons.article_outlined, size: 16, color: ColorRes.gold),
                  ),
                  const SizedBox(width: 12),
                  const Text('Bio',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                (currentUser?.bio ?? '').isEmpty ? 'No bio added yet' : currentUser!.bio!,
                style: TextStyle(
                  color: (currentUser?.bio ?? '').isEmpty ? Colors.white38 : Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );

      case 2:
        final catDisplay = _getCategoryDisplay();
        final subCatDisplay = _getSubCategoryDisplay();
        final topicDisplay = _getTopicDisplay();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ColorRes.cardBackground, ColorRes.surfaceBackground],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _skillRow(Icons.category_outlined, 'Category', catDisplay),
              Container(height: .5, color: Colors.white24),
              _skillRow(Icons.subdirectory_arrow_right, 'Sub Category', subCatDisplay),
              Container(height: .5, color: Colors.white24),
              _skillRow(Icons.topic_outlined, 'Topic', topicDisplay),
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }

  Widget _skillRow(IconData icon, String title, String value) {
    final hasValue = value.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withValues(alpha: .15),
            child: Icon(icon, size: 16, color: ColorRes.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('$title:', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          Text(
            hasValue ? value : '-',
            style: TextStyle(
              color: hasValue ? Colors.white : Colors.white38,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
