import 'package:flutter/material.dart';
import 'package:geoedu/utilities/color_res.dart';

class StarStepTabs extends StatelessWidget {
  final int currentStep;
  final Function(int) onChanged;

  const StarStepTabs({
    super.key,
    required this.currentStep,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      "Diamond",
      "Entry effects",
    ];

    return Container(
      height: 50,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorRes.cardBackground, ColorRes.surfaceBackground],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double tabWidth = constraints.maxWidth / tabs.length;
          return Stack(
            children: [
              /// 🔹 Sliding Rounded Indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: currentStep * tabWidth,
                // top: 0,
                bottom: 0,
                child: Container(
                  width: tabWidth,
                  height: 3,
                  decoration: BoxDecoration(
                    color: ColorRes.primaryColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),

              /// 🔹 Tab Items
              Row(
                children: List.generate(tabs.length, (index) {
                  bool isSelected = index == currentStep;
                  return GestureDetector(
                    onTap: () => onChanged(index),
                    child: SizedBox(
                      width: tabWidth,
                      child: Center(
                        child: Text(
                          tabs[index],
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFb6ff52)
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
