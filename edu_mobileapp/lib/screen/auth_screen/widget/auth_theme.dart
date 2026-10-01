import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ─── GeoEdu Auth Design System ────────────────────────────────────────────────
/// Premium dark-theme palette with orange CTA, green success, gold accents.
/// Glassmorphism surfaces, animated focus rings, gradient buttons.
class AuthColors {
  AuthColors._();

  // ── Backgrounds ──
  static const background    = Color(0xFF060810);
  static const surface       = Color(0xFF0F1218);
  static const cardSurface   = Color(0xFF131720);
  static const inputBg       = Color(0xFF141920);
  static const glassSurface  = Color(0x1AFFFFFF);

  // ── Borders ──
  static const border        = Color(0xFF252C38);
  static const borderFaint   = Color(0xFF1C2230);

  // ── Brand ──
  static const primaryOrange  = Color(0xFFFF6200);
  static const orangeLight    = Color(0xFFFF8A40);
  static const orangeDark     = Color(0xFFD94F00);
  static const gioGreen       = Color(0xFF2ECC71);
  static const gioDarkGreen   = Color(0xFF1A9950);
  static const gioGold        = Color(0xFFFFBB33);
  static const goldDark       = Color(0xFFE09900);

  // ── Text ──
  static const textPrimary    = Color(0xFFF2F4F8);
  static const textSecondary  = Color(0xFF8A93A6);
  static const textMuted      = Color(0xFF4A5568);

  // ── Feedback ──
  static const success        = Color(0xFF2ECC71);
  static const error          = Color(0xFFFF4757);
  static const warning        = Color(0xFFFFBB33);

  // ── Gradients ──
  static const List<Color> orangeGradient = [Color(0xFFFF6200), Color(0xFFFF9A3C)];
  static const List<Color> greenGradient  = [Color(0xFF1A9950), Color(0xFF2ECC71)];
  static const List<Color> goldGradient   = [Color(0xFFE09900), Color(0xFFFFBB33)];
  static const List<Color> bgGradient     = [Color(0xFF060810), Color(0xFF0B0F1A), Color(0xFF0F1520)];
}

// ─── Animated Gradient Button ─────────────────────────────────────────────────

class AuthPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final Widget? trailingIcon;
  final List<Color>? gradientColors;

  const AuthPrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
    this.height = 56,
    this.trailingIcon,
    this.gradientColors,
  });

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween<double>(begin: 1, end: 0.97).animate(
        CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final colors = widget.gradientColors ?? AuthColors.orangeGradient;

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) => _scaleCtrl.reverse(),
      onTapCancel: () => _scaleCtrl.reverse(),
      onTap: (widget.isLoading || disabled) ? null : widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: disabled
                ? null
                : LinearGradient(
                    colors: colors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: disabled ? AuthColors.border : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                      spreadRadius: -2,
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3),
                    ),
                    if (widget.trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      widget.trailingIcon!
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Glassmorphism Text Field ─────────────────────────────────────────────────

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final bool isPassword;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.icon,
    this.isPassword = false,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.hasError = false,
    this.onChanged,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  bool _isFocused = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut);
    _focusNode.addListener(() {
      final focused = _focusNode.hasFocus;
      setState(() => _isFocused = focused);
      focused ? _glowCtrl.forward() : _glowCtrl.reverse();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        widget.hasError ? AuthColors.error : AuthColors.primaryOrange;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) => Container(
        height: 56,
        decoration: BoxDecoration(
          color: AuthColors.inputBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.hasError
                ? AuthColors.error
                : _isFocused
                    ? AuthColors.primaryOrange
                    : AuthColors.border,
            width: _isFocused ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (_isFocused || widget.hasError)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25 * _glowAnim.value),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        obscureText: widget.isPassword && _obscure,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
            color: AuthColors.textPrimary, fontSize: 15, height: 1.2),
        cursorColor: AuthColors.primaryOrange,
        decoration: InputDecoration(
          isDense: true,
          isCollapsed: true,
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: const TextStyle(
              color: AuthColors.textSecondary, fontSize: 15),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 48, minHeight: 20),
          prefixIcon: widget.icon == null
              ? null
              : Icon(widget.icon,
                  color: _isFocused
                      ? AuthColors.primaryOrange
                      : AuthColors.textSecondary,
                  size: 20),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 48, minHeight: 20),
          suffixIcon: widget.isPassword
              ? IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AuthColors.textSecondary,
                    size: 20,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// ─── Phone Number Field ───────────────────────────────────────────────────────

class AuthMobileField extends StatefulWidget {
  final String countryCode;
  final List<String> countryCodes;
  final ValueChanged<String?>? onCountryCodeChanged;
  final TextEditingController controller;
  final bool enabled;
  final bool hasError;

  final ValueChanged<String>? onChanged;

  const AuthMobileField({
    super.key,
    required this.countryCode,
    required this.countryCodes,
    required this.onCountryCodeChanged,
    required this.controller,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
  });

  @override
  State<AuthMobileField> createState() => _AuthMobileFieldState();
}

class _AuthMobileFieldState extends State<AuthMobileField>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut);
    _focusNode.addListener(() {
      final focused = _focusNode.hasFocus;
      setState(() => _isFocused = focused);
      focused ? _glowCtrl.forward() : _glowCtrl.reverse();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        widget.hasError ? AuthColors.error : AuthColors.primaryOrange;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (ctx, child) => Container(
        height: 56,
        decoration: BoxDecoration(
          color: AuthColors.inputBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.hasError
                ? AuthColors.error
                : _isFocused
                    ? AuthColors.primaryOrange
                    : AuthColors.border,
            width: _isFocused ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (_isFocused || widget.hasError)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25 * _glowAnim.value),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.phone_android_rounded,
              color: _isFocused
                  ? AuthColors.primaryOrange
                  : AuthColors.textSecondary,
              size: 20),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                dropdownColor: AuthColors.cardSurface,
                value: widget.countryCode,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AuthColors.textSecondary, size: 16),
                style: const TextStyle(
                    color: AuthColors.textPrimary, fontSize: 15),
                items: widget.countryCodes
                    .map((code) =>
                        DropdownMenuItem(value: code, child: Text(code)))
                    .toList(),
                onChanged:
                    widget.enabled ? widget.onCountryCodeChanged : null,
              ),
            ),
          ),
          Container(
              width: 1,
              height: 26,
              color: AuthColors.border.withValues(alpha: 0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10)
              ],
              onChanged: widget.onChanged,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: const TextStyle(
                  color: AuthColors.textPrimary, fontSize: 15),
              cursorColor: AuthColors.primaryOrange,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter mobile number',
                hintStyle: TextStyle(
                    color: AuthColors.textSecondary, fontSize: 15),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

// ─── Dropdown Field ───────────────────────────────────────────────────────────

class AuthDropdownField extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final bool hasError;
  final IconData? icon;

  const AuthDropdownField({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hasError = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AuthColors.inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: hasError ? AuthColors.error : AuthColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon,
                color: disabled
                    ? AuthColors.textMuted
                    : AuthColors.textSecondary,
                size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: AuthColors.cardSurface,
                value: (value != null && items.contains(value)) ? value : null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AuthColors.textSecondary),
                hint: Text(hint,
                    style: const TextStyle(
                        color: AuthColors.textSecondary, fontSize: 15),
                    overflow: TextOverflow.ellipsis),
                style: const TextStyle(
                    color: AuthColors.textPrimary, fontSize: 15),
                items: items
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────

class AuthFieldLabel extends StatelessWidget {
  final String text;
  final bool mandatory;

  const AuthFieldLabel(this.text, {super.key, this.mandatory = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
              color: AuthColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2),
          children: mandatory
              ? const [
                  TextSpan(
                      text: ' *',
                      style: TextStyle(color: AuthColors.error))
                ]
              : null,
        ),
      ),
    );
  }
}

class AuthErrorText extends StatelessWidget {
  final String? error;
  final String? actionText;
  final VoidCallback? onAction;

  const AuthErrorText(this.error, {super.key, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    if (error == null || error!.isEmpty) return const SizedBox(height: 2);
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AuthColors.error, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: error!,
                style: const TextStyle(
                  color: AuthColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  if (actionText != null && onAction != null) ...[
                    const TextSpan(text: ' '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: GestureDetector(
                        onTap: onAction,
                        child: Text(
                          actionText!,
                          style: const TextStyle(
                            color: AuthColors.primaryOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: AuthColors.primaryOrange,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Icon Header ──────────────────────────────────────────────────────

class AuthSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color>? iconGradient;

  const AuthSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconGradient,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = iconGradient ?? AuthColors.orangeGradient;
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: gradient.map((c) => c.withValues(alpha: 0.18)).toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: gradient.first.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: gradient.last, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AuthColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      color: AuthColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
