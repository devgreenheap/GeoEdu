import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/common/widget/bottom_sheet_top_view.dart';
import 'package:geoedu/common/widget/text_button_custom.dart';
import 'package:geoedu/common/widget/text_field_custom.dart';
import 'package:geoedu/languages/languages_keys.dart';
import 'package:geoedu/model/user_model/user_model.dart';
import 'package:geoedu/utilities/app_res.dart';
import 'package:geoedu/utilities/theme_res.dart';

class AddEditLinksSheet extends StatefulWidget {
  final Link? link;
  final LinkType type;
  final Function(Link link) onLinksUpdate;

  const AddEditLinksSheet(
      {super.key, this.link, required this.onLinksUpdate, required this.type});

  @override
  State<AddEditLinksSheet> createState() => _AddEditLinksSheetState();
}

class _AddEditLinksSheetState extends State<AddEditLinksSheet> {
  TextEditingController linkController = TextEditingController();
  BaseController baseController = BaseController();

  @override
  void initState() {
    super.initState();
    linkController = TextEditingController(text: widget.link?.url ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
          color: const Color(0xFF1E1E1E),
          shape: const SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius.vertical(
                  top: SmoothRadius(cornerRadius: 40, cornerSmoothing: 1)))),
      child: SingleChildScrollView(
        child: Column(
          children: [
            BottomSheetTopView(
                title: widget.link == null
                    ? 'Add Instagram Link'
                    : 'Edit Instagram Link'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Instagram Profile URL',
                      style: TextStyle(color: Colors.white, fontSize: 17)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: linkController,
                    keyboardType: TextInputType.url,
                    style: const TextStyle(color: Colors.black, fontSize: 17),
                    cursorColor: Colors.black54,
                    decoration: InputDecoration(
                      hintText: 'Enter here',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 17),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextButtonCustom(
                onTap: _onSave,
                title: LKey.save.tr,
                titleColor: whitePure(context),
                backgroundColor: blackPure(context)),
            SizedBox(height: AppBar().preferredSize.height),
          ],
        ),
      ),
    );
  }

  void _onSave() async {
    if (linkController.text.trim().isEmpty) {
      return baseController.showSnackBar(LKey.urlEmpty.tr);
    }

    baseController.showLoader();
    var response = await UserService.instance.addEditDeleteUserLink(
        title: 'Instagram',
        linkId: widget.link?.id?.toInt(),
        urlLink: linkController.text.trim(),
        linkType: widget.type);
    baseController.stopLoader();
    Get.back();

    switch (widget.type) {
      case LinkType.add:
        widget.onLinksUpdate((response.data ?? []).last);
      case LinkType.edit:
        Link link = (response.data ?? [])
            .firstWhere((element) => element.id == widget.link?.id);
        widget.onLinksUpdate(link);
      case LinkType.delete:
    }
  }
}

enum LinkType { add, edit, delete }
