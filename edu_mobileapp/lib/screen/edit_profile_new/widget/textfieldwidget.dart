import 'package:flutter/material.dart';
import 'package:geoedu/utilities/color_res.dart';

/// GIO EDU brand gradient (orange -> gold) — replaces the old purple-pink
/// gradient used across Edit Profile's fields, dropdowns and buttons.
const kFieldGradient = [ColorRes.primaryColor, ColorRes.gold];
const kLabelLavender = ColorRes.textDarkGrey;

class CustomDynamicField extends StatefulWidget {
  final String label;
  final String hint;
  final bool isRequired;
  final bool readOnly;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final EdgeInsets padding;
  final double height;
  final IconData? icon;
  final Function(String)? onChanged;
  const CustomDynamicField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.isRequired = false,
    this.readOnly = false,
    this.height = 54,
    this.keyboardType = TextInputType.text,
    this.icon,
    this.onChanged,
  });

  @override
  State<CustomDynamicField> createState() => _CustomDynamicFieldState();
}

class _CustomDynamicFieldState extends State<CustomDynamicField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Label
        RichText(
          text: TextSpan(
            text: widget.label,
            style: const TextStyle(
              color: kLabelLavender,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            children: widget.isRequired
                ? const [
                    TextSpan(
                      text: " *",
                      style: TextStyle(color: ColorRes.liveRed),
                    )
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 7),

        /// TextField UI — gradient pill border
        GradientPillBorder(
          isActive: !widget.readOnly,
          isFocused: _isFocused,
          height: widget.height,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            readOnly: widget.readOnly,
            onChanged: widget.onChanged,
            style: TextStyle(color: widget.readOnly ? Colors.white38 : Colors.white),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
              ),
              border: InputBorder.none,
              contentPadding: widget.padding,
              suffixIcon: widget.icon == null
                  ? null
                  : Icon(widget.icon, color: ColorRes.primaryColor, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared gradient-outline pill container used by [CustomDynamicField] and
/// [CustomDynamicDropdown] — a thin pink-to-purple gradient stroke around a
/// near-black fill, matching the reference design.
class GradientPillBorder extends StatelessWidget {
  final Widget child;
  final double height;
  final bool isActive;
  final bool isFocused;

  const GradientPillBorder({
    super.key,
    required this.child,
    required this.height,
    this.isActive = true,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: height,
      padding: EdgeInsets.all(isFocused ? 1.8 : 1.3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        gradient: isActive
            ? LinearGradient(
                colors: kFieldGradient,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isActive ? null : Colors.white.withValues(alpha: 0.06),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ColorRes.cardBackground,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: child,
      ),
    );
  }
}

class CustomDynamicDropdown extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final String hint;
  final IconData? icon;

  const CustomDynamicDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.isRequired = false,
    this.hint = "Select",
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Label
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: kLabelLavender,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            children: isRequired
                ? const [
                    TextSpan(
                      text: " *",
                      style: TextStyle(color: ColorRes.liveRed),
                    )
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 7),

        /// Dropdown Container (Same Design as TextField)
        GradientPillBorder(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: (value != null && items.contains(value)) ? value : null,
                isExpanded: true,
                dropdownColor: ColorRes.cardBackground,
                borderRadius: BorderRadius.circular(16),
                icon: Icon(icon ?? Icons.keyboard_arrow_down_rounded, color: ColorRes.primaryColor),
                style: const TextStyle(color: Colors.white),
                hint: Text(
                  hint,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                items: items
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final Function() onTap;
  final bool isEnabled;
  final bool isPrimary;
  final double height;
  final double width;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isEnabled = true,
    this.isPrimary = true,
    this.height = 54,
    this.width = double.infinity,
    this.borderRadius = 27,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(borderRadius),
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [ColorRes.primaryColor, ColorRes.orangeDark],
                )
              : null,
          color: isPrimary ? null : Colors.transparent,
          border: isPrimary
              ? null
              : Border.all(color: ColorRes.primaryColor, width: 1.4),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isPrimary) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
