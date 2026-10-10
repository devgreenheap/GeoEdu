import 'package:flutter/material.dart';
import 'package:geoedu/utilities/text_style_custom.dart';

/// Compact floating "Last Round" indicator pinned near top center
/// between the two host video feeds during PK Battle
class LastRoundIndicatorWidget extends StatelessWidget {
  final Map<String, dynamic>? lastRoundResult;

  const LastRoundIndicatorWidget({super.key, this.lastRoundResult});

  @override
  Widget build(BuildContext context) {
    if (lastRoundResult == null) return const SizedBox.shrink();

    final bool isTie = lastRoundResult!['is_tie'] == true;
    final String winnerName =
        lastRoundResult!['winner_name']?.toString() ?? 'Winner';
    final String loserName =
        lastRoundResult!['loser_name']?.toString() ?? 'Loser';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header "Last Round"
          Text(
            'Last Round',
            style: TextStyleCustom.outFitSemiBold600(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),

          // Content
          if (isTie)
            Text(
              'was a Tie 🙁',
              style: TextStyleCustom.outFitBold700(
                color: Colors.white,
                fontSize: 12,
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Winner green pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Winner 🥳',
                        style: TextStyleCustom.outFitBold700(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      if (winnerName.isNotEmpty) ...[
                        const SizedBox(width: 3),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 55),
                          child: Text(
                            winnerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyleCustom.outFitSemiBold600(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Loser red pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1744),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Loser 😭',
                        style: TextStyleCustom.outFitBold700(
                          color: Colors.white,
                        ),
                      ),
                      if (loserName.isNotEmpty) ...[
                        const SizedBox(width: 3),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 55),
                          child: Text(
                            loserName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyleCustom.outFitSemiBold600(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
