import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/functions/media_picker_helper.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/search_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/common/widget/level_badge.dart';
import 'package:geoedu/model/audio_call/audio_room.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/post_story/hashtag_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/audio_call/audio_room_screen.dart';
import 'package:geoedu/screen/live_stream/go_live_shared_state.dart';
import 'package:geoedu/utilities/audio_theme_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/firebase_const.dart';

// ─── Controller ───

class CreateAudioRoomController extends BaseController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Rx<User?> myUser = Rx(SessionManager.instance.getUser());

  // Edits the host's own display name — separate from the room's own name.
  final displayNameController = TextEditingController();
  final chatRoomController = TextEditingController();

  // Language/hashtag/auto-call are shared with the Video tab of the
  // Go-Live setup screen so switching tabs doesn't lose the host's choices.
  GoLiveSharedState get _shared => Get.find<GoLiveSharedState>();
  RxList<Language> get languageList => _shared.languageList;
  Rx<Language?> get selectedLanguage => _shared.selectedLanguage;
  RxList<Hashtag> get selectedHashtags => _shared.selectedHashtags;
  RxBool get isAutoMode => _shared.isAutoMode;

  // Hidden default — not user-editable, matches the reference UI which has
  // no Max Participants control.
  static const int maxParticipants = 8;
  RxList<XFile> musicFiles = <XFile>[].obs;
  RxList<String> musicFileNames = <String>[].obs;
  Rx<XFile?> backgroundImageFile = Rx(null);
  RxString backgroundImageUrl = ''.obs;
  Rx<int?> selectedThemeIndex = Rx(null);

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<GoLiveSharedState>()) Get.put(GoLiveSharedState());
  }

  void onLanguageChanged(Language? value) {
    _shared.onLanguageChanged(value);
  }

  void toggleHashtag(Hashtag hashtag) {
    _shared.toggleHashtag(hashtag);
  }

  void pickAndUploadAvatar() async {
    final image =
        await MediaPickerHelper.shared.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    showLoader();
    try {
      final updated =
          await UserService.instance.updateUserDetails(profilePhoto: image);
      if (updated != null) myUser.value = updated;
    } catch (_) {
      showSnackBar('Failed to update photo');
    }
    stopLoader();
  }

  /// Commits an edited display name on submit — not on every keystroke, so
  /// this doesn't spam the profile-update API while the host is still typing.
  Future<void> submitNameEdit(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == myUser.value?.fullname) return;
    try {
      final updated =
          await UserService.instance.updateUserDetails(fullname: trimmed);
      if (updated != null) myUser.value = updated;
    } catch (_) {
      showSnackBar('Failed to update name');
    }
  }

  void pickBackgroundImage() async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take Photo',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                _pickBgImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                _pickBgImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickBgImage(ImageSource source) async {
    final image = await MediaPickerHelper.shared.pickImage(source: source);
    if (image != null) {
      backgroundImageFile.value = image;
      backgroundImageUrl.value = image.path;
      // A custom image and a preset theme are mutually exclusive, same as
      // the in-room Themes feature already enforces.
      selectedThemeIndex.value = null;
    }
  }

  void selectTheme(int index) {
    selectedThemeIndex.value = index;
    backgroundImageFile.value = null;
    backgroundImageUrl.value = '';
  }

  void removeMusicFileAt(int index) {
    if (index < 0 || index >= musicFiles.length) return;
    musicFiles.removeAt(index);
    musicFileNames.removeAt(index);
  }

  void pickMusicFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'aac', 'wav', 'm4a', 'ogg', 'wma', 'flac'],
      allowMultiple: true,
    );
    if (result == null) return;
    for (final file in result.files) {
      if (file.path == null) continue;
      musicFiles.add(XFile(file.path!));
      musicFileNames.add(file.name);
    }
  }

  Future<void> onGoLive() async {
    if (chatRoomController.text.trim().isEmpty) {
      return showSnackBar('Please enter a chatroom name');
    }
    if (selectedLanguage.value == null) {
      return showSnackBar('Please select a language');
    }

    final user = myUser.value;
    if (user?.id == null) return;

    showLoader();

    try {
      // Upload background image if selected
      String? bgImagePath;
      if (backgroundImageFile.value != null) {
        final result = await CommonService.instance
            .uploadFileGivePath(backgroundImageFile.value!);
        bgImagePath = result.data;
      }

      // Upload each picked song — the room plays them as a playlist.
      final List<String> musicPaths = [];
      for (final file in musicFiles) {
        final result = await CommonService.instance.uploadFileGivePath(file);
        if (result.data != null) musicPaths.add(result.data!);
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final roomId = 'room_${user!.id}_$now';

      final hashtagString =
          selectedHashtags.map((h) => '#${h.hashtag}').join(' ');

      final room = AudioRoom(
        roomId: roomId,
        hostId: user.id,
        hostName: user.fullname ?? '',
        hostPhoto: user.profilePhoto ?? '',
        roomName: chatRoomController.text.trim(),
        maxParticipants: maxParticipants,
        participantIds: [user.id!],
        createdAt: now,
        isActive: true,
        languageId: selectedLanguage.value?.id,
        languageName: selectedLanguage.value?.title,
        isAutoMode: isAutoMode.value,
        chatRoomField: chatRoomController.text.trim(),
        hashtag: hashtagString,
        musicUrls: musicPaths,
        backgroundImage: bgImagePath,
        themeIndex: selectedThemeIndex.value,
      );

      await _db
          .collection(FirebaseConst.audioRooms)
          .doc(user.id.toString())
          .set(room.toJson());

      stopLoader();

      Get.off(() => AudioRoomScreen(room: room, isHost: true));
    } catch (e) {
      stopLoader();
      showSnackBar('Failed to create room');
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
      body: Stack(
        children: [
          // Selected theme as a full-screen, dimmed background — changes
          // live when a theme card below is tapped.
          Obx(() {
            final index = controller.selectedThemeIndex.value;
            final customPath = controller.backgroundImageUrl.value;
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: customPath.isEmpty
                    ? LinearGradient(
                        colors: index != null
                            ? AudioThemeRes.presets[index]
                            : AudioThemeRes.presets.first,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                image: customPath.isNotEmpty
                    ? DecorationImage(
                        image: FileImage(File(customPath)), fit: BoxFit.cover)
                    : null,
              ),
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            );
          }),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "< Host Live Show" + white language pill + Auto Call
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        padding: EdgeInsets.zero,
                      ),
                      const Text('Host Live Show',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Obx(() => GestureDetector(
                            onTap: () =>
                                _showLanguagePicker(context, controller),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                      controller
                                              .selectedLanguage.value?.title ??
                                          'Language',
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const Icon(Icons.keyboard_arrow_down,
                                      color: Colors.black, size: 16),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Auto Call',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        Obx(() => Switch(
                              value: controller.isAutoMode.value,
                              onChanged: (val) =>
                                  controller.isAutoMode.value = val,
                              activeColor: ColorRes.primaryColor,
                              inactiveTrackColor: Colors.white24,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Profile Image & Name
                  Center(
                    child: Obx(() {
                      final user = controller.myUser.value;
                      return Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          ClipOval(
                            child: CustomImage(
                              size: const Size(80, 80),
                              image: user?.profilePhoto?.addBaseURL(),
                              fullName: user?.fullname,
                            ),
                          ),
                          GestureDetector(
                            onTap: controller.pickAndUploadAvatar,
                            child: Container(
                              width: 80,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit,
                                      color: Colors.white, size: 11),
                                  SizedBox(width: 3),
                                  Text('Edit',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Enter your name — editable, prefilled + level badge
                  _buildLabel('Enter your name'),
                  const SizedBox(height: 6),
                  Obx(() {
                    final user = controller.myUser.value;
                    if (controller.displayNameController.text.isEmpty) {
                      controller.displayNameController.text =
                          user?.fullname ?? '';
                    }
                    return Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller.displayNameController,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                              onTapOutside: (_) =>
                                  FocusManager.instance.primaryFocus?.unfocus(),
                              onSubmitted: controller.submitNameEdit,
                              onEditingComplete: () =>
                                  controller.submitNameEdit(
                                      controller.displayNameController.text),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          LevelBadge(
                              level: user?.getLevel.level,
                              navigateOnTap: false),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Chatroom Name
                  _buildLabel('Chatroom Name'),
                  const SizedBox(height: 6),
                  _buildOutlinedTextField(controller.chatRoomController, ''),
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Examples: Gf Bf online setting, Will u be my friend?, I Love U, Just Chill, Bewafa Nikli Tu, Dosti Aur Pyaar',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hashtag Multi-Select
                  _buildLabel('Hashtags'),
                  const SizedBox(height: 6),
                  // Selected hashtags chips
                  Obx(() {
                    if (controller.selectedHashtags.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: controller.selectedHashtags.map((h) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: ColorRes.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: ColorRes.primaryColor
                                        .withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#${h.hashtag}',
                                    style: const TextStyle(
                                        color: ColorRes.primaryColor, fontSize: 13),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => controller.toggleHashtag(h),
                                    child: const Icon(Icons.close,
                                        color: ColorRes.primaryColor, size: 16),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  // Search & select button
                  GestureDetector(
                    onTap: () => _showHashtagPickerSheet(context, controller),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.tag, color: ColorRes.primaryColor, size: 22),
                          SizedBox(width: 12),
                          Text(
                            'Tap to select hashtags',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 15),
                          ),
                          Spacer(),
                          Icon(Icons.arrow_forward_ios,
                              color: Colors.white38, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Music Playlist Upload
                  Row(
                    children: [
                      const Icon(Icons.music_note, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      _buildLabel('Music Player'),
                      const Spacer(),
                      GestureDetector(
                        onTap: controller.pickMusicFile,
                        child: const Text('See more',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0;
                              i < controller.musicFileNames.length;
                              i++)
                            Container(
                              height: 50,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.15)),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 13),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.music_note,
                                      color: ColorRes.primaryColor, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      controller.musicFileNames[i],
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        controller.removeMusicFileAt(i),
                                    child: const Icon(Icons.close,
                                        color: Colors.redAccent, size: 20),
                                  ),
                                ],
                              ),
                            ),
                          GestureDetector(
                            onTap: controller.pickMusicFile,
                            child: Container(
                              height: 50,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.15)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.add,
                                      color: ColorRes.primaryColor, size: 22),
                                  const SizedBox(width: 12),
                                  Text(
                                    controller.musicFileNames.isEmpty
                                        ? 'Tap to upload music'
                                        : 'Add more songs',
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )),
                  const SizedBox(height: 16),

                  // Theme presets
                  _buildLabel('Room Theme'),
                  const SizedBox(height: 6),
                  Obx(() => SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: AudioThemeRes.presets.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            if (index == AudioThemeRes.presets.length) {
                              final isCustom = controller
                                  .backgroundImageUrl.value.isNotEmpty;
                              return GestureDetector(
                                onTap: controller.pickBackgroundImage,
                                child: Container(
                                  width: 68,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCustom
                                          ? ColorRes.primaryColor
                                          : Colors.white.withOpacity(0.15),
                                      width: isCustom ? 2 : 1,
                                    ),
                                    image: isCustom
                                        ? DecorationImage(
                                            image: FileImage(File(controller
                                                .backgroundImageUrl.value)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: isCustom
                                      ? null
                                      : const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
                                                color: Colors.white54,
                                                size: 24),
                                            SizedBox(height: 4),
                                            Text('Custom',
                                                style: TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 11)),
                                          ],
                                        ),
                                ),
                              );
                            }
                            final isSelected =
                                controller.selectedThemeIndex.value == index;
                            return GestureDetector(
                              onTap: () => controller.selectTheme(index),
                              child: Container(
                                width: 68,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: AudioThemeRes.presets[index],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? ColorRes.primaryColor
                                        : Colors.white.withOpacity(0.15),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_circle,
                                        color: ColorRes.primaryColor, size: 22)
                                    : null,
                              ),
                            );
                          },
                        ),
                      )),
                  const SizedBox(height: 30),

                  // Go Live Button
                  GestureDetector(
                    onTap: controller.onGoLive,
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: ColorRes.primaryGradient,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Go Live',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildOutlinedTextField(TextEditingController controller, String hint) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _showLanguagePicker(
      BuildContext context, CreateAudioRoomController controller) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.6),
        decoration: const BoxDecoration(
          color: Color(0xFF0C203C),
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
        color: Color(0xFF0C203C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
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
          // Title & Done
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
          // Search field
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
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
                    color: Colors.white.withOpacity(0.4), fontSize: 15),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Results list
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
                                ? ColorRes.primaryColor.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          color: Colors.white38, fontSize: 12),
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
