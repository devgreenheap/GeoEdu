import 'package:flutter/material.dart';



class AudioBackgroundImage extends StatelessWidget {
  const AudioBackgroundImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/audio-background-live.png',
        fit: BoxFit.cover,
      ),
    );
  }
}
