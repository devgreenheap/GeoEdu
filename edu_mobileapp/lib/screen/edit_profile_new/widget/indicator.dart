import 'package:flutter/material.dart';
import 'package:geoedu/utilities/color_res.dart';

class StepTabs extends StatelessWidget {
  final int currentStep;
  final List<String> tabs;
  final ValueChanged<int> onChanged;

  const StepTabs({
    super.key,
    required this.currentStep,
    required this.tabs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      color: Colors.black,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;
          final isActive = isCurrent || isCompleted;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: isActive
                                ? const LinearGradient(
                                    colors: [ColorRes.primaryColor, ColorRes.orangeDark],
                                  )
                                : null,
                            color: isActive ? null : ColorRes.cardBackground,
                            border: Border.all(
                              color: isActive
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCompleted)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                  ),
                                Text(
                                  tabs[index],
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.white54,
                                    fontSize: 11.5,
                                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index != tabs.length - 1)
                    Container(
                      width: 10,
                      height: 2,
                      color: isCompleted
                          ? ColorRes.primaryColor
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
