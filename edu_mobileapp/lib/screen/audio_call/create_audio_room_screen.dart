import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/functions/media_picker_helper.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/common/service/api/search_service.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/audio_call/audio_room.dart';
import 'package:geoedu/model/general/category_sub_category_topic_model.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/post_story/hashtag_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/audio_call/audio_room_controller.dart';
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

  // Input Controllers
  late final TextEditingController nameController;
  final TextEditingController chatRoomController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Shared state with LiveStream video setup
  GoLiveSharedState get _shared => Get.find<GoLiveSharedState>();
  RxList<Language> get languageList => _shared.languageList;
  Rx<Language?> get selectedLanguage => _shared.selectedLanguage;
  RxList<Hashtag> get selectedHashtags => _shared.selectedHashtags;
  RxBool get isAutoMode => _shared.isAutoMode;

  // Real-time hashtags loaded from backend
  RxList<Hashtag> realTimeHashtags = <Hashtag>[].obs;
  RxBool isLoadingHashtags = false.obs;

  // Real-time categories
  RxList<Category> categoryList = <Category>[].obs;
  Rx<Category?> selectedCategory = Rx(null);
  Rx<SubCategory?> selectedSubCategory = Rx(null);
  Rx<Topic?> selectedTopic = Rx(null);

  // Host Avatar Edit
  Rx<XFile?> thumbnailFile = Rx(null);
  RxString thumbnailPreviewPath = ''.obs;

  // Music Player selection from device
  RxString selectedMusicPath = ''.obs;
  RxString selectedMusicName = ''.obs;

  // Preset Theme / Wallpaper Banners
  final List<String> presetBanners = [
    'https://images.unsplash.com/photo-1532375810709-75b1da00537c?w=800', // Indian flag
    'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800', // Sunset city aesthetic
    'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=800', // Modern classroom
    'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=800', // Library study
    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800', // Tech & Coding
  ];
  late final RxString selectedBackgroundPath;
  Rx<XFile?> customBackgroundFile = Rx(null);

  // Join Call seats selection for host
  RxInt maxParticipants = 8.obs;
  final List<int> seatOptions = [2, 4, 6, 8, 10, 12];
  Rx<int?> selectedThemeIndex = Rx(0);
  RxBool isStartingLive = false.obs;

  @override
  void onInit() {
    super.onInit();
    final user = myUser.value;
    nameController = TextEditingController(text: user?.fullname ?? 'Host');
    selectedBackgroundPath = presetBanners.first.obs;

    if (!Get.isRegistered<GoLiveSharedState>()) Get.put(GoLiveSharedState());
    fetchCategories();
    fetchRealTimeHashtags();
  }

  @override
  void onClose() {
    nameController.dispose();
    chatRoomController.dispose();
    descriptionController.dispose();
    super.onClose();
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

  Future<void> fetchRealTimeHashtags() async {
    isLoadingHashtags.value = true;
    try {
      final tags = await SearchService.instance.searchHashtags(keyword: '');
      if (tags.isNotEmpty) {
        realTimeHashtags.value = tags;
      } else {
        _setFallbackHashtags();
      }
    } catch (e) {
      Loggers.error('fetchRealTimeHashtags error: $e');
      _setFallbackHashtags();
    } finally {
      isLoadingHashtags.value = false;
    }
  }

  void _setFallbackHashtags() {
    realTimeHashtags.value = [
      Hashtag(id: 1, hashtag: 'SpokenEnglish'),
      Hashtag(id: 2, hashtag: 'MathsDoubt'),
      Hashtag(id: 3, hashtag: 'ScienceQuiz'),
      Hashtag(id: 4, hashtag: 'GovtExamPrep'),
      Hashtag(id: 5, hashtag: 'CodingTech'),
      Hashtag(id: 6, hashtag: 'GroupStudy'),
      Hashtag(id: 7, hashtag: 'DailyDoubt'),
    ];
  }

  void onLanguageChanged(Language? value) {
    _shared.onLanguageChanged(value);
  }

  void toggleHashtag(Hashtag hashtag) {
    _shared.toggleHashtag(hashtag);
  }

  void selectPresetBackground(String url) {
    customBackgroundFile.value = null;
    selectedBackgroundPath.value = url;
  }

  Future<void> pickCustomBackground() async {
    final image =
        await MediaPickerHelper.shared.pickImage(source: ImageSource.gallery);
    if (image != null) {
      customBackgroundFile.value = image;
      selectedBackgroundPath.value = image.path;
    }
  }

  Future<void> pickDeviceMusic() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null && result.files.single.path != null) {
        selectedMusicPath.value = result.files.single.path!;
        selectedMusicName.value = result.files.single.name;
      }
    } catch (e) {
      Loggers.error('pickDeviceMusic error: $e');
      showSnackBar('Could not pick audio file: $e');
    }
  }

  void clearSelectedMusic() {
    selectedMusicPath.value = '';
    selectedMusicName.value = '';
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
    if (user?.id == null) {
      showSnackBar('Please log in to start an audio live room');
      return;
    }
    if (isStartingLive.value) return;

    if (selectedLanguage.value == null && languageList.isNotEmpty) {
      selectedLanguage.value = languageList.first;
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      showSnackBar('Microphone permission is required to start live audio');
      return;
    }

    isStartingLive.value = true;
    try {
      String hostPhotoUrl = user!.profilePhoto ?? '';
      if (thumbnailFile.value != null) {
        final res = await CommonService.instance
            .uploadFileGivePath(thumbnailFile.value!);
        if (res.data != null && res.data!.isNotEmpty) {
          hostPhotoUrl = res.data!;
        }
      }

      String? backgroundUrl;
      if (customBackgroundFile.value != null) {
        final res = await CommonService.instance
            .uploadFileGivePath(customBackgroundFile.value!);
        if (res.data != null && res.data!.isNotEmpty) {
          backgroundUrl = res.data!;
        }
      } else if (selectedBackgroundPath.value.startsWith('http')) {
        backgroundUrl = selectedBackgroundPath.value;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final roomId = 'room_${user.id}_$now';

      final enteredName = nameController.text.trim();
      final hostDisplayName =
          enteredName.isNotEmpty ? enteredName : (user.fullname ?? 'Host');

      final roomTitle = chatRoomController.text.trim().isNotEmpty
          ? chatRoomController.text.trim()
          : (selectedCategory.value?.name != null
              ? "$hostDisplayName's ${selectedCategory.value!.name} Classroom"
              : "$hostDisplayName's Classroom");

      final hashtagString =
          selectedHashtags.map((h) => '#${h.hashtag}').join(' ');

      List<String> musicList = [];
      if (selectedMusicPath.value.isNotEmpty) {
        musicList.add(selectedMusicPath.value);
      }

      // 1. Call backend API to record the audio live room session (matching Video Call flow)
      var apiResult = await GiftWalletService.instance.startAudioRoomApi(
        roomId: roomId,
        roomName: roomTitle,
        languageId: selectedLanguage.value?.id,
      );

      // Auto-recover if already marked running server-side (same as Video Call flow)
      if (apiResult['status'] != true && apiResult['message'] == 'Audio room already running') {
        apiResult = await GiftWalletService.instance.startAudioRoomApi(
          roomId: roomId,
          roomName: roomTitle,
          languageId: selectedLanguage.value?.id,
          force: true,
        );
      }

      if (apiResult['status'] != true) {
        isStartingLive.value = false;
        showSnackBar(apiResult['message']?.toString() ?? 'Failed to start audio live');
        return;
      }

      final int? apiAudioRoomId = apiResult['data']?['id'] != null
          ? int.tryParse(apiResult['data']['id'].toString())
          : null;

      final room = AudioRoom(
        roomId: roomId,
        hostId: user.id,
        hostName: hostDisplayName,
        hostPhoto: hostPhotoUrl,
        roomName: roomTitle,
        description: descriptionController.text.trim(),
        maxParticipants: maxParticipants.value,
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
        musicUrls: musicList,
        backgroundImage: backgroundUrl,
        themeIndex: selectedThemeIndex.value ?? 0,
        categoryId: selectedCategory.value?.id,
        categoryName: selectedCategory.value?.name,
        targetDiamonds: 0,
        favouriteGiftTarget: 3,
      );

      // 2. Clear old live room subcollections in background (do NOT block navigation)
      try {
        final hostDocRef =
            _db.collection(FirebaseConst.audioRooms).doc(user.id.toString());
        hostDocRef.collection('comments').limit(100).get().then((oldComments) {
          if (oldComments.docs.isNotEmpty) {
            final batchDelete = _db.batch();
            for (final doc in oldComments.docs) {
              batchDelete.delete(doc.reference);
            }
            batchDelete.commit();
          }
        }).catchError((_) {});

        hostDocRef.collection('gifts').limit(100).get().then((oldGifts) {
          if (oldGifts.docs.isNotEmpty) {
            final batchGifts = _db.batch();
            for (final doc in oldGifts.docs) {
              batchGifts.delete(doc.reference);
            }
            batchGifts.commit();
          }
        }).catchError((_) {});
      } catch (e) {
        Loggers.error('Error clearing old live room subcollections: $e');
      }

      if (Get.isRegistered<AudioRoomController>()) {
        Get.delete<AudioRoomController>(force: true);
      }

      // 3. Write room to Firestore using non-blocking batch.commit() (matching Video Call flow)
      final WriteBatch batch = _db.batch();
      final DocumentReference roomRef =
          _db.collection(FirebaseConst.audioRooms).doc(user.id.toString());
      batch.set(roomRef, room.toJson());
      batch.commit();

      Loggers.success('Audio live room started successfully!');

      // 4. Immediately stop loading state and navigate to AudioRoomScreen
      isStartingLive.value = false;
      Get.to(() => AudioRoomScreen(
            room: room,
            isHost: true,
            apiAudioRoomId: apiAudioRoomId,
          ));
    } catch (e) {
      isStartingLive.value = false;
      Loggers.error('Audio onGoLive error: $e');
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

    return Obx(() {
      final bgPath = controller.selectedBackgroundPath.value;
      final isNetwork = bgPath.startsWith('http');
      final isLocal = bgPath.isNotEmpty && !isNetwork && File(bgPath).existsSync();

      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: ColorRes.blackPure,
          image: isNetwork
              ? DecorationImage(
                  image: NetworkImage(bgPath),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.38),
                    BlendMode.darken,
                  ),
                )
              : (isLocal
                  ? DecorationImage(
                      image: FileImage(File(bgPath)),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.38),
                        BlendMode.darken,
                      ),
                    )
                  : null),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top App Bar: Back button + "Host Live Show" + Language Pill
                  _buildTopBar(context, controller),

                  const SizedBox(height: 12),

                  // 2. Avatar & Auto Call Row
                  _buildAvatarAndAutoCall(controller),

                  const SizedBox(height: 16),

                  // 3. "Enter your name" input
                  _buildNameInput(controller),

                  const SizedBox(height: 14),

                  // 4. "Classroom Name" input with educational helper guide
                  _buildClassroomInput(controller),

                  const SizedBox(height: 14),

                  // 5. "Classroom Description" input
                  _buildDescriptionInput(controller),

                  const SizedBox(height: 14),

                  // 6. "Select Hashtag" horizontal tags
                  _buildHashtagSelector(context, controller),

                  const SizedBox(height: 10),

                  // 7. Join Call Seats selector (Host controls seat count)
                  _buildSeatSelector(controller),

                  const SizedBox(height: 14),

                  // 8. "Select Image / Banner" Header
                  _buildBannerHeader(controller),

                  const SizedBox(height: 8),

                  // 9. Wallpaper / Theme Banners Horizontal List
                  _buildBannerSelector(controller),

                  const SizedBox(height: 14),

                  // 10. "🎵 Music Player" + "Add Music" Header
                  _buildMusicPlayerHeader(controller),

                  const SizedBox(height: 8),

                  // 11. Dedicated Music Player Card / Selection
                  _buildMusicPlayerContent(controller),

                  const SizedBox(height: 12),

                  // 12. Educational Quote Line
                  _buildEducationalQuote(),

                  const SizedBox(height: 18),

                  // 13. Large Orange "Go Live" Button
                  _buildGoLiveButton(controller),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ─── Sub-widgets ───

  Widget _buildTopBar(
      BuildContext context, CreateAudioRoomController controller) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Host Live Show',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        // Language Selector White Pill (as in reference: [ বাংলা ▾ ])
        Obx(() {
          final langTitle =
              controller.selectedLanguage.value?.title ?? 'English';
          return GestureDetector(
            onTap: () => _showLanguagePicker(context, controller),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    langTitle,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black87,
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAvatarAndAutoCall(CreateAudioRoomController controller) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: circular host avatar with "✏ Edit" badge
          Obx(() {
            final user = controller.myUser.value;
            final previewPath = controller.thumbnailPreviewPath.value;
            final hasLocalPreview =
                previewPath.isNotEmpty && File(previewPath).existsSync();

            return GestureDetector(
              onTap: controller.pickThumbnail,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasLocalPreview
                          ? Image.file(
                              File(previewPath),
                              width: 82,
                              height: 82,
                              fit: BoxFit.cover,
                            )
                          : CustomImage(
                              size: const Size(82, 82),
                              image: user?.profilePhoto?.addBaseURL(),
                              fullName: user?.fullname,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: -6,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 10),
                          SizedBox(width: 3),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Right side: Auto Call switch placed cleanly under the English language section
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Auto Call',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Obx(() => SizedBox(
                    width: 40,
                    height: 24,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Switch(
                        value: controller.isAutoMode.value,
                        onChanged: (v) => controller.isAutoMode.value = v,
                        activeThumbColor: ColorRes.primaryColor,
                        inactiveTrackColor: Colors.white24,
                      ),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput(CreateAudioRoomController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your name',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Text('😎', style: TextStyle(fontSize: 18)),
              ),
              Expanded(
                child: TextField(
                  controller: controller.nameController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter your name',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 14,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassroomInput(CreateAudioRoomController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Classroom Name',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: controller.chatRoomController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter classroom name',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Examples: Spoken English, Math Doubt Clearing, Science Quiz, UPSC & Govt Exam Prep, Coding & Tech Talk, Group Study',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionInput(CreateAudioRoomController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Classroom Description',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: controller.descriptionController,
            maxLines: 2,
            minLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter classroom description or agenda (optional)',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHashtagSelector(
      BuildContext context, CreateAudioRoomController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Hashtag',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 38,
          child: Obx(() {
            if (controller.isLoadingHashtags.value &&
                controller.realTimeHashtags.isEmpty) {
              return const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ColorRes.primaryColor,
                  ),
                ),
              );
            }

            return ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                ...controller.realTimeHashtags.map((h) {
                  return Obx(() {
                    final isSelected = controller.selectedHashtags
                        .any((element) => element.hashtag == h.hashtag);
                    return GestureDetector(
                      onTap: () => controller.toggleHashtag(h),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ColorRes.primaryColor.withValues(alpha: 0.22)
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? ColorRes.primaryColor
                                : Colors.white.withValues(alpha: 0.25),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '#${h.hashtag ?? ''}',
                            style: TextStyle(
                              color: isSelected
                                  ? ColorRes.primaryColor
                                  : Colors.white,
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                }),
                GestureDetector(
                  onTap: () => _showHashtagPickerSheet(context, controller),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
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
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSeatSelector(CreateAudioRoomController controller) {
    return Row(
      children: [
        Text(
          'Join Call Seats:',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Obx(() => Row(
                  children: controller.seatOptions.map((seats) {
                    final isSelected = controller.maxParticipants.value == seats;
                    return GestureDetector(
                      onTap: () => controller.maxParticipants.value = seats,
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ColorRes.primaryColor.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? ColorRes.primaryColor
                                : Colors.white.withValues(alpha: 0.2),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          '$seats Seats',
                          style: TextStyle(
                            color: isSelected
                                ? ColorRes.primaryColor
                                : Colors.white70,
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerHeader(CreateAudioRoomController controller) {
    return const Row(
      children: [
        Icon(Icons.photo_library_outlined, color: Colors.white, size: 17),
        SizedBox(width: 6),
        Text(
          'Select Image / Banner',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMusicPlayerHeader(CreateAudioRoomController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note_rounded, color: Colors.white, size: 17),
            SizedBox(width: 6),
            Text(
              'Music Player',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: controller.pickDeviceMusic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: ColorRes.primaryColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ColorRes.primaryColor,
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: ColorRes.primaryColor, size: 13),
                SizedBox(width: 3),
                Text(
                  'Add Music',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMusicPlayerContent(CreateAudioRoomController controller) {
    return Obx(() {
      final musicName = controller.selectedMusicName.value;
      if (musicName.isNotEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ColorRes.primaryColor.withValues(alpha: 0.65),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ColorRes.primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.audiotrack_rounded,
                  color: ColorRes.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      musicName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ready to stream as classroom background music',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: controller.pickDeviceMusic,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: controller.clearSelectedMusic,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.close, color: Colors.white70, size: 14),
                ),
              ),
            ],
          ),
        );
      }

      return GestureDetector(
        onTap: controller.pickDeviceMusic,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.library_music_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Background Music (Optional)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Tap "+ Add Music" to select audio from your device',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.add_circle_outline_rounded,
                color: ColorRes.primaryColor,
                size: 18,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEducationalQuote() {
    return Text(
      '“Education is the passport to the future, for tomorrow belongs to those who prepare for it today. 🎓”',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.8),
        fontSize: 11.5,
        fontStyle: FontStyle.italic,
        height: 1.3,
      ),
    );
  }

  Widget _buildBannerSelector(CreateAudioRoomController controller) {
    return SizedBox(
      height: 104,
      child: Obx(() {
        final activeBg = controller.selectedBackgroundPath.value;
        final customFile = controller.customBackgroundFile.value;

        return ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: [
            // Card 1: "[ + ] Add from Device"
            GestureDetector(
              onTap: controller.pickCustomBackground,
              child: Container(
                width: 74,
                height: 100,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 28),
                    SizedBox(height: 4),
                    Text(
                      'Add from\nDevice',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // If user uploaded a custom file from device, show it with preview
            if (customFile != null) ...[
              _buildWallpaperCard(
                imageProvider: FileImage(File(customFile.path)),
                isSelected: activeBg == customFile.path,
                onTap: () => controller.selectedBackgroundPath.value = customFile.path,
              ),
            ],

            // Preset sample banners
            ...controller.presetBanners.map((url) {
              return _buildWallpaperCard(
                imageProvider: NetworkImage(url),
                isSelected: activeBg == url,
                onTap: () => controller.selectPresetBackground(url),
              );
            }),
          ],
        );
      }),
    );
  }

  Widget _buildWallpaperCard({
    required ImageProvider imageProvider,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 100,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? ColorRes.primaryColor : Colors.transparent,
            width: isSelected ? 2.5 : 1,
          ),
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: ColorRes.primaryColor.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: isSelected
            ? Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: ColorRes.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildGoLiveButton(CreateAudioRoomController controller) {
    return Obx(() {
      final isLoading = controller.isStartingLive.value;
      return InkWell(
        onTap: isLoading ? null : controller.onGoLive,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ColorRes.primaryColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: ColorRes.primaryColor.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
              : Text(
                  'Go Live',
                  style: TextStyleCustom.unboundedMedium500(
                    color: Colors.white,
                    fontSize: 16.5,
                  ),
                ),
        ),
      );
    });
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
                  title: Text(
                    lang.title ?? '',
                    style: TextStyle(
                      color: isSelected ? ColorRes.primaryColor : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
