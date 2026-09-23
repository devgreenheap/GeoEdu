import 'package:flutter/material.dart';
import 'package:geoedu/utilities/color_res.dart';

/// Pill-shaped filter chip, extracted from the category chip markup that
/// used to be inlined in LiveCategoriesListWidget so it can be reused by
/// the Go-Live setup screen's category picker too.
class CategoryTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? ColorRes.primaryColor : ColorRes.cardBackground,
          border: isSelected ? null : Border.all(color: ColorRes.bgGrey),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}
