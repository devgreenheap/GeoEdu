import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geoedu/utilities/asset_res.dart';

/// Modal bottom sheet for setting live earning target in diamonds
/// matching the exact design:
/// - Title: Set Live Earning Target
/// - Diamond prefix icon + "Enter target in Diamonds" hint
/// - Orange warning icon + "Enter value between 1 – 99,999"
/// - "Set Target" button
class SetLiveTargetSheet extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onTargetSet;

  const SetLiveTargetSheet({
    super.key,
    required this.initialValue,
    required this.onTargetSet,
  });

  static Future<void> show(
    BuildContext context, {
    required int initialValue,
    required ValueChanged<int> onTargetSet,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SetLiveTargetSheet(
        initialValue: initialValue,
        onTargetSet: onTargetSet,
      ),
    );
  }

  @override
  State<SetLiveTargetSheet> createState() => _SetLiveTargetSheetState();
}

class _SetLiveTargetSheetState extends State<SetLiveTargetSheet> {
  late final TextEditingController _textController;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    final text = widget.initialValue > 0 ? widget.initialValue.toString() : '';
    _textController = TextEditingController(text: text);
    _validate(text);
    _textController.addListener(() => _validate(_textController.text));
  }

  void _validate(String value) {
    final parsed = int.tryParse(value.trim()) ?? 0;
    final valid = parsed >= 1 && parsed <= 99999;
    if (valid != _isValid) {
      setState(() => _isValid = valid);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_textController.text.trim()) ?? 0;
    if (value >= 1 && value <= 99999) {
      widget.onTargetSet(value);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 22,
        bottom: bottomInset + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1B2228),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Set Live Earning Target',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 18),

          // Input Box with Diamond icon prefix
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF151B21),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF6B7682),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // Diamond Icon (purple)
                Image.asset(
                  AssetRes.editDiamond,
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) => const Text(
                    '💎',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: Colors.white,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      hintText: 'Enter target in Diamonds',
                      hintStyle: TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Orange Info Message: ⓘ Enter value between 1 – 99,999
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Color(0xFFFF6622),
              ),
              SizedBox(width: 6),
              Text(
                'Enter value between 1 – 99,999',
                style: TextStyle(
                  color: Color(0xFFFF6622),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Set Target Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isValid ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isValid
                    ? const Color(0xFFFF5500)
                    : const Color(0xFF8B3A13),
                disabledBackgroundColor: const Color(0xFF8B3A13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Set Target',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
