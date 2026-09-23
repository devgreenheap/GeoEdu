import 'dart:io';

import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keyboard_avoider/keyboard_avoider.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/service/api/search_service.dart';
import 'package:geoedu/common/widget/black_gradient_shadow.dart';
import 'package:geoedu/common/widget/custom_back_button.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/general/category_sub_category_topic_model.dart';
import 'package:geoedu/model/post_story/hashtag_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/live_stream/create_live_stream_screen/create_live_stream_screen_controller.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class CreateLiveStreamScreen extends StatelessWidget {
  const CreateLiveStreamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateLiveStreamScreenController());
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Obx(
            () {
              User? user = controller.myUser.value;
              if (!controller.isVideoOn.value) {
                return CustomImage(
                    size: Size(Get.width, Get.height),
                    cornerSmoothing: 0,
                    radius: 0,
                    image: user?.profilePhoto?.addBaseURL(),
                    fullName: user?.fullname);
              }
              return controller.localView.value ??
                  CustomImage(
                      size: Size(Get.width, Get.height),
                      cornerSmoothing: 0,
                      radius: 0,
                      image: user?.profilePhoto?.addBaseURL(),
                      fullName: user?.fullname);
            },
          ),
          const Align(
              alignment: Alignment.bottomCenter,
              child: BlackGradientShadow(height: 350)),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 15),
                child: InkWell(
                  onTap: controller.toggleCamera,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Image.asset(AssetRes.icCameraFlip,
                        color: Colors.white, width: 18, height: 18),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: KeyboardAvoider(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                      alignment: AlignmentDirectional.topStart,
                      child: CustomBackButton(
                        image: AssetRes.icClose,
                        height: 30,
                        width: 30,
                        color: whitePure(context),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        onTap: controller.onCloseTap,
                      )),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Host photo card — persisted cover shown on
                              // room cards before viewers join, separate
                              // from the live camera feed behind this screen.
                              Obx(() => InkWell(
                                    onTap: controller.pickThumbnail,
                                    child: Container(
                                      width: 100,
                                      height: 140,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: ShapeDecoration(
                                        color: whitePure(context)
                                            .withValues(alpha: .15),
                                        shape: SmoothRectangleBorder(
                                          borderRadius: SmoothBorderRadius(
                                              cornerRadius: 16,
                                              cornerSmoothing: 1),
                                        ),
                                        image: controller.thumbnailPreviewPath
                                                .value.isNotEmpty
                                            ? DecorationImage(
                                                image: FileImage(File(
                                                    controller
                                                        .thumbnailPreviewPath
                                                        .value)),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: Stack(
                                        children: [
                                          if (controller.thumbnailPreviewPath
                                              .value.isEmpty)
                                            Center(
                                              child: Icon(
                                                  Icons.add_a_photo_outlined,
                                                  color: whitePure(context),
                                                  size: 26),
                                            ),
                                          Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 6),
                                              color: Colors.black
                                                  .withValues(alpha: 0.55),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  Icon(Icons.edit,
                                                      color: Colors.white,
                                                      size: 12),
                                                  SizedBox(width: 4),
                                                  Text('Edit',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w600)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                              const Spacer(),
                              // Right column: language, Edit Interest,
                              // Video ON, Auto Call — top-right stack.
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Obx(() => _CompactDarkPill(
                                        icon: null,
                                        label:
                                            controller.selectedLanguage.value
                                                    ?.title ??
                                                'Language',
                                        onTap: () => _showLanguagePicker(
                                            context, controller),
                                      )),
                                  const SizedBox(height: 8),
                                  Obx(() {
                                    final parts = [
                                      controller.selectedCategory.value?.name,
                                      controller
                                          .selectedSubCategory.value?.name,
                                      controller.selectedTopic.value?.name,
                                    ].whereType<String>().toList();
                                    return _CompactDarkPill(
                                      icon: Icons.edit_outlined,
                                      label: parts.isEmpty
                                          ? 'Edit Interest'
                                          : parts.join(' · '),
                                      onTap: () => Get.bottomSheet(
                                        _InterestPickerSheet(
                                            controller: controller),
                                        isScrollControlled: true,
                                        ignoreSafeArea: false,
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 14),
                                  Obx(() => _ToggleRow(
                                        label: 'Video ON',
                                        value: controller.isVideoOn.value,
                                        onChanged: controller.toggleVideoOn,
                                      )),
                                  const SizedBox(height: 8),
                                  Obx(() => _ToggleRow(
                                        label: 'Auto Call',
                                        value: controller.isAutoMode.value,
                                        onChanged: (v) =>
                                            controller.isAutoMode.value = v,
                                      )),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Bottom sheet — Host Live Show
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24)),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Host Live Show',
                                    style: TextStyleCustom.unboundedMedium500(
                                        color: whitePure(context),
                                        fontSize: 18)),
                                const SizedBox(height: 14),
                                Text('Room Type',
                                    style: TextStyleCustom.outFitLight300(
                                        fontSize: 13,
                                        color: whitePure(context)
                                            .withValues(alpha: .7))),
                                const SizedBox(height: 8),
                                // Room Type — outlined pill, not filled, per
                                // the reference (fixed to the PK-capable
                                // video room mode; Direct Call / PK Battle
                                // stream modes remain in the model for other
                                // entry points that still set them).
                                Obx(() => Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          controller.streamModes.map((mode) {
                                        final isSelected = controller
                                                .selectedStreamMode.value ==
                                            mode['value'];
                                        return GestureDetector(
                                          onTap: () => controller
                                              .onStreamModeChanged(
                                                  mode['value']),
                                          child: Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 16, vertical: 9),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: isSelected
                                                      ? ColorRes.primaryColor
                                                      : whitePure(context)
                                                          .withValues(
                                                              alpha: .25),
                                                  width: isSelected ? 1.5 : 1),
                                            ),
                                            child: Text(
                                              mode['label']!,
                                              style: TextStyleCustom
                                                  .outFitRegular400(
                                                      fontSize: 14,
                                                      color: isSelected
                                                          ? ColorRes
                                                              .primaryColor
                                                          : whitePure(
                                                              context)),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    )),
                                const SizedBox(height: 16),
                                Text('Choose Category',
                                    style: TextStyleCustom.outFitLight300(
                                        fontSize: 13,
                                        color: whitePure(context)
                                            .withValues(alpha: .7))),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 76,
                                  child: Obx(() => ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount:
                                            controller.categoryList.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 10),
                                        itemBuilder: (context, index) {
                                          final category =
                                              controller.categoryList[index];
                                          final isSelected = controller
                                                  .selectedCategory
                                                  .value
                                                  ?.id ==
                                              category.id;
                                          return _CategoryTile3D(
                                            name: category.name ?? '',
                                            isSelected: isSelected,
                                            onTap: () => controller
                                                .onCategoryChanged(category),
                                          );
                                        },
                                      )),
                                ),
                                const SizedBox(height: 16),
                                Text('Select Hashtag',
                                    style: TextStyleCustom.outFitLight300(
                                        fontSize: 13,
                                        color: whitePure(context)
                                            .withValues(alpha: .7))),
                                const SizedBox(height: 8),
                                Obx(() => Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _HashtagChip(
                                          label: 'None',
                                          isSelected:
                                              controller.selectedHashtags.isEmpty,
                                          onTap: () {
                                            for (final h
                                                in List.of(controller
                                                    .selectedHashtags)) {
                                              controller.toggleHashtag(h);
                                            }
                                          },
                                        ),
                                        ...controller.selectedHashtags
                                            .map((h) => _HashtagChip(
                                                  label: '#${h.hashtag}',
                                                  isSelected: true,
                                                  onTap: () =>
                                                      controller
                                                          .toggleHashtag(h),
                                                )),
                                        GestureDetector(
                                          onTap: () => _showHashtagPickerSheet(
                                              context, controller),
                                          child: Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: whitePure(context)
                                                      .withValues(alpha: .25)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.add,
                                                    size: 14,
                                                    color: whitePure(context)),
                                                const SizedBox(width: 4),
                                                Text('More',
                                                    style: TextStyleCustom
                                                        .outFitRegular400(
                                                            fontSize: 13,
                                                            color: whitePure(
                                                                context))),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Obx(() => Checkbox(
                                          checkColor: Colors.black,
                                          value: controller.isRestricted.value,
                                          activeColor: ColorRes.primaryColor,
                                          side: BorderSide(
                                              color: whitePure(context)
                                                  .withValues(alpha: .4)),
                                          onChanged: (value) => controller
                                              .isRestricted.value = value ?? false,
                                        )),
                                    Expanded(
                                      child: Text(
                                        LKey.restrictUserRequests.tr,
                                        style: TextStyleCustom.outFitLight300(
                                            color: whitePure(context),
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: controller.onStartLive,
                                  child: Container(
                                    height: 50,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: ColorRes.primaryGradient,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      LKey.startLive.tr,
                                      style: TextStyleCustom
                                          .unboundedMedium500(
                                        color: Colors.white,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHashtagPickerSheet(
      BuildContext context, CreateLiveStreamScreenController controller) {
    Get.bottomSheet(
      _LiveStreamHashtagPickerSheet(controller: controller),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  void _showLanguagePicker(
      BuildContext context, CreateLiveStreamScreenController controller) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.6),
        decoration: const BoxDecoration(
          color: Color(0xFF2C2F48),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Obx(() => ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: controller.languageList.length,
              itemBuilder: (context, index) {
                final lang = controller.languageList[index];
                final isSelected =
                    controller.selectedLanguage.value?.id == lang.id;
                return ListTile(
                  title: Text(lang.title ?? '',
                      style: TextStyle(
                          color: isSelected
                              ? ColorRes.primaryColor
                              : Colors.white)),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: ColorRes.primaryColor)
                      : null,
                  onTap: () {
                    controller.onLanguageChanged(lang);
                    Get.back();
                  },
                );
              },
            )),
      ),
      isScrollControlled: true,
    );
  }
}

/// Compact dark pill used for the language + Edit Interest controls
/// stacked at top-right of the Video tab.
class _CompactDarkPill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  const _CompactDarkPill({this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

/// Label + Switch row used for Video ON / Auto Call on the Video tab.
class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        Transform.scale(
          scale: 0.75,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ColorRes.primaryColor,
            inactiveTrackColor: Colors.white24,
          ),
        ),
      ],
    );
  }
}

/// Square icon tile for "Choose Category" — real categories from the
/// backend, styled to resemble the reference's colorful icon tiles (no
/// hardcoded/fake category options).
class _CategoryTile3D extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile3D({required this.name, required this.isSelected, required this.onTap});

  static const _iconsByKeyword = <String, IconData>{
    'live': Icons.videocam_rounded,
    'show': Icons.videocam_rounded,
    'party': Icons.celebration_rounded,
    'sing': Icons.mic_rounded,
    'dance': Icons.nightlife_rounded,
    'comedy': Icons.sentiment_very_satisfied_rounded,
    'funny': Icons.sentiment_very_satisfied_rounded,
  };

  IconData get _icon {
    final lower = name.toLowerCase();
    for (final entry in _iconsByKeyword.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 62,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isSelected ? ColorRes.primaryColor : Colors.transparent,
                    width: 2),
              ),
              alignment: Alignment.center,
              child: Icon(_icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 4),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: isSelected ? ColorRes.primaryColor : Colors.white70,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

/// Outlined-when-selected hashtag chip for the Video tab's inline hashtag
/// row (matches the reference's "இல்லை" / selected style).
class _HashtagChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _HashtagChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? ColorRes.primaryColor : Colors.white24,
              width: isSelected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? ColorRes.primaryColor : Colors.white,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }
}

// ─── Interest (Category / Sub-Category / Topic) Picker Sheet ───

class _InterestPickerSheet extends StatelessWidget {
  final CreateLiveStreamScreenController controller;

  const _InterestPickerSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF2C2F48),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Interest',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: ColorRes.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Done',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              final category = controller.selectedCategory.value;
              final subCategory = controller.selectedSubCategory.value;
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _section('Category'),
                  _tiles<Category>(
                    items: controller.categoryList,
                    label: (c) => c.name ?? '',
                    isSelected: (c) => c.id == category?.id,
                    onTap: controller.onCategoryChanged,
                  ),
                  if ((category?.subCategories ?? []).isNotEmpty) ...[
                    _section('Sub Category'),
                    _tiles<SubCategory>(
                      items: category!.subCategories!,
                      label: (s) => s.name ?? '',
                      isSelected: (s) => s.id == subCategory?.id,
                      onTap: controller.onSubCategoryChanged,
                    ),
                  ],
                  if ((subCategory?.topics ?? []).isNotEmpty) ...[
                    _section('Topic'),
                    _tiles<Topic>(
                      items: subCategory!.topics!,
                      label: (t) => t.name ?? '',
                      isSelected: (t) =>
                          t.id == controller.selectedTopic.value?.id,
                      onTap: controller.onTopicChanged,
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      );

  Widget _tiles<T>({
    required List<T> items,
    required String Function(T) label,
    required bool Function(T) isSelected,
    required ValueChanged<T?> onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final selected = isSelected(item);
        return GestureDetector(
          onTap: () => onTap(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? ColorRes.primaryColor
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected
                      ? ColorRes.primaryColor
                      : Colors.white.withValues(alpha: 0.15)),
            ),
            child: Text(
              label(item),
              style: TextStyle(
                  color: selected ? Colors.black : Colors.white,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Hashtag Picker Bottom Sheet ───

class _LiveStreamHashtagPickerSheet extends StatefulWidget {
  final CreateLiveStreamScreenController controller;

  const _LiveStreamHashtagPickerSheet({required this.controller});

  @override
  State<_LiveStreamHashtagPickerSheet> createState() =>
      _LiveStreamHashtagPickerSheetState();
}

class _LiveStreamHashtagPickerSheetState
    extends State<_LiveStreamHashtagPickerSheet> {
  final searchController = TextEditingController();
  RxList<Hashtag> searchResults = <Hashtag>[].obs;
  RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _fetchHashtags();
  }

  Future<void> _fetchHashtags({bool reset = false}) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final data = await SearchService.instance.searchHashtags(
        keyword: searchController.text.trim(),
        lastItemId: reset || searchResults.isEmpty
            ? null
            : searchResults.last.id?.toInt(),
      );
      if (reset) searchResults.clear();
      searchResults.addAll(data);
    } catch (_) {}
    isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF2C2F48),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Hashtags',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: ColorRes.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Obx(() => Text(
                          'Done (${widget.controller.selectedHashtags.length})',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        )),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              onChanged: (_) => _fetchHashtags(reset: true),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              decoration: InputDecoration(
                hintText: 'Search hashtags...',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 15),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              if (isLoading.value && searchResults.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: ColorRes.primaryColor, strokeWidth: 2),
                );
              }
              if (searchResults.isEmpty) {
                return const Center(
                  child: Text('No hashtags found',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              return NotificationListener<ScrollNotification>(
                onNotification: (scroll) {
                  if (scroll.metrics.pixels >=
                      scroll.metrics.maxScrollExtent - 100) {
                    _fetchHashtags();
                  }
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final hashtag = searchResults[index];
                    return Obx(() {
                      final isSelected = widget.controller.selectedHashtags
                          .any((h) => h.id == hashtag.id);
                      return GestureDetector(
                        onTap: () => widget.controller.toggleHashtag(hashtag),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ColorRes.primaryColor
                                    .withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(Icons.tag,
                                      color: Colors.white54, size: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '#${hashtag.hashtag ?? ''}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${hashtag.postCount ?? 0} posts',
                                      style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: isSelected
                                    ? ColorRes.primaryColor
                                    : Colors.white24,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
