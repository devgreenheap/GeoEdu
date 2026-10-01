import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/general/settings_model.dart';
import 'package:geoedu/utilities/color_res.dart';

class FavouriteGiftSheet extends StatefulWidget {
  final int? currentFavGiftId;
  final List<Gift> availableGifts;
  final ValueChanged<Gift> onSetGift;
  final VoidCallback onRemoveGift;

  const FavouriteGiftSheet({
    super.key,
    required this.currentFavGiftId,
    required this.availableGifts,
    required this.onSetGift,
    required this.onRemoveGift,
  });

  static void show({
    required BuildContext context,
    required int? currentFavGiftId,
    required List<Gift> availableGifts,
    required ValueChanged<Gift> onSetGift,
    required VoidCallback onRemoveGift,
  }) {
    Get.bottomSheet(
      FavouriteGiftSheet(
        currentFavGiftId: currentFavGiftId,
        availableGifts: availableGifts,
        onSetGift: onSetGift,
        onRemoveGift: onRemoveGift,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  @override
  State<FavouriteGiftSheet> createState() => _FavouriteGiftSheetState();
}

class _FavouriteGiftSheetState extends State<FavouriteGiftSheet> {
  Gift? _selectedGift;

  @override
  void initState() {
    super.initState();
    if (widget.currentFavGiftId != null && widget.availableGifts.isNotEmpty) {
      _selectedGift = widget.availableGifts.firstWhereOrNull(
        (g) => g.id == widget.currentFavGiftId,
      );
    }
    _selectedGift ??= widget.availableGifts.isNotEmpty ? widget.availableGifts.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final gifts = widget.availableGifts;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      decoration: const BoxDecoration(
        color: ColorRes.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.card_giftcard_rounded, color: Color(0xFFFF7A19), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Set Favourite Gift',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Get.back(),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, color: Colors.white70, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Highlight a gift to your viewers to help encourage more gifting during live.',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 18),
          if (gifts.isEmpty)
            const SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'No gifts available',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: gifts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  final isSelected = _selectedGift?.id != null && _selectedGift?.id == gift.id;
                  final isCurrentFav = widget.currentFavGiftId != null && widget.currentFavGiftId == gift.id;

                  String? badgeText;
                  if (gift.categoryName != null && gift.categoryName!.isNotEmpty) {
                    badgeText = gift.categoryName;
                  } else if (gift.createdAt != null &&
                      DateTime.now().difference(gift.createdAt!).inDays <= 7) {
                    badgeText = 'New';
                  }

                  return GestureDetector(
                    onTap: () => setState(() => _selectedGift = gift),
                    child: Container(
                      width: 80,
                      height: 110,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2E221B)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: const Color(0xFFFF7A19), width: 2)
                            : Border.all(color: Colors.transparent, width: 2),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              const SizedBox(height: 5),
                              SizedBox(
                                height: 16,
                                child: badgeText != null
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: badgeText.toLowerCase().contains('love')
                                              ? const Color(0xFFE91E63)
                                              : const Color(0xFFFFB300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          badgeText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              Expanded(
                                child: Center(
                                  child: CustomImage(
                                    image: gift.image?.addBaseURL(),
                                    size: const Size(48, 48),
                                    fit: BoxFit.contain,
                                    radius: 4,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.diamond, color: Colors.white, size: 12),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${gift.coinPrice ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                          if (isCurrentFav)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFB300),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.star, size: 10, color: Colors.black),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              onPressed: () {
                if (_selectedGift != null) {
                  widget.onSetGift(_selectedGift!);
                  Get.back();
                }
              },
              child: const Text(
                'Set Gift',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (widget.currentFavGiftId != null) ...[
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () {
                  widget.onRemoveGift();
                  Get.back();
                },
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: Text(
                    'Remove Favourite Gift',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
