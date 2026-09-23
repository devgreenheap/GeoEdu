import 'package:flutter/material.dart';
import 'package:geoedu/utilities/color_res.dart';

class EffectsToggle extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onChanged;

  const EffectsToggle({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = ["Buy Effects", "My Effects"];

    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: ColorRes.cardBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? ColorRes.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  color: isSelected
                      ? Colors.black
                      : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
