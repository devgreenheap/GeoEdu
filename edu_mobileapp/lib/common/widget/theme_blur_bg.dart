import 'package:flutter/material.dart';
import 'package:geoedu/utilities/asset_res.dart';

class ThemeBlurBg extends StatelessWidget {
  const ThemeBlurBg({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: const BoxDecoration(
        // color: Colors.black
        gradient: LinearGradient(
          colors: [
            Color(0xff022135),
            Color(0xff075E97),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
    // return Image.asset(
    //   AssetRes.icBackground,
    //   height: double.infinity,
    //   width: double.infinity,
    //   fit: BoxFit.cover,
    // );
  }
}
