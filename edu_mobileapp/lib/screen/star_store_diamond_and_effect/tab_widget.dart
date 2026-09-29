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
      "Diamonds",
      "Entry Effects",
    ];

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double tabWidth = constraints.maxWidth / tabs.length;
          return Stack(
            children: [
              /// Bottom subtle divider line
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),

              /// Glowing sliding gold indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: currentStep * tabWidth + (tabWidth * 0.15),
                bottom: 0,
                child: Container(
                  width: tabWidth * 0.7,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFFD54F)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                ),
              ),

              /// Tab items
              Row(
                children: List.generate(tabs.length, (index) {
                  bool isSelected = index == currentStep;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(index),
                      child: Center(
                        child: Text(
                          tabs[index],
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFFFB300)
                                : const Color(0xFF8E95A5),
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            fontSize: 15,
                            letterSpacing: 0.2,
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
