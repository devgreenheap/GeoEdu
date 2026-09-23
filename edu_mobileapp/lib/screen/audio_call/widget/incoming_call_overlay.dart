import 'package:flutter/material.dart';
import 'package:geoedu/common/widget/custom_image.dart';
import 'package:geoedu/model/audio_call/audio_call.dart';
import 'package:geoedu/utilities/color_res.dart';

class IncomingCallOverlay extends StatelessWidget {
  final AudioCall call;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallOverlay({
    super.key,
    required this.call,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF214f86), Color(0xFF021636)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                const Text(
                  'Incoming Audio Call',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                // Caller avatar with glow ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xffB6FF52).withValues(alpha: 0.35),
                          width: 6,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xffB6FF52).withValues(alpha: 0.8),
                            width: 6,
                          ),
                        ),
                        child: CustomImage(
                          size: const Size(120, 120),
                          image: call.callerPhoto,
                          radius: 60,
                          fullName: call.callerName,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  call.callerName ?? 'Unknown',
                  style: const TextStyle(
                    color: ColorRes.whitePure,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Audio Call',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
                const Spacer(flex: 3),
                // Accept / Reject buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 60, vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reject
                      Column(
                        children: [
                          GestureDetector(
                            onTap: onReject,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.call_end,
                                color: ColorRes.whitePure,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Decline',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                      // Accept
                      Column(
                        children: [
                          GestureDetector(
                            onTap: onAccept,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.call,
                                color: ColorRes.whitePure,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Accept',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
