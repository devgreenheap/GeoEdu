import 'package:flutter/material.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart' show kAppBarGradient;
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

  List<Map<String, dynamic>> _buildAboutFields(User? user) {
    String age = '';
    if (user?.dateOfBirth != null && user!.dateOfBirth!.isNotEmpty) {
      try {
        final dob = DateTime.parse(user.dateOfBirth!);
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
      {"title": "School Name", "value": user?.collegeName ?? '', "icon": Icons.school},
      {"title": "Email", "value": user?.identity ?? '', "icon": Icons.email},
      {"title": "Age", "value": age, "icon": Icons.person},
      {"title": "Stream Language", "value": user?.languageName ?? '', "icon": Icons.language},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.getUser();
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
      body: Column(
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
          Expanded(child: _buildSubTabContent(user)),
        ],
      ),
    );
  }

  Widget _buildSubTabContent(User? user) {
    switch (selectedIndex) {
      case 0:
        final fields = _buildAboutFields(user);
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
                      item["value"].toString(),
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
                (user?.bio ?? '').isEmpty ? 'No bio added yet' : user!.bio!,
                style: TextStyle(
                  color: (user?.bio ?? '').isEmpty ? Colors.white38 : Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );

      case 2:
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
              _skillRow(Icons.category_outlined, 'Category', user?.categoryName ?? ''),
              Container(height: .5, color: Colors.white24),
              _skillRow(Icons.subdirectory_arrow_right, 'Sub Category', user?.subCategoryName ?? ''),
              Container(height: .5, color: Colors.white24),
              _skillRow(Icons.topic_outlined, 'Topic', user?.topicName ?? ''),
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }

  Widget _skillRow(IconData icon, String title, String value) {
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
            value.isEmpty ? '-' : value,
            style: TextStyle(
              color: value.isEmpty ? Colors.white38 : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
