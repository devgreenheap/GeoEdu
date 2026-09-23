import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/extensions/user_extension.dart';
import 'package:geoedu/common/functions/media_picker_helper.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/common/widget/confirmation_dialog.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/general/category_sub_category_topic_model.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/livestream/app_user.dart';
import 'package:geoedu/model/livestream/livestream.dart';
import 'package:geoedu/model/livestream/livestream_user_state.dart';
import 'package:geoedu/model/post_story/hashtag_model.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/live_stream/go_live_shared_state.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/host/livestream_host_screen.dart';
import 'package:geoedu/utilities/firebase_const.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class CreateLiveStreamScreenController extends BaseController {
  RxBool isRestricted = false.obs;
  bool isFrontCamera = true;
  FirebaseFirestore db = FirebaseFirestore.instance;
  ZegoExpressEngine zegoEngine = ZegoExpressEngine.instance;

  Rx<User?> get myUser => SessionManager.instance.getUser().obs;

  Setting? get _setting => SessionManager.instance.getSettings();
  Rx<Widget?> localView = Rx(null);
  RxInt localViewID = RxInt(-1);
  TextEditingController titleController = TextEditingController();

  // Language/hashtag/auto-call are shared with the Audio tab of the Go-Live
  // setup screen so switching tabs doesn't lose the host's choices.
  GoLiveSharedState get _shared => Get.find<GoLiveSharedState>();
  RxList<Language> get languageList => _shared.languageList;
  Rx<Language?> get selectedLanguage => _shared.selectedLanguage;
  RxList<Hashtag> get selectedHashtags => _shared.selectedHashtags;
  RxBool get isAutoMode => _shared.isAutoMode;

  // Category / SubCategory / Topic selection state
  RxList<Category> categoryList = <Category>[].obs;
  Rx<Category?> selectedCategory = Rx(null);
  Rx<SubCategory?> selectedSubCategory = Rx(null);
  Rx<Topic?> selectedTopic = Rx(null);

  // Host thumbnail (persisted, shown before the stream starts and in room
  // cards — separate from the live camera feed itself once streaming).
  Rx<XFile?> thumbnailFile = Rx(null);
  RxString thumbnailPreviewPath = ''.obs;

  // Video ON/OFF on the setup screen — off stops the camera preview here
  // and shows the host's avatar instead, matching the reference toggle.
  RxBool isVideoOn = true.obs;

  // Stream mode: video_room, direct_call, pk_battle
  RxString selectedStreamMode = 'video_room'.obs;
  final List<Map<String, String>> streamModes = [
    {'value': 'video_room', 'label': 'Video Room'},
    {'value': 'direct_call', 'label': 'Direct Call'},
    {'value': 'pk_battle', 'label': 'PK Battle'},
  ];

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<GoLiveSharedState>()) Get.put(GoLiveSharedState());
    initZegoEngine();
    fetchCategories();
  }

  @override
  void onClose() {
    super.onClose();
    stopPreview();
  }

  Future<void> fetchCategories() async {
    try {
      final result =
          await CommonService.instance.fetchCategorySubCategoryTopic();
      categoryList.value = result.data ?? [];
    } catch (e) {
      Loggers.error('fetchCategories error: $e');
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

  void pickThumbnail() async {
    final image = await MediaPickerHelper.shared.pickImage(source: ImageSource.gallery);
    if (image != null) {
      thumbnailFile.value = image;
      thumbnailPreviewPath.value = image.path;
    }
  }

  void onStreamModeChanged(String? value) {
    if (value != null) selectedStreamMode.value = value;
  }

  Future<bool> requestPermission() async {
    Loggers.info("requestPermission...");
    try {
      PermissionStatus microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        Loggers.error('Error: Microphone permission not granted!!!');
        return false;
      }
    } on Exception catch (error) {
      Loggers.error(
          "[ERROR], request microphone permission exception, $error");
      return false;
    }

    try {
      PermissionStatus cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        Loggers.error('[Error]: Camera permission not granted!!!');
        return false;
      }
    } on Exception catch (error) {
      Loggers.error("[ERROR], request camera permission exception, $error");
      return false;
    }

    return true;
  }

  void initZegoEngine() async {
    bool isPermissionGranted = await requestPermission();
    if (isPermissionGranted) {
      await initializeCameraPreview();
    } else {
      Get.bottomSheet(ConfirmationSheet(
          title: LKey.cameraMicrophonePermissionTitle.tr,
          description: LKey.cameraMicrophonePermissionDescription.tr,
          onTap: openAppSettings));
    }
  }

  Future<void> initializeCameraPreview() async {
    try {
      showLoader();
      await zegoEngine.enableCamera(true);
      await zegoEngine.mutePublishStreamAudio(false);
      zegoEngine.muteMicrophone(false);
      zegoEngine.useFrontCamera(true, channel: ZegoPublishChannel.Main);

      await zegoEngine.createCanvasView((viewID) async {
        localViewID.value = viewID;
        Loggers.info('LOCAL VIEW ID : $localViewID');
        ZegoCanvas previewCanvas =
            ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
        zegoEngine.startPreview(canvas: previewCanvas);
      }).then((canvasViewWidget) {
        localView.value = canvasViewWidget;
      });
    } catch (e, stackTrace) {
      Loggers.error('Failed to initialize camera preview: $e\n$stackTrace');
    } finally {
      stopLoader();
    }
  }

  void toggleCamera() {
    isFrontCamera = !isFrontCamera;
    zegoEngine.useFrontCamera(isFrontCamera, channel: ZegoPublishChannel.Main);
  }

  Future<void> toggleVideoOn(bool value) async {
    isVideoOn.value = value;
    if (value) {
      await initializeCameraPreview();
    } else {
      await stopPreview();
    }
  }

  void onCloseTap() {
    Get.back();
    stopPreview();
  }

  Future<void> stopPreview() async {
    zegoEngine.stopPreview();
    if (localViewID.value != -1) {
      await zegoEngine.destroyCanvasView(localViewID.value);
      localViewID.value = -1;
      localView.value = null;
    }
  }

  Future<void> onStartLive() async {
    if ((myUser.value?.followerCount ?? 0) <
        (_setting?.minFollowersForLive ?? 0)) {
      showSnackBar(LKey.minFollowersNeededToGoLive
          .trParams({'count': '${_setting?.minFollowersForLive}'}));
      return;
    }

    // The reference UI has no title field on the Video tab — derive one
    // from the chosen category (or the host's name) instead of blocking.
    if (titleController.text.trim().isEmpty) {
      titleController.text =
          selectedCategory.value?.name ?? myUser.value?.fullname ?? 'Live';
    }

    if (selectedCategory.value == null) {
      return showSnackBar('Please select a category');
    }

    if (selectedSubCategory.value == null) {
      return showSnackBar('Please select a sub category');
    }

    if (selectedTopic.value == null) {
      return showSnackBar('Please select a topic');
    }

    if (selectedLanguage.value == null) {
      return showSnackBar('Please select a language');
    }

    User? user = myUser.value;
    if (user == null) {
      Loggers.error('User Not found. Cannot start live stream.');
      return;
    }

    if (isVideoOn.value && localView.value == null) {
      showSnackBar('Local View not found');
      return;
    }

    showLoader();

    try {
      // Call the API first to get apiLiveStreamId
      var apiResult = await GiftWalletService.instance.startLiveStream(
        categoryId: selectedCategory.value!.id!,
        subCategoryId: selectedSubCategory.value!.id!,
        topicId: selectedTopic.value!.id!,
        languageId: selectedLanguage.value?.id,
        title: titleController.text.trim(),
      );

      // A stream from a previous session (e.g. app killed/crashed mid-live)
      // can be left marked active server-side with no way for the user to
      // ever end it normally. Auto-recover the same way the Home screen's
      // "Go Live" already silently cleans up the equivalent stale Firestore
      // state, instead of leaving the user permanently stuck.
      if (apiResult.status != true && apiResult.message == 'Live stream already running') {
        apiResult = await GiftWalletService.instance.startLiveStream(
          categoryId: selectedCategory.value!.id!,
          subCategoryId: selectedSubCategory.value!.id!,
          topicId: selectedTopic.value!.id!,
          languageId: selectedLanguage.value?.id,
          title: titleController.text.trim(),
          force: true,
        );
      }

      if (apiResult.status != true) {
        stopLoader();
        showSnackBar(apiResult.message ?? 'Failed to start live stream');
        return;
      }

      final apiLiveStreamId = apiResult.data?.id;

      // Then save to Firebase
      await _startFirestoreLive(apiLiveStreamId: apiLiveStreamId);
    } catch (e) {
      stopLoader();
      Loggers.error('startLiveStream error: $e');
      showSnackBar('Failed to start live stream');
    }
  }

  Future<void> _startFirestoreLive({int? apiLiveStreamId}) async {
    User? user = myUser.value;
    int userId = user?.id ?? -1;

    int time = DateTime.now().millisecondsSinceEpoch;

    final hashtagString = selectedHashtags
        .map((h) => '#${h.hashtag}')
        .join(' ');

    String? thumbnailPath;
    if (thumbnailFile.value != null) {
      final result = await CommonService.instance.uploadFileGivePath(thumbnailFile.value!);
      thumbnailPath = result.data;
    }

    Livestream livestream = user!.livestream(
      type: LivestreamType.livestream,
      time: time,
      description: titleController.text.trim(),
      restrictToJoin: isRestricted.value ? 1 : 0,
      hostViewId: localViewID.value,
      categoryId: selectedCategory.value?.id,
      categoryName: selectedCategory.value?.name,
      subCategoryId: selectedSubCategory.value?.id,
      subCategoryName: selectedSubCategory.value?.name,
      topicId: selectedTopic.value?.id,
      topicName: selectedTopic.value?.name,
      languageId: selectedLanguage.value?.id,
      languageName: selectedLanguage.value?.title,
      hashtag: hashtagString.isNotEmpty ? hashtagString : null,
      streamMode: selectedStreamMode.value,
      isAutoMode: isAutoMode.value,
      thumbnailUrl: thumbnailPath,
    );

    AppUser livestreamUser = user.appUser;

    LivestreamUserState livestreamUserState =
        user.streamState(time: time, stateType: LivestreamUserType.host);

    Loggers.info('Starting live stream...');

    try {
      DocumentReference livestreamRef =
          db.collection(FirebaseConst.liveStreams).doc('$userId');
      DocumentReference usersRef =
          db.collection(FirebaseConst.appUsers).doc('$userId');
      DocumentReference userStateRef =
          livestreamRef.collection(FirebaseConst.userState).doc('$userId');

      WriteBatch batch = db.batch();

      batch.set(livestreamRef, livestream.toJson());
      batch.set(usersRef, livestreamUser.toJson());
      batch.set(userStateRef, livestreamUserState.toJson());

      batch.commit();

      Loggers.success('Livestream started successfully!');

      Widget? hostPreview = localView.value;
      stopLoader();
      Get.to(() => LivestreamHostScreen(
          hostPreview: hostPreview,
          livestream: livestream,
          isHost: true,
          apiLiveStreamId: apiLiveStreamId));
    } catch (e, stackTrace) {
      stopLoader();
      Loggers.error('Failed to start live stream: $e');
      Loggers.error('StackTrace: $stackTrace');
    }
  }
}
