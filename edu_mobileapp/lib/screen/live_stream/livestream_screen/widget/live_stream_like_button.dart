import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geoedu/common/extensions/common_extension.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/theme_res.dart';

class LiveStreamLikeButton extends StatefulWidget {
  final Function(Function())? onLikeTap;
  final VoidCallback onTap;
  final int? likeCount;
  final double size;

  const LiveStreamLikeButton({
    super.key,
    required this.onLikeTap,
    required this.onTap,
    this.likeCount,
    this.size = 40,
  });

  @override
  State<LiveStreamLikeButton> createState() => _LiveStreamLikeButtonState();
}

class _LiveStreamLikeButtonState extends State<LiveStreamLikeButton>
    with TickerProviderStateMixin {
  final List<ReactionAnimation> _reactions = [];

  @override
  void initState() {
    widget.onLikeTap?.call(_addReaction);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant LiveStreamLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onLikeTap != widget.onLikeTap) {
      widget.onLikeTap?.call(_addReaction);
    }
  }

  void _addReaction() {
    final reactionController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    final random = Random();
    final xAxisValue = random.nextDouble() * 20 * (random.nextBool() ? 1 : -1);

    final reaction = ReactionAnimation(
      controller: reactionController,
      xAxisAnimation: reactionController.drive(TweenSequence([
        TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: xAxisValue), weight: 20),
        TweenSequenceItem(
            tween: Tween<double>(begin: xAxisValue, end: 0.0), weight: 20),
      ])),
      opacityAnimation:
          reactionController.drive(Tween<double>(begin: 1.0, end: 0.0)),
      sizeAnimation:
          reactionController.drive(Tween<double>(begin: .8, end: 0.4)),
      reactionAnimation:
          reactionController.drive(Tween<double>(begin: 0.0, end: 1.0)),
    );

    _reactions.add(reaction);

    setState(() {});

    reactionController.forward().then((_) {
      if (mounted) {
        setState(() {
          _reactions.remove(reaction);
        });
      }
      reactionController.dispose();
    });
  }

  @override
  void dispose() {
    for (var reaction in _reactions) {
      reaction.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heartStack = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ..._reactions.map((reaction) {
          final double rotationAngle =
              (reaction.xAxisAnimation.value / 20) * pi / 6;
          return AnimatedBuilder(
            animation: reaction.controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(reaction.xAxisAnimation.value,
                    -170.0 * reaction.reactionAnimation.value),
                child: Transform.rotate(
                  angle: rotationAngle,
                  child: FadeTransition(
                    opacity: reaction.opacityAnimation,
                    child: Transform.scale(
                        scale: reaction.sizeAnimation.value, child: child),
                  ),
                ),
              );
            },
            child: _likeCircleWidget,
          );
        }),
        InkWell(
          onTap: widget.onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: _likeCircleWidget,
        ),
      ],
    );

    if (widget.likeCount == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: heartStack,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          heartStack,
          const SizedBox(height: 2),
          Text(
            widget.likeCount!.numberFormat,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget get _likeCircleWidget {
    final double iconSize = widget.size * (24 / 40);
    return Container(
      height: widget.size,
      width: widget.size,
      decoration:
          const BoxDecoration(shape: BoxShape.circle, color: ColorRes.likeRed),
      alignment: const Alignment(0, 0.15),
      child: Image.asset(
        AssetRes.icFillHeart,
        width: iconSize,
        height: iconSize,
        color: whitePure(context),
      ),
    );
  }
}

class ReactionAnimation {
  final AnimationController controller;
  final Animation<double> xAxisAnimation;
  final Animation<double> opacityAnimation;
  final Animation<double> sizeAnimation;
  final Animation<double> reactionAnimation;

  ReactionAnimation({
    required this.controller,
    required this.xAxisAnimation,
    required this.opacityAnimation,
    required this.sizeAnimation,
    required this.reactionAnimation,
  });
}
