import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/screen/edit_profile_screen/edit_profile_screen_controller.dart';
import 'package:geoedu/screen/edit_profile_screen/widget/add_edit_link_sheet.dart';
import 'package:geoedu/utilities/asset_res.dart';
import 'package:geoedu/utilities/text_style_custom.dart';
import 'package:geoedu/utilities/theme_res.dart';

class BuildLinkView extends StatelessWidget {
  final EditProfileScreenController controller;

  const BuildLinkView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(CupertinoIcons.link, color: Color(0xFFFF3B7F), size: 16),
            const SizedBox(width: 8),
            const Text('Social Links',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            const Spacer(),
            InkWell(
                onTap: controller.openAddEditLinkSheet,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF3B7F), width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.add, color: Color(0xFFFF3B7F), size: 14),
                      SizedBox(width: 4),
                      Text('Add',
                          style: TextStyle(
                              color: Color(0xFFFF3B7F), fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ))
          ],
        ),
        const SizedBox(height: 10),
        Obx(
          () => Column(
            children: List.generate(
              controller.links.length,
              (index) {
                Link link = controller.links[index];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF171717),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFC5246D), Color(0xFF6B4FD6)],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(CupertinoIcons.link, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              link.title ?? '',
                              style: TextStyleCustom.unboundedMedium500(
                                  color: Colors.white, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              link.url ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyleCustom.outFitLight300(
                                  color: Colors.white54, fontSize: 12),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      PopupMenuButton<LinkType>(
                        onSelected: (value) {
                          controller.handleLinkAction(value, link);
                        },
                        itemBuilder: (BuildContext context) {
                          final menuItems = <LinkType, String>{
                            LinkType.edit: LKey.edit.tr,
                            LinkType.delete: LKey.delete.tr
                          };

                          return menuItems.entries.map((entry) {
                            return PopupMenuItem<LinkType>(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                style: TextStyleCustom.outFitRegular400(
                                    color: textLightGrey(context),
                                    fontSize: 16),
                              ),
                            );
                          }).toList();
                        },
                        shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                                cornerRadius: 10, cornerSmoothing: 1)),
                        popUpAnimationStyle: const AnimationStyle(
                            curve: Curves.linear,
                            duration: Duration(milliseconds: 500)),
                        color: const Color(0xFF171717),
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08)),
                          alignment: Alignment.center,
                          child: Image.asset(AssetRes.icMore,
                              height: 18, width: 18, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
