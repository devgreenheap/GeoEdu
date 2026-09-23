import 'package:flutter/material.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/widget/live_room/popular_host_avatar.dart';
import 'package:geoedu/model/general/coupon_model.dart';
import 'package:geoedu/common/service/api/gift_wallet_service.dart';
import 'package:geoedu/common/widget/loader_widget.dart';
import 'package:geoedu/screen/live_stream/live_home_page_widget/all_rooms_screen.dart';
import 'package:geoedu/screen/live_stream/live_home_page_widget/room_grid_with_banners.dart';
import 'package:geoedu/screen/star_score/widgets/diamond_purchase_bottom.dart';
import 'package:geoedu/screen/star_store_diamond_and_effect/star_store_diamond _screen.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/live_room/live_top_bar.dart';
import 'package:geoedu/screen/live_stream/live_home_page_widget/direct_call_level_widget.dart';
import 'package:geoedu/screen/live_stream/live_home_page_widget/geo_premium_banner_widget.dart';
import 'package:geoedu/screen/live_stream/live_home_page_widget/live_categories_list_widget.dart';
import 'package:geoedu/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:geoedu/screen/live_stream/livestream_screen/widget/live_stream_background_blur_image.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import '../../../common/widget/banner_carousel_new.dart';
import '../../../model/user_model/user_model.dart';

class LiveStreamSearchScreen extends StatefulWidget {
  final User? myUser;

  const LiveStreamSearchScreen({super.key, this.myUser});

  @override
  State<LiveStreamSearchScreen> createState() => _LiveStreamSearchScreenState();
}


class _LiveStreamSearchScreenState extends State<LiveStreamSearchScreen> {
  /// Changes made in this screen is made stateless to stateful, and initstate, that's are the only unwanted changes.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showBestOfferPopup();
    });
  }

  Future<void> _showBestOfferPopup() async {
    try {
      final packs = await GiftWalletService.instance.fetchDiamondPackages();
      if (packs.isEmpty || !mounted) return;
      // Pick the pack with the highest diamond count
      final best = packs.reduce((a, b) =>
          (a.diamonds ?? 0) > (b.diamonds ?? 0) ? a : b);
      showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        builder: (_) => DiamondPurchaseBottom(
          diamonds: '${best.diamonds ?? 0}',
          price: '${best.originalPrice ?? 0}',
          offerPrice: '${best.discountedPrice ?? 0}',
          diamondPackId: best.id,
          isOfferPopup: true,
        ),
      );
    } catch (_) {}
  }

  /// Changes made in this screen is stateless to stateful, and added initstate, that's are the only unwanted changes.


  @override
  Widget build(BuildContext context) {



    final controller = Get.put(LiveStreamSearchScreenController());
    return Stack(
      children: [
        const LiveStreamBlurBackgroundImage(),
        Column(
          children: [
            LiveTopBar(controller: controller, myUser: widget.myUser),
            const SizedBox(
              height: 5,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.onHomeRefresh,
                color: ColorRes.primaryColor,
                backgroundColor: ColorRes.cardBackground,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const DirectCallLevelWidget(),
                      const SizedBox(
                        height: 10,
                      ),
                      _PopularHostsRow(controller: controller),
                      const SizedBox(
                        height: 15,
                      ),
                      const LiveCategoriesListWidget(),
                      const SizedBox(
                        height: 15,
                      ),
                      _MergedRoomsGrid(controller: controller),
                      const SizedBox(
                        height: 20,
                      ),
                      const GeoPremiumBannerWidget(),
                      const SizedBox(
                        height: 20,
                      ),
                      const BannerCarousel(),
                      const SizedBox(
                        height: 20,
                      ),
                      const CouponFloatBanner(),
                      const SizedBox(
                        height: 50,
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ],
    );
  }
}

/// Horizontal carousel of currently-live hosts (video + audio), ranked by
/// viewer/listener count — see
/// [LiveStreamSearchScreenController.popularLiveHosts].
class _PopularHostsRow extends StatelessWidget {
  final LiveStreamSearchScreenController controller;

  const _PopularHostsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hosts = controller.popularLiveHosts;
      if (hosts.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Text('⭐', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text('Popular Hosts',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: hosts.length,
              itemBuilder: (context, index) {
                final host = hosts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: PopularHostAvatar(
                    photoUrl: host.hostPhotoUrl,
                    name: host.hostName.isNotEmpty ? host.hostName : host.title,
                    onTap: host.onTap,
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

/// Merged 2-column preview grid (video + recorded + audio), replacing the
/// previously separate Live Classrooms / Live Audio Rooms rows. Shows the
/// first 6 items with a "View All" leading to [AllRoomsScreen] for the
/// full list, mirroring the header pattern already used above it.
class _MergedRoomsGrid extends StatelessWidget {
  final LiveStreamSearchScreenController controller;

  const _MergedRoomsGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.filteredHomeRoomItems;
      final isInitialLoading = controller.isLoading.value && items.isEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Image.asset(AssetRes.liveStreamIcon, height: 26),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Live Chatrooms',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                GestureDetector(
                  onTap: () => Get.to(() => const AllRoomsScreen()),
                  child: const Text('View All',
                      style: TextStyle(color: ColorRes.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: LiveStreamSearchScreenController.roomFilterLabels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = controller.selectedRoomFilterIndex.value == index;
                return GestureDetector(
                  onTap: () => controller.onRoomFilterSelected(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? null : ColorRes.cardBackground,
                      gradient: isSelected ? ColorRes.primaryGradient : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      LiveStreamSearchScreenController.roomFilterLabels[index],
                      style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFFB8B8B8),
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty && !isInitialLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text('No live rooms right now', style: TextStyle(color: Color(0xFFB8B8B8), fontSize: 13)),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: RoomGridWithBanners(
                items: items.take(6).toList(),
                mainAxisExtent: 220,
              ),
            ),
          if (isInitialLoading) ...[
            const SizedBox(height: 20),
            const LoaderWidget(),
          ],
        ],
      );
    });
  }
}

class CouponFloatBanner extends StatefulWidget {
  const CouponFloatBanner({super.key});

  @override
  State<CouponFloatBanner> createState() => _CouponFloatBannerState();
}

class _CouponFloatBannerState extends State<CouponFloatBanner> {
  Coupon? latestCoupon;

  @override
  void initState() {
    super.initState();
    _fetchLatestCoupon();
  }

  Future<void> _fetchLatestCoupon() async {
    try {
      final result = await CommonService.instance.fetchCoupons(limit: 1);
      if (result.status == true && (result.data ?? []).isNotEmpty) {
        final activeCoupon = result.data!.firstWhereOrNull((c) => c.isActive == 1);
        if (mounted && activeCoupon != null) {
          setState(() => latestCoupon = activeCoupon);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (latestCoupon == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Get.to(() => const StarStoreDiamondScreen()),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorRes.cardBackground,
          border: Border.all(color: ColorRes.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.percent_rounded, color: ColorRes.primaryColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Use "${latestCoupon!.code}" code for ${latestCoupon!.displayValue} off',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Text(
              "Use Now >",
              style: TextStyle(color: ColorRes.gold, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

