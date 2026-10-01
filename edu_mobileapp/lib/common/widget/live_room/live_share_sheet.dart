import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/screenshot_manager.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/utilities/app_res.dart';
import 'package:geoedu/utilities/asset_res.dart';

/// EloTV-style Live Stream Share Sheet:
/// Shows a branded purple card with the 2 circular avatars (User + Host),
/// "Join Me & [HOST]" title, and social sharing options (Stories, WhatsApp,
/// Telegram, Copy Link, More). Captures and shares the card image directly!
class LiveShareSheet extends StatefulWidget {
  final String hostName;
  final String? hostPhotoUrl;
  final String currentUserName; 
  final String? currentUserPhotoUrl;
  final String shareLink;
  final bool isAudio;
  final bool isHost;

  const LiveShareSheet({
    super.key,
    required this.hostName,
    required this.hostPhotoUrl,
    required this.currentUserName,
    required this.currentUserPhotoUrl,
    required this.shareLink,
    this.isAudio = false,
    this.isHost = false,
  });

  static void show({
    required BuildContext context,
    required String hostName,
    required String? hostPhotoUrl,
    required String currentUserName,
    required String? currentUserPhotoUrl,
    required String shareLink,
    bool isAudio = false,
    bool isHost = false,
  }) {
    Get.bottomSheet(
      LiveShareSheet(
        hostName: hostName,
        hostPhotoUrl: hostPhotoUrl,
        currentUserName: currentUserName,
        currentUserPhotoUrl: currentUserPhotoUrl,
        shareLink: shareLink,
        isAudio: isAudio,
        isHost: isHost,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  @override
  State<LiveShareSheet> createState() => _LiveShareSheetState();
}

class _LiveShareSheetState extends State<LiveShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  bool get _isHostSharing =>
      widget.isHost ||
      (widget.currentUserName.trim().toLowerCase() ==
              widget.hostName.trim().toLowerCase() &&
          widget.currentUserName.trim().isNotEmpty);

  Future<String?> _captureCardImage() async {
    try {
      final xFile = await ScreenshotManager.captureScreenshot(_cardKey);
      return xFile?.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareImageToPlatform(String platform) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final imagePath = await _captureCardImage();
      final shareText = AppRes.getLiveShareMessage(
        hostName: widget.hostName,
        smartLink: widget.shareLink,
        isHost: _isHostSharing,
      );
      final shareSubject = _isHostSharing
          ? (widget.isAudio ? 'Join My Audio Live' : 'Join My Live')
          : 'Join Me & ${widget.hostName}';

      if (imagePath != null && File(imagePath).existsSync()) {
        final xFile = XFile(imagePath);
        if (platform == 'more') {
          await SharePlus.instance.share(
            ShareParams(
              files: [xFile],
              text: shareText,
              subject: shareSubject,
            ),
          );
        } else if (platform == 'whatsapp') {
          // Share via share_plus with WhatsApp targeting if possible
          await SharePlus.instance.share(
            ShareParams(
              files: [xFile],
              text: shareText,
            ),
          );
        } else if (platform == 'telegram') {
          await SharePlus.instance.share(
            ShareParams(
              files: [xFile],
              text: shareText,
            ),
          );
        } else if (platform == 'stories') {
          await SharePlus.instance.share(
            ShareParams(
              files: [xFile],
              text: shareText,
            ),
          );
        }
      } else {
        // Fallback to text share
        await SharePlus.instance.share(
          ShareParams(
            text: shareText,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161616),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // THE SHAREABLE CARD (Wrapped with RepaintBoundary for high-res screenshot capture)
            RepaintBoundary(
              key: _cardKey,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Color(0xFF6B1D99),
                      Color(0xFF3F0B63),
                      Color(0xFF280442),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5A1485).withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Stack(
                  children: [
                    // Sunburst Radial Rays Background effect
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SunburstPainter(),
                      ),
                    ),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Branding: App Name + Play Store Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  AppRes.appName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5200),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Google Play Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.white30, width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_rounded,
                                      color: Colors.greenAccent, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'GET IT ON Google Play',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Profile Avatar(s): Single centered avatar if host sharing, two side-by-side if audience sharing
                        SizedBox(
                          height: 88,
                          child: _isHostSharing
                              ? Center(
                                  child: Container(
                                    width: 86,
                                    height: 86,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 3.5),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black38,
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: CustomImage(
                                        size: const Size(79, 79),
                                        image: widget.hostPhotoUrl?.addBaseURL(),
                                        fullName: widget.hostName,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Current User Avatar
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 3.5),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black38,
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: CustomImage(
                                          size: const Size(73, 73),
                                          image: widget.currentUserPhotoUrl?.addBaseURL(),
                                          fullName: widget.currentUserName,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Host Avatar
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 3.5),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black38,
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: CustomImage(
                                          size: const Size(73, 73),
                                          image: widget.hostPhotoUrl?.addBaseURL(),
                                          fullName: widget.hostName,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                        const SizedBox(height: 14),

                        // Title: "Join My Live" / "Join My Audio Live" (Host) or "Join Me & [HOST]" (Audience)
                        Text(
                          _isHostSharing
                              ? (widget.isAudio ? 'Join My Audio Live' : 'Join My Live')
                              : 'Join Me & ${widget.hostName.toUpperCase()}',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Subtitle
                        Text(
                          widget.isAudio
                              ? 'In Audio Live on ${AppRes.appName}'
                              : 'In Video Live on ${AppRes.appName}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // "Share with your friends" Heading
            const Text(
              'Share with your friends',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 16),

            // Share Options Icons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionIcon(
                  icon: Icons.gradient_rounded,
                  label: 'Stories',
                  bgGradient: const LinearGradient(
                    colors: [Color(0xFFFF3366), Color(0xFFFF9933)],
                  ),
                  onTap: () => _shareImageToPlatform('stories'),
                ),
                _buildActionIcon(
                  iconWidget: Image.asset(AssetRes.icWhatsapp,
                      width: 26, height: 26, color: Colors.white),
                  label: 'WhatsApp',
                  bgColor: const Color(0xFF25D366),
                  onTap: () => _shareImageToPlatform('whatsapp'),
                ),
                _buildActionIcon(
                  icon: Icons.send_rounded,
                  label: 'Telegram',
                  bgColor: const Color(0xFF0088CC),
                  onTap: () => _shareImageToPlatform('telegram'),
                ),
                _buildActionIcon(
                  iconWidget: Image.asset(AssetRes.icCopy,
                      width: 22, height: 22, color: Colors.white),
                  label: 'Copy Link',
                  bgColor: const Color(0xFF2C2C2E),
                  onTap: () async {
                    final copyMessage = AppRes.getLiveShareMessage(
                      hostName: widget.hostName,
                      smartLink: widget.shareLink,
                    );
                    await copyMessage.copyText;
                    Get.back();
                    Get.rawSnackbar(
                      message: 'Play Store link & invitation copied to clipboard!',
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
                _buildActionIcon(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  bgColor: const Color(0xFF2C2C2E),
                  onTap: () => _shareImageToPlatform('more'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    IconData? icon,
    Widget? iconWidget,
    Color? bgColor,
    LinearGradient? bgGradient,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              gradient: bgGradient,
            ),
            child: Center(
              child: iconWidget ??
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 26,
                  ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom sunburst radial rays painter for the branded share card
class _SunburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    const count = 28;
    const sweep = (2 * 3.14159265) / count;

    for (int i = 0; i < count; i += 2) {
      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: size.width * 1.2),
        i * sweep,
        sweep,
        false,
      );
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
