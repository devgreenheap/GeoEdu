import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Color palette + reusable components for the Login / Create Account / OTP
/// screens — ELO TV-inspired dark structure, GIO EDU branding (orange CTA,
/// green/gold identity). Deliberately separate from the app-wide
/// purple-pink `kFieldGradient` theme used elsewhere (edit profile, etc.).
class AuthColors {
  AuthColors._();

  static const background = Color(0xFF05070A);
  static const surface = Color(0xFF101318);
  static const inputBackground = Color(0xFF14181D);
  static const border = Color(0xFF2A2F35);
  static const primaryOrange = Color(0xFFFF6A00);
  static const orangePressed = Color(0xFFE85D00);
  static const gioGreen = Color(0xFF39A852);
  static const gioDarkGreen = Color(0xFF087F3E);
  static const gioGold = Color(0xFFF5C542);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA1A1AA);
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
}

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final bool isPassword;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool hasError;

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
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError
        ? AuthColors.error
        : _isFocused
            ? AuthColors.primaryOrange
            : AuthColors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 54,
      decoration: BoxDecoration(
        color: AuthColors.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: _isFocused ? 1.4 : 1),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: (widget.hasError ? AuthColors.error : AuthColors.primaryOrange)
                      .withValues(alpha: 0.28),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        obscureText: widget.isPassword && _obscure,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        inputFormatters: widget.inputFormatters,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: AuthColors.textPrimary, fontSize: 15),
        cursorColor: AuthColors.primaryOrange,
        decoration: InputDecoration(
          isDense: true,
          isCollapsed: true,
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: AuthColors.textSecondary, fontSize: 15),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
          prefixIcon: widget.icon == null
              ? null
              : Icon(widget.icon, color: AuthColors.textSecondary, size: 20),
          suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
          suffixIcon: widget.isPassword
              ? IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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

/// Country code + mobile number as ONE bordered field (not two separate
/// boxes) so its left/right edges and height line up exactly with every
/// other field on the screen.
class AuthMobileField extends StatefulWidget {
  final String countryCode;
  final List<String> countryCodes;
  final ValueChanged<String?>? onCountryCodeChanged;
  final TextEditingController controller;
  final bool enabled;
  final bool hasError;

  const AuthMobileField({
    super.key,
    required this.countryCode,
    required this.countryCodes,
    required this.onCountryCodeChanged,
    required this.controller,
    this.enabled = true,
    this.hasError = false,
  });

  @override
  State<AuthMobileField> createState() => _AuthMobileFieldState();
}

class _AuthMobileFieldState extends State<AuthMobileField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError
        ? AuthColors.error
        : _isFocused
            ? AuthColors.primaryOrange
            : AuthColors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 54,
      decoration: BoxDecoration(
        color: AuthColors.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: _isFocused ? 1.4 : 1),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: (widget.hasError ? AuthColors.error : AuthColors.primaryOrange)
                      .withValues(alpha: 0.28),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.phone_android_rounded, color: AuthColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                dropdownColor: AuthColors.surface,
                value: widget.countryCode,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AuthColors.textSecondary, size: 16),
                style: const TextStyle(color: AuthColors.textPrimary, fontSize: 15),
                items: widget.countryCodes
                    .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                    .toList(),
                onChanged: widget.enabled ? widget.onCountryCodeChanged : null,
              ),
            ),
          ),
          Container(width: 1, height: 24, color: AuthColors.border),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              style: const TextStyle(color: AuthColors.textPrimary, fontSize: 15),
              cursorColor: AuthColors.primaryOrange,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter mobile number',
                hintStyle: TextStyle(color: AuthColors.textSecondary, fontSize: 15),
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

class AuthPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final Widget? trailingIcon;

  const AuthPrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
    this.height = 54,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      borderRadius: BorderRadius.circular(height / 2),
      onTap: isLoading ? null : onTap,
      child: Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled ? AuthColors.orangePressed.withValues(alpha: 0.4) : AuthColors.primaryOrange,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  if (trailingIcon != null) ...[const SizedBox(width: 8), trailingIcon!],
                ],
              ),
      ),
    );
  }
}

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
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AuthColors.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasError ? AuthColors.error : AuthColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
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
                    ? AuthColors.textSecondary.withValues(alpha: 0.4)
                    : AuthColors.textSecondary,
                size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: AuthColors.surface,
                value: (value != null && items.contains(value)) ? value : null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AuthColors.textSecondary),
                hint: Text(hint,
                    style: const TextStyle(color: AuthColors.textSecondary, fontSize: 15),
                    overflow: TextOverflow.ellipsis),
                style: const TextStyle(color: AuthColors.textPrimary, fontSize: 15),
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
          style: const TextStyle(color: AuthColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
          children: mandatory
              ? const [TextSpan(text: ' *', style: TextStyle(color: AuthColors.error))]
              : null,
        ),
      ),
    );
  }
}

class AuthErrorText extends StatelessWidget {
  final String? error;

  const AuthErrorText(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Text(error!, style: const TextStyle(color: AuthColors.error, fontSize: 12)),
    );
  }
}
