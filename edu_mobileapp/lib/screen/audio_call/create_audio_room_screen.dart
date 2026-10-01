import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/functions/media_picker_helper.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/search_service.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/audio_call/audio_room.dart';
import 'package:geoedu/model/general/category_sub_category_topic_model.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/post_story/hashtag_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/audio_call/audio_room_screen.dart';
import 'package:geoedu/screen/live_stream/go_live_shared_state.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/firebase_const.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geoedu/utilities/text_style_custom.dart';

// ─── Controller ───

class CreateAudioRoomController extends BaseController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Rx<User?> myUser = Rx(SessionManager.instance.getUser());

  final chatRoomController = TextEditingController();

  // Language/hashtag/auto-call shared with the Video tab of Go-Live setup screen
  GoLiveSharedState get _shared => Get.find<GoLiveSharedState>();
  RxList<Language> get languageList => _shared.languageList;
  Rx<Language?> get selectedLanguage => _shared.selectedLanguage;
  RxList<Hashtag> get selectedHashtags => _shared.selectedHashtags;
  RxBool get isAutoMode => _shared.isAutoMode;

  // Real-time categories fetched from CommonService
  RxList<Category> categoryList = <Category>[].obs;
  Rx<Category?> selectedCategory = Rx(null);
  Rx<SubCategory?> selectedSubCategory = Rx(null);
  Rx<Topic?> selectedTopic = Rx(null);

  // Host cover thumbnail card
  Rx<XFile?> thumbnailFile = Rx(null);
  RxString thumbnailPreviewPath = ''.obs;

  // Video OFF/ON switch (audio defaults to OFF)
  RxBool isVideoOn = false.obs;

  // Room type selection
  RxString selectedRoomType = 'audio_pk'.obs;
  final List<Map<String, String>> roomTypes = [
    {'value': 'audio_pk', 'label': 'Audio Room + PK'},
    {'value': 'audio_room', 'label': 'Audio Room'},
  ];

  static const int maxParticipants = 8;
  Rx<int?> selectedThemeIndex = Rx(0);

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<GoLiveSharedState>()) Get.put(GoLiveSharedState());
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final result =
          await CommonService.instance.fetchCategorySubCategoryTopic();
      categoryList.value = result.data ?? [];
      if (categoryList.isNotEmpty && selectedCategory.value == null) {
        selectedCategory.value = categoryList.first;
      }
    } catch (e) {
      Loggers.error('CreateAudioRoomController fetchCategories error: $e');
    }
  }

  void onCategoryChanged(Category? value) {
    selectedCategory.value = value;
    selectedSubCategory.value = null;
    selectedTopic.value = null;
  }

  void onSubCategoryChanged(SubCategory? value) {
    selectedSubCategory.value = value;
    selectedTopic.value = null;
  }

  void onTopicChanged(Topic? value) {
    selectedTopic.value = value;
  }

  void onLanguageChanged(Language? value) {
    _shared.onLanguageChanged(value);
  }

  void toggleHashtag(Hashtag hashtag) {
    _shared.toggleHashtag(hashtag);
  }

  void toggleVideoOn(bool value) {
    isVideoOn.value = value;
  }

  void pickThumbnail() async {
    final image =
        await MediaPickerHelper.shared.pickImage(source: ImageSource.gallery);
    if (image != null) {
      thumbnailFile.value = image;
      thumbnailPreviewPath.value = image.path;
    }
  }

  Future<void> onGoLive() async {
    final user = myUser.value;
    if (user?.id == null) return;

    if (selectedLanguage.value == null && languageList.isNotEmpty) {
      selectedLanguage.value = languageList.first;
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      showSnackBar('Microphone permission is required to start live audio');
      return;
    }

    showLoader();
    try {
      String hostPhotoUrl = user!.profilePhoto ?? '';
      if (thumbnailFile.value != null) {
        final res = await CommonService.instance
            .uploadFileGivePath(thumbnailFile.value!);
        if (res.data != null && res.data!.isNotEmpty) {
          hostPhotoUrl = res.data!;
        }
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final roomId = 'room_${user.id}_$now';
      final roomTitle = chatRoomController.text.trim().isNotEmpty
          ? chatRoomController.text.trim()
          : (selectedCategory.value?.name != null
              ? "${user.fullname ?? 'Host'}'s ${selectedCategory.value!.name} Room"
              : "${user.fullname ?? 'Host'}'s Live Show");

      final hashtagString =
          selectedHashtags.map((h) => '#${h.hashtag}').join(' ');

      final room = AudioRoom(
        roomId: roomId,
        hostId: user.id,
        hostName: user.fullname ?? '',
        hostPhoto: hostPhotoUrl,
        roomName: roomTitle,
        maxParticipants: maxParticipants,
        participantIds: [user.id!],
        speakerIds: [user.id!],
        requestIds: [],
        createdAt: now,
        isActive: true,
        languageId: selectedLanguage.value?.id,
        languageName: selectedLanguage.value?.title,
        isAutoMode: isAutoMode.value,
        chatRoomField: roomTitle,
        hashtag: hashtagString,
        musicUrls: [],
        backgroundImage: null,
        themeIndex: selectedThemeIndex.value ?? 0,
        categoryId: selectedCategory.value?.id,
        categoryName: selectedCategory.value?.name,
      );

      // Purge leftover comments & gifts from any previous live so the new room starts fresh
      try {
        final hostDocRef = _db.collection(FirebaseConst.audioRooms).doc(user.id.toString());
        final oldComments = await hostDocRef.collection('comments').limit(300).get();
        if (oldComments.docs.isNotEmpty) {
          final batchDelete = _db.batch();
          for (final doc in oldComments.docs) {
            batchDelete.delete(doc.reference);
          }
          await batchDelete.commit();
        }
        final oldGifts = await hostDocRef.collection('gifts').limit(100).get();
        if (oldGifts.docs.isNotEmpty) {
          final batchGifts = _db.batch();
          for (final doc in oldGifts.docs) {
            batchGifts.delete(doc.reference);
          }
          await batchGifts.commit();
        }
      } catch (e) {
        Loggers.error('Error clearing old live room subcollections: $e');
      }

      await _db
          .collection(FirebaseConst.audioRooms)
          .doc(user.id.toString())
          .set(room.toJson());

      stopLoader();
      Get.off(() => AudioRoomScreen(room: room, isHost: true));
    } catch (e) {
      stopLoader();
      showSnackBar('Failed to create room: $e');
    }
  }
}

// ─── Screen ───

class CreateAudioRoomScreen extends StatelessWidget {
  const CreateAudioRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateAudioRoomController());

    return Scaffold(
      backgroundColor: ColorRes.blackPure,
      body: SafeArea(
        child: Column(
          children: [
            // Top back button
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  onPressed: () => Get.back(),
                ),
              ),
            ),

            // Top section: Left thumbnail card + glowing pink circular avatar + right settings stack
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Left: Host cover photo thumbnail card
                  Positioned(
                    left: 18,
                    top: 6,
                    child: _buildThumbnailCard(context, controller),
                  ),

                  // Right: Language, Edit Interest, Video OFF, Auto Call
                  Positioned(
                    right: 18,
                    top: 0,
                    child: _buildTopRightSettings(context, controller),
                  ),

                  // Center: Glowing Neon Pink Circular Avatar
                  Positioned(
                    child: _buildGlowingAvatar(controller),
                  ),
                ],
              ),
            ),

            // Bottom section: Host Live Show Card
            _buildHostLiveShowCard(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowingAvatar(CreateAudioRoomController controller) {
    return Obx(() {
      final user = controller.myUser.value;
      return Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFF2A85), width: 3.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2A85).withValues(alpha: 0.65),
              blurRadius: 18,
              spreadRadius: 3,
            ),
            BoxShadow(
              color: const Color(0xFFFF2A85).withValues(alpha: 0.25),
              blurRadius: 36,
              spreadRadius: 6,
            ),
          ],
        ),
        child: ClipOval(
          child: CustomImage(
            size: const Size(104, 104),
            image: user?.profilePhoto?.addBaseURL(),
            fullName: user?.fullname,
          ),
        ),
      );
    });
  }

  Widget _buildThumbnailCard(
      BuildContext context, CreateAudioRoomController controller) {
    return Obx(() {
      final user = controller.myUser.value;
      final hasPreview = controller.thumbnailPreviewPath.value.isNotEmpty;
      return InkWell(
        onTap: controller.pickThumbnail,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 88,
          height: 122,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 16,
                cornerSmoothing: 1,
              ),
            ),
            image: hasPreview
                ? DecorationImage(
                    image:
                        FileImage(File(controller.thumbnailPreviewPath.value)),
                    fit: BoxFit.cover,
                  )
                : (user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(user.profilePhoto!.addBaseURL()),
                        fit: BoxFit.cover,
                      )
                    : null),
          ),
          child: Stack(
            children: [
              if (!hasPreview &&
                  (user?.profilePhoto == null || user!.profilePhoto!.isEmpty))
                const Center(
                  child: Icon(Icons.add_a_photo_outlined,
                      color: Colors.white70, size: 24),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  color: Colors.black.withValues(alpha: 0.6),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 11),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTopRightSettings(
      BuildContext context, CreateAudioRoomController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Language selector
        Obx(() => _CompactDarkPill(
              icon: null,
              label: controller.selectedLanguage.value?.title ?? 'Language',
              onTap: () => _showLanguagePicker(context, controller),
            )),
        const SizedBox(height: 8),

        // Edit Interest
        Obx(() {
          final parts = [
            controller.selectedCategory.value?.name,
            controller.selectedSubCategory.value?.name,
            controller.selectedTopic.value?.name,
          ].whereType<String>().toList();
          return _CompactDarkPill(
            icon: Icons.edit_outlined,
            label: parts.isEmpty ? 'Edit Interest' : parts.join(' · '),
            onTap: () => Get.bottomSheet(
              _InterestPickerSheet(controller: controller),
              isScrollControlled: true,
              ignoreSafeArea: false,
            ),
          );
        }),
        const SizedBox(height: 10),

        // Video OFF / ON
        Obx(() => _ToggleRow(
              label: controller.isVideoOn.value ? 'Video ON' : 'Video OFF',
              value: controller.isVideoOn.value,
              onChanged: controller.toggleVideoOn,
            )),
        const SizedBox(height: 6),

        // Auto Call
        Obx(() => _ToggleRow(
              label: 'Auto Call',
              value: controller.isAutoMode.value,
              onChanged: (v) => controller.isAutoMode.value = v,
            )),
      ],
    );
  }

  Widget _buildHostLiveShowCard(
      BuildContext context, CreateAudioRoomController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161922).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title: Host Live Show + Soundwave Equalizer
          Row(
            children: [
              Text(
                'Host Live Show',
                style: TextStyleCustom.unboundedMedium500(
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 12),
              const _AudioSoundwaveIcon(),
            ],
          ),
          const SizedBox(height: 12),

          // Room Type
          Text(
            'Room Type',
            style: TextStyleCustom.outFitLight300(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 7),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.roomTypes.map((mode) {
                  final isSelected =
                      controller.selectedRoomType.value == mode['value'];
                  return GestureDetector(
                    onTap: () =>
                        controller.selectedRoomType.value = mode['value']!,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? ColorRes.primaryColor
                              : Colors.white.withValues(alpha: 0.25),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        mode['label']!,
                        style: TextStyleCustom.outFitRegular400(
                          fontSize: 13.5,
                          color: isSelected
                              ? ColorRes.primaryColor
                              : Colors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )),
          const SizedBox(height: 14),

          // Choose Category
          Text(
            'Choose Category',
            style: TextStyleCustom.outFitLight300(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 76,
            child: Obx(() {
              if (controller.categoryList.isEmpty) {
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorRes.primaryColor,
                    ),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.categoryList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = controller.categoryList[index];
                  final isSelected =
                      controller.selectedCategory.value?.id == category.id;
                  return _CategoryTile3D(
                    name: category.name ?? '',
                    isSelected: isSelected,
                    onTap: () => controller.onCategoryChanged(category),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 14),

          // Select Hashtag
          Text(
            'Select Hashtag',
            style: TextStyleCustom.outFitLight300(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 7),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HashtagChip(
                    label: 'None',
                    isSelected: controller.selectedHashtags.isEmpty,
                    onTap: () {
                      for (final h in List.of(controller.selectedHashtags)) {
                        controller.toggleHashtag(h);
                      }
                    },
                  ),
                  ...controller.selectedHashtags.map((h) => _HashtagChip(
                        label: '#${h.hashtag}',
                        isSelected: true,
                        onTap: () => controller.toggleHashtag(h),
                      )),
                  GestureDetector(
                    onTap: () => _showHashtagPickerSheet(context, controller),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'More',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )),
          const SizedBox(height: 16),

          // Go Live Button
          InkWell(
            onTap: controller.onGoLive,
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: ColorRes.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Text(
                'Go Live',
                style: TextStyleCustom.unboundedMedium500(
                  color: Colors.white,
                  fontSize: 16.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHashtagPickerSheet(
      BuildContext context, CreateAudioRoomController controller) {
    Get.bottomSheet(
      _HashtagPickerSheet(controller: controller),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  void _showLanguagePicker(
      BuildContext context, CreateAudioRoomController controller) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.6),
        decoration: const BoxDecoration(
          color: Color(0xFF1E2130),
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

// ─── Soundwave Equalizer Bars ───

class _AudioSoundwaveIcon extends StatelessWidget {
  const _AudioSoundwaveIcon();

  @override
  Widget build(BuildContext context) {
    const bars = [8.0, 16.0, 24.0, 18.0, 10.0];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: bars
          .map((h) => Container(
                width: 3.5,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFB5E853),
                  borderRadius: BorderRadius.circular(2),
                ),
              ))
          .toList(),
    );
  }
}

// ─── Top-Right Pill & Switch Helpers ───

class _CompactDarkPill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  const _CompactDarkPill({
    this.icon,
    required this.label,
    required this.onTap,
  });

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
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.keyboard_arrow_down,
                size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
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

// ─── Category & Hashtag Widgets ───

class _CategoryTile3D extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile3D({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  static const _iconsByKeyword = <String, IconData>{
    'live': Icons.videocam_rounded,
    'show': Icons.videocam_rounded,
    'party': Icons.celebration_rounded,
    'sing': Icons.mic_rounded,
    'music': Icons.music_note_rounded,
    'dance': Icons.nightlife_rounded,
    'comedy': Icons.sentiment_very_satisfied_rounded,
    'funny': Icons.sentiment_very_satisfied_rounded,
    'astro': Icons.public_rounded,
    'room': Icons.meeting_room_rounded,
    'chat': Icons.chat_bubble_rounded,
    'game': Icons.sports_esports_rounded,
    'educat': Icons.school_rounded,
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
                  color:
                      isSelected ? ColorRes.primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(_icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? ColorRes.primaryColor : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HashtagChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _HashtagChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? ColorRes.primaryColor : Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Interest (Category / Sub-Category / Topic) Picker Sheet ───

class _InterestPickerSheet extends StatelessWidget {
  final CreateAudioRoomController controller;

  const _InterestPickerSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF1E2130),
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
                const Text(
                  'Edit Interest',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: ColorRes.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              label(item),
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Hashtag Picker Bottom Sheet ───

class _HashtagPickerSheet extends StatefulWidget {
  final CreateAudioRoomController controller;

  const _HashtagPickerSheet({required this.controller});

  @override
  State<_HashtagPickerSheet> createState() => _HashtagPickerSheetState();
}

class _HashtagPickerSheetState extends State<_HashtagPickerSheet> {
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
        color: Color(0xFF1E2130),
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
                const Text(
                  'Select Hashtags',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: ColorRes.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Obx(() => Text(
                          'Done (${widget.controller.selectedHashtags.length})',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
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
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                prefixIcon: const Icon(Icons.search,
                    color: Colors.white38, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              if (isLoading.value && searchResults.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: ColorRes.primaryColor,
                    strokeWidth: 2,
                  ),
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
                                ? ColorRes.primaryColor.withValues(alpha: 0.12)
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
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${hashtag.postCount ?? 0} posts',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
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
