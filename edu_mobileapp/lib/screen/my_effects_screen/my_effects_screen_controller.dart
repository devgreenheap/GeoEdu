import 'package:get/get.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/model/star_store/effects_model.dart';

class MyEffectsScreenController extends GetxController {
  final RxList<EntryEffectModel> effects = <EntryEffectModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  bool hasMore = true;
  int? lastItemId;

  @override
  void onInit() {
    super.onInit();
    fetchEffects();
  }

  Future<void> fetchEffects({bool loadMore = false}) async {
    if (loadMore) {
      if (isLoadingMore.value || !hasMore) return;
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
      effects.clear();
      lastItemId = null;
      hasMore = true;
    }

    try {
      final results = await GiftWalletService.instance
          .fetchMyEntryEffects(lastItemId: lastItemId);
      effects.addAll(results);
      if (results.isNotEmpty) {
        lastItemId = results.last.id;
      }
      if (results.isEmpty) {
        hasMore = false;
      }
    } catch (_) {}

    isLoading.value = false;
    isLoadingMore.value = false;
  }
}
