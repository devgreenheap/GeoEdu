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
import 'package:geoedu/model/post_story/hashtag_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/live_stream/create_live_stream_screen/create_live_stream_screen_controller.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
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
                              // Host photo card — defaults to host's profile photo.
                              // Host can tap anywhere or tap Edit to pick a custom
                              // cover image specifically for this call/stream.
                              Obx(() {
                                final user = controller.myUser.value;
                                final customPath =
                                    controller.thumbnailPreviewPath.value;
                                final hasCustom = customPath.isNotEmpty;
                                final profilePhotoUrl =
                                    user?.profilePhoto?.addBaseURL();

                                return Container(
                                  width: 100,
                                  height: 140,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: ShapeDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    shape: SmoothRectangleBorder(
                                      borderRadius: SmoothBorderRadius(
                                        cornerRadius: 16,
                                        cornerSmoothing: 1,
                                      ),
                                      side: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Image display
                                      InkWell(
                                        onTap: controller.pickThumbnail,
                                        child: hasCustom
                                            ? Image.file(
                                                File(customPath),
                                                fit: BoxFit.cover,
                                              )
                                            : (profilePhotoUrl != null &&
                                                    profilePhotoUrl.isNotEmpty)
                                                ? CustomImage(
                                                    size: const Size(100, 140),
                                                    radius: 16,
                                                    cornerSmoothing: 1,
                                                    fit: BoxFit.cover,
                                                    image: profilePhotoUrl,
                                                    fullName: user?.fullname,
                                                  )
                                                : Center(
                                                    child: Icon(
                                                      Icons.person_rounded,
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.6),
                                                      size: 46,
                                                    ),
                                                  ),
                                      ),
                                      // If custom thumbnail picked, allow reset back to default profile photo
                                      if (hasCustom)
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: GestureDetector(
                                            onTap: () {
                                              controller.thumbnailFile.value =
                                                  null;
                                              controller.thumbnailPreviewPath
                                                  .value = '';
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withValues(alpha: 0.7),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close,
                                                  color: Colors.white,
                                                  size: 13),
                                            ),
                                          ),
                                        ),
                                      // Edit pill at bottom
                                      Align(
                                        alignment: Alignment.bottomCenter,
                                        child: InkWell(
                                          onTap: controller.pickThumbnail,
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6),
                                            color: Colors.black
                                                .withValues(alpha: 0.65),
                                            child: const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.edit,
                                                    color: Colors.white,
                                                    size: 12),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Edit',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const Spacer(),
                              // Right column: language, Edit Interest,
                              // Video ON, Auto Call — top-right stack.
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Obx(() {
                                    final hasError = controller.languageHasError.value;
                                    final lang = controller.selectedLanguage.value;
                                    return GestureDetector(
                                      onTap: () {
                                        controller.languageHasError.value = false;
                                        _showLanguagePicker(context, controller);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        constraints: const BoxConstraints(maxWidth: 160),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: hasError
                                              ? Colors.red.withValues(alpha: 0.25)
                                              : Colors.black.withValues(alpha: 0.55),
                                          borderRadius: BorderRadius.circular(20),
                                          border: hasError
                                              ? Border.all(color: Colors.redAccent, width: 1.5)
                                              : null,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (hasError)
                                              const Icon(Icons.warning_amber_rounded,
                                                  size: 13, color: Colors.redAccent)
                                            else
                                              const SizedBox.shrink(),
                                            if (hasError) const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                lang?.title ?? 'Language',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: hasError ? Colors.redAccent : Colors.white,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            Icon(
                                              Icons.keyboard_arrow_down,
                                              size: 14,
                                              color: hasError ? Colors.redAccent : Colors.white70,
                                            ),
                                          ],
                                        ),
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
                        const SizedBox(height: 10),
                        // Bottom sheet — Host Live Show
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
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
                                    const SizedBox(height: 14),
                                    Text('Join Call Seats (Max 7)',
                                        style: TextStyleCustom.outFitLight300(
                                            fontSize: 13,
                                            color: whitePure(context)
                                                .withValues(alpha: .7))),
                                    const SizedBox(height: 8),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      child: Obx(() => Row(
                                            children: controller.seatOptions
                                                .map((seats) {
                                              final isSelected = controller
                                                      .maxParticipants.value ==
                                                  seats;
                                              return GestureDetector(
                                                onTap: () {
                                                  HapticManager.shared.light();
                                                  controller.maxParticipants
                                                      .value = seats;
                                                },
                                                child: Container(
                                                  margin: const EdgeInsets.only(
                                                      right: 8),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? ColorRes.primaryColor
                                                            .withValues(
                                                                alpha: 0.25)
                                                        : Colors.white
                                                            .withValues(
                                                                alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? ColorRes.primaryColor
                                                          : whitePure(context)
                                                              .withValues(
                                                                  alpha: .25),
                                                      width: isSelected
                                                          ? 1.5
                                                          : 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '$seats ${seats == 1 ? "Seat" : "Seats"}',
                                                    style: TextStyleCustom
                                                        .outFitRegular400(
                                                      fontSize: 13,
                                                      color: isSelected
                                                          ? ColorRes.primaryColor
                                                          : whitePure(context),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          )),
                                    ),
                                    const SizedBox(height: 16),
                                    Text('Choose Category',
                                        style: TextStyleCustom.outFitLight300(
                                            fontSize: 13,
                                            color: whitePure(context)
                                                .withValues(alpha: .7))),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 86,
                                      child: Obx(() {
                                        // Subscribe to selectedCategory so Obx rebuilds on category switch
                                        final _ = controller.selectedCategory.value;
                                        return ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount:
                                              controller.categoryList.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 10),
                                          itemBuilder: (context, index) {
                                            final category =
                                                controller.categoryList[index];
                                            final isSelected = controller
                                                .isCategorySelected(category);
                                            return _CategoryTile3D(
                                              name: category.name ?? '',
                                              isSelected: isSelected,
                                              onTap: () => controller
                                                  .onCategoryChanged(category),
                                            );
                                          },
                                        );
                                      }),
                                    ),
                                    // Sub Category section
                                    Obx(() {
                                      final currentCat = controller.selectedCategory.value;
                                      final currentSub = controller.selectedSubCategory.value;
                                      if (currentCat == null) return const SizedBox.shrink();
                                      final subs = currentCat.subCategories ?? [];
                                      if (subs.isEmpty) return const SizedBox.shrink();

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 14),
                                          Text(
                                            'Choose Sub Category',
                                            style: TextStyleCustom.outFitLight300(
                                              fontSize: 13,
                                              color: whitePure(context).withValues(alpha: .7),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 38,
                                            child: ListView.separated(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: subs.length,
                                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                                              itemBuilder: (context, index) {
                                                final sub = subs[index];
                                                final isSelected = controller.isSubCategorySelected(sub);
                                                return GestureDetector(
                                                  behavior: HitTestBehavior.opaque,
                                                  onTap: () => controller.onSubCategoryChanged(sub),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 200),
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      gradient: isSelected
                                                          ? const LinearGradient(
                                                              colors: [ColorRes.primaryColor, ColorRes.primaryColorEnd],
                                                            )
                                                          : null,
                                                      color: isSelected
                                                          ? null
                                                          : Colors.white.withValues(alpha: 0.08),
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? Colors.white
                                                            : Colors.white.withValues(alpha: 0.2),
                                                        width: isSelected ? 1.5 : 1,
                                                      ),
                                                      boxShadow: isSelected
                                                          ? [
                                                              BoxShadow(
                                                                color: ColorRes.primaryColor.withValues(alpha: 0.45),
                                                                blurRadius: 8,
                                                                spreadRadius: 1,
                                                              ),
                                                            ]
                                                          : null,
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      sub.name ?? '',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12.5,
                                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                    // Topic section
                                    Obx(() {
                                      final currentSub = controller.selectedSubCategory.value;
                                      final currentTopic = controller.selectedTopic.value;
                                      if (currentSub == null) return const SizedBox.shrink();
                                      final topics = currentSub.topics ?? [];
                                      if (topics.isEmpty) return const SizedBox.shrink();

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 14),
                                          Text(
                                            'Choose Topic',
                                            style: TextStyleCustom.outFitLight300(
                                              fontSize: 13,
                                              color: whitePure(context).withValues(alpha: .7),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 34,
                                            child: ListView.separated(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: topics.length,
                                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                                              itemBuilder: (context, index) {
                                                final topic = topics[index];
                                                final isSelected = controller.isTopicSelected(topic);
                                                return GestureDetector(
                                                  behavior: HitTestBehavior.opaque,
                                                  onTap: () => controller.onTopicChanged(topic),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 200),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      gradient: isSelected
                                                          ? const LinearGradient(
                                                              colors: [ColorRes.primaryColor, ColorRes.primaryColorEnd],
                                                            )
                                                          : null,
                                                      color: isSelected
                                                          ? null
                                                          : Colors.white.withValues(alpha: 0.06),
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? Colors.white
                                                            : Colors.white.withValues(alpha: 0.15),
                                                        width: isSelected ? 1.5 : 1,
                                                      ),
                                                      boxShadow: isSelected
                                                          ? [
                                                              BoxShadow(
                                                                color: ColorRes.primaryColor.withValues(alpha: 0.4),
                                                                blurRadius: 6,
                                                              ),
                                                            ]
                                                          : null,
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      topic.name ?? '',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11.5,
                                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                    const SizedBox(height: 16),
                                    Text('Select Hashtag',
                                        style: TextStyleCustom.outFitLight300(
                                            fontSize: 13,
                                            color: whitePure(context)
                                                .withValues(alpha: .7))),
                                    const SizedBox(height: 8),
                                    Obx(() {
                                      // Show admin preloaded hashtags (up to 5)
                                      // as quick-pick chips so the section is
                                      // never empty. If none are loaded yet, fall
                                      // back to the 'None' placeholder.
                                      final available = controller.availableHashtags;
                                      final selected = controller.selectedHashtags;

                                      final quickPicks = available
                                          .where((h) => !selected.any((s) => s.id == h.id))
                                          .take(5)
                                          .toList();

                                      return Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          // Selected hashtags always shown first
                                          ...selected.map((h) => _HashtagChip(
                                                label: '#${h.hashtag}',
                                                isSelected: true,
                                                onTap: () =>
                                                    controller.toggleHashtag(h),
                                              )),
                                          // Quick-pick from admin list (not yet selected)
                                          ...quickPicks.map((h) => _HashtagChip(
                                                label: '#${h.hashtag}',
                                                isSelected: false,
                                                onTap: () =>
                                                    controller.toggleHashtag(h),
                                              )),
                                          // If nothing is loaded yet, show 'None'
                                          if (available.isEmpty && selected.isEmpty)
                                            _HashtagChip(
                                              label: 'None',
                                              isSelected: true,
                                              onTap: () {},
                                            ),
                                          // + More always last
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
                                      );
                                    }),
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
            activeThumbColor: ColorRes.primaryColor,
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

  const _CategoryTile3D({
    super.key,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  static const _iconsByKeyword = <String, IconData>{
    // Education & Academics — matches screenshot icons
    'engineer': Icons.handyman_rounded,
    'engineering': Icons.handyman_rounded,
    'exam': Icons.category_rounded,
    'test': Icons.category_rounded,
    'medical': Icons.local_hospital_rounded,
    'health': Icons.local_hospital_rounded,
    'doctor': Icons.medical_services_rounded,
    'school': Icons.school_rounded,
    'education': Icons.school_rounded,
    'college': Icons.school_rounded,
    'study': Icons.menu_book_rounded,
    'math': Icons.calculate_rounded,
    'science': Icons.science_rounded,
    'chemistry': Icons.science_rounded,
    'physics': Icons.bolt_rounded,
    'biology': Icons.biotech_rounded,
    'law': Icons.gavel_rounded,
    'business': Icons.business_center_rounded,
    'finance': Icons.account_balance_rounded,
    'tech': Icons.computer_rounded,
    'coding': Icons.code_rounded,
    'program': Icons.terminal_rounded,
    'language': Icons.translate_rounded,
    'english': Icons.abc_rounded,
    // Entertainment & Lifestyle
    'live': Icons.videocam_rounded,
    'show': Icons.videocam_rounded,
    'video': Icons.play_circle_rounded,
    'party': Icons.celebration_rounded,
    'sing': Icons.mic_rounded,
    'music': Icons.music_note_rounded,
    'dance': Icons.nightlife_rounded,
    'comedy': Icons.sentiment_very_satisfied_rounded,
    'funny': Icons.sentiment_very_satisfied_rounded,
    'game': Icons.sports_esports_rounded,
    'sport': Icons.sports_soccer_rounded,
    'fitness': Icons.fitness_center_rounded,
    'cook': Icons.restaurant_rounded,
    'food': Icons.fastfood_rounded,
    'travel': Icons.flight_rounded,
    'art': Icons.palette_rounded,
    'fashion': Icons.checkroom_rounded,
    'news': Icons.newspaper_rounded,
    'religion': Icons.self_improvement_rounded,
    'spiritual': Icons.self_improvement_rounded,
  };

  IconData get _icon {
    final lower = name.toLowerCase().trim();
    for (final entry in _iconsByKeyword.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF5200), Color(0xFFFF7A00)],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white12,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF5200).withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Color(0xFFFF5200),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFFF8533)
                    : Colors.white.withValues(alpha: 0.75),
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
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
