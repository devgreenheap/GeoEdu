import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/model/general/leaderboard_user_model.dart';
import 'package:geoedu/model/general/settings_model.dart';

enum LeaderboardTabType {
  videoGifters,
  videoHosts,
  pkBattle,
  audioGifters,
  audioHosts,
}

class LeaderBoardController extends BaseController {
  static const List<String> periodLabels = [
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
  ];
  static const List<String> periodValues = [
    'today',
    'yesterday',
    'this_week',
    'this_month',
  ];

  final RxInt selectedTab = 0.obs;
  final RxInt selectedPeriod = 0.obs;
  final Rx<Language?> selectedLanguage = Rx(null);
  final RxList<Language> languageList = <Language>[].obs;

  final RxMap<int, List<LeaderboardUser>> rows = <int, List<LeaderboardUser>>{}.obs;
  final RxMap<int, LeaderboardUser?> myRank = <int, LeaderboardUser?>{}.obs;
  final RxSet<int> loadingTabs = <int>{}.obs;

  int get myUserId => SessionManager.instance.getUser()?.id ?? -1;

  String get _period => periodValues[selectedPeriod.value];

  LeaderBoardController({int initialTab = 0, int initialPeriod = 0}) {
    selectedTab.value = initialTab;
    selectedPeriod.value = initialPeriod;
  }

  @override
  void onInit() {
    super.onInit();
    _fetchLanguages();
    fetchTab(selectedTab.value);
  }

  Future<void> _fetchLanguages() async {
    try {
      final result = await CommonService.instance.fetchLanguages();
      languageList.value = result.data ?? [];
    } catch (_) {}
  }

  void onTabChanged(int index) {
    selectedTab.value = index;
    if (!rows.containsKey(index)) fetchTab(index);
  }

  void onPeriodChanged(int index) {
    selectedPeriod.value = index;
    _refetchAll();
  }

  void onLanguageChanged(Language? language) {
    selectedLanguage.value = language;
    _refetchAll();
  }

  /// Period and language apply to every tab, so cached tabs must be dropped
  /// rather than left showing results for the old filter.
  void _refetchAll() {
    rows.clear();
    myRank.clear();
    fetchTab(selectedTab.value);
  }

  Future<void> fetchTab(int index) async {
    loadingTabs.add(index);
    loadingTabs.refresh();
    try {
      final languageId = selectedLanguage.value?.id;
      final LeaderboardUsersModel model;
      switch (LeaderboardTabType.values[index]) {
        case LeaderboardTabType.videoGifters:
          model = await CommonService.instance.fetchTopGifters(
              period: _period, type: 'video', languageId: languageId);
          break;
        case LeaderboardTabType.videoHosts:
          model = await CommonService.instance.fetchTopHosts(
              period: _period, type: 'video', languageId: languageId);
          break;
        case LeaderboardTabType.pkBattle:
          model = await CommonService.instance
              .fetchTopPkBattlePlayers(period: _period);
          break;
        case LeaderboardTabType.audioGifters:
          model = await CommonService.instance.fetchTopGifters(
              period: _period, type: 'audio', languageId: languageId);
          break;
        case LeaderboardTabType.audioHosts:
          model = await CommonService.instance.fetchTopHosts(
              period: _period, type: 'audio', languageId: languageId);
          break;
      }
      rows[index] = model.data ?? [];
      myRank[index] = model.myRank;
    } catch (_) {
      rows[index] = [];
      myRank[index] = null;
    }
    loadingTabs.remove(index);
    loadingTabs.refresh();
  }

  Future<void> refreshCurrentTab() => fetchTab(selectedTab.value);

  bool isTabLoading(int index) => loadingTabs.contains(index);

  List<LeaderboardUser> usersOf(int index) => rows[index] ?? [];

  Future<void> toggleFollow(LeaderboardUser user) async {
    final userId = user.userId;
    if (userId == null || userId == myUserId) return;

    final wasFollowing = user.isFollowing;
    user.isFollowing = !wasFollowing;
    rows.refresh();

    final result = wasFollowing
        ? await UserService.instance.unFollowUser(userId: userId)
        : await UserService.instance.followUser(userId: userId);

    if (result.status != true) {
      user.isFollowing = wasFollowing;
      rows.refresh();
    }
  }
}
