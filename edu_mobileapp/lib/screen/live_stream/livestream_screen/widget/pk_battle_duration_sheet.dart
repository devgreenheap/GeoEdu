import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/utilities/text_style_custom.dart';

/// Modal bottom sheet allowing the host to select PK Battle duration (2, 5, or 10 minutes)
/// before starting a new round or battle.
class PkBattleDurationSheet extends StatefulWidget {
  final int initialDuration;
  final ValueChanged<int> onStart;
  final VoidCallback? onCancel;

  const PkBattleDurationSheet({
    super.key,
    this.initialDuration = 2,
    required this.onStart,
    this.onCancel,
  });

  static Future<int?> show({
    int initialDuration = 2,
    required BuildContext context,
    required ValueChanged<int> onStart,
    VoidCallback? onCancel,
  }) async {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PkBattleDurationSheet(
        initialDuration: initialDuration,
        onStart: onStart,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<PkBattleDurationSheet> createState() => _PkBattleDurationSheetState();
}

class _PkBattleDurationSheetState extends State<PkBattleDurationSheet> {
  late int _selectedDuration;

  final List<int> _durations = [2, 5, 10];

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialDuration;
    if (!_durations.contains(_selectedDuration)) {
      _selectedDuration = 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1C2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF332D52), width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF1744), Color(0xFFFF8A00)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('⚔️', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PK Battle Duration',
                      style: TextStyleCustom.outFitBold700(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select duration for this PK round',
                      style: TextStyleCustom.outFitRegular400(
                        color: Colors.white60,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Duration option tiles (2, 5, 10 mins)
          for (final duration in _durations)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  HapticManager.shared.light();
                  setState(() => _selectedDuration = duration);
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedDuration == duration
                        ? const Color(0xFF6C29B7).withOpacity(0.35)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedDuration == duration
                          ? const Color(0xFFFFD700)
                          : Colors.white12,
                      width: _selectedDuration == duration ? 1.8 : 1.0,
                    ),
                    boxShadow: _selectedDuration == duration
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedDuration == duration
                                ? const Color(0xFFFFD700)
                                : Colors.white38,
                            width: 2,
                          ),
                          color: _selectedDuration == duration
                              ? const Color(0xFFFFD700)
                              : Colors.transparent,
                        ),
                        child: _selectedDuration == duration
                            ? const Icon(Icons.check, size: 14, color: Colors.black)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '$duration Minutes',
                        style: TextStyleCustom.outFitSemiBold600(
                          color: _selectedDuration == duration ? Colors.white : Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          duration == 2
                              ? 'Fast'
                              : duration == 5
                                  ? 'Standard'
                                  : 'Long',
                          style: TextStyleCustom.outFitMedium500(
                            color: _selectedDuration == duration
                                ? const Color(0xFFFFD700)
                                : Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 14),

          // Action buttons: Start Battle & Cancel
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Get.back();
                    widget.onCancel?.call();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyleCustom.outFitMedium500(
                      color: Colors.white60,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF1744), Color(0xFFFF8A00)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF1744).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      HapticManager.shared.medium();
                      Get.back();
                      widget.onStart(_selectedDuration);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Start Battle',
                      style: TextStyleCustom.outFitBold700(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
