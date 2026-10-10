import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/extensions/string_extension.dart';
import 'package:geoedu/common/manager/haptic_manager.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';

/// PK Battle Result Dialog for Win/Loss and Tie states matching GIO EDU reference screenshots
class PkBattleResultDialog extends StatelessWidget {
  final Map<String, dynamic> result;
  final bool isHost;
  final VoidCallback? onStartAnotherRound;
  final VoidCallback? onClose;

  const PkBattleResultDialog({
    super.key,
    required this.result,
    this.isHost = false,
    this.onStartAnotherRound,
    this.onClose,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> result,
    bool isHost = false,
    VoidCallback? onStartAnotherRound,
    VoidCallback? onClose,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => PkBattleResultDialog(
        result: result,
        isHost: isHost,
        onStartAnotherRound: onStartAnotherRound,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTie = result['is_tie'] == true;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Purple Result Card
              isTie ? _buildTieCard(context) : _buildWinLossCard(context),

              const SizedBox(height: 20),

              // Close button (White circle with dark X)
              GestureDetector(
                onTap: () {
                  HapticManager.shared.light();
                  Get.back();
                  onClose?.call();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close,
                      color: Color(0xFF1E1C2E),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// -------------------------------------------------------------
  /// WIN / LOSS RESULT CARD (Screenshot 3)
  /// -------------------------------------------------------------
  Widget _buildWinLossCard(BuildContext context) {
    final winnerName = result['winner_name']?.toString() ?? 'Winner';
    final winnerProfile = result['winner_profile']?.toString();
    final winnerScore = result['winner_score'] ?? 0;

    final loserName = result['loser_name']?.toString() ?? 'Opponent';
    final loserProfile = result['loser_profile']?.toString();
    final loserScore = result['loser_score'] ?? 0;

    final topSupporters = (result['top_supporters'] as List?) ?? [];

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Card Container
        Container(
          margin: const EdgeInsets.only(top: 48),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.1,
              colors: [
                Color(0xFF7A2EB8),
                Color(0xFF531A82),
                Color(0xFF330E53),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFFD700),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.35),
                blurRadius: 22,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Winner Name with sparkles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🦋', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      winnerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleCustom.outFitBold700(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('🦋', style: TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'won this round!',
                style: TextStyleCustom.outFitSemiBold600(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 10),

              // Winner score pill (💎 X)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B0A49),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diamond_rounded,
                        color: Color(0xFFE040FB), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$winnerScore',
                      style: TextStyleCustom.outFitBold700(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Top Supporters section
              Text(
                '$winnerName\'s Top Supporters',
                style: TextStyleCustom.outFitSemiBold600(
                  color: Colors.white,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 10),

              if (topSupporters.isNotEmpty)
                _buildTopSupportersList(topSupporters)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'No supporters this round',
                    style: TextStyleCustom.outFitRegular400(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 14),

              // Loser this Round section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Loser this Round',
                          style: TextStyleCustom.outFitMedium500(
                            color: Colors.white,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('👎', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CustomImage(
                          size: const Size(32, 32),
                          radius: 16,
                          image: loserProfile?.addBaseURL(),
                          fullName: loserName,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            loserName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyleCustom.outFitSemiBold600(
                              color: Colors.white,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$loserScore',
                              style: TextStyleCustom.outFitBold700(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.diamond_rounded,
                                color: Color(0xFFE040FB), size: 15),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Start Another Round button for host
              if (isHost && onStartAnotherRound != null) ...[
                const SizedBox(height: 16),
                _buildStartAnotherRoundButton(),
              ],
            ],
          ),
        ),

        // Floating Winner Avatar with Golden Crown
        Positioned(
          top: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Golden crown
              Image.asset(
                AssetRes.icCrown,
                width: 38,
                height: 28,
              ),
              const SizedBox(height: 2),
              // Avatar with glowing border
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 3.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.55),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CustomImage(
                  size: const Size(70, 70),
                  radius: 35,
                  image: winnerProfile?.addBaseURL(),
                  fullName: winnerName,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// -------------------------------------------------------------
  /// TIE RESULT CARD (Screenshot 2)
  /// -------------------------------------------------------------
  Widget _buildTieCard(BuildContext context) {
    final finalScore = result['final_score'] ?? 0;
    final user1Profile = result['winner_profile']?.toString() ??
        result['user1_profile']?.toString();
    final user1Name = result['winner_name']?.toString() ?? 'Host 1';
    final user2Profile = result['loser_profile']?.toString() ??
        result['user2_profile']?.toString();
    final user2Name = result['loser_name']?.toString() ?? 'Host 2';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 45),
          padding: const EdgeInsets.fromLTRB(22, 54, 22, 22),
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.1,
              colors: [
                Color(0xFF7A2EB8),
                Color(0xFF531A82),
                Color(0xFF330E53),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFFD700),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.35),
                blurRadius: 22,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "IT'S A TIE!" header
              Text(
                "IT'S A TIE!",
                style: TextStyleCustom.unboundedExtraBold800(
                  color: const Color(0xFFFF7A00),
                  fontSize: 24,
                ).copyWith(
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Final score pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B0A49),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diamond_rounded,
                        color: Color(0xFFE040FB), size: 19),
                    const SizedBox(width: 8),
                    Text(
                      '$finalScore',
                      style: TextStyleCustom.outFitBold700(
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),

              // Start Another Round button for host
              if (isHost && onStartAnotherRound != null) ...[
                const SizedBox(height: 20),
                _buildStartAnotherRoundButton(),
              ],
            ],
          ),
        ),

        // Floating Overlapping Avatars for Tie
        Positioned(
          top: 0,
          child: SizedBox(
            width: 140,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Left avatar
                Positioned(
                  left: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 2.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.45),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: CustomImage(
                      size: const Size(64, 64),
                      radius: 32,
                      image: user1Profile?.addBaseURL(),
                      fullName: user1Name,
                    ),
                  ),
                ),
                // Right avatar (overlapping)
                Positioned(
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 2.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.45),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: CustomImage(
                      size: const Size(64, 64),
                      radius: 32,
                      image: user2Profile?.addBaseURL(),
                      fullName: user2Name,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Top supporters list
  Widget _buildTopSupportersList(List supporters) {
    return Column(
      children: supporters.take(3).map((item) {
        final data = Map<String, dynamic>.from(item as Map);
        final name = data['name']?.toString() ?? 'Supporter';
        final profile = data['profile']?.toString();
        final diamonds = data['diamonds'] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFD700),
                ),
                child: const Center(
                  child: Icon(Icons.star, color: Colors.black, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              CustomImage(
                size: const Size(28, 28),
                radius: 14,
                image: profile?.addBaseURL(),
                fullName: name,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleCustom.outFitSemiBold600(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond_rounded,
                      color: Color(0xFFE040FB), size: 14),
                  const SizedBox(width: 3),
                  Text(
                    '$diamonds',
                    style: TextStyleCustom.outFitBold700(
                      color: const Color(0xFFFFD700),
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// "Start Another Round" button
  Widget _buildStartAnotherRoundButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF1744), Color(0xFFFF8A00)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF1744).withOpacity(0.45),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          HapticManager.shared.medium();
          Get.back();
          onStartAnotherRound?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚔️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              'Start Another Round',
              style: TextStyleCustom.outFitBold700(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
