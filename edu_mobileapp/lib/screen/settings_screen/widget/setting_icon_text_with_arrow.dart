import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/utilities/asset_res.dart';

class SettingIconTextWithArrow extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? widget;
  final String count;
  final double height;
  final double width;
  final bool isBold;
  const SettingIconTextWithArrow({super.key,
    required this.icon,
    required this.title,
    this.count = "0",
    this.onTap,
    this.height = 18,
    this.width = 18,
    this.widget,
    this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Image.asset(icon,
                  height: height, width: width, color: const Color(0xFFFF7A00)),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(title.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  color: Colors.white,
                ),
            ),
            ),
            count != "0"
                ? Text(count, style: const TextStyle(color: Color(0xFFFF7A00), fontSize: 14, fontWeight: FontWeight.w700))
                : widget ??
                    Image.asset(
                      AssetRes.icForwardArrow,
                      width: 16,
                      height: 14,
                      color: Colors.white24,
                    ),
          ],
        ),
      ),
    );
  }
}
