import 'package:flutter/material.dart';


class SlideFadeRight extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration visibleDuration;
  final double top;
  final double right;

  const SlideFadeRight({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.visibleDuration = const Duration(seconds: 3),
    this.top = 0,
    this.right = 0,
  });

  @override
  State<SlideFadeRight> createState() => _SlideFadeRightState();
}

class _SlideFadeRightState extends State<SlideFadeRight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fade = Tween<double>(begin: 1, end: 1).animate(_controller);

    _controller.forward();

    Future.delayed(widget.visibleDuration, () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      right: widget.right,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: widget.child,
        ),
      ),
    );
  }
}