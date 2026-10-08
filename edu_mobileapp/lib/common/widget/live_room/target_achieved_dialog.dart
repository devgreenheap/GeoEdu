import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/general/settings_model.dart';

/// Modal dialog celebrating that the host achieved their diamond or favorite gift target.
/// Matches the requirement:
/// - Attractive success message: "🎉 Target Achieved! You reached your goal!"
/// - "Increase Target" action button
/// - "Okay" confirmation button
/// - Supports both Audio and Video live rooms.
class TargetAchievedDialog extends StatelessWidget {
  final bool isDiamond;
  final int targetValue;
  final int currentValue;
  final Gift? gift;
  final VoidCallback onIncreaseTarget;
  final VoidCallback? onOkay;

  const TargetAchievedDialog({
    super.key,
    required this.isDiamond,
    required this.targetValue,
    required this.currentValue,
    this.gift,
    required this.onIncreaseTarget,
    this.onOkay,
  });

  static Future<void> show({
    BuildContext? context,
    required bool isDiamond,
    required int targetValue,
    required int currentValue,
    Gift? gift,
    required VoidCallback onIncreaseTarget,
    VoidCallback? onOkay,
  }) {
    HapticManager.shared.medium();
    final dialog = TargetAchievedDialog(
      isDiamond: isDiamond,
      targetValue: targetValue,
      currentValue: currentValue,
      gift: gift,
      onIncreaseTarget: onIncreaseTarget,
      onOkay: onOkay,
    );

    if (context != null) {
      return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => dialog,
      );
    } else {
      return Get.dialog(dialog, barrierDismissible: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isDiamond
        ? '🎉 Target Achieved!'
        : '🎉 Favorite Gift Goal Reached!';
    final subtitle = isDiamond
        ? 'You reached your goal of $targetValue Diamonds! 💎\nKeep the excitement going with your viewers!'
        : 'You collected all $targetValue of ${gift?.displayName ?? "Favorite Gifts"}! 🎁\nAwesome work achieving your goal!';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E232F), Color(0xFF141722)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6E00).withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Celebration Avatar Icon
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDiamond
                          ? [const Color(0xFFBA68C8), const Color(0xFF7B1FA2)]
                          : [const Color(0xFFFF9800), const Color(0xFFFF3D00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDiamond
                                ? const Color(0xFFBA68C8)
                                : const Color(0xFFFF5722))
                            .withValues(alpha: 0.5),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isDiamond
                        ? const Icon(
                            Icons.diamond_rounded,
                            color: Colors.white,
                            size: 40,
                          )
                        : (gift?.image != null
                            ? CustomImage(
                                size: const Size(44, 44),
                                image: gift!.image!.addBaseURL(),
                                fit: BoxFit.contain,
                              )
                            : const Icon(
                                Icons.card_giftcard_rounded,
                                color: Colors.white,
                                size: 40,
                              )),
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD54F),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Text('🎉', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Headline
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 16),

            // Progress Pill Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF00E676),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isDiamond ? 'Diamond Goal' : 'Gift Goal',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$currentValue / $targetValue',
                        style: const TextStyle(
                          color: Color(0xFFFFB300),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 1.0,
                      minHeight: 6,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E676),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // "Increase Target" Primary Action Button
            GestureDetector(
              onTap: () {
                HapticManager.shared.light();
                Navigator.of(context).pop();
                onIncreaseTarget();
              },
              child: Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A00), Color(0xFFFF3D00)],
                  ),
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Increase Target',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // "Okay" Secondary Confirmation Button
            GestureDetector(
              onTap: () {
                HapticManager.shared.light();
                Navigator.of(context).pop();
                onOkay?.call();
              },
              child: Container(
                width: double.infinity,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Okay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal bottom sheet for increasing the Favorite Gift goal.
class SetFavoriteGiftTargetSheet extends StatefulWidget {
  final Gift? gift;
  final int currentTarget;
  final int currentCount;
  final ValueChanged<int> onTargetSet;
  final VoidCallback onChangeGift;

  const SetFavoriteGiftTargetSheet({
    super.key,
    required this.gift,
    required this.currentTarget,
    required this.currentCount,
    required this.onTargetSet,
    required this.onChangeGift,
  });

  static Future<void> show(
    BuildContext context, {
    required Gift? gift,
    required int currentTarget,
    required int currentCount,
    required ValueChanged<int> onTargetSet,
    required VoidCallback onChangeGift,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SetFavoriteGiftTargetSheet(
        gift: gift,
        currentTarget: currentTarget,
        currentCount: currentCount,
        onTargetSet: onTargetSet,
        onChangeGift: onChangeGift,
      ),
    );
  }

  @override
  State<SetFavoriteGiftTargetSheet> createState() =>
      _SetFavoriteGiftTargetSheetState();
}

class _SetFavoriteGiftTargetSheetState
    extends State<SetFavoriteGiftTargetSheet> {
  late final TextEditingController _textController;
  int _selectedTarget = 0;

  @override
  void initState() {
    super.initState();
    // Default to current count + 3 or at least currentTarget + 3
    final suggested = (widget.currentCount > widget.currentTarget
            ? widget.currentCount
            : widget.currentTarget) +
        3;
    _selectedTarget = suggested;
    _textController = TextEditingController(text: suggested.toString());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onChipSelected(int target) {
    setState(() {
      _selectedTarget = target;
      _textController.text = target.toString();
    });
  }

  void _submit() {
    final value = int.tryParse(_textController.text.trim()) ?? 0;
    if (value > 0) {
      widget.onTargetSet(value);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final baseCount = widget.currentCount > widget.currentTarget
        ? widget.currentCount
        : widget.currentTarget;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 22,
        bottom: bottomInset + 22,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1B2228),
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
                  Icon(Icons.flag_rounded, color: Color(0xFFFF8A00), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Increase Gift Target',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, color: Colors.white70, size: 22),
              ),
            ],
          ),

          const SizedBox(height: 6),
          const Text(
            'Raise your target to inspire your audience to send more of this gift!',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),

          const SizedBox(height: 16),

          // Gift Info Preview
          if (widget.gift != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  CustomImage(
                    size: const Size(40, 40),
                    image: widget.gift?.image?.addBaseURL(),
                    radius: 8,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.gift?.displayName ?? 'Favorite Gift',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.diamond_rounded,
                                color: Color(0xFFBA68C8), size: 12),
                            const SizedBox(width: 3),
                            Text(
                              '${widget.gift?.coinPrice ?? 0} Diamonds',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onChangeGift();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          color: Color(0xFFFFB300),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Quick Chip Selection (+3, +5, +10)
          Text(
            'Quick Suggestions (Current: ${widget.currentCount}):',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [3, 5, 10].map((add) {
              final target = baseCount + add;
              final isSelected = _selectedTarget == target;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _onChipSelected(target),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF7A00).withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF7A00)
                              : Colors.white.withValues(alpha: 0.1),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '+$add ($target)',
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFFFB300)
                                : Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Custom Input Field
          TextField(
            controller: _textController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            onChanged: (val) {
              final parsed = int.tryParse(val.trim()) ?? 0;
              setState(() {
                _selectedTarget = parsed;
              });
            },
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Target Count',
              labelStyle: const TextStyle(color: Colors.white60),
              hintText: 'Enter new goal count',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFFFF8A00), width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Submit Button
          GestureDetector(
            onTap: _submit,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A00), Color(0xFFFF3D00)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Set New Target',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
