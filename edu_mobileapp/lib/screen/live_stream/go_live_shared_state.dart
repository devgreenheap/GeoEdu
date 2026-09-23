import 'package:get/get.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/model/post_story/hashtag_model.dart';

/// Shared across the Go-Live setup screen's Video/Audio tabs so switching
/// tabs doesn't lose the host's language/hashtag/auto-call choices.
/// CreateLiveStreamScreenController and CreateAudioRoomController both read
/// and write through this instead of keeping their own copies of these 3
/// fields — everything else (category, room name, music, background, etc.)
/// stays independent per controller/tab.
class GoLiveSharedState extends GetxController {
  RxList<Language> languageList = <Language>[].obs;
  Rx<Language?> selectedLanguage = Rx(null);
  RxList<Hashtag> selectedHashtags = <Hashtag>[].obs;
  RxBool isAutoMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLanguages();
  }

  Future<void> fetchLanguages() async {
    try {
      final result = await CommonService.instance.fetchLanguages();
      languageList.value = result.data ?? [];
    } catch (e) {
      Loggers.error('GoLiveSharedState fetchLanguages error: $e');
    }
  }

  void onLanguageChanged(Language? value) {
    selectedLanguage.value = value;
  }

  void toggleHashtag(Hashtag hashtag) {
    final exists = selectedHashtags.any((h) => h.id == hashtag.id);
    if (exists) {
      selectedHashtags.removeWhere((h) => h.id == hashtag.id);
    } else {
      selectedHashtags.add(hashtag);
    }
  }
}
