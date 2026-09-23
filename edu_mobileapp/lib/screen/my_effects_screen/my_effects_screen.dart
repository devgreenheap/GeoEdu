import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/widget/custom_app_bar.dart';
import 'package:geoedu/model/star_store/effects_model.dart';
import 'package:geoedu/screen/my_effects_screen/my_effects_screen_controller.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyEffectsScreen extends StatefulWidget {
  const MyEffectsScreen({super.key});

  @override
  State<MyEffectsScreen> createState() => _MyEffectsScreenState();
}

class _MyEffectsScreenState extends State<MyEffectsScreen> {
  final controller = Get.put(MyEffectsScreenController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !controller.isLoadingMore.value &&
        controller.hasMore) {
      controller.fetchEffects(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: kSecondaryHeaderGradient)),
          ),
          Column(
            children: [
              const CustomAppBar(
                iconColor: ColorRes.whitePure,
                title: 'My Effects',
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.effects.isEmpty) {
                    return const Center(
                      child: Text(
                        'No effects purchased yet',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => controller.fetchEffects(),
                    child: ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.effects.length +
                          (controller.isLoadingMore.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == controller.effects.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _EffectCard(effect: controller.effects[index]);
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EffectCard extends StatelessWidget {
  final EntryEffectModel effect;

  const _EffectCard({required this.effect});

  @override
  Widget build(BuildContext context) {
    final expired = effect.isExpired;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff5C24B7), Color(0xff36404E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: effect.image,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 56,
                height: 56,
                color: Colors.white12,
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white38, size: 24),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: Colors.white12,
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white38, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  effect.title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  effect.durationHours != null
                      ? '${effect.durationHours} hours'
                      : effect.duration,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Status badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: expired
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: expired
                        ? Colors.redAccent.withValues(alpha: 0.6)
                        : Colors.greenAccent.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Text(
                  expired ? 'Expired' : 'Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: expired ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
              ),
              if (!expired) ...[
                const SizedBox(height: 4),
                Text(
                  effect.remainingTimeDisplay,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
