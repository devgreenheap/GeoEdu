import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:geoedu/common/manager/logger.dart';

/// Real-time Beauty Filters sheet for video livestreaming.
/// Configures Zego Express Video preprocessing effects:
/// - Smooth / Polish (Skin softening)
/// - Whiten (Skin brightening)
/// - Rosy (Natural cheek blush)
/// - Sharpen (Edge clarity)
class LiveBeautyFilterSheet extends StatefulWidget {
  const LiveBeautyFilterSheet({super.key});

  /// Static state preserved across sheet opens
  static final RxBool isBeautyEnabled = true.obs;
  static final RxDouble smoothLevel = 50.0.obs;
  static final RxDouble whitenLevel = 50.0.obs;
  static final RxDouble rosyLevel = 35.0.obs;
  static final RxDouble sharpenLevel = 30.0.obs;

  static void show(BuildContext context) {
    // Apply current settings immediately when opening
    applyBeautySettings();

    Get.bottomSheet(
      const LiveBeautyFilterSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  static Future<void> applyBeautySettings() async {
    final bool enable = isBeautyEnabled.value;
    final int smooth = smoothLevel.value.toInt();
    final int whiten = whitenLevel.value.toInt();
    final int rosy = rosyLevel.value.toInt();
    final int sharpen = sharpenLevel.value.toInt();

    try {
      // 1. Zego Effects Beauty (Modern Zego API)
      await ZegoExpressEngine.instance.enableEffectsBeauty(enable);
      if (enable) {
        await ZegoExpressEngine.instance.setEffectsBeautyParam(
          ZegoEffectsBeautyParam(whiten, rosy, smooth, sharpen),
        );
      }
    } catch (e) {
      Loggers.warning('enableEffectsBeauty fallback: $e');
    }

    try {
      // 2. Zego Basic Beautify (Fallback for broad device support)
      await ZegoExpressEngine.instance.enableBeautify(enable ? 15 : 0);
      if (enable) {
        await ZegoExpressEngine.instance.setBeautifyOption(
          ZegoBeautifyOption(
            smooth / 100.0,
            whiten / 100.0,
            sharpen / 100.0,
          ),
        );
      }
    } catch (e) {
      Loggers.warning('enableBeautify fallback: $e');
    }
  }

  @override
  State<LiveBeautyFilterSheet> createState() => _LiveBeautyFilterSheetState();
}

class _LiveBeautyFilterSheetState extends State<LiveBeautyFilterSheet> {
  String _selectedPreset = 'Custom';

  void _applyPreset({
    required String name,
    required double smooth,
    required double whiten,
    required double rosy,
    required double sharpen,
  }) {
    setState(() {
      _selectedPreset = name;
      LiveBeautyFilterSheet.isBeautyEnabled.value = true;
      LiveBeautyFilterSheet.smoothLevel.value = smooth;
      LiveBeautyFilterSheet.whitenLevel.value = whiten;
      LiveBeautyFilterSheet.rosyLevel.value = rosy;
      LiveBeautyFilterSheet.sharpenLevel.value = sharpen;
    });
    LiveBeautyFilterSheet.applyBeautySettings();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141722).withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 25,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row: Title + Master Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.face_retouching_natural_rounded,
                        color: Color(0xFFFFB300), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Beauty & Filters',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Obx(() => Switch(
                      value: LiveBeautyFilterSheet.isBeautyEnabled.value,
                      activeThumbColor: const Color(0xFFFF7A19),
                      onChanged: (val) {
                        LiveBeautyFilterSheet.isBeautyEnabled.value = val;
                        LiveBeautyFilterSheet.applyBeautySettings();
                      },
                    )),
              ],
            ),

            const SizedBox(height: 10),

            // Presets Row
            Row(
              children: [
                _buildPresetChip('Natural', 35, 30, 25, 20),
                const SizedBox(width: 8),
                _buildPresetChip('Glowing', 65, 60, 45, 35),
                const SizedBox(width: 8),
                _buildPresetChip('Studio', 85, 75, 55, 45),
                const SizedBox(width: 8),
                _buildPresetChip('Reset', 0, 0, 0, 0),
              ],
            ),

            const Divider(color: Colors.white12, height: 24),

            // Sliders
            Obx(() {
              final enabled = LiveBeautyFilterSheet.isBeautyEnabled.value;
              return Opacity(
                opacity: enabled ? 1.0 : 0.4,
                child: IgnorePointer(
                  ignoring: !enabled,
                  child: Column(
                    children: [
                      _buildSliderRow(
                        icon: Icons.auto_fix_high_rounded,
                        label: 'Smooth Skin',
                        value: LiveBeautyFilterSheet.smoothLevel.value,
                        onChanged: (val) {
                          _selectedPreset = 'Custom';
                          LiveBeautyFilterSheet.smoothLevel.value = val;
                          LiveBeautyFilterSheet.applyBeautySettings();
                        },
                      ),
                      _buildSliderRow(
                        icon: Icons.wb_sunny_rounded,
                        label: 'Brighten',
                        value: LiveBeautyFilterSheet.whitenLevel.value,
                        onChanged: (val) {
                          _selectedPreset = 'Custom';
                          LiveBeautyFilterSheet.whitenLevel.value = val;
                          LiveBeautyFilterSheet.applyBeautySettings();
                        },
                      ),
                      _buildSliderRow(
                        icon: Icons.favorite_rounded,
                        label: 'Cheek Blush',
                        value: LiveBeautyFilterSheet.rosyLevel.value,
                        onChanged: (val) {
                          _selectedPreset = 'Custom';
                          LiveBeautyFilterSheet.rosyLevel.value = val;
                          LiveBeautyFilterSheet.applyBeautySettings();
                        },
                      ),
                      _buildSliderRow(
                        icon: Icons.details_rounded,
                        label: 'Clarity',
                        value: LiveBeautyFilterSheet.sharpenLevel.value,
                        onChanged: (val) {
                          _selectedPreset = 'Custom';
                          LiveBeautyFilterSheet.sharpenLevel.value = val;
                          LiveBeautyFilterSheet.applyBeautySettings();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(
      String label, double smooth, double whiten, double rosy, double sharpen) {
    final isSelected = _selectedPreset == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _applyPreset(
          name: label,
          smooth: smooth,
          whiten: whiten,
          rosy: rosy,
          sharpen: sharpen,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF7A19)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFFF7A19) : Colors.white12,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: const SliderThemeData(
                activeTrackColor: Color(0xFFFF7A19),
                inactiveTrackColor: Colors.white12,
                thumbColor: Color(0xFFFFB300),
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                trackHeight: 3,
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 100,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${value.toInt()}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
